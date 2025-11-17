<!--
目的・役割: リポジトリ全体の意義・提供価値・利用方法を示すメインドキュメント（ビジネス視点・技術視点の両立）
作成日: 2025/11/17
-->

# XRPLutter — Tokenization & Atomic Operations Toolkit

XRPLutter は、XRPL 上でのトークナイゼーション（XLS-33 MPT/XLS-89メタデータ）と、複数操作の原子的実行（Batch）をシンプルな体験で実現するためのツールキットです。非カストディアル運用に必要なウォレット連携と安全設計（事前検証）を、開発者・運用者にとって扱いやすい構成で提供します。

## このリポジトリが提供する価値
- 規格準拠のトークナイゼーション:
  - XLS-89準拠の圧縮メタデータを自動生成・可視化
  - MPT発行時の運用フラグ（CanTransfer/RequireAuth/CanLock）設定と数値合算
- 安全設計と実務運用の両立:
  - Escrow（XRP/IOU/MPT）での時間条件ロックを実演
  - IOU事前検証（ネット参照）により、RequireAuth/GlobalFreeze/authorized/freeze/残高を送信前に確認
- 操作原子性による信頼性:
  - Batch（ALLORNOTHING/ONLYONE/UNTILFAILURE/INDEPENDENT）を比較・プレビューしてから原子的実行
  - 成功パターンの事前入力（例 `F,T,T`）→適用プレビュー（✔/✖）→実行→ログサマリ表示
- ウォレット連携の実装容易性:
  - Xaman（XUMM）をバックエンドプロキシ経由で安全に利用（BYOS最小テンプレートを同梱）
  - Crossmark/GemWallet/WalletConnect との連携骨子も用意

## モジュール構成
- `packages/xrplutter_sdk`:
  - 高レベルAPI群（`TokenService`/`EscrowService`/`BatchService`/`EscrowPreflightClient`/`WalletConnector`）
  - 目的: 規格準拠のトークナイゼーション操作と、署名・送信・進捗イベントの抽象化
- `apps/hackathon_demo`:
  - 初心者にも分かりやすい一枚UIの実演アプリ（ガイダンス付き）
  - 目的: 仕様・UX・安全設計を短時間で伝えるデモ体験の提供
- `templates/byos_proxy_minimal_vercel`:
  - Vercel 用の最小バックエンド（`/api/xumm/v1/*`）
  - 目的: フロントに秘密情報を置かずに Xaman/XUMM API を安全連携（CORS/JWT/RateLimit/可換ENV対応）

## ビジネス視点の意図（運用価値）
- 規制・運用要件への配慮: `RequireAuth` や `CanLock` を設定し、流通管理や譲渡制限を表現可能
- ユーザー体験の確実性: Batch による原子的実行で「中途半端な適用」を防ぎ、オンチェーン操作の信頼性を担保
- 誤操作の抑止: 事前検証ダイアログで失敗条件を明示し、送信前の合否判断を可能にする
- 導入容易性: 最小プロキシを同梱し、環境変数を設定するだけで Xaman 連携を開始可能

## クイックスタート（デモ）
1) 依存取得
```
cd apps/hackathon_demo
flutter pub get
```
2) 起動（Web）
```
flutter run -d web-server --web-port 53212
```
3) ブラウザで開く
```
http://localhost:53212/
```
4) 画面左上「Step 1: ウォレット接続」から、Xaman/WalletConnect/Crossmark/GemWallet を選択
5) 「Proxy 設定（Xaman最小構成）」で以下を入力
- `Xaman Proxy Base URL`: `https://<your-vercel-app>.vercel.app/api/xumm/v1/`
- `JWT Bearer Token`: サーバ側 `JWT_SECRET` で署名した短命JWT
6) 上から順に操作（圧縮メタデータ→Flags→Issue MPT + Escrow (Batch)→IOU事前検証→Batch比較）

## バックエンド（Vercel最小構成）
- ディレクトリ: `templates/byos_proxy_minimal_vercel`
- 公開ルート（Vercel Functions）:
  - `POST /api/xumm/v1/payload/create`
  - `GET  /api/xumm/v1/payload/status/:payloadId`
- 必須環境変数:
  - `JWT_SECRET`
  - `CORS_ORIGINS`（例: `http://localhost:53212`）
  - `XUMM_API_KEY` または `XAMAN_API_KEY`
  - `XUMM_API_SECRET` または `XAMAN_API_SECRET`
- 推奨環境変数:
  - `JWT_MAX_TTL_SECONDS`（既定 300）
  - `RL_WINDOW_SECONDS` / `RL_MAX_REQUESTS`
  - `STORAGE_BACKEND=memory` と `TTL_SECONDS`（Upstash利用時は `UPSTASH_REDIS_REST_URL/TOKEN`）

### 動作確認（例）
作成:
```
curl -X POST "https://<your-app>.vercel.app/api/xumm/v1/payload/create" \
 -H "authorization: Bearer <JWT>" \
 -H "content-type: application/json" \
 -d "{\"tx_json\":{\"TransactionType\":\"SignIn\"}}"
```
ステータス:
```
curl "https://<your-app>.vercel.app/api/xumm/v1/payload/status/<payloadId>" \
 -H "authorization: Bearer <JWT>"
```

## アーキテクチャ概要
- SDKレイヤ:
  - `TokenService`: MPT発行の `MPTokenIssuanceCreate` を構築、`compactMetadata` でXLS-89準拠の圧縮を提供
  - `EscrowService`: `EscrowCreate` など時間条件ロックを構築
  - `BatchService`: 複数操作の内包・モード制御（Feeのゼロ化の調整を例示）
  - `EscrowPreflightClient`: IOUの事前検証（ネット参照）
  - `WalletConnector`: 進捗イベント（created/opened/signed/submitted/canceled/error）を発火し、UXの観測性を担保
- デモレイヤ（hackathon_demo）:
  - 一枚UIで上から順に「設定→確認→実行→サマリ」と辿れる導線
- プロキシレイヤ（Vercel）:
  - CORSホワイトリスト、JWT検証、レート制限の最小ガードを用意

## セキュリティと運用注意
- 秘密情報はフロントへ置かない（XamanキーはVercel Functionsへ）
- JWTは短命運用を前提に検証（`exp`の過大値を拒否）
- CORSはホワイトリストのみ許可、ワイルドカードは不使用
- 送信前の事前検証により、凍結や認証不備による失敗を事前把握

## 期待される利用シナリオ
- トークナイゼーションの導入検討・社内実験
- 発行フローと運用フラグの検証（コンプライアンス方針の具体化）
- エンドユーザー向けの安全な署名UXのプロトタイプ

## ライセンス
MIT License