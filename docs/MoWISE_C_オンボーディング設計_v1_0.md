# MoWISE｜C オンボーディング設計書
**バージョン：v1.0**  
**策定日：2026年2月23日**  
**ステータス：設計確定・エンジニア実装引き渡し用**  
**関連設計書：C2（チェックイン日記）/ E（全画面設計書）/ A（Mowiアニメーション）**

---

## 設計の根幹思想

> **「Mowiとの出会いは、自分の英語力との出会いだ」**

- Mowiは「外からやってくるキャラクター」ではない。ユーザーの英語力そのものが、初めて「形」になって現れる瞬間を演出する
- オンボーディングの目的は **アカウント作成ではなく、内なる変化への気づきの種を植えること**
- 初回体験で「英語が怖い自分」「英語を楽しめる自分」のどちらの感覚も受け入れられると実感させる
- 3分以内でコアループ（朝チェックイン → 練習 → Mowiが変わる）を体験させ、「これが毎日続く」と体で理解させる

---

## ⏱️ 全体タイムライン目標

| フェーズ | 内容 | 目標時間 |
|---------|------|---------|
| Phase 1 | スプラッシュ〜Mowiとの出会い | 0:00〜0:30 |
| Phase 2 | ルート分岐〜アカウント作成 | 0:30〜1:00 |
| Phase 3 | 朝チェックイン（初回体験）| 1:00〜1:20 |
| Phase 4 | P001 練習（Layer 2のみ・3問）| 1:20〜2:20 |
| Phase 5 | Mowi変化の確認・ホーム到達 | 2:20〜3:00 |
| **合計** | **初回起動〜ホーム到達** | **≦ 3:00** |

---

## 🗺️ 全体フロー（画面遷移マップ）

```
【アプリ初回起動】
     ↓
【SPLASH】（1.5秒）
     ↓
【ONB_1：Mowi登場演出】（15秒）
     ↓
【ONB_2：ルート選択】（≦15秒）
     ↓
    ┌──────────────────────────────────┐
    ↓                ↓                ↓
【先生ルート】  【生徒ルート】  【ソロルート】
  ↓                 ↓               ↓
  アカウント作成（共通フォーム）
  + ルート別オプション入力
    ↓
【ONB_3：朝チェックイン（初回）】
    ↓
【MOWI_REACTION】（800ms）
    ↓
【ONB_4：P001 練習（3問のみ）】
    ↓
【ONB_5：Mowi変化・ホーム誘導】
    ↓
【HOME（初回版）】
```

---

## 📱 各画面の詳細設計仕様

---

### SCREEN ONB_0：スプラッシュ（初回共通）

**→ 詳細仕様：E設計書 SCREEN 01（SPLASH）に準拠**

初回起動時の特殊仕様として、1.5秒後に `ONB_1` へ遷移する（通常の HOME チェック分岐は行わない）。

---

### SCREEN ONB_1：Mowi登場演出（初回のみ）

#### ワイヤーフレーム

```
┌─────────────────────────────────────────┐
│  ステータスバー                           │
│─────────────────────────────────────────│
│                                         │
│                                         │
│                                         │
│     [暗い宇宙空間のような背景]            │
│     （#0d0d1a ・ 星のパーティクル）       │
│                                         │
│         ╔═══════════════╗               │
│         ║               ║               │
│         ║  [Mowi・登場]  ║   ← 画面中央  │
│         ║   (下からゆっ   ║               │
│         ║    くり浮上)   ║               │
│         ╚═══════════════╝               │
│                                         │
│     「ずっと、ここにいた。」              │
│     Been here all along.               │
│                                         │
│                                         │
│     （タップで次へ / 5秒で自動遷移）      │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

#### 演出シーケンス

| 時間 | アニメーション | テキスト |
|-----|-------------|--------|
| 0.0s | 背景：暗い宇宙グラデーション表示（#0d0d1a）| - |
| 0.0〜1.0s | 星のパーティクル、ゆっくりと生成開始（最大30粒・2px白点）| - |
| 1.0〜2.5s | Mowi、画面下から中央へ浮上（ease-decelerate）。サイズ：0px → 120px | - |
| 2.5〜3.0s | Mowiが中央でふわっと止まる。Idleアニメ（浮遊）開始 | テキスト fade-in |
| 3.0〜4.5s | テキスト表示 | 「ずっと、ここにいた。」/ "Been here all along." |
| 4.5〜5.0s | テキスト消える・次画面へ自動遷移 | - |

#### 詳細仕様

| 項目 | 仕様 |
|------|------|
| **背景** | #0d0d1a（深夜宇宙）。全面グラジエント不要。パーティクルのみ動的 |
| **Mowiサイズ** | 140px × 140px（通常より大きく。出会いの演出）|
| **テキスト** | 中央揃え。16sp（日本語）/ 14sp（英語・半透明）|
| **スキップ** | 画面どこでもタップ → 即次画面（ONB_2）へ |
| **自動遷移** | 5秒後に自動で ONB_2 へ |
| **BGM/SE** | ミュート（BGM非対応）。将来的に効果音追加を検討 |

#### このセリフの意図

「Mowiはどこか遠いところからやってきた」のではない。  
「ずっとここにいた（＝ずっとあなたの中に英語力はあった）」という本質を、最初の一言で伝える。

---

### SCREEN ONB_2：ルート選択

#### ワイヤーフレーム

```
┌─────────────────────────────────────────┐
│  ステータスバー                           │
│─────────────────────────────────────────│
│                                         │
│     [Mowi・Idle ・小さめ表示 60px]        │
│                                         │
│     「どんな立場で、英語と向き合う？」     │
│     What brings you to English?        │
│                                         │
│─────────────────────────────────────────│
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ 🏫  先生として使う                  │ │
│  │     英語を教えている / クラスを持つ   │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ 🎒  生徒として使う                  │ │
│  │     先生から教わっている / クラスがある│ │
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │ 🌿  ひとりで使う                    │ │
│  │     独学 / クラスなし               │ │
│  └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

