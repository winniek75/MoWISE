# 開発spec: MoWISE Reading（レベル別多読 + 音読 + 試験形式クイズ）v1.0

作成日: 2026-07-03 ／ 作成: Claude（開発担当・教育設計担当）
対象リポジトリ: https://github.com/winniek75/MoWISE （main）
Stack: Vue 3 + TypeScript + Tailwind + Supabase + Capacitor / Vercel deploy
正本の保管先: Notion（ナレッジ担当管理）※このファイルは自己完結。口頭補足なしで実装・再開できること。

---

## 0. このspecの読み方（Claude Code向け）

- 実装は **Step 1 → 2 → 3a（→3b）** の順。1 Step = 1 リリース = 1 preview URL。
- 各 Step の受け入れ条件をすべて満たしたら commit し、`TODO.md` に「どこまで終わった／次に何をする」を日本語で残すこと。
- Winnie はコードを読まない。完了報告は「日本語サマリ + preview URL + スクショ」で返すこと。
- APIキーは必ず環境変数（`.env` / Vercel env）。リポジトリ直書き禁止。

---

## 1. 目的（1行）

Raz-Kids 型の「レベル別リーディング→音読→クイズ」体験を MoWISE 内のミニアプリとして提供し、英検・TOEIC 学習に直結する日本人学習者向け多読機能を作る。

---

## 2. スコープ

### やる（全Step合計）
- レベル別ライブラリ（6レベル × 各5冊 = 30冊、オリジナルストーリー）
- 読書ビュー（ページ送り・挿絵・TTS音声再生・テキストハイライト）
- 読了後クイズ（英検・TOEIC形式、レベル別に出題形式が変わる）
- 音読の録音・再生・提出（Step 2）
- AI発音評価: 単語一致率スコア（Step 3a）→ 発音精度スコア（Step 3b・任意）
- 既存の XP / mowi_level / streak への加算連携
- 進捗画面（読了冊数・クイズ正答率・レベル進行）

### やらない（今回の範囲外）
- 教師によるクラス管理画面（既存 classes 連携は将来spec）
- 課金プラン制御（is_free フラグだけ用意、決済連動はしない)
- 多言語UI（日本語UIのみ。本文は英語）
- オフライン対応
- ストーリー本文の執筆（別途、教育設計担当が納品。§7のコンテンツJSON仕様に従う）

---

## 3. レベル設計（教育設計担当 確定版）

| level | code | 名称 | 目安 | 語数/冊 | 本文の形 | 世界観 |
|---|---|---|---|---|---|---|
| 1 | seed | Seed | 英検5級 / Pre-A1 | 40–80 | 1ページ1文型・絵本 | レベルごと自由（挿絵中心） |
| 2 | sprout | Sprout | 英検4級 / A1 | 80–120 | 短い物語 | 自由 |
| 3 | leaf | Leaf | 英検3級 / A2 | 150–250 | 物語＋説明文 | 自由 |
| 4 | branch | Branch | 英検準2級 / TOEIC ~500 | 250–400 | 物語・エッセイ | 自由 |
| 5 | tree | Tree | 英検2級 / TOEIC 600–750 | 400–600 | 長文・意見文 | 自由 |
| 6 | summit | Summit | TOEIC 850 / B2 | 500–700 | 記事・Eメール・社内通知（TOEIC Part 7 と同形式の文書） | 実用文体 |

- 世界観は「レベルごと自由」（Winnie 決定 2026-07-03）。ただし新キャラを本文に登場させる場合、Mowi & Friends 以外のキャラ設定は世界観担当の承認を得ること（Character Bible v1.2 との整合）。
- Lv1 は WIDA L1-2 死守（1ページ1文型）。

## 4. クイズ形式（教育設計担当 確定版）

日本人学習者が試験で見慣れた形式に統一する。Razのような回りくどい設問は禁止。

| レベル | 形式（1冊あたり5問） |
|---|---|
| Lv1–2 | 絵↔単語マッチング（4択・画像選択肢） / True–False |
| Lv3–4 | 語彙4択（英検大問1形式: 短文空所） / 内容一致4択 |
| Lv5–6 | 空所補充4択（TOEIC Part 5/6 形式） / 内容一致4択（Part 7 形式: "What is the purpose of this email?" 型） |

出題形式は quiz JSON の `format` フィールドで指定（§7）。UIは形式ごとにコンポーネントを分ける:
- `MatchPictureQuiz.vue`（画像4択）
- `TrueFalseQuiz.vue`
- `MultipleChoiceQuiz.vue`（テキスト4択・語彙/空所/内容一致 共通）

---

## 5. DBスキーマ追加（Supabase migration）

既存テーブル（users, patterns, pattern_progress 等）との命名衝突なし。RLSは既存スキーマの流儀に合わせる。

