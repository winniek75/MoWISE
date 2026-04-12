# MoWISE｜F Supabase スキーマ最終確定書
**バージョン：v1.0**
**策定日：2026年3月10日**
**ステータス：設計確定・エンジニア引き渡し用**
**対応要件定義：v3.1（2026年2月23日）**

---

## 📋 ドキュメント概要

このファイルは、MoWISE アプリケーションの Supabase（PostgreSQL）データベース定義書です。
エンジニアが **Supabase SQL Editor に上から順にコピペして実行**することで、
MVPに必要な全テーブル・RLS・トリガーが構築されます。

---

## 📦 テーブル一覧

| # | テーブル名 | 役割 | フェーズ |
|---|-----------|------|---------|
| 01 | `users` | ユーザープロフィール（auth.usersを拡張） | MVP |
| 02 | `mowi_state` | Mowiの感情・成長状態 | MVP |
| 03 | `checkins` | 朝・夜のチェックイン日記 | MVP |
| 04 | `patterns` | パターン図鑑マスターデータ | MVP |
| 05 | `pattern_content` | 各パターンのLayer別問題コンテンツ | MVP |
| 06 | `pattern_progress` | ユーザー別習熟度（SM-2アルゴリズム） | MVP |
| 07 | `flash_output_logs` | Layer 3 Flash Sprint詳細ログ | MVP |
| 08 | `classes` | クラス（先生が管理） | MVP |
| 09 | `class_members` | クラスメンバー（生徒の所属） | MVP |
| 10 | `gym_badges` | ジムバッジ（先生による認定） | MVP |
| 11 | `battles` | バトルセッション全体記録 | MVP |
| 12 | `battle_logs` | バトル内1問ごとの回答ログ | MVP |
| 13 | `class_battles` | クラスバトルイベント定義 | Phase 2 |
| 14 | `raids` | レイドバトルイベント定義 | Phase 2 |

---

## ⚙️ 実行前の確認事項

```sql
-- 1. Supabase Auth が有効になっていること（デフォルトで有効）
-- 2. uuid-ossp 拡張が有効になっていること
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 3. pgcrypto 拡張が有効になっていること
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

---

## 🔴 STEP 1：ユーザー・Mowi関連テーブル

---

### 01. `users` テーブル

```sql
-- =====================================================
-- テーブル名: users
-- 役割: auth.usersと1:1で紐づくユーザープロフィール
-- 要件: v3.1 §17.1 / AGENTS.md §6
-- =====================================================
CREATE TABLE users (
    -- 主キー（auth.usersのUUIDをそのまま使用）
    id                  UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    -- 基本情報
    email               TEXT NOT NULL,
    display_name        TEXT NOT NULL DEFAULT '',
    avatar_url          TEXT,

    -- ロール管理
    -- 'student' : 生徒（トレーナー）
    -- 'teacher' : 先生（ジムリーダー）
    -- 'admin'   : システム管理者
    role                TEXT NOT NULL DEFAULT 'student'
                        CHECK (role IN ('student', 'teacher', 'admin')),

    -- プラン管理（Stripe連携 Month 3〜）
    -- 'free'    : P001〜P020 + 基本バトル + チェックイン
    -- 'premium' : 全パターン + AI補強フル + 週次レポート
    -- 'teacher' : ダッシュボード + クラス管理 + チェックインデータ
    -- 'school'  : 複数クラス + 無制限生徒 + 優先サポート
    plan                TEXT NOT NULL DEFAULT 'free'
                        CHECK (plan IN ('free', 'premium', 'teacher_plan', 'school')),

    -- 学習進捗（全体）
    mowi_level          INTEGER NOT NULL DEFAULT 1 CHECK (mowi_level BETWEEN 1 AND 30),
    total_xp            INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
    streak_days         INTEGER NOT NULL DEFAULT 0 CHECK (streak_days >= 0),
    max_streak_days     INTEGER NOT NULL DEFAULT 0 CHECK (max_streak_days >= 0),

    -- ログイン管理
    last_login_at       TIMESTAMPTZ,
    last_practice_at    TIMESTAMPTZ,

    -- 設定
    notification_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    language_ui         TEXT NOT NULL DEFAULT 'ja' CHECK (language_ui IN ('ja', 'en', 'ko')),

    -- タイムスタンプ
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX users_role_idx     ON users(role);
CREATE INDEX users_plan_idx     ON users(plan);
CREATE INDEX users_mowi_lv_idx  ON users(mowi_level DESC);

-- RLS 有効化
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- ポリシー：自分のプロフィールのみ読み書き可
CREATE POLICY "users_select_own"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "users_update_own"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- ポリシー：先生は同じクラスの生徒プロフィールを閲覧可
CREATE POLICY "teachers_select_class_members"
    ON users FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM class_members cm
            JOIN classes c ON cm.class_id = c.id
            WHERE cm.user_id = users.id
              AND c.teacher_id = auth.uid()
        )
    );
```

---

### 02. `mowi_state` テーブル

```sql
-- =====================================================
-- テーブル名: mowi_state
-- 役割: Mowiの感情・成長状態（ユーザーの英語力の鏡）
-- 要件: v3.1 §3, §5, §17.1
-- =====================================================
CREATE TABLE mowi_state (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 感情パラメータ（0〜100）
    -- happiness: 練習結果・コンボ・チェックインから算出
    happiness               INTEGER NOT NULL DEFAULT 50
                            CHECK (happiness BETWEEN 0 AND 100),

    -- 成長ステージ（Mowiのビジュアル変化）
    -- 0: モノクロ（Lv.1）  1: うっすら色づく（Lv.5）
    -- 2: 光輪が現れる（Lv.10）  3: フルカラー（Lv.20）
    -- 4: 星のエフェクト（Lv.30）
    growth_stage            INTEGER NOT NULL DEFAULT 0
                            CHECK (growth_stage BETWEEN 0 AND 4),

    -- 感情ステート（アニメーション用）
    -- idle / joy / cheer / sad / think / grow / sleep / streak / first_pattern
    current_emotion         TEXT NOT NULL DEFAULT 'idle'
                            CHECK (current_emotion IN (
                                'idle', 'joy', 'cheer', 'sad', 'think',
                                'grow', 'sleep', 'streak', 'first_pattern'
                            )),

    -- コンボ状態（ゲームループ中のリアルタイム値）
    current_combo           INTEGER NOT NULL DEFAULT 0 CHECK (current_combo >= 0),
    max_combo_today         INTEGER NOT NULL DEFAULT 0 CHECK (max_combo_today >= 0),

    -- 週次スナップショット（先週のMowiと比較用）
    weekly_snapshot_happiness   INTEGER CHECK (weekly_snapshot_happiness BETWEEN 0 AND 100),
    weekly_snapshot_at          TIMESTAMPTZ,

    -- インタラクション管理
    last_interaction_at     TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- タイムスタンプ
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- ユーザー1人につき1レコード
    UNIQUE (user_id)
);

-- インデックス
CREATE INDEX mowi_state_user_idx ON mowi_state(user_id);

-- RLS 有効化
ALTER TABLE mowi_state ENABLE ROW LEVEL SECURITY;

CREATE POLICY "mowi_state_own"
    ON mowi_state FOR ALL
    USING (auth.uid() = user_id);

-- 先生は生徒のMowi状態を参照可（ダッシュボード用）
CREATE POLICY "teachers_view_mowi_state"
    ON mowi_state FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM class_members cm
            JOIN classes c ON cm.class_id = c.id
            WHERE cm.user_id = mowi_state.user_id
              AND c.teacher_id = auth.uid()
        )
    );
