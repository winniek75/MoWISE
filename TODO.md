
## 2026-07-03 Reading機能 Step 1（Claude / Fable 5 実装）
- ✅ DB: reading_* 5テーブル + reading_add_xp RPC + Storageバケット(reading/recordings) → 本番(mowisse)適用済み
- ✅ データ: B101「Where Is Momo?」投入済み（8ページ・5問）
- ✅ フロント: /reading ライブラリ・読書ビュー・クイズ3形式・XP連携・ゲーム画面に入口カード
- ⬜ 次: このコミットをpush → Vercel自動デプロイ → 実機確認
- ⬜ 次spec: Step 2（音読録音）。着手前にWinnieの体調・レビュー時間を確認
- 備考: TTSはaudio_url未配置時ブラウザ音声合成でフォールバック中。画像はプレースホルダー表示（docs/B101_image_prompts.md参照）