```sql
-- 本
CREATE TABLE reading_books (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_no       TEXT NOT NULL UNIQUE CHECK (book_no ~ '^B[0-9]{3}$'), -- B101 = Lv1の1冊目
    level         INTEGER NOT NULL CHECK (level BETWEEN 1 AND 6),
    level_code    TEXT NOT NULL CHECK (level_code IN ('seed','sprout','leaf','branch','tree','summit')),
    title         TEXT NOT NULL,
    title_ja      TEXT NOT NULL DEFAULT '',
    genre         TEXT NOT NULL DEFAULT 'story'
                  CHECK (genre IN ('story','nonfiction','email','article','notice','essay')),
    word_count    INTEGER NOT NULL DEFAULT 0,
    cover_url     TEXT,               -- Supabase Storage: reading/{book_no}/cover.png
    is_free       BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order    INTEGER NOT NULL DEFAULT 0,
    is_published  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE reading_books ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_books_select_all" ON reading_books FOR SELECT USING (is_published = TRUE);
CREATE POLICY "reading_books_admin_all"  ON reading_books FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));

-- ページ
CREATE TABLE reading_pages (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id       UUID NOT NULL REFERENCES reading_books(id) ON DELETE CASCADE,
    page_no       INTEGER NOT NULL,
    body          TEXT NOT NULL,      -- 英語本文（1ページ分）
    image_url     TEXT,               -- reading/{book_no}/page_{NN}.png（挿絵なしページはNULL可）
    audio_url     TEXT,               -- reading/{book_no}/audio_{NN}.mp3（Google TTS Neural2で事前生成）
    UNIQUE (book_id, page_no)
);
ALTER TABLE reading_pages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_pages_select_all" ON reading_pages FOR SELECT
    USING (EXISTS (SELECT 1 FROM reading_books b WHERE b.id = book_id AND b.is_published = TRUE));

-- クイズ
CREATE TABLE reading_quizzes (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id       UUID NOT NULL REFERENCES reading_books(id) ON DELETE CASCADE,
    question_no   INTEGER NOT NULL,
    format        TEXT NOT NULL CHECK (format IN
                  ('match_picture','true_false','vocab_mc','cloze_mc','comprehension_mc')),
    question      TEXT NOT NULL,
    choices       JSONB NOT NULL,     -- ["A","B","C","D"] または画像URL配列
    answer_index  INTEGER NOT NULL CHECK (answer_index BETWEEN 0 AND 3),
    explanation_ja TEXT NOT NULL DEFAULT '',  -- 日本語解説（英検過去問解説の粒度）
    UNIQUE (book_id, question_no)
);
ALTER TABLE reading_quizzes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_quizzes_select_all" ON reading_quizzes FOR SELECT
    USING (EXISTS (SELECT 1 FROM reading_books b WHERE b.id = book_id AND b.is_published = TRUE));

-- 進捗
CREATE TABLE reading_progress (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id        UUID NOT NULL REFERENCES reading_books(id) ON DELETE CASCADE,
    status         TEXT NOT NULL DEFAULT 'reading'
                   CHECK (status IN ('reading','read','quiz_done')),
    quiz_score     INTEGER CHECK (quiz_score BETWEEN 0 AND 5),
    quiz_attempts  INTEGER NOT NULL DEFAULT 0,
    listened       BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, book_id)
);
ALTER TABLE reading_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_progress_own" ON reading_progress FOR ALL USING (auth.uid() = user_id);

-- 音読録音（Step 2で使用）
CREATE TABLE reading_recordings (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id        UUID NOT NULL REFERENCES reading_books(id) ON DELETE CASCADE,
    audio_path     TEXT NOT NULL,     -- Storage: recordings/{user_id}/{book_no}_{timestamp}.webm
    duration_sec   INTEGER,
    accuracy_score INTEGER CHECK (accuracy_score BETWEEN 0 AND 100), -- Step 3aで書き込み
    score_detail   JSONB,             -- 単語別の一致/不一致、3bではフォニームスコア
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE reading_recordings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_recordings_own" ON reading_recordings FOR ALL USING (auth.uid() = user_id);
```

Storage バケット: `reading`（公開・画像/TTS音声）、`recordings`（非公開・ユーザー録音、RLS: 本人のみ）。

### XP連携ルール
- 読了（最終ページ到達）: +10 XP
- 音声を全ページ聴いた: +5 XP
- クイズ 5問中4問以上正解: +20 XP（初回のみ）
- 音読録音を提出: +10 XP
- 加算は既存の total_xp 更新ロジック（pattern_progress で使っている経路）を再利用すること。

---

## 6. 画面フロー（UX）

```
ライブラリ画面（レベルタブ 1–6 → 冊子カードのグリッド）
  └─ 本の詳細（表紙・タイトル・語数・「聴く/読む」開始）
       └─ 読書ビュー（横スワイプでページ送り）
            ・▶ボタンでTTS再生、再生中の文をハイライト
            ・最終ページ → 「クイズへ」「音読する」の2ボタン
       └─ クイズ（1問ずつ表示 → 即時正誤 + 日本語解説 → 5問終了でスコア + XP演出）
       └─ 音読モード（Step 2）: ページごとに録音 → 再生確認 → 提出
            └─ 提出後（Step 3a）: 単語一致率スコア表示（読めた単語は緑・落とした単語は赤）
進捗画面: 読了冊数 / レベル別進行バー / 平均クイズスコア
```