```

---

### 03. `checkins` テーブル

```sql
-- =====================================================
-- テーブル名: checkins
-- 役割: 朝・夜のチェックイン日記
-- 要件: v3.1 §4, §17.1 / C2 UX設計書 v3.0
-- =====================================================
CREATE TABLE checkins (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- チェックイン種別
    -- 'morning': 練習前（朝）/ 'evening': 練習後（夜）
    type            TEXT NOT NULL CHECK (type IN ('morning', 'evening')),

    -- 朝チェックイン選択肢（C2 v3.0 確定コピー）
    -- morning_confident  : 自信ある（Ready for it ✨）
    -- morning_okay       : まあまあ（Somewhere in the middle 😌）
    -- morning_anxious    : 不安（A little heavy 😟）
    -- morning_unsure     : わからない（Can't tell yet 🌀）
    feeling         TEXT CHECK (feeling IN (
                        'morning_confident', 'morning_okay',
                        'morning_anxious', 'morning_unsure'
                    )),

    -- 夜チェックイン選択肢（C2 v3.0 確定コピー）
    -- evening_said_it    : 言えた気がする（Something came out 💬）
    -- evening_fun        : 楽しかった（Actually enjoyed it 😊）
    -- evening_hard       : 難しかった（Couldn't get there 🤔）
    -- evening_not_quite  : しっくりこない（Not quite clicking 🌫）
    result          TEXT CHECK (result IN (
                        'evening_said_it', 'evening_fun',
                        'evening_hard', 'evening_not_quite'
                    )),

    -- Mowiの内なる声（そのチェックインで表示されたセリフ）
    mowi_quote      TEXT,

    -- 当日の練習セッションとの紐付け（任意）
    -- 夜チェックインが特定のバトル・練習セッション後に行われた場合に記録
    session_ref_id  UUID,

    -- その日のストリーク日数（記録時点）
    streak_at_checkin INTEGER,

    -- タイムスタンプ
    checkin_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX checkins_user_date_idx  ON checkins(user_id, checkin_date DESC);
CREATE INDEX checkins_user_type_idx  ON checkins(user_id, type, checkin_date DESC);
CREATE INDEX checkins_feeling_idx    ON checkins(feeling, checkin_date DESC);

-- RLS 有効化
ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "checkins_own"
    ON checkins FOR ALL
    USING (auth.uid() = user_id);

-- 先生は生徒のチェックインデータを閲覧可（ダッシュボード用）
CREATE POLICY "teachers_view_checkins"
    ON checkins FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM class_members cm
            JOIN classes c ON cm.class_id = c.id
            WHERE cm.user_id = checkins.user_id
              AND c.teacher_id = auth.uid()
        )
    );
```

---

## 🔴 STEP 2：パターン図鑑・コンテンツテーブル

---

### 04. `patterns` テーブル

```sql
-- =====================================================
-- テーブル名: patterns
-- 役割: パターン図鑑マスターデータ（P001〜P100）
-- 要件: v3.1 §8 / パターン図鑑100リスト v2.0
-- =====================================================
CREATE TABLE patterns (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- 図鑑番号（例：'P001', 'P035', 'P100'）
    pattern_no          TEXT NOT NULL UNIQUE CHECK (pattern_no ~ '^P[0-9]{3}$'),

    -- パターン内容
    pattern_text        TEXT NOT NULL,   -- 例：[代名詞] + be動詞 + [名前/形容詞/名詞]
    pattern_short       TEXT NOT NULL,   -- 例：I'm [形容詞]. （図鑑カード表示用・短縮版）
    japanese            TEXT NOT NULL,   -- 例：〜は…です

    -- レアリティ（ポケモン設計準拠）
    -- 1: ★☆☆☆☆ （エリア1・最初から所持）
    -- 2: ★★☆☆☆ （エリア1後半〜エリア2）
    -- 3: ★★★☆☆ （エリア2〜エリア3）
    -- 4: ★★★★☆ （エリア3〜エリア4）
    -- 5: ★★★★★ （エリア4〜5・最高レア）
    rarity              INTEGER NOT NULL DEFAULT 1
                        CHECK (rarity BETWEEN 1 AND 5),

    -- エリア分類
    -- 'area1': はじまりの村（P001〜P019）
    -- 'area2': 街の市場（P020〜P035）
    -- 'area3': 港の街（P036〜P055）Phase 2〜
    -- 'area4': 山の学院（P056〜P075）Phase 3〜
    -- 'area5': 英語の都（P076〜P100）Phase 3〜
    area                TEXT NOT NULL DEFAULT 'area1'
                        CHECK (area IN ('area1', 'area2', 'area3', 'area4', 'area5')),

    -- 進化関係
    evolution_of        TEXT REFERENCES patterns(pattern_no),  -- 進化前パターン番号
    evolution_forms     TEXT[] DEFAULT '{}',  -- 進化形パターン（例：['P045', 'P046']）
    evolution_label     TEXT[],               -- 進化形の英語表現ラベル（表示用）

    -- 解禁条件
    -- NULL: 最初から所持
    -- それ以外: 条件パターン番号（例：'P001'）とレベルを記述
    unlock_condition_pattern TEXT REFERENCES patterns(pattern_no),
    unlock_condition_stars   INTEGER CHECK (unlock_condition_stars BETWEEN 1 AND 5),

    -- 使用シーン・タグ
    scene_tags          TEXT[] DEFAULT '{}',  -- 例：['自己紹介', '天気', 'お店']

    -- 音声設定（Google Cloud TTS）
    audio_voice_male    TEXT NOT NULL DEFAULT 'en-US-Neural2-D',
    audio_voice_female  TEXT NOT NULL DEFAULT 'en-US-Neural2-F',

    -- MVP対象フラグ
    is_mvp              BOOLEAN NOT NULL DEFAULT FALSE,  -- P001〜P035 = TRUE

    -- フリープラン公開フラグ
    is_free             BOOLEAN NOT NULL DEFAULT FALSE,  -- P001〜P020 = TRUE

    -- ソート用
    sort_order          INTEGER NOT NULL DEFAULT 0,

    -- タイムスタンプ
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX patterns_area_idx      ON patterns(area, sort_order);
CREATE INDEX patterns_rarity_idx    ON patterns(rarity);
CREATE INDEX patterns_mvp_idx       ON patterns(is_mvp) WHERE is_mvp = TRUE;
CREATE INDEX patterns_free_idx      ON patterns(is_free) WHERE is_free = TRUE;

-- RLS 有効化（パターンマスターは全員読み取り可）
ALTER TABLE patterns ENABLE ROW LEVEL SECURITY;

CREATE POLICY "patterns_select_all"
    ON patterns FOR SELECT
    USING (TRUE);

-- 管理者のみ更新可
CREATE POLICY "patterns_admin_all"
    ON patterns FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
```

---

### 05. `pattern_content` テーブル

```sql
-- =====================================================
-- テーブル名: pattern_content
-- 役割: 各パターンのLayer別問題コンテンツ（P001〜P035）
-- 要件: P001〜P035コンテンツ設計書群 / v3.1 §7
-- =====================================================
CREATE TABLE pattern_content (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_no      TEXT NOT NULL REFERENCES patterns(pattern_no) ON DELETE CASCADE,

    -- Layer番号
    -- 0: Sound Foundation（音を聞く）
    -- 1: Echo Drill（まねる）
    -- 2: Pattern Sense（スロット穴埋め＋音声予測）← v3.1刷新
    -- 3: Flash Output（瞬間英作文）← 最重要
    -- 4: Scene Challenge（実践）← Phase 2
    layer           INTEGER NOT NULL CHECK (layer BETWEEN 0 AND 4),

    -- 問題順序（Layer内の出題順）
    question_order  INTEGER NOT NULL DEFAULT 1,

    -- 問題サブタイプ
    -- layer0: 'sound_compare'（2音聞き比べ）
    -- layer1: 'sound_match'（音声→テキスト3択）
    -- layer2: 'slot_fill'（スロット穴埋め）| 'audio_predict'（音声予測）
    -- layer3: 'tile_select'（タイル選択）| 'keyboard_input'（キーボード入力）
    -- layer4: 'scene_challenge'（場面実践）
    question_type   TEXT NOT NULL CHECK (question_type IN (
                        'sound_compare', 'sound_match',
                        'slot_fill', 'audio_predict',
                        'tile_select', 'keyboard_input',
                        'scene_challenge'
                    )),

    -- 問題テキスト・表示内容
    prompt_ja       TEXT,   -- 日本語プロンプト（Flash Output用）
    prompt_en       TEXT,   -- 英語プロンプト（Layer 0〜2用）
    display_text    TEXT,   -- 画面表示テキスト（スロット穴埋めの「I'm ___」など）
    context_text    TEXT,   -- 状況説明テキスト（L2-S4の「ユキとケンジが2人いる」など）

    -- 音声ファイルパス（Supabase Storage）
    audio_url_a     TEXT,   -- Layer 0の音声A（ゆっくり版）
    audio_url_b     TEXT,   -- Layer 0の音声B（ネイティブ速度版）
    audio_url_main  TEXT,   -- Layer 1〜3のメイン音声

    -- 選択肢データ（JSON配列）
    -- 例：[{"text": "tired", "is_correct": true}, {"text": "sleep", "is_correct": false, "explanation": "..."}, ...]
    choices         JSONB,

    -- 正解データ
    correct_answer  TEXT,   -- 単一正解テキスト（キーボード入力用）
    alternate_answers TEXT[], -- 別解（複数正解がある場合）

    -- フィードバック
    explanation_ja  TEXT,   -- 不正解時の解説（日本語）
    mowi_quote_correct TEXT, -- 正解時のMowiセリフ
    mowi_quote_wrong   TEXT, -- 不正解時のMowiセリフ

    -- ゲームパラメータ
    time_limit_sec  INTEGER DEFAULT 8,   -- Layer 3の制限時間（秒）
    pass_threshold  INTEGER,             -- クリア基準（N問中M問正解）

    -- 音声制作仕様（Google Cloud TTS）
    tts_text_a      TEXT,   -- TTSに渡すテキストA
    tts_text_b      TEXT,   -- TTSに渡すテキストB
    tts_speed_a     NUMERIC(3,2) DEFAULT 0.75,
    tts_speed_b     NUMERIC(3,2) DEFAULT 1.00,
    tts_voice       TEXT DEFAULT 'en-US-Neural2-D',

    -- タイムスタンプ
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- 同一パターン・Layer・順序の重複防止
    UNIQUE (pattern_no, layer, question_order)
);

-- インデックス
CREATE INDEX pattern_content_pattern_layer_idx ON pattern_content(pattern_no, layer, question_order);
CREATE INDEX pattern_content_type_idx          ON pattern_content(question_type);

-- RLS 有効化（コンテンツは全員読み取り可）
ALTER TABLE pattern_content ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pattern_content_select_all"
    ON pattern_content FOR SELECT
    USING (TRUE);

-- 管理者のみ更新可
CREATE POLICY "pattern_content_admin_all"
    ON pattern_content FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'admin'
        )
    );