#### 詳細仕様

| 項目 | 仕様 |
|------|------|
| **背景** | ONB_1 から slide-up で遷移。背景は同じ宇宙グラデーションを継続 |
| **Mowi** | 60px・上部に小さく配置（存在感は残す）。Idleアニメ継続 |
| **選択肢ボタン** | 幅100%・高さ80px・角丸16px・白背景80%透過・ボーダー#E0E0E0 |
| **スキップボタン** | **表示しない**（3択のどれかを必ず選ぶ設計）|
| **戻るボタン** | **表示しない**（ONB_1への戻り不要）|
| **タップ後** | 選択したルートに応じてアカウント作成画面（ONB_2A/B/C）へ slide-left |

#### ルート定義

| 選択肢ID | 日本語ラベル | ルート | role値 |
|---------|-----------|-------|--------|
| `route_teacher` | 先生として使う | 先生ルート → ONB_2A | `teacher` |
| `route_student` | 生徒として使う | 生徒ルート → ONB_2B | `student` |
| `route_solo` | ひとりで使う | ソロルート → ONB_2C | `solo` |

---

### SCREEN ONB_2A：アカウント作成（先生ルート）

#### ワイヤーフレーム

```
┌─────────────────────────────────────────┐
│  ← 戻る              先生アカウント     │
│─────────────────────────────────────────│
│                                         │
│   [Mowi・小さめ・上部右寄り 48px]         │
│                                         │
│  ── あなたについて教えてください ────────  │
│                                         │
│  表示名（ニックネーム）                   │
│  ┌─────────────────────────────────────┐ │
│  │ 例：Watanabe Sensei                 │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  メールアドレス                          │
│  ┌─────────────────────────────────────┐ │
│  │                                     │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  パスワード（8文字以上）                  │
│  ┌─────────────────────────────────────┐ │
│  │ ●●●●●●●●                           │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  ── クラスを作成する（任意・あとでも可）── │
│                                         │
│  クラス名                               │
│  ┌─────────────────────────────────────┐ │
│  │ 例：WISE English 水曜クラス          │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │        次へ進む →                   │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  すでにアカウントをお持ちですか？ ログイン │
│                                         │
└─────────────────────────────────────────┘
```

#### 詳細仕様

| 項目 | 仕様 |
|------|------|
| **入力フィールド** | 表示名（必須・max 20文字）/ メール（必須）/ パスワード（必須・min 8文字）/ クラス名（任意）|
| **クラス名入力** | スキップ可能。「あとで設定」リンクも表示 |
| **バリデーション** | メール形式チェック / パスワード強度表示（弱・普通・強）/ リアルタイムバリデーション |
| **「次へ」ボタン** | 必須フィールドが全て入力済みの場合のみアクティブ化 |
| **ログインリンク** | 既存ユーザー向け。タップでログインフォームへ（ONBフローから離脱）|
| **エラー表示** | フィールド下にインラインエラー。トースト通知なし |

---

### SCREEN ONB_2B：アカウント作成（生徒ルート）

#### ワイヤーフレーム

```
┌─────────────────────────────────────────┐
│  ← 戻る              生徒アカウント     │
│─────────────────────────────────────────│
│                                         │
│   [Mowi・小さめ・上部右寄り 48px]         │
│                                         │
│  ── あなたについて教えてください ────────  │
│                                         │
│  表示名（ニックネーム）                   │
│  ┌─────────────────────────────────────┐ │
│  │ 例：Kenji                           │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  メールアドレス                          │
│  ┌─────────────────────────────────────┐ │
│  │                                     │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  パスワード（8文字以上）                  │
│  ┌─────────────────────────────────────┐ │
│  │ ●●●●●●●●                           │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  ── クラスに参加する（任意・あとでも可）── │
│                                         │
│  先生から受け取ったクラスコード            │
│  ┌─────────────────────────────────────┐ │
│  │ 例：WISE-2024-A3                    │ │
│  └─────────────────────────────────────┘ │
│  ✅ コードが合っています（入力後にリアルタイム確認）│
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │        次へ進む →                   │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  すでにアカウントをお持ちですか？ ログイン │
│                                         │
└─────────────────────────────────────────┘
```