- モバイルファースト（Capacitor配信前提、375px基準）。
- 読書ビューは既存 MoWISE のデザイントークン（Tailwind設定）に従う。

---

## 7. コンテンツJSON仕様（教育設計担当からの納品形式）

ストーリー30冊は教育設計担当が別途この形式で納品する。seeds/ ディレクトリに置き、投入スクリプト（scripts/seed_reading.ts）で Supabase に登録する。

```json
{
  "book_no": "B101",
  "level": 1,
  "level_code": "seed",
  "title": "My Red Ball",
  "title_ja": "ぼくの赤いボール",
  "genre": "story",
  "pages": [
    { "page_no": 1, "body": "I have a ball.", "image": "page_01.png" }
  ],
  "quizzes": [
    {
      "question_no": 1,
      "format": "match_picture",
      "question": "Which is a ball?",
      "choices": ["q1_a.png", "q1_b.png", "q1_c.png", "q1_d.png"],
      "answer_index": 0,
      "explanation_ja": "ball は「ボール」。"
    }
  ]
}
```

### 画像スロット命名規則（Canva / Nano Banana どちらで作っても差し替え可能）
- 表紙: `reading/{book_no}/cover.png`（1024×1024）
- 挿絵: `reading/{book_no}/page_{NN}.png`（横1024×縦768）
- クイズ画像選択肢: `reading/{book_no}/q{N}_{a-d}.png`（512×512）
- TTS音声: `reading/{book_no}/audio_{NN}.mp3`（既存の en-US-Neural2-F で事前生成、scripts/gen_tts.ts を作る）

---

## 8. 実装ステップ（1 Step = 1リリース = 1レビュー）

### Step 1: 読書＋クイズ（コア）
- migration 実行、seeds 投入スクリプト、ライブラリ/読書ビュー/クイズUI、XP連携、進捗画面
- 受け入れ条件:
  - [ ] preview URL でレベル1のサンプル本1冊が最後まで読める（TTS再生・ハイライト含む）
  - [ ] クイズ5問に回答でき、正誤と日本語解説が出て、XPが加算される
  - [ ] 進捗画面に読了が反映される
  - [ ] 未公開本（is_published=false）が一覧に出ない

### Step 2: 音読録音
- MediaRecorder API（Capacitor では @capacitor-community/media or native bridge を検討）で録音 → recordings バケットへアップロード → 再生確認 → 提出
- 受け入れ条件:
  - [ ] iPhone Safari と Android Chrome で録音→再生→提出ができる
  - [ ] 録音は本人しか聴けない（RLS確認）
  - [ ] 提出でXP加算

### Step 3a: 発音評価（無料版・単語一致率）
- Web Speech API（SpeechRecognition）で音読をテキスト化 → 本文と単語単位で突合 → accuracy_score（0–100）と単語別の緑/赤表示
- 制約: iOS Safari は SpeechRecognition 対応が不安定。非対応端末では「スコアなし・提出のみ」にフォールバックすること。
- 受け入れ条件:
  - [ ] 対応ブラウザでスコアと単語別ハイライトが表示される
  - [ ] 非対応端末でエラーにならずフォールバックする

### Step 3b（任意・別spec化推奨）: Azure Pronunciation Assessment
- フォニーム単位の発音スコア（Accuracy/Fluency/Completeness）。従量課金（音声1時間あたり数百円規模）。
- キーは Supabase Edge Function 経由で呼び、クライアントに露出させない。
- Winnie の承認（コスト確認）を得てから着手すること。

---

## 9. 技術メモ

- ルーティング: 既存ミニアプリポータルの流儀に合わせ `/reading` 配下に追加
- 状態管理: 既存の構成（Pinia想定）に従う
- TTSの事前生成はビルド時ではなく scripts/ の手動スクリプト（コンテンツ追加時のみ実行）
- 全ての新規ファイルは `src/features/reading/` に集約（既存構造と衝突させない）

## 10. レビュー方法（Winnie向け）

- 各Step完了時: Vercel preview URL ＋ スクショ3枚 ＋ 日本語サマリ
- コードレビューは不要。触って確認できること。

## 11. 未確定・要確認（実装前にWinnieへ）

- [ ] 今日の体調(1〜10)とレビュー可能時間（Step 1着手前に確認）
- [ ] Step 3b（Azure・有料）をやるかどうかは Step 3a の体感を見てから判断

---

## 更新履歴

| 日付 | 版 | 内容 |
|---|---|---|
| 2026-07-03 | v1.0 | 初版。レベル6段階・試験形式クイズ・録音/発音評価の3段実装を確定 |