```

---

### 06. `pattern_progress` テーブル（SM-2アルゴリズム対応）

```sql
-- =====================================================
-- テーブル名: pattern_progress
-- 役割: ユーザー別のパターン習熟度管理
-- 要件: v3.1 §7, §13.1 / SM-2アルゴリズム実装
-- SM-2参考: ease_factor / interval_days / times_seen
-- =====================================================
CREATE TABLE pattern_progress (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pattern_no          TEXT NOT NULL REFERENCES patterns(pattern_no) ON DELETE CASCADE,

    -- 習熟度（ポケモン★システム）
    -- 0: 未解禁  1: ★☆☆☆☆（Layer 0クリア）  2: ★★☆☆☆（Layer 1クリア）
    -- 3: ★★★☆☆（Layer 2クリア）  4: ★★★★☆（Layer 3クリア）
    -- 5: ★★★★★（全Layer完了・進化形解禁）
    mastery_level       INTEGER NOT NULL DEFAULT 0
                        CHECK (mastery_level BETWEEN 0 AND 5),

    -- Layer完了フラグ
    layer0_done         BOOLEAN NOT NULL DEFAULT FALSE,
    layer1_done         BOOLEAN NOT NULL DEFAULT FALSE,
    layer2_done         BOOLEAN NOT NULL DEFAULT FALSE,
    layer3_done         BOOLEAN NOT NULL DEFAULT FALSE,
    layer4_done         BOOLEAN NOT NULL DEFAULT FALSE,

    -- 学習統計
    correct_count       INTEGER NOT NULL DEFAULT 0 CHECK (correct_count >= 0),
    total_attempts      INTEGER NOT NULL DEFAULT 0 CHECK (total_attempts >= 0),
    -- 正解率（0.000〜1.000）: correct_count / total_attempts で都度計算も可
    correct_rate        NUMERIC(5,3) NOT NULL DEFAULT 0
                        CHECK (correct_rate BETWEEN 0 AND 1),

    -- 平均回答速度（ミリ秒）
    avg_response_ms     INTEGER CHECK (avg_response_ms > 0),

    -- タイムアウト率（Flash Output用）
    timeout_rate        NUMERIC(5,3) NOT NULL DEFAULT 0
                        CHECK (timeout_rate BETWEEN 0 AND 1),

    -- Flash Output難易度（AI自動調整用）
    -- 1: タイル選択式（デフォルト）
    -- 2: キーボード入力式（Phase 2〜）
    -- 3: 音声入力式（Phase 3〜）
    flash_output_difficulty INTEGER NOT NULL DEFAULT 1
                            CHECK (flash_output_difficulty BETWEEN 1 AND 3),

    -- ──────────────────────────────────────────────
    -- SM-2 アルゴリズム用フィールド
    -- 参考：SuperMemo-2（Anki等でも使われる忘却曲線アルゴリズム）
    -- ──────────────────────────────────────────────

    -- 次回復習予定日
    -- 正解後: next_review_date = now() + interval_days
    -- 未練習の間は時間経過で習熟度が自然減衰
    next_review_date    DATE,

    -- 復習間隔（日数）
    -- SM-2: interval(n) = interval(n-1) × ease_factor
    -- 初回: 1日 / 2回目: 6日 / 3回目以降: × ease_factor
    interval_days       INTEGER NOT NULL DEFAULT 1 CHECK (interval_days >= 1),

    -- 習熟度係数（SM-2 ease factor）
    -- 初期値: 2.5 / 範囲: 1.3〜5.0
    -- 正解のたびに +0.1（最大5.0まで） / 不正解のたびに -0.2（最小1.3まで）
    ease_factor         NUMERIC(4,2) NOT NULL DEFAULT 2.50
                        CHECK (ease_factor BETWEEN 1.30 AND 5.00),

    -- 累計練習回数（SM-2 repetition counter）
    -- 正解が続くと interval が伸び、忘却しにくくなる計算に使用
    times_seen          INTEGER NOT NULL DEFAULT 0 CHECK (times_seen >= 0),

    -- 直近の練習スコア（SM-2 quality rating: 0〜5）
    -- 0〜1: 全く思い出せず  2: 思い出したが不正解
    -- 3: 時間切れで正解  4: 正解（通常）  5: 即座に正解（高速）
    last_quality_rating INTEGER CHECK (last_quality_rating BETWEEN 0 AND 5),

    -- ──────────────────────────────────────────────
    -- AI弱点補強システム用フィールド（v3.1 §12）
    -- ──────────────────────────────────────────────

    -- デイリー自動追加フラグ（正解率<60%で自動追加）
    is_daily_reinforced BOOLEAN NOT NULL DEFAULT FALSE,

    -- 連続不正解カウント（5回でヒントモード）
    consecutive_wrong   INTEGER NOT NULL DEFAULT 0 CHECK (consecutive_wrong >= 0),

    -- 最終練習日時
    last_practiced_at   TIMESTAMPTZ,

    -- タイムスタンプ
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- 1ユーザー × 1パターン で1レコード
    UNIQUE (user_id, pattern_no)
);