#### 詳細仕様（生徒ルート固有）

| 項目 | 仕様 |
|------|------|
| **クラスコード入力** | 任意入力。リアルタイムでSupabaseの `classes` テーブルをチェック |
| **コードバリデーション** | 入力後500ms debounceでAPIコール → 「✅ コードが合っています」 or 「❌ 見つかりません」をインラインで表示 |
| **コードなしのパス** | 「あとでクラスに参加する」テキストリンクでスキップ可能 |
| **コード形式** | 英数字ハイフン区切り（例：WISE-2024-A3）。大文字小文字は自動正規化 |

---

### SCREEN ONB_2C：アカウント作成（ソロルート）

#### ワイヤーフレーム

ONB_2B と同レイアウト。クラスコード入力セクションの代わりに以下を表示。

```
│  ── ひとりで英語と向き合う ────────────── │
│                                         │
│   将来、先生のクラスに参加することも     │
│   いつでもできます。                     │
│                                         │
│   今は、まず Mowi と出会おう。           │
│                                         │
```

| 項目 | 仕様 |
|------|------|
| **クラスコード** | 表示しない |
| **メッセージ** | ソロを選んだことを肯定するコピーを表示（強制感なし）|

---

### 📌 アカウント作成共通仕様

#### Supabase への初期書き込み（ONB_2A/B/C 完了時）

「次へ進む」ボタン押下後、以下を順次実行する。失敗時はエラー表示してリトライを促す。

```
STEP 1：Supabase Auth でユーザー登録
───────────────────────────────────────
supabase.auth.signUp({
  email: formData.email,
  password: formData.password,
  options: {
    data: {
      display_name: formData.displayName,
      role: 'teacher' | 'student' | 'solo',   // ルートに応じて自動セット
      onboarding_completed: false,             // オンボーディング完了前フラグ
      onboarding_route: 'teacher' | 'student' | 'solo'
    }
  }
})
  ↓ 成功 → STEP 2 へ

STEP 2：users テーブルにプロフィール行を INSERT
───────────────────────────────────────
INSERT INTO users (
  id,            -- auth.uid()
  display_name,  -- formData.displayName
  email,         -- formData.email
  role,          -- 'teacher' | 'student' | 'solo'
  language_level,-- 'beginner'（初期値固定）
  onboarding_completed, -- false
  onboarding_route,     -- 'teacher' | 'student' | 'solo'
  created_at,    -- now()
  updated_at     -- now()
)
  ↓ 成功 → STEP 3 へ

STEP 3：mowi_state テーブルに初期行を INSERT
───────────────────────────────────────
INSERT INTO mowi_state (
  user_id,           -- auth.uid()
  current_emotion,   -- 'idle'
  current_combo,     -- 0
  brightness_level,  -- 1
  current_streak,    -- 0
  created_at,        -- now()
  updated_at         -- now()
)
  ↓ 成功 → STEP 4（ルート別）へ

STEP 4A（先生ルート・クラス名あり）：classes テーブルに INSERT
───────────────────────────────────────
INSERT INTO classes (
  id,            -- gen_random_uuid()
  teacher_id,    -- auth.uid()
  class_name,    -- formData.className
  class_code,    -- 自動生成: 'WISE-' + YYYYMM + '-' + random 2文字大文字
  created_at,    -- now()
)

STEP 4B（生徒ルート・クラスコードあり）：class_members テーブルに INSERT
───────────────────────────────────────
-- まずクラスコードからclass_idを取得
SELECT id FROM classes WHERE class_code = formData.classCode;

INSERT INTO class_members (
  id,         -- gen_random_uuid()
  class_id,   -- 取得したclass_id
  user_id,    -- auth.uid()
  joined_at,  -- now()
  is_active,  -- true
)

STEP 5（全ルート共通）：完了後 ONB_3 へ遷移
───────────────────────────────────────
router.push('/onboarding/checkin')
```

#### エラーハンドリング

| エラー種別 | 表示方法 | リトライ |
|----------|---------|---------|
| メール重複 | 「このメールはすでに登録されています」インライン表示 | ログインリンクを強調 |
| ネットワークエラー | ボタン下に「通信に失敗しました。もう一度お試しください。」| ボタンを再度押下でリトライ |
| クラスコード無効 | コード入力欄下に即座に「見つかりません」| 再入力 |
| タイムアウト（5秒超過）| 「時間がかかっています。もう一度お試しください。」| 自動リトライ1回 → 失敗でメッセージ |

#### UX上の離脱率低下施策

1. **入力フィールドは最少化**：必須フィールドを3項目（表示名・メール・パスワード）に絞る
2. **クラス関連は任意**：「あとで設定できます」を明記して焦らせない
3. **ローディング中の演出**：「次へ進む」押下後にMowiがCheerアニメ + 「準備してる。」のセリフ表示（スピナーの代わり）
4. **パスワード表示切替**：👁 ボタンでパスワードを確認可能

---

### SCREEN ONB_3：朝チェックイン（初回体験）

#### ワイヤーフレーム

