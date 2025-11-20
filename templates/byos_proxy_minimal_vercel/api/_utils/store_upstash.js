// -------------------------------------------------------
// 目的・役割: Upstash Redis を用いたKVストア（本番/信頼性向上向け）
// 作成日: 2025/11/10
// 更新履歴:
// 2025/11/20 変更: 原子的カウンタ(incrWithTtl)を追加しレート制限を1往復化
// 理由: Redis往復回数削減と競合時一貫性確保のため
// -------------------------------------------------------

const { Redis } = require('@upstash/redis');

function create(ttlSeconds) {
  const url = process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.UPSTASH_REDIS_REST_TOKEN;

  if (!url || !token) {
    throw new Error('UPSTASH_REDIS_REST_URL/UPSTASH_REDIS_REST_TOKEN are required for STORAGE_BACKEND=upstash');
  }

  const redis = new Redis({ url, token });

  return {
    async setWcSession(id, obj) {
      await redis.set(`wc:${id}`, JSON.stringify(obj), { ex: ttlSeconds });
    },
    async getWcSession(id) {
      const s = await redis.get(`wc:${id}`);
      return s ? JSON.parse(s) : null;
    },
    async incrWithTtl(key, windowSec) {
      const count = await redis.incr(key);
      if (count === 1) {
        await redis.expire(key, windowSec);
      }
      return count;
    },
    async setXummPayload(id, obj) {
      await redis.set(`xumm:${id}`, JSON.stringify(obj), { ex: ttlSeconds });
    },
    async getXummPayload(id) {
      const p = await redis.get(`xumm:${id}`);
      return p ? JSON.parse(p) : null;
    },
  };
}

module.exports = { create };