-- インデックス
CREATE INDEX pp_user_mastery_idx     ON pattern_progress(user_id, mastery_level DESC);
CREATE INDEX pp_user_review_idx      ON pattern_progress(user_id, next_review_date ASC)
    WHERE next_review_date IS NOT NULL;
CREATE INDEX pp_user_correct_idx     ON pattern_progress(user_id, correct_rate ASC);
CREATE INDEX pp_pattern_idx          ON pattern_progress(pattern_no);
CREATE INDEX pp_daily_reinforce_idx  ON pattern_progress(user_id, is_daily_reinforced)
    WHERE is_daily_reinforced = TRUE;

-- RLS 有効化
ALTER TABLE pattern_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "pp_own"
    ON pattern_progress FOR ALL
    USING (auth.uid() = user_id);

-- 先生は生徒の習熟度を閲覧可（ダッシュボード用）
CREATE POLICY "teachers_view_pp"
    ON pattern_progress FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM class_members cm
            JOIN classes c ON cm.class_id = c.id
            WHERE cm.user_id = pattern_progress.user_id
              AND c.teacher_id = auth.uid()
        )
    );
```

---

### 07. `flash_output_logs` テーブル

```sql
-- =====================================================
-- テーブル名: flash_output_logs
-- 役割: Layer 3 Flash Sprint（Flash Output）の1問ごとログ
-- 要件: v3.1 §7（Layer 3） / AI弱点補強 §12
-- =====================================================
CREATE TABLE flash_output_logs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pattern_no          TEXT NOT NULL REFERENCES patterns(pattern_no) ON DELETE CASCADE,

    -- セッション識別子（同一セッションの複数問を束ねる）
    session_id          UUID NOT NULL,

    -- 問題情報
    layer               INTEGER NOT NULL DEFAULT 3 CHECK (layer = 3),
    question_type       TEXT NOT NULL CHECK (question_type IN ('tile_select', 'keyboard_input')),
    question_order      INTEGER NOT NULL,  -- セッション内の出題順

    -- 問題内容スナップショット（AI分析用）
    prompt_ja           TEXT,   -- 出題された日本語プロンプト
    correct_answer      TEXT,   -- 正解英文

    -- 回答結果
    user_answer         TEXT,   -- ユーザーの実際の回答（keyboard_input のみ）
    is_correct          BOOLEAN NOT NULL,
    was_timeout         BOOLEAN NOT NULL DEFAULT FALSE,
    hint_used           BOOLEAN NOT NULL DEFAULT FALSE,

    -- 回答速度
    response_time_ms    INTEGER NOT NULL DEFAULT 0,
    time_limit_ms       INTEGER NOT NULL DEFAULT 8000,  -- 制限時間（ms）

    -- コンボ状態（回答時点）
    combo_at_time       INTEGER NOT NULL DEFAULT 0,

    -- SM-2 クオリティレーティング（回答時に自動計算・保存）
    -- 5: 制限時間の50%以内で正解
    -- 4: 制限時間内で正解
    -- 3: ヒント使用で正解
    -- 2: タイムアウトで不正解
    -- 1: 間違いで不正解
    -- 0: 連続3回以上不正解
    quality_rating      INTEGER NOT NULL DEFAULT 0
                        CHECK (quality_rating BETWEEN 0 AND 5),

    -- Flash Sprintゲームクローン統合用フィールド
    -- （既存Flash Sprint実装からの移植・連携に対応）
    game_mode           TEXT DEFAULT 'standard'
                        CHECK (game_mode IN ('standard', 'sprint', 'review', 'battle')),
    -- 'sprint'  : Flash Sprint専用モード（制限時間短縮・高難易度）
    -- 'review'  : SM-2で次回復習日が来たパターンの復習
    -- 'battle'  : バトルセッション中のFlash Output

    -- バトルとの紐付け（battle_modeの場合）
    battle_id           UUID REFERENCES battles(id) ON DELETE SET NULL,

    -- タイムスタンプ
    answered_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX fol_user_pattern_idx   ON flash_output_logs(user_id, pattern_no, answered_at DESC);
CREATE INDEX fol_session_idx        ON flash_output_logs(session_id, question_order);
CREATE INDEX fol_user_correct_idx   ON flash_output_logs(user_id, is_correct, answered_at DESC);
CREATE INDEX fol_timeout_idx        ON flash_output_logs(user_id, was_timeout)
    WHERE was_timeout = TRUE;

-- RLS 有効化
ALTER TABLE flash_output_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fol_own"
    ON flash_output_logs FOR ALL
    USING (auth.uid() = user_id);

-- 先生は生徒のFlash Outputログを閲覧可
CREATE POLICY "teachers_view_fol"
    ON flash_output_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM class_members cm
            JOIN classes c ON cm.class_id = c.id
            WHERE cm.user_id = flash_output_logs.user_id
              AND c.teacher_id = auth.uid()
        )
    );
```

---

## 🔴 STEP 3：クラス・先生ダッシュボード関連テーブル

---

### 08. `classes` テーブル

```sql
-- =====================================================
-- テーブル名: classes
-- 役割: 先生（ジムリーダー）が管理するクラス
-- 要件: v3.1 §10, §11, §17.1
-- =====================================================
CREATE TABLE classes (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id              UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- クラス基本情報
    class_name              TEXT NOT NULL,
    class_code              TEXT NOT NULL UNIQUE,  -- 生徒が入室に使う6桁コード（例：ABC123）
    description             TEXT,

    -- 課題設定（先生が指定したパターン範囲）
    -- 例：['P001', 'P002', 'P003', ...]
    assigned_pattern_ids    TEXT[] NOT NULL DEFAULT '{}',

    -- 現在のフォーカスパターン範囲
    current_pattern_range_start TEXT REFERENCES patterns(pattern_no),
    current_pattern_range_end   TEXT REFERENCES patterns(pattern_no),

    -- エリア解禁設定（先生がバッジ発行でエリアを解禁）
    unlocked_areas          TEXT[] NOT NULL DEFAULT ARRAY['area1'],

    -- クラスのステータス
    status                  TEXT NOT NULL DEFAULT 'active'
                            CHECK (status IN ('active', 'archived')),

    -- 生徒数上限（プランによる制限）
    max_students            INTEGER NOT NULL DEFAULT 30,

    -- タイムスタンプ
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE UNIQUE INDEX classes_code_idx    ON classes(class_code);
CREATE INDEX classes_teacher_idx        ON classes(teacher_id);
CREATE INDEX classes_status_idx         ON classes(status);

-- RLS 有効化
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;

-- 先生は自分のクラスを全操作可
CREATE POLICY "teachers_manage_classes"
    ON classes FOR ALL
    USING (auth.uid() = teacher_id);

-- 生徒は所属クラスを閲覧可
CREATE POLICY "students_view_own_class"
    ON classes FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members
            WHERE class_id = classes.id
              AND user_id = auth.uid()
        )
    );
