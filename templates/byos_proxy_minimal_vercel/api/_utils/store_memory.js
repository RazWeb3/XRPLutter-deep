// -------------------------------------------------------
// 目的・役割: ステージング/PoC向けのメモリストア（揮発性）
// 作成日: 2025/11/10
// 更新履歴:
// 2025/11/20 変更: 原子的カウンタ(incrWithTtl)を追加しレート制限を1往復化
// 理由: ストア抽象の統一と性能改善のため
// -------------------------------------------------------

function create(ttlSeconds) {
  const wcMap = new Map();
  const xummMap = new Map();
  const counterMap = new Map();

  function setWithTtl(map, key, value) {
    map.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
  }

  function getWithTtl(map, key) {
    const item = map.get(key);
    if (!item) return null;
    if (item.expiresAt < Date.now()) {
      map.delete(key);
      return null;
    }
    return item.value;
  }

  function incrWithTtl(map, key, windowSec) {
    const now = Date.now();
    const item = map.get(key);
    if (!item || item.expiresAt < now) {
      const expiresAt = now + windowSec * 1000;
      const next = { value: { count: 1 }, expiresAt };
      map.set(key, next);
      return 1;
    }
    item.value.count = (item.value.count || 0) + 1;
    return item.value.count;
  }

  return {
    async setWcSession(id, obj) {
      setWithTtl(wcMap, `wc:${id}`, obj);
    },
    async getWcSession(id) {
      return getWithTtl(wcMap, `wc:${id}`);
    },
    async incrWithTtl(key, windowSec) {
      return incrWithTtl(counterMap, key, windowSec);
    },
    async setXummPayload(id, obj) {
      setWithTtl(xummMap, `xumm:${id}`, obj);
    },
    async getXummPayload(id) {
      return getWithTtl(xummMap, `xumm:${id}`);
    },
  };
}

module.exports = { create };
