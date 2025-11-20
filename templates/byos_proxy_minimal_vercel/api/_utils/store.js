// -------------------------------------------------------
// 目的・役割: ストレージ抽象（memory / upstash）を選択して提供する
// 作成日: 2025/11/10
// 更新履歴:
// 2025/11/20 変更: モジュールスコープのシングルトン化で初期化オーバーヘッドを削減
// 理由: コールドスタート短縮とUpstashクライアントの多重生成防止のため
// -------------------------------------------------------

const memoryStore = require('./store_memory');
let upstashStore = null;
let storeInstance = null;

function getBackend() {
  const b = (process.env.STORAGE_BACKEND || 'memory').toLowerCase();
  return b;
}

function getStore() {
  if (storeInstance) return storeInstance;
  const backend = getBackend();
  const ttl = parseInt(process.env.TTL_SECONDS || '600', 10);
  if (backend === 'upstash') {
    if (!upstashStore) {
      upstashStore = require('./store_upstash');
    }
    storeInstance = upstashStore.create(ttl);
    return storeInstance;
  }
  storeInstance = memoryStore.create(ttl);
  return storeInstance;
}

module.exports = {
  getStore,
};