```

---

### 09. `class_members` テーブル

```sql
-- =====================================================
-- テーブル名: class_members
-- 役割: クラスと生徒の紐付け（多対多）
-- 要件: v3.1 §10, §11
-- =====================================================
CREATE TABLE class_members (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id    UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 参加状態
    -- 'pending'  : 参加申請中（先生の承認待ち）
    -- 'approved' : 参加承認済み
    -- 'removed'  : 先生によって削除済み
    status      TEXT NOT NULL DEFAULT 'pending'
                CHECK (status IN ('pending', 'approved', 'removed')),

    -- 承認情報
    approved_by UUID REFERENCES users(id),
    approved_at TIMESTAMPTZ,

    -- クラス入室コード（入室時に使用したコードを記録）
    joined_via_code TEXT,

    -- タイムスタンプ
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- 同一クラス・同一ユーザーの重複防止
    UNIQUE (class_id, user_id)
);

-- インデックス
CREATE INDEX cm_class_idx       ON class_members(class_id, status);
CREATE INDEX cm_user_idx        ON class_members(user_id, status);

-- RLS 有効化
ALTER TABLE class_members ENABLE ROW LEVEL SECURITY;

-- 自分自身の所属情報は参照可
CREATE POLICY "members_view_own"
    ON class_members FOR SELECT
    USING (auth.uid() = user_id);

-- 先生は自分のクラスのメンバー情報を全操作可
CREATE POLICY "teachers_manage_members"
    ON class_members FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM classes
            WHERE id = class_members.class_id
              AND teacher_id = auth.uid()
        )
    );

-- 生徒は自分でクラスに参加申請可（INSERT）
CREATE POLICY "students_join_class"
    ON class_members FOR INSERT
    WITH CHECK (auth.uid() = user_id);
```

---

### 10. `gym_badges` テーブル

```sql
-- =====================================================
-- テーブル名: gym_badges
-- 役割: ジムバッジ（先生による認定証）
-- 要件: v3.1 §13.3
-- =====================================================
CREATE TABLE gym_badges (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id        UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,

    -- バッジ種別（エリアクリア認定）
    area            TEXT NOT NULL CHECK (area IN ('area1', 'area2', 'area3', 'area4', 'area5')),

    -- バッジ名（表示用）
    -- 例：'Hello Badge'（エリア1）
    badge_name      TEXT NOT NULL,

    -- 申請・承認フロー
    -- 'pending'  : 生徒が申請中
    -- 'approved' : 先生が承認（正式発行）
    -- 'rejected' : 先生が却下（再申請可）
    status          TEXT NOT NULL DEFAULT 'pending'
                    CHECK (status IN ('pending', 'approved', 'rejected')),

    -- 申請時のスナップショット
    mastery_avg_at_apply  NUMERIC(4,2),  -- 申請時の該当エリア平均★

    -- 承認情報
    approved_by     UUID REFERENCES users(id),
    approved_at     TIMESTAMPTZ,
    rejection_reason TEXT,  -- 却下理由（先生が入力）

    -- タイムスタンプ
    applied_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- 1生徒 × 1クラス × 1エリア で1バッジ
    UNIQUE (student_id, class_id, area)
);

-- インデックス
CREATE INDEX gym_badges_student_idx ON gym_badges(student_id, status);
CREATE INDEX gym_badges_class_idx   ON gym_badges(class_id, status);
CREATE INDEX gym_badges_teacher_idx ON gym_badges(approved_by);

-- RLS 有効化
ALTER TABLE gym_badges ENABLE ROW LEVEL SECURITY;

-- 生徒は自分のバッジを閲覧・申請可
CREATE POLICY "students_manage_own_badges"
    ON gym_badges FOR ALL
    USING (auth.uid() = student_id);

-- 先生は自分のクラスのバッジを全操作可
CREATE POLICY "teachers_manage_class_badges"
    ON gym_badges FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM classes
            WHERE id = gym_badges.class_id
              AND teacher_id = auth.uid()
        )
    );
```

---

## 🔴 STEP 4：バトルシステムテーブル

---

### 11. `battles` テーブル

```sql
-- =====================================================
-- テーブル名: battles
-- 役割: バトルセッション全体の記録
-- 要件: v3.1 §9 / バトルシステム設計書 v1.0 §10.1
-- =====================================================
CREATE TABLE battles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- バトル種別
    -- 'daily' : デイリーバトル（AI対戦）← MVP
    -- 'class' : クラスバトル（生徒間非同期対戦）← Phase 2
    -- 'raid'  : レイドバトル（クラス全員協力）← Phase 2
    battle_type         TEXT NOT NULL CHECK (battle_type IN ('daily', 'class', 'raid')),
    battle_date         DATE NOT NULL DEFAULT CURRENT_DATE,

    -- クラスバトル・レイドへの紐付け（Phase 2〜）
    class_battle_id     UUID REFERENCES class_battles(id) ON DELETE SET NULL,
    raid_id             UUID REFERENCES raids(id) ON DELETE SET NULL,

    -- バトル設定（開始時に確定・変更不可）
    ai_level            INTEGER CHECK (ai_level BETWEEN 0 AND 4),  -- デイリーのみ使用
    question_count      INTEGER NOT NULL DEFAULT 7,
    time_limit_sec      INTEGER NOT NULL DEFAULT 8,

    -- チェックイン連動（朝チェックインの状態がバトルに影響）
    morning_mood        TEXT CHECK (morning_mood IN (
                            'morning_confident', 'morning_okay',
                            'morning_anxious', 'morning_unsure'
                        )),
    combo_multiplier    NUMERIC(4,2) NOT NULL DEFAULT 1.00,
    time_multiplier     NUMERIC(4,2) NOT NULL DEFAULT 1.00,
    hint_bonus          INTEGER NOT NULL DEFAULT 0,  -- ヒント利用可能追加回数

    -- バトル結果
    score               INTEGER NOT NULL DEFAULT 0 CHECK (score >= 0),
    accuracy_rate       NUMERIC(5,3) NOT NULL DEFAULT 0
                        CHECK (accuracy_rate BETWEEN 0 AND 1),
    avg_response_ms     INTEGER,
    max_combo           INTEGER NOT NULL DEFAULT 0 CHECK (max_combo >= 0),
    correct_count       INTEGER NOT NULL DEFAULT 0,
    total_questions     INTEGER NOT NULL DEFAULT 0,

    -- デイリー専用：AI対戦結果
    -- AI目標スコア = 3日前の自分のスコア × 1.05
    ai_target_score     INTEGER,
    battle_won          BOOLEAN,

    -- ステータス
    status              TEXT NOT NULL DEFAULT 'in_progress'
                        CHECK (status IN ('in_progress', 'completed', 'abandoned')),

    -- タイムスタンプ
    started_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at            TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX battles_user_type_date_idx ON battles(user_id, battle_type, battle_date DESC);
