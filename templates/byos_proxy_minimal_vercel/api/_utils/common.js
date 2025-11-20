// -------------------------------------------------------
// 目的・役割: 共通ユーティリティ（CORS, JWT検証, JSON応答）を提供する
// 作成日: 2025/11/10
// 更新履歴:
// 2025/11/20 変更: JWT検証をalg/iss/audで強化しclockToleranceを追加
// 理由: 署名検証の安全性向上と誤受理防止のため
// 2025/11/20 変更: レート制限を原子的カウンタ実装に変更し1往復化
// 理由: Redis往復削減と高負荷時の一貫性確保のため
// -------------------------------------------------------

const jwt = require('jsonwebtoken');
const { getStore } = require('./store');

function getClientId(req) {
  const xf = req.headers['x-forwarded-for'];
  if (typeof xf === 'string' && xf.length > 0) return xf.split(',')[0].trim();
  try {
    return req.socket && req.socket.remoteAddress ? String(req.socket.remoteAddress) : 'unknown';
  } catch (_) {
    return 'unknown';
  }
}

async function rateLimit(req, res) {
  try {
    const store = getStore();
    const id = getClientId(req);
    const windowSec = parseInt(process.env.RL_WINDOW_SECONDS || '10', 10);
    const maxReq = parseInt(process.env.RL_MAX_REQUESTS || '20', 10);
    const key = `rl:${Math.floor(Date.now() / (windowSec * 1000))}:${id}`;
    const count = await (store.incrWithTtl ? store.incrWithTtl(key, windowSec) : (async () => {
      // フォールバック（ストアが未対応の場合のみ）
      const current = (await store.getWcSession(key)) || { count: 0 };
      current.count = (current.count || 0) + 1;
      await store.setWcSession(key, current);
      return current.count;
    })());
    if (count > maxReq) {
      res.statusCode = 429;
      res.setHeader('content-type', 'application/json');
      res.end(JSON.stringify({ error: 'rate limit exceeded' }));
      return false;
    }
    return true;
  } catch (_) {
    // ストア未構成時はレート制限をスキップ（最小構成）
    return true;
  }
}

function getAllowedOrigins() {
  return (process.env.CORS_ORIGINS || '')
    .split(',')
    .map((s) => s.trim())
    .filter(Boolean);
}

function allowCors(origin, res) {
  const allowed = getAllowedOrigins();
  if (origin && allowed.includes(origin)) {
    res.setHeader('Access-Control-Allow-Origin', origin);
  }
  // 厳格化: ワイルドカード許可は行わない
  res.setHeader('Access-Control-Allow-Credentials', 'false');
  res.setHeader('Access-Control-Allow-Headers', 'authorization, content-type');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Vary', 'Origin');
}

function handleCorsPreflight(req, res) {
  allowCors(req.headers.origin, res);
  if (req.method === 'OPTIONS') {
    res.statusCode = 200;
    res.end();
    return true;
  }
  return false;
}

function verifyJwt(req, res) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.substring(7) : null;
  if (!token) {
    res.statusCode = 401;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'missing token' }));
    return false;
  }
  try {
    const secret = process.env.JWT_SECRET;
    if (!secret) {
      res.statusCode = 500;
      res.setHeader('content-type', 'application/json');
      res.end(JSON.stringify({ error: 'server misconfigured: JWT_SECRET missing' }));
      return false;
    }
    const algs = (process.env.JWT_ALGORITHMS || 'HS256')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    const issuer = process.env.JWT_ISSUER;
    const audience = process.env.JWT_AUDIENCE;
    const verifyOpts = { algorithms: algs, clockTolerance: 2 };
    if (issuer) verifyOpts.issuer = issuer;
    if (audience) verifyOpts.audience = audience;
    const decoded = jwt.verify(token, secret, verifyOpts);
    const nowSec = Math.floor(Date.now() / 1000);
    const maxTtl = parseInt(process.env.JWT_MAX_TTL_SECONDS || '300', 10);
    if (typeof decoded === 'object' && decoded && typeof decoded.exp === 'number') {
      const ttl = decoded.exp - nowSec;
      if (ttl > maxTtl) {
        res.statusCode = 401;
        res.setHeader('content-type', 'application/json');
        res.end(JSON.stringify({ error: 'invalid token: exp too far' }));
        return false;
      }
    }
    return true;
  } catch (e) {
    res.statusCode = 401;
    res.setHeader('content-type', 'application/json');
    res.end(JSON.stringify({ error: 'invalid token' }));
    return false;
  }
}

function sendJson(res, obj) {
  res.statusCode = 200;
  res.setHeader('content-type', 'application/json');
  res.end(JSON.stringify(obj));
}

module.exports = {
  allowCors,
  handleCorsPreflight,
  rateLimit,
  verifyJwt,
  sendJson,
};
