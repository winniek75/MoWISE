# 開発spec: Service Worker更新時の自動リロード（controllerchange検知）

作成日: 2026-07-28 ／ 作成: 開発担当（Claude） ／ 実装: Claude Code
対象リポジトリ: `github.com/winniek75/MoWISE`（ポータル本体のみ）

---

## 1. 目的（なぜ作るか・ユーザー価値）

デプロイ後、既存ユーザーの端末が「リロード不要で」最新バンドルに切り替わるようにする。2026-07-28のログイン障害（旧SWが誤ったSupabase URL入りバンドルをキャッシュ配信）の再発防止・最後の仕上げ。

## 2. スコープ

**やる:**
- `src/main.ts` に `navigator.serviceWorker` の `controllerchange` イベントリスナーを追加し、新SWがページの制御を取得した瞬間に `window.location.reload()` を1回だけ実行する
- リロード無限ループ防止のガードフラグ（モジュールスコープの boolean）を必ず入れる

**やらない（今回の範囲外）:**
- 「新しいバージョンがあります」等の更新通知UI（トースト・モーダル）は作らない
- `vite.config.ts` の変更はしない（`registerType: 'autoUpdate'` + `skipWaiting` + `clientsClaim` は設定済み・変更不要）
- `index.html` の既存インラインスクリプト（SKIP_WAITING送信）は削除しない（無害なため現状維持）
- 19個のゲーム側リポジトリは触らない

## 3. 受け入れ条件（検証可能な形で）

- [ ] `src/main.ts` に controllerchange リスナーが追加され、ガードフラグ付きで1回のみリロードする
- [ ] `npm run build` が成功する
- [ ] デプロイ後、旧バージョンを開いている状態のタブが（新SWのインストール完了後）自動で1回リロードされ、最新バンドルになる
- [ ] リロードが繰り返し発生しない（DevTools > Application > Service Workers で確認）
- [ ] 通常の初回アクセス・ログイン動作に影響がない

## 4. 技術メモ

追加コードの参考実装（`app.mount('#app')` の後に配置）:

```ts
// SW更新時: 新SWが制御を取得したら1回だけリロードして最新バンドルへ
if ('serviceWorker' in navigator) {
  let refreshing = false
  navigator.serviceWorker.addEventListener('controllerchange', () => {
    if (refreshing) return
    refreshing = true
    window.location.reload()
  })
}
```

- 前提: `sw.js` は `skipWaiting()` + `clientsClaim()` 済みのため、新SWは待機せず即activateする。その瞬間に controllerchange が発火する
- 注意: 初回訪問（SWが初めて登録された時）も clientsClaim により controllerchange が発火しうる。ガードフラグはループ防止用であり、初回1回のリロードは許容（表示直後のため体感影響なし）。もし初回リロードを避けたい場合は `navigator.serviceWorker.controller` の有無をリスナー登録時に記録して分岐してよい（任意）
- 触るファイル: `src/main.ts` のみ

## 5. 体調とレビュー時間

体調: Winnie記入 ／ レビュー: 5分想定

## 6. レビュー方法（Winnieはコードを読まない）

1. デプロイ完了後、https://mowise.vercel.app を開いたまま放置
2. 次回の別デプロイ時に、開いていたタブが勝手に1回リロードされれば合格
3. すぐ確認したい場合: DevTools > Application > Service Workers で「Update」を押し、ページが1回だけリロードされることを確認

---

## 背景（引き継ぎ用・2026-07-28障害の記録）

- 原因: 旧SWが誤ったSupabase URL入りの旧バンドルをキャッシュ配信 → 本番からのログインリクエストがSupabaseに一切届かず失敗
- 対処済み: sw.jsに skipWaiting + clientsClaim + cleanupOutdatedCaches、Supabase auth/rest/realtime/functions は NetworkOnly 化（commit 6324c9d, e23e37a）
- 本specはその最終仕上げ。これ以降のデプロイは「開いているタブも含めて」自動で最新化される