CREATE INDEX battles_class_battle_idx   ON battles(class_battle_id)
    WHERE class_battle_id IS NOT NULL;
CREATE INDEX battles_raid_idx           ON battles(raid_id)
    WHERE raid_id IS NOT NULL;
CREATE INDEX battles_status_idx         ON battles(user_id, status);

-- RLS 有効化
ALTER TABLE battles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "battles_own"
    ON battles FOR ALL
    USING (auth.uid() = user_id);

-- 先生は同クラス生徒のバトルを閲覧可
CREATE POLICY "teachers_view_class_battles"
    ON battles FOR SELECT
    USING (
        EXISTS (
            SELECT 1
            FROM class_members cm
            JOIN classes c ON cm.class_id = c.id
            WHERE cm.user_id = battles.user_id
              AND c.teacher_id = auth.uid()
        )
    );
```

---

### 12. `battle_logs` テーブル

```sql
-- =====================================================
-- テーブル名: battle_logs
-- 役割: バトル内の1問ごとの回答ログ
-- 要件: バトルシステム設計書 v1.0 §10.2
-- =====================================================
CREATE TABLE battle_logs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    battle_id           UUID NOT NULL REFERENCES battles(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- 問題情報
    pattern_no          TEXT NOT NULL,   -- 'P001' 〜 'P100'
    layer               INTEGER NOT NULL DEFAULT 3 CHECK (layer BETWEEN 0 AND 4),
    question_order      INTEGER NOT NULL,  -- バトル内の出題順（1〜N）

    -- 回答情報
    is_correct          BOOLEAN NOT NULL,
    response_time_ms    INTEGER NOT NULL DEFAULT 0,
    was_timeout         BOOLEAN NOT NULL DEFAULT FALSE,
    hint_used           BOOLEAN NOT NULL DEFAULT FALSE,

    -- スコア計算の中間値（デバッグ・分析用）
    base_score          INTEGER NOT NULL DEFAULT 0,
    speed_bonus         NUMERIC(4,2) NOT NULL DEFAULT 1.00,
    combo_at_time       INTEGER NOT NULL DEFAULT 0,
    combo_multiplier    NUMERIC(4,2) NOT NULL DEFAULT 1.00,
    question_score      INTEGER NOT NULL DEFAULT 0,

    -- タイムスタンプ
    answered_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX bl_battle_order_idx    ON battle_logs(battle_id, question_order);
CREATE INDEX bl_user_pattern_idx    ON battle_logs(user_id, pattern_no, answered_at DESC);

-- RLS 有効化
ALTER TABLE battle_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bl_own"
    ON battle_logs FOR ALL
    USING (auth.uid() = user_id);
```

---

### 13. `class_battles` テーブル（Phase 2〜）

```sql
-- =====================================================
-- テーブル名: class_battles
-- 役割: 先生が設定するクラスバトルイベント定義
-- 要件: v3.1 §9.2 / バトルシステム設計書 v1.0 §10.3
-- フェーズ: Phase 2（Month 4〜）
-- =====================================================
CREATE TABLE class_battles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id            UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id          UUID NOT NULL REFERENCES users(id),

    title               TEXT NOT NULL,
    pattern_ids         TEXT[] NOT NULL DEFAULT '{}',
    question_count      INTEGER NOT NULL DEFAULT 15,
    time_limit_sec      INTEGER NOT NULL DEFAULT 8,

    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,

    status              TEXT NOT NULL DEFAULT 'scheduled'
                        CHECK (status IN ('scheduled', 'active', 'finished')),

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX cb_class_status_idx ON class_battles(class_id, status, end_date DESC);

-- RLS 有効化
ALTER TABLE class_battles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teachers_manage_cb"
    ON class_battles FOR ALL
    USING (auth.uid() = teacher_id);

CREATE POLICY "students_view_cb"
    ON class_battles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members
            WHERE class_id = class_battles.class_id
              AND user_id = auth.uid()
              AND status = 'approved'
        )
    );
```

---

### 14. `raids` テーブル（Phase 2〜）

```sql
-- =====================================================
-- テーブル名: raids
-- 役割: 先生が設定するレイドバトルイベント定義
-- 要件: v3.1 §9.3 / バトルシステム設計書 v1.0 §10.4
-- フェーズ: Phase 2（Month 4〜）
-- =====================================================
CREATE TABLE raids (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id                UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id              UUID NOT NULL REFERENCES users(id),

    title                   TEXT NOT NULL,
    boss_name               TEXT NOT NULL,  -- 例：「The Shadow of が構文」

    pattern_ids             TEXT[] NOT NULL DEFAULT '{}',

    -- HPシステム（クラス人数 × 50 を目安に設定）
    boss_hp                 INTEGER NOT NULL CHECK (boss_hp > 0),
    current_hp              INTEGER NOT NULL,
    total_damage_dealt      INTEGER NOT NULL DEFAULT 0,

    -- ダメージ設定
    normal_damage           INTEGER NOT NULL DEFAULT 1,
    combo_damage            INTEGER NOT NULL DEFAULT 2,  -- コンボ5以上時
    daily_question_limit    INTEGER NOT NULL DEFAULT 10, -- 1人1日の攻撃上限

    start_date              DATE NOT NULL,
    end_date                DATE NOT NULL,

    status                  TEXT NOT NULL DEFAULT 'scheduled'
                            CHECK (status IN ('scheduled', 'active', 'finished')),
    result                  TEXT CHECK (result IN ('victory', 'defeat')),
    finished_at             TIMESTAMPTZ,

    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX raids_class_status_idx ON raids(class_id, status, end_date DESC);

-- RLS 有効化
ALTER TABLE raids ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teachers_manage_raids"
    ON raids FOR ALL
    USING (auth.uid() = teacher_id);

CREATE POLICY "students_view_raids"
    ON raids FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members
            WHERE class_id = raids.class_id
              AND user_id = auth.uid()
              AND status = 'approved'
        )
    );
```

---

## 🔴 STEP 5：自動化・トリガー

---

### T-01：auth.users作成時の自動初期化トリガー

```sql
-- =====================================================
-- 関数名: handle_new_user
-- 役割: auth.usersに新規ユーザーが作成された際に
--       users / mowi_state を自動的に初期化する
-- =====================================================
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    new_user_role TEXT := 'student';
    new_user_plan TEXT := 'free';