```
┌─────────────────────────────────────────┐
│  ステータスバー                           │
│─────────────────────────────────────────│
│                                         │
│              ☀️                          │
│                                         │
│     ┌─────────────────────────────┐     │
│     │                             │     │
│     │    [Mowi・Idleアニメーション] │     │
│     │      (ゆっくり浮遊)          │     │
│     │                             │     │
│     │  「今の英語、どんな感じ？」   │     │
│     │  How do you feel right now? │     │
│     │                             │     │
│     └─────────────────────────────┘     │
│                                         │
│  ── はじめての質問 ──────────────────── │
│                                         │
│  今日の英語、どんな感じ？               │
│  How do you feel about English?        │
│                                         │
│  ┌──────────────────┐ ┌──────────────────┐ │
│  │  ✨ 自信ある     │ │  😌 まあまあかな  │ │
│  │  Feeling sharp   │ │  Pretty okay     │ │
│  └──────────────────┘ └──────────────────┘ │
│                                         │
│  ┌──────────────────┐ ┌──────────────────┐ │
│  │  😟 不安        │ │  🌀 わからない    │ │
│  │ A little anxious │ │  Hard to say     │ │
│  └──────────────────┘ └──────────────────┘ │
│                                         │
│  ※ スキップなし。どの気持ちも正解。     │
│                                         │
└─────────────────────────────────────────┘
```

#### 詳細仕様

| 項目 | 仕様 |
|------|------|
| **背景** | 夜明けグラデーション（#1a1a2e → #f4a261）|
| **Mowiセリフ** | Idleから変化。テキスト：「今の英語、どんな感じ？」/ "How do you feel right now?" |
| **ガイドコピー** | 選択肢の上に「はじめての質問」ラベル（初回のみ表示）|
| **スキップ** | **表示しない**（コアポリシー）|
| **タップ後の動作** | C2設計書 2-1 と同一フロー（MOWI_REACTION → ONB_4 へ） |
| **戻るボタン** | **表示しない**（OS戻るジェスチャーも無効化）|

#### 初回チェックイン → Supabase 書き込み

C2設計書 5-1 と同一仕様。ただし初回は以下フィールドも更新する。

```sql
-- checkins テーブル（初回書き込み）
INSERT INTO checkins (
  user_id,
  checkin_date,
  morning_feeling,
  morning_checked_at,
  is_onboarding    -- 初回チェックインフラグ（TRUE）
)
VALUES (
  auth.uid(),
  CURRENT_DATE,
  '選択値',
  now(),
  TRUE
);

-- users テーブルのonboarding_checkin_completedを更新
UPDATE users
SET onboarding_checkin_completed = TRUE,
    updated_at = now()
WHERE id = auth.uid();
```

> **注意**：`is_onboarding` カラムは `checkins` テーブルに追加が必要。  
> `ALTER TABLE checkins ADD COLUMN is_onboarding BOOLEAN NOT NULL DEFAULT FALSE;`

#### 初回チェックイン後の Mowiリアクション画面（特別版）

通常の `MOWI_REACTION`（800ms）に加え、初回限定で以下のセリフを優先使用する。

| 朝の選択 | 初回限定Mowiセリフ（日本語）| 初回限定（English）|
|---------|------------------------|------------------|
| 自信ある | 「その感覚、本物。」| That feeling—it's real. |
| まあまあかな | 「まあまあが、一番続く。」| Okay is the most sustainable. |
| 不安 | 「不安でいい。それが今のすがた。」| Anxious is fine. That's what you are right now. |
| わからない | 「わからないまま、始まる。それでいい。」| Starting without knowing. That's fine. |

---

### SCREEN ONB_4：P001 練習（初回・短縮版）

#### 設計思想

> **「難しくない」と体感させる。3問で終わる。**

初回の練習はLayer 2（4択選択）のみ。P001の最も基本的な3問を、難易度の低い順に出題する。コンボゲージも表示するが、コンボ切れ演出は省略する（初回は「失敗」で終わらせない）。

#### ワイヤーフレーム

```
┌─────────────────────────────────────────┐
│  [練習 1/3]    ████████░░  コンボ:1     │
│─────────────────────────────────────────│
│                                         │
│     [Mowi・Cheer or Joy]                │
│     「言ってみる。」                      │
│                                         │
│─────────────────────────────────────────│
│                                         │
│  ── P001：[代名詞] + be動詞パターン ───  │
│                                         │
│  次の英語の____に入るのはどれ？          │
│                                         │
│     "I ___ Kenji."                     │
│                                         │
│  ┌──────────────────┐ ┌──────────────────┐ │
│  │  A. am           │ │  B. is           │ │
│  └──────────────────┘ └──────────────────┘ │
│  ┌──────────────────┐ ┌──────────────────┐ │
│  │  C. are          │ │  D. be           │ │
│  └──────────────────┘ └──────────────────┘ │
│                                         │
│  ──── ヒントを見る ─────────────────────  │
│                                         │
└─────────────────────────────────────────┘
```

#### 初回練習 問題セット（固定・乱数なし）

