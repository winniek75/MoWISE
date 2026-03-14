# MoWISE｜Step K セットアップガイド

## 必要条件
- Node.js 20.x 以上
- npm 10.x 以上
- Supabase アカウント（https://supabase.com）

---

## Step 1: パッケージのインストール

```bash
cd mowisse
npm install
```

---

## Step 2: 環境変数の設定

```bash
cp .env.example .env
```

`.env` を開き、Supabase の値を入力：

```env
VITE_SUPABASE_URL=https://xxxxxxxxxxxxxxxxxxxx.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

取得方法：Supabase ダッシュボード → 対象プロジェクト → Settings → API

---

## Step 3: Supabase スキーマ実行

1. Supabase ダッシュボード → SQL Editor を開く
2. `supabase_schema.sql` の内容を**全コピー**して貼り付ける
3. 「Run」をクリック
4. 全テーブルが作成されたことを確認（Table Editor で確認）

### 確認すべきテーブル（14個）

| テーブル名 | フェーズ |
|-----------|---------|
| users | MVP |
| mowi_state | MVP |
| checkins | MVP |
| patterns | MVP |
| pattern_content | MVP |
| pattern_progress | MVP |
| flash_output_logs | MVP |
| classes | MVP |
| class_members | MVP |
| chart_badges | MVP |
| battles | MVP |
| battle_logs | MVP |
| class_battles | Phase 2 |
| raids | Phase 2 |

---

## Step 4: Supabase Auth 設定

1. Supabase → Authentication → Providers
2. Email を有効化（デフォルトでオン）
3. （任意）Google OAuth を有効化

---

## Step 5: ローカル起動

```bash
npm run dev
```

http://localhost:5173 でアプリが起動します。

---

## Step 6: 動作確認チェックリスト

```
□ ブラウザで http://localhost:5173 が開く
□ /onboarding/1 にスプラッシュ画面が表示される
□ アカウント作成 → Supabase auth.users にレコードが作成される
□ auth.users 作成後 → users / mowi_state が自動生成される（トリガー確認）
□ オンボーディング5画面が遷移する
□ 正解後に Mowi の growth_stage が 1 になる
□ HOME 画面が正常に表示される
```

---

## Step 7: Capacitor セットアップ（iOS/Android）

```bash
npx cap init
npx cap add ios
npx cap add android
npm run build
npx cap sync
```

---

## ファイル構成

```
mowisse/
├── src/
│   ├── main.ts                   # エントリーポイント
│   ├── App.vue                   # ルートコンポーネント
│   ├── router/index.ts           # ルーティング（全画面定義）
│   ├── lib/supabase.ts           # Supabaseクライアント
│   ├── types/database.ts         # 全テーブルの型定義
│   ├── composables/useSM2.ts     # SM-2アルゴリズム
│   ├── stores/
│   │   ├── auth.ts               # 認証状態
│   │   ├── mowi.ts               # Mowi感情・輝き
│   │   ├── checkin.ts            # チェックイン日記
│   │   └── session.ts            # 練習セッション
│   ├── views/
│   │   ├── auth/                 # Auth コールバック
│   │   ├── onboarding/           # 1〜5画面（Step L）
│   │   ├── home/                 # HOME
│   │   ├── checkin/              # 朝・夜チェックイン（Step M）
│   │   ├── session/              # Layer 2・3 練習（Step M）
│   │   └── teacher/              # 先生ダッシュボード（Step N）
│   └── assets/styles/main.css   # デザイントークン・グローバルCSS
├── supabase_schema.sql           # ← Supabase SQL Editorに貼り付ける
├── .env.example                  # 環境変数テンプレート
├── capacitor.config.ts           # Capacitor設定
├── tailwind.config.js            # デザイントークン設定
├── vite.config.ts
└── package.json
```

---

## 次のステップ

- **Step K 完了後 → Step L（オンボーディング実装）**
  - `MoWISE_C_オンボーディング設計_v1_0.md` を参照
  - onboarding_events テーブルを追加（離脱分析用）

- **Step L 完了後 → Step M（コアゲームループ実装）**
  - `MoWISE_C2_チェックイン日記UX設計_v3_0.md`
  - `MoWISE_H2_コアゲームループUI設計_v1_0.md`
  - `MoWISE_P001_コンテンツ設計_v2.md`

---

*MoWISE Step K セットアップガイド*
*作成日：2026-03-11*