BEGIN
    -- ① users テーブルに初期レコードを作成
    INSERT INTO users (
        id,
        email,
        display_name,
        role,
        plan,
        mowi_level,
        total_xp,
        streak_days,
        max_streak_days
    )
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        new_user_role,
        new_user_plan,
        1,    -- mowi_level: 1スタート
        0,    -- total_xp: 0スタート
        0,    -- streak_days: 0スタート
        0     -- max_streak_days: 0スタート
    )
    ON CONFLICT (id) DO NOTHING;

    -- ② mowi_state テーブルに初期レコードを作成
    -- Mowiはモノクロ状態（growth_stage=0）からスタート
    INSERT INTO mowi_state (
        user_id,
        happiness,
        growth_stage,
        current_emotion,
        current_combo,
        last_interaction_at
    )
    VALUES (
        NEW.id,
        50,       -- happiness: 中間値からスタート
        0,        -- growth_stage: モノクロ（Lv.1）
        'idle',   -- current_emotion: 通常
        0,        -- current_combo: 0
        now()
    )
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- トリガー登録
-- auth.usersへのINSERT後に発火
CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION handle_new_user();
```

---

### T-02：users.updated_at自動更新トリガー

```sql
-- =====================================================
-- 関数名: update_updated_at_column
-- 役割: updated_atを自動更新する汎用関数
-- =====================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 各テーブルにトリガーを登録
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_mowi_state_updated_at
    BEFORE UPDATE ON mowi_state
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pattern_progress_updated_at
    BEFORE UPDATE ON pattern_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_classes_updated_at
    BEFORE UPDATE ON classes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_class_members_updated_at
    BEFORE UPDATE ON class_members
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_gym_badges_updated_at
    BEFORE UPDATE ON gym_badges
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_class_battles_updated_at
    BEFORE UPDATE ON class_battles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_raids_updated_at
    BEFORE UPDATE ON raids
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

---

### T-03：レイドHP更新トリガー（Phase 2〜）

```sql
-- =====================================================
-- 関数名: update_raid_hp
-- 役割: バトル完了時にレイドのHPを自動更新する
-- フェーズ: Phase 2（Month 4〜）
-- =====================================================
CREATE OR REPLACE FUNCTION update_raid_hp()
RETURNS TRIGGER AS $$
DECLARE
    v_damage INTEGER;
BEGIN
    -- バトルがレイド型で完了した場合のみ処理
    IF NEW.battle_type = 'raid'
        AND NEW.status = 'completed'
        AND NEW.raid_id IS NOT NULL
        AND OLD.status = 'in_progress'
    THEN
        -- ダメージ計算（コンボ5以上で2ダメージ、それ以外で1ダメージ）
        SELECT COALESCE(SUM(
            CASE WHEN bl.combo_at_time >= 5 THEN 2 ELSE 1 END
        ), 0)
        INTO v_damage
        FROM battle_logs bl
        WHERE bl.battle_id = NEW.id
          AND bl.is_correct = TRUE;

        -- レイドHPを更新
        UPDATE raids
        SET
            current_hp         = GREATEST(0, current_hp - v_damage),
            total_damage_dealt = total_damage_dealt + v_damage,
            updated_at         = now()
        WHERE id = NEW.raid_id;

        -- ボスHPが0以下になったら討伐完了処理
        UPDATE raids
        SET
            status      = 'finished',
            result      = 'victory',
            finished_at = now()
        WHERE id = NEW.raid_id
          AND current_hp <= 0
          AND status = 'active';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- トリガー登録
CREATE TRIGGER on_battle_complete_update_raid
    AFTER UPDATE ON battles
    FOR EACH ROW
    WHEN (OLD.status = 'in_progress' AND NEW.status = 'completed')
    EXECUTE FUNCTION update_raid_hp();
```

---

### T-04：ストリーク日数自動更新

```sql
-- =====================================================
-- 関数名: update_streak_on_checkin
-- 役割: 夜チェックイン完了時にストリーク日数を更新する
-- =====================================================
CREATE OR REPLACE FUNCTION update_streak_on_checkin()
RETURNS TRIGGER AS $$
DECLARE
    v_last_checkin_date DATE;
    v_current_streak    INTEGER;
BEGIN
    -- 夜チェックイン（evening）のみ対象
    IF NEW.type != 'evening' THEN
        RETURN NEW;
    END IF;

    -- 直近の夜チェックイン日を取得（今日より前）
    SELECT checkin_date INTO v_last_checkin_date
    FROM checkins
    WHERE user_id = NEW.user_id
      AND type = 'evening'
      AND checkin_date < NEW.checkin_date
    ORDER BY checkin_date DESC
    LIMIT 1;

    -- ストリーク計算
    SELECT streak_days INTO v_current_streak
    FROM users WHERE id = NEW.user_id;

    IF v_last_checkin_date IS NULL THEN
        -- 初回チェックイン
        v_current_streak := 1;
    ELSIF v_last_checkin_date = NEW.checkin_date - INTERVAL '1 day' THEN
        -- 前日にチェックイン済み → ストリーク継続
        v_current_streak := v_current_streak + 1;
    ELSE
        -- 途切れた → リセット
        v_current_streak := 1;
    END IF;

    -- users テーブルを更新
    UPDATE users
    SET
        streak_days     = v_current_streak,
        max_streak_days = GREATEST(max_streak_days, v_current_streak),
        last_practice_at = now()
    WHERE id = NEW.user_id;

    -- チェックインレコードにストリーク値を記録
    NEW.streak_at_checkin := v_current_streak;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- トリガー登録
CREATE TRIGGER on_evening_checkin_update_streak
    BEFORE INSERT ON checkins
    FOR EACH ROW
    EXECUTE FUNCTION update_streak_on_checkin();
```

---

## 🔴 STEP 6：便利ビュー（クエリ効率化）

---

```sql
-- =====================================================
-- ビュー：student_class_summary
-- 役割: 先生ダッシュボード用の生徒進捗サマリー
-- =====================================================
CREATE OR REPLACE VIEW student_class_summary AS
SELECT
    cm.class_id,
    cm.user_id                              AS student_id,
    u.display_name,
    u.mowi_level,
    u.streak_days,
    u.last_practice_at,

    -- 習熟度集計
    COUNT(pp.id)                            AS total_patterns_started,
    AVG(pp.mastery_level)                   AS avg_mastery_level,
    SUM(CASE WHEN pp.mastery_level = 5 THEN 1 ELSE 0 END)
                                            AS patterns_mastered,
    AVG(pp.correct_rate)                    AS avg_correct_rate,

    -- 弱点上位3パターン（正解率の低い順）は別クエリで取得

    -- 直近のチェックイン
    (
        SELECT feeling
        FROM checkins
        WHERE user_id = cm.user_id
          AND type = 'morning'
        ORDER BY created_at DESC
        LIMIT 1
    )                                       AS latest_morning_mood,

    -- 連続不安チェックイン検出（先生アラート用）
    (
        SELECT COUNT(*)
        FROM checkins
        WHERE user_id = cm.user_id
          AND type = 'morning'
          AND feeling = 'morning_anxious'
          AND checkin_date >= CURRENT_DATE - INTERVAL '3 days'
    )                                       AS anxious_days_last_3,

    -- ジムバッジ取得数
    (
        SELECT COUNT(*)
        FROM gym_badges gb
        WHERE gb.student_id = cm.user_id
          AND gb.class_id = cm.class_id
          AND gb.status = 'approved'
    )                                       AS approved_badges

FROM class_members cm
JOIN users u ON cm.user_id = u.id
LEFT JOIN pattern_progress pp ON pp.user_id = cm.user_id
WHERE cm.status = 'approved'
GROUP BY
    cm.class_id,
    cm.user_id,
    u.display_name,
    u.mowi_level,
    u.streak_days,
    u.last_practice_at;
```

---

## 🔴 STEP 7：初期データ投入（patterns テーブル・MVP分）