| 問題 | 形式 | 問題文 | 正解 | 難易度 |
|-----|-----|-------|-----|-------|
| 問1 | 4択 | "I ___ Kenji." → am / is / are / be | am | 最易 |
| 問2 | 4択 | "She ___ a teacher." → am / is / are / be | is | 易 |
| 問3 | 4択 | "We ___ students." → am / is / are / be | are | 普通 |

#### 初回練習の特殊仕様

| 項目 | 通常仕様 | 初回オンボーディング仕様 |
|-----|---------|-------------------|
| 問題数 | 10問〜 | **3問固定** |
| Layer | 0〜3 | **Layer 2（4択）のみ** |
| コンボ切れ演出 | あり（COMBO_BREAK） | **省略**（コンボ数はリセットするが画面は出ない） |
| タイムアウト | あり | **なし**（制限時間を設定しない）|
| 不正解後の解説 | あり | **あり**（ただし「なんか変」演出は省略。直接正解を表示）|
| セッション終了画面 | SESSION_END | **ONB_5 へ直接遷移** |
| ボトムナビ | 非表示 | **非表示（同一）**|

#### 正解時Mowiセリフ（ONB専用・初回のみ）

| # | 日本語 | English |
|---|--------|---------|
| 1 | 「出た。それでいい。」| There it is. That's enough. |
| 2 | 「知ってた。ちゃんと知ってた。」| You knew it. Really knew it. |
| 3 | 「また一つ、体に入った。」| One more in the body. |

#### 不正解時Mowiセリフ（ONB専用・初回のみ）

| # | 日本語 | English |
|---|--------|---------|
| 1 | 「これが今の形。次で変える。」| This is the shape right now. Change it next. |
| 2 | 「まだ慣れていない。それが正直なとこ。」| Not used to it yet. That's the honest truth. |

---

### SCREEN ONB_5：Mowi変化の確認・ホーム誘導

#### ワイヤーフレーム

```
┌─────────────────────────────────────────┐
│  ステータスバー                           │
│─────────────────────────────────────────│
│                                         │
│         ╔═══════════════════╗           │
│         ║                   ║           │
│         ║  [Mowi・Grow演出]  ║  ← 練習後の輝き変化  │
│         ║  輝度 Lv.1→2       ║           │
│         ║  （わずかに輝く）   ║           │
│         ╚═══════════════════╝           │
│                                         │
│   「動いた。ほんのすこし、変わった。」    │
│   Moved. Changed, just a little.       │
│                                         │
│─────────────────────────────────────────│
│                                         │
│  ── 今日の練習完了 ─────────────────────  │
│                                         │
│  P001 を練習しました。                   │
│  ★ ☆ ☆ ☆ ☆  → ★★ ☆ ☆ ☆              │
│  ★が増えると、英語が体に入っていく証。   │
│                                         │
│─────────────────────────────────────────│
│                                         │
│  明日また来ると、Mowiが変わっていく。    │
│                                         │
│  ┌─────────────────────────────────────┐ │
│  │        Mowi に会いに行く ✨           │ │
│  └─────────────────────────────────────┘ │
│                                         │
│  （このボタンが HOME へ遷移）            │
│                                         │
└─────────────────────────────────────────┘
```

#### 詳細仕様

| 項目 | 仕様 |
|------|------|
| **Mwiアニメーション** | Grow ステート。練習後の輝度変化を可視化（brightness_level: 1 → 2）|
| **Mowiセリフ** | 「動いた。ほんのすこし、変わった。」/ "Moved. Changed, just a little." |
| **★表示** | P001の現在の★数を表示。初回は必ず 1→2 に見せる（固定演出）|
| **CTA文言** | 「Mowi に会いに行く ✨」（通常の「始める」等の言葉は使わない）|
| **CTAタップ後** | HOMEへ遷移。同時に `users.onboarding_completed = TRUE` を更新 |
| **戻るボタン** | **表示しない** |
| **自動遷移** | なし（ユーザーがボタンを押すまで待機）|

#### Supabase 書き込み（ONB_5 ボタン押下時）

```sql
-- onboarding完了フラグ更新
UPDATE users
SET onboarding_completed = TRUE,
    onboarding_completed_at = now(),
    updated_at = now()
WHERE id = auth.uid();

-- パターン進捗の初期化
INSERT INTO pattern_progress (
  user_id,
  pattern_id,      -- 'P001'
  star_count,      -- 1（初回練習で1問以上正解したため）
  first_played_at, -- now()
  last_played_at,  -- now()
  next_review_at   -- now() + interval '1 day'
)
ON CONFLICT (user_id, pattern_id)
DO UPDATE SET
  star_count = GREATEST(pattern_progress.star_count, 1),
  last_played_at = now(),
  next_review_at = now() + interval '1 day';

-- mowi_state の輝度更新
UPDATE mowi_state
SET brightness_level = 2,
    current_emotion = 'grow',
    updated_at = now()
WHERE user_id = auth.uid();
```

---

## 🏠 HOME（初回版）

オンボーディング完了直後の HOME は通常版と同じコンポーネントを使うが、以下のフラグで初回専用表示を制御する。