```sql
-- =====================================================
-- 初期データ：patterns（P001〜P035のMVP範囲）
-- 要件: パターン図鑑100リスト v2.0
-- ※ ここではP001〜P005のサンプルのみ掲載。
--    P006〜P035はパターン図鑑100リスト v2.0に基づき別途投入すること。
-- =====================================================
INSERT INTO patterns
    (pattern_no, pattern_text, pattern_short, japanese, rarity, area, is_mvp, is_free, sort_order)
VALUES
    ('P001', '[代名詞] + be動詞 + [名前/形容詞/名詞]', 'I''m [形容詞].', '〜は…です', 1, 'area1', TRUE, TRUE, 1),
    ('P002', 'This is [名詞].', 'This is [名詞].', 'これは〜です', 1, 'area1', TRUE, TRUE, 2),
    ('P003', 'I like [名詞/動名詞].', 'I like [名詞].', '〜が好きです', 1, 'area1', TRUE, TRUE, 3),
    ('P004', 'I want [名詞].', 'I want [名詞].', '〜が欲しいです', 1, 'area1', TRUE, TRUE, 4),
    ('P005', 'I have [名詞].', 'I have [名詞].', '〜を持っています', 1, 'area1', TRUE, TRUE, 5)
    -- P006〜P035 は pattern_no, rarity, area, sort_order を更新して同形式で追加
    ;

-- 解禁条件の設定（パターン図鑑100リスト v2.0に基づく）
UPDATE patterns SET
    unlock_condition_pattern = 'P001',
    unlock_condition_stars = 2
WHERE pattern_no IN ('P002', 'P003');

UPDATE patterns SET
    unlock_condition_pattern = 'P002',
    unlock_condition_stars = 2
WHERE pattern_no = 'P004';
```

---

## 📐 テーブルリレーション図

```
auth.users (Supabase管理)
    │
    │── [T-01 自動初期化トリガー]
    │
    ├── users (1:1)
    │       │
    │       ├── mowi_state (1:1)
    │       │
    │       ├── checkins (1:N)
    │       │
    │       ├── pattern_progress (1:N) ──── patterns (N:1)
    │       │
    │       ├── flash_output_logs (1:N) ──── patterns (N:1)
    │       │
    │       ├── battles (1:N)
    │       │       │
    │       │       ├── battle_logs (1:N)
    │       │       ├── class_battles (N:1) [Phase 2]
    │       │       └── raids (N:1) [Phase 2]
    │       │
    │       ├── class_members (N:M) ──── classes (M:N)
    │       │                               │
    │       │                               ├── class_battles [Phase 2]
    │       │                               └── raids [Phase 2]
    │       │
    │       └── gym_badges (1:N) ──── classes (N:1)
    │
    └── patterns (独立マスター)
            │
            └── pattern_content (1:N)
```

---

## 🔑 SM-2アルゴリズム 実装ガイド

SM-2を使った `pattern_progress` の更新ロジック（フロントエンド or Edge Function で実装）：

```typescript
// composables/useSM2.ts（Vue 3 実装例）

interface SM2Update {
  ease_factor: number;    // 現在の ease_factor（初期: 2.50）
  interval_days: number;  // 現在の interval_days（初期: 1）
  times_seen: number;     // 現在の times_seen（初期: 0）
  quality: number;        // 回答品質（0〜5）
}

export function calculateSM2(current: SM2Update): SM2Update {
  const { ease_factor, interval_days, times_seen, quality } = current;

  let new_interval: number;
  let new_ease_factor: number;
  let new_times_seen: number = times_seen + 1;

  // quality 3未満（不正解・時間切れ）→ リセット
  if (quality < 3) {
    new_interval = 1;
    new_ease_factor = Math.max(1.30, ease_factor - 0.20);
    new_times_seen = 0;  // 連続正解カウントをリセット
  } else {
    // 正解時の interval 計算
    if (times_seen === 0) {
      new_interval = 1;
    } else if (times_seen === 1) {
      new_interval = 6;
    } else {
      new_interval = Math.round(interval_days * ease_factor);
    }

    // ease_factor の更新（SM-2 公式）
    // EF' = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
    new_ease_factor = ease_factor + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    new_ease_factor = Math.min(5.00, Math.max(1.30, new_ease_factor));
  }

  return {
    ease_factor: parseFloat(new_ease_factor.toFixed(2)),
    interval_days: new_interval,
    times_seen: new_times_seen,
    quality
  };
}

// quality_rating の決定ロジック
export function calcQualityRating(
  is_correct: boolean,
  response_time_ms: number,
  time_limit_ms: number,
  hint_used: boolean,
  consecutive_wrong: number
): number {
  if (!is_correct) {
    if (response_time_ms >= time_limit_ms) return 2;  // タイムアウト
    if (consecutive_wrong >= 3) return 0;             // 連続3回以上不正解
    return 1;                                          // 通常不正解
  }
  if (hint_used) return 3;                            // ヒント使用で正解
  if (response_time_ms <= time_limit_ms * 0.5) return 5;  // 制限時間の50%以内
  return 4;                                           // 通常正解
}
```

---

## ✅ 実行チェックリスト

エンジニアはこの順番でSQLを実行してください：

```
□ STEP 0: 拡張機能の有効化（uuid-ossp, pgcrypto）
□ STEP 1: users テーブル作成
□ STEP 1: mowi_state テーブル作成
□ STEP 1: checkins テーブル作成
□ STEP 2: patterns テーブル作成
□ STEP 2: pattern_content テーブル作成
□ STEP 2: pattern_progress テーブル作成
□ STEP 2: flash_output_logs テーブル作成
□ STEP 3: classes テーブル作成
□ STEP 3: class_members テーブル作成
□ STEP 3: gym_badges テーブル作成
□ STEP 4: battles テーブル作成
□ STEP 4: battle_logs テーブル作成
□ STEP 4: class_battles テーブル作成（Phase 2まで任意）
□ STEP 4: raids テーブル作成（Phase 2まで任意）
□ STEP 5: handle_new_user 関数 & トリガー作成
□ STEP 5: update_updated_at_column 関数 & 各トリガー作成
□ STEP 5: update_raid_hp 関数 & トリガー作成（Phase 2まで任意）
□ STEP 5: update_streak_on_checkin 関数 & トリガー作成
□ STEP 6: student_class_summary ビュー作成
□ STEP 7: patterns 初期データ投入（P001〜P035）
□ 動作確認: テストユーザーを auth.users に作成 → users/mowi_state の自動生成を確認
```

---

## ⚠️ 注意事項

| 項目 | 内容 |
|------|------|
| **外部キー順序** | `class_battles` と `raids` が `battles` テーブルから参照されるため、先にSTEP 4で両テーブルを作成すること |
| **RLSポリシー** | Supabaseは RLS ON にしただけではポリシーがないとアクセス不可になる。必ずポリシーもセットで実行すること |
| **トリガーの実行権限** | `SECURITY DEFINER` を使用しているため、関数はテーブル所有者として実行される |
| **SM-2更新** | SM-2フィールドの更新はフロントエンドで計算し Supabase に UPDATE する設計。Edge Functionへの移行も可 |
| **パターン初期データ** | P001〜P035 の全データは `pattern_content` テーブルへの投入が別途必要（コンテンツ設計書P001〜P035参照） |
| **Phase 2テーブル** | `class_battles` と `raids` はMVPでも作成しておくことを推奨（`battles` の FK が参照するため） |

---

*MoWISE Supabase スキーマ定義書 v1.0*
*策定日：2026年3月10日*
*対応要件定義：v3.1*
*次回更新：MVP Phase 1 実装着手時（開発者フィードバック反映）*