| 表示要素 | 初回版 | 通常版 |
|---------|-------|-------|
| デイリー練習ボタン | 「✅ 今日の練習、完了！」（グレー・再挑戦可）| 通常表示 |
| Mowiセリフ | 「明日また来ると、もっと変わる。」| 通常Idleセリフ |
| ストリーク表示 | 「🔥 1日連続」| 通常通り |
| チュートリアル吹き出し | 「📖 図鑑でP001を確認できます」「📊 記録に今日のチェックインが残ります」| なし |
| ボトムナビ | 表示（ここから通常通り）| 通常通り |

---

## ルート別フロー詳細

### 先生ルート（`route_teacher`）

```
SPLASH → ONB_1 → ONB_2（ルート選択）→ ONB_2A（先生アカウント）
     → ONB_3（朝チェックイン）→ MOWI_REACTION → ONB_4（P001練習）
     → ONB_5（完了）→ HOME（初回）
```

**先生ルート固有の HOME 以降の動作：**

| タイミング | 追加表示 |
|----------|---------|
| HOME 初回表示時 | 「クラスを作成する」バナー（クラス名未入力の場合のみ）|
| 設定タブ | 「先生ダッシュボードを確認する」リンク（Phase 2実装後に活性化）|

### 生徒ルート（`route_student`）

```
SPLASH → ONB_1 → ONB_2（ルート選択）→ ONB_2B（生徒アカウント）
     → ONB_3（朝チェックイン）→ MOWI_REACTION → ONB_4（P001練習）
     → ONB_5（完了）→ HOME（初回）
```

**生徒ルート固有の HOME 以降の動作：**

| タイミング | 追加表示 |
|----------|---------|
| HOME 初回表示時（クラス参加済み）| 「クラス：〇〇に参加中」バッジを表示 |
| HOME 初回表示時（クラス未参加）| 「クラスコードを入力する」バナー表示 |

### ソロルート（`route_solo`）

```
SPLASH → ONB_1 → ONB_2（ルート選択）→ ONB_2C（ソロアカウント）
     → ONB_3（朝チェックイン）→ MOWI_REACTION → ONB_4（P001練習）
     → ONB_5（完了）→ HOME（初回）
```

**ソロルート固有の HOME 以降の動作：**

| タイミング | 追加表示 |
|----------|---------|
| HOME 初回表示時 | 先生ルート・クラス関連のバナーは一切表示しない |

---

## 🛡️ オンボーディング状態管理

### onboarding_step の定義

オンボーディング中断・再開を管理するため、`users` テーブルに `onboarding_step` カラムを追加する。

```sql
ALTER TABLE users
ADD COLUMN onboarding_step TEXT NOT NULL DEFAULT 'not_started'
CHECK (onboarding_step IN (
  'not_started',          -- 未着手
  'route_selected',       -- ルート選択完了
  'account_created',      -- アカウント作成完了
  'checkin_completed',    -- 初回チェックイン完了
  'practice_completed',   -- 初回練習完了
  'completed'             -- オンボーディング全完了
));

ALTER TABLE users
ADD COLUMN onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE;

ALTER TABLE users
ADD COLUMN onboarding_completed_at TIMESTAMPTZ;

ALTER TABLE users
ADD COLUMN onboarding_route TEXT CHECK (onboarding_route IN ('teacher', 'student', 'solo'));

ALTER TABLE users
ADD COLUMN onboarding_checkin_completed BOOLEAN NOT NULL DEFAULT FALSE;
```

### 中断・再開ロジック

アプリを再起動した際に `onboarding_completed = FALSE` のユーザーは、`onboarding_step` に応じて以下の画面へリダイレクトする。

| onboarding_step | リダイレクト先 |
|----------------|-------------|
| `not_started` | ONB_1 |
| `route_selected` | ONB_2A/B/C（routeに応じて）|
| `account_created` | ONB_3 |
| `checkin_completed` | ONB_4 |
| `practice_completed` | ONB_5 |
| `completed` | HOME（通常フロー）|

---

## 📊 離脱率を下げるUX設計

### 各ステップの離脱リスクと対策

| ステップ | 主な離脱リスク | 対策 |
|---------|-------------|-----|
| ONB_1（Mowi登場）| 「なにこれ？」と思って閉じる | タップでスキップ可 / 5秒の短時間で自動遷移 |
| ONB_2（ルート選択）| 「どれを選べばいい？」と迷う | 各選択肢に短い説明を付記 / 「あとで変更可」を記載 |
| ONB_2A/B/C（アカウント作成）| 入力が面倒 / クラスコードが分からない | クラス関連は任意 / 最少フィールド数 / ローディング中のMowi演出 |
| ONB_3（チェックイン）| 「どれが正解？」と不安になる | 「どの気持ちも正解」のサブコピーを常時表示 |
| ONB_4（練習）| 難しすぎて萎える | 3問固定 / タイムアウトなし / コンボ切れ演出省略 |
| ONB_5（完了画面）| 「で、何すればいいの？」 | ★変化・Mowi変化を可視化 / CTAを「会いに行く」という能動的な言葉に |

### 全体共通対策

1. **進捗インジケーター**：ONB_1〜5 の各画面上部に小さなステップドット（●○○○○ → ●●○○○ → ...）を表示。残りが分かる安心感
2. **Mowiの常時存在**：どの画面でもMowiが画面内に存在する（存在感 = 一人じゃない感）
3. **戻るを許容**：アカウント作成画面（ONB_2A/B/C）のみ「← 戻る」でONB_2（ルート選択）へ戻れる
4. **エラーは優しく**：赤い警告より「もう一度確認してみて」のようなMowiセリフ風トーン
5. **時間の見える化**：ONB_4（練習）開始時に「3問だけ。2分で終わります。」をテキスト表示

---

## 🎞️ オンボーディング中の Mowi セリフ集（専用版）

Mowiセリフ集 v2.0 の共通セリフに加え、オンボーディング中のみ使用する専用セリフ。

### ONB_1 登場時

| # | 日本語 | English |
|---|--------|---------|
| 1 | 「ずっと、ここにいた。」| Been here all along. |

（固定。ランダム選択なし）

### ONB_2 ルート選択後（アカウント作成ローディング中）

| # | 日本語 | English |
|---|--------|---------|
| 1 | 「準備してる。」| Getting ready. |
| 2 | 「もうすぐ始まる。」| Almost there. |

### ONB_3 初回チェックイン後（Mowiリアクション・初回限定）

| 朝の選択 | 日本語 | English |
|---------|--------|---------|
| 自信ある | 「その感覚、本物。」| That feeling—it's real. |
| まあまあかな | 「まあまあが、一番続く。」| Okay is the most sustainable. |
| 不安 | 「不安でいい。それが今のすがた。」| Anxious is fine. That's you right now. |
| わからない | 「わからないまま、始まる。それでいい。」| Starting without knowing. That's fine. |

### ONB_4 練習中（正解時・初回限定）

| # | 日本語 | English |
|---|--------|---------|
| 1 | 「出た。それでいい。」| There it is. That's enough. |
| 2 | 「知ってた。ちゃんと知ってた。」| You knew it. Really knew it. |
| 3 | 「また一つ、体に入った。」| One more in the body. |

### ONB_4 練習中（不正解時・初回限定）

| # | 日本語 | English |
|---|--------|---------|
| 1 | 「これが今の形。次で変える。」| This is the shape right now. |
| 2 | 「まだ慣れていない。それが正直なとこ。」| Not used to it yet. |

### ONB_5 完了画面

| # | 日本語 | English |
|---|--------|---------|
| 1 | 「動いた。ほんのすこし、変わった。」| Moved. Changed, just a little. |

（固定。ランダム選択なし）

### HOME（初回版）・到達直後

| # | 日本語 | English |
|---|--------|---------|
| 1 | 「明日また来ると、もっと変わる。」| Come back tomorrow. Changes more. |

---

## 📐 画面遷移フロー（コード実装レベル）

### Vue Router ガード実装

```javascript
// router/index.js
// オンボーディング未完了ユーザーをリダイレクトするガード

router.beforeEach(async (to, from, next) => {
  const user = await supabase.auth.getUser();
  
  // 未ログインはオンボーディングへ
  if (!user && to.path !== '/onboarding') {
    return next('/onboarding');
  }
  
  if (user) {
    const { data: profile } = await supabase
      .from('users')
      .select('onboarding_completed, onboarding_step, onboarding_route')
      .eq('id', user.id)
      .single();
    
    // オンボーディング未完了の場合
    if (!profile.onboarding_completed && !to.path.startsWith('/onboarding')) {
      const stepRoutes = {
        'not_started': '/onboarding/welcome',
        'route_selected': `/onboarding/account/${profile.onboarding_route}`,
        'account_created': '/onboarding/checkin',
        'checkin_completed': '/onboarding/practice',
        'practice_completed': '/onboarding/complete',
      };
      return next(stepRoutes[profile.onboarding_step] || '/onboarding/welcome');
    }
  }
  
  next();
});

// オンボーディングルート定義
const onboardingRoutes = [
  { path: '/onboarding/welcome',           name: 'ONB_1', component: OnbWelcomeView },
  { path: '/onboarding/route',             name: 'ONB_2', component: OnbRouteView },
  { path: '/onboarding/account/teacher',   name: 'ONB_2A', component: OnbAccountTeacherView },
  { path: '/onboarding/account/student',   name: 'ONB_2B', component: OnbAccountStudentView },
  { path: '/onboarding/account/solo',      name: 'ONB_2C', component: OnbAccountSoloView },
  { path: '/onboarding/checkin',           name: 'ONB_3', component: OnbCheckinView },
  { path: '/onboarding/practice',          name: 'ONB_4', component: OnbPracticeView },
  { path: '/onboarding/complete',          name: 'ONB_5', component: OnbCompleteView },
];
```

### Pinia Store（オンボーディング状態管理）

```javascript
// stores/onboarding.js
import { defineStore } from 'pinia'

export const useOnboardingStore = defineStore('onboarding', {
  state: () => ({
    step: 'not_started',
    route: null,           // 'teacher' | 'student' | 'solo'
    classCode: null,       // 生徒ルート用
    className: null,       // 先生ルート用
    morningFeeling: null,  // 初回チェックイン選択値
    practiceResults: [],   // 初回練習の正誤記録
  }),

  actions: {
    setRoute(route) {
      this.route = route;
      this.step = 'route_selected';
      this.persistStep();
    },

    async completeAccountCreation(userId) {
      this.step = 'account_created';
      await this.persistStep();
    },

    async completeCheckin(feeling) {
      this.morningFeeling = feeling;
      this.step = 'checkin_completed';
      await this.persistStep();
    },

    async completePractice(results) {
      this.practiceResults = results;
      this.step = 'practice_completed';
      await this.persistStep();
    },

    async completeOnboarding() {
      this.step = 'completed';
      await supabase
        .from('users')
        .update({
          onboarding_completed: true,
          onboarding_completed_at: new Date().toISOString(),
        })
        .eq('id', useAuthStore().userId);
    },

    async persistStep() {
      await supabase
        .from('users')
        .update({ onboarding_step: this.step })
        .eq('id', useAuthStore().userId);
    },
  },
});
```

---

## 📋 Supabase テーブル追加・変更仕様まとめ

### users テーブル 追加カラム

```sql
ALTER TABLE users
ADD COLUMN IF NOT EXISTS onboarding_step TEXT NOT NULL DEFAULT 'not_started'
  CHECK (onboarding_step IN (
    'not_started', 'route_selected', 'account_created',
    'checkin_completed', 'practice_completed', 'completed'
  )),
ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS onboarding_completed_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS onboarding_route TEXT
  CHECK (onboarding_route IN ('teacher', 'student', 'solo')),
ADD COLUMN IF NOT EXISTS onboarding_checkin_completed BOOLEAN NOT NULL DEFAULT FALSE;
```

### checkins テーブル 追加カラム

```sql
ALTER TABLE checkins
ADD COLUMN IF NOT EXISTS is_onboarding BOOLEAN NOT NULL DEFAULT FALSE;
```

### classes テーブル（先生ルートで新規作成時）

```sql
-- 既存テーブルに class_code の自動生成を追加
-- class_code の生成ロジック（DB関数）
CREATE OR REPLACE FUNCTION generate_class_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  exists_count INTEGER;
BEGIN
  LOOP
    code := 'WISE-' || TO_CHAR(NOW(), 'YYYYMM') || '-' ||
            CHR(65 + FLOOR(RANDOM() * 26)::INT) ||
            CHR(65 + FLOOR(RANDOM() * 26)::INT);
    SELECT COUNT(*) INTO exists_count FROM classes WHERE class_code = code;
    EXIT WHEN exists_count = 0;
  END LOOP;
  RETURN code;
END;
$$ LANGUAGE plpgsql;
```

---

## 📏 実装優先順位

| 優先度 | 機能 | 実装コスト | 必須 |
|-------|------|----------|-----|
| 🔴 最優先 | ONB_1 Mowi登場演出 | 低 | ✅ |
| 🔴 最優先 | ONB_2 ルート選択 | 低 | ✅ |
| 🔴 最優先 | ONB_2A/B/C アカウント作成（共通部分）| 中 | ✅ |
| 🔴 最優先 | ONB_3 初回朝チェックイン（C2設計書フロー）| 低 | ✅ |
| 🔴 最優先 | ONB_4 P001 練習3問（Layer 2のみ）| 中 | ✅ |
| 🔴 最優先 | ONB_5 完了・ホーム誘導 | 低 | ✅ |
| 🔴 最優先 | Supabase 初期書き込みロジック（users / mowi_state）| 中 | ✅ |
| 🟡 次フェーズ | クラスコードリアルタイム検証（ONB_2B）| 中 | - |
| 🟡 次フェーズ | class_members 書き込み（生徒クラス参加）| 中 | - |
| 🟡 次フェーズ | classes 書き込み（先生クラス作成）| 中 | - |
| 🟡 次フェーズ | 中断・再開ロジック（Vue Routerガード）| 中 | - |
| 🟢 Phase 2 | Apple Sign In / Google Sign In | 中〜高 | - |
| 🟢 Phase 2 | メール認証フロー（confirm email）| 中 | - |

---

## 🧪 テスト・検証指標

| 指標 | 目標値 | 計測方法 |
|-----|-------|---------|
| ONB完了率（全体）| ≧ 70% | `onboarding_completed = TRUE` の割合 |
| ONB完了時間（中央値）| ≦ 3分 | `onboarding_completed_at - created_at` |
| ONB_2（ルート選択）→ ONB_3（チェックイン）通過率 | ≧ 85% | ステップ間の funnel 分析 |
| ONB_4（練習）完了率 | ≧ 80% | `practice_completed` ステップ到達率 |
| 初回朝チェックイン翌日継続率 | ≧ 50% | 翌日の `checkins` 存在確認 |

---

*MoWISE C オンボーディング設計書 v1.0*  
*策定日：2026年2月23日*  
*次回更新：MVP実装後のUXテスト（完了率・時間計測）結果を反映*
