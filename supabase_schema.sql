-- ============================================================
-- MoWISE｜Supabase スキーマ 完全版
-- スキーマ定義書 v1.0 準拠（2026-03-10）
-- Supabase SQL Editor に上から順に貼り付けて実行してください
-- ============================================================

-- ========== STEP 0: 拡張機能 ==========
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ========== STEP 1: ユーザー・Mowi関連 ==========

CREATE TABLE users (
    id                   UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email                TEXT NOT NULL,
    display_name         TEXT NOT NULL DEFAULT '',
    avatar_url           TEXT,
    role                 TEXT NOT NULL DEFAULT 'student'
                         CHECK (role IN ('student', 'teacher', 'admin')),
    plan                 TEXT NOT NULL DEFAULT 'free'
                         CHECK (plan IN ('free', 'premium', 'teacher_plan', 'school')),
    mowi_level           INTEGER NOT NULL DEFAULT 1 CHECK (mowi_level BETWEEN 1 AND 30),
    total_xp             INTEGER NOT NULL DEFAULT 0 CHECK (total_xp >= 0),
    streak_days          INTEGER NOT NULL DEFAULT 0 CHECK (streak_days >= 0),
    max_streak_days      INTEGER NOT NULL DEFAULT 0 CHECK (max_streak_days >= 0),
    last_login_at        TIMESTAMPTZ,
    last_practice_at     TIMESTAMPTZ,
    notification_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    language_ui          TEXT NOT NULL DEFAULT 'ja' CHECK (language_ui IN ('ja', 'en', 'ko')),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX users_role_idx    ON users(role);
CREATE INDEX users_plan_idx    ON users(plan);
CREATE INDEX users_mowi_lv_idx ON users(mowi_level DESC);
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_select_own" ON users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "users_update_own" ON users FOR UPDATE USING (auth.uid() = id);
-- NOTE: teachers_select_class_members は class_members 作成後に追加

-- mowi_state
CREATE TABLE mowi_state (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    happiness                   INTEGER NOT NULL DEFAULT 50 CHECK (happiness BETWEEN 0 AND 100),
    growth_stage                INTEGER NOT NULL DEFAULT 0  CHECK (growth_stage BETWEEN 0 AND 4),
    current_emotion             TEXT NOT NULL DEFAULT 'idle'
                                CHECK (current_emotion IN ('idle','joy','cheer','sad','think','grow','sleep','streak','first_pattern')),
    current_combo               INTEGER NOT NULL DEFAULT 0 CHECK (current_combo >= 0),
    max_combo_today             INTEGER NOT NULL DEFAULT 0 CHECK (max_combo_today >= 0),
    weekly_snapshot_happiness   INTEGER CHECK (weekly_snapshot_happiness BETWEEN 0 AND 100),
    weekly_snapshot_at          TIMESTAMPTZ,
    last_interaction_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id)
);
CREATE INDEX mowi_state_user_idx ON mowi_state(user_id);
ALTER TABLE mowi_state ENABLE ROW LEVEL SECURITY;
CREATE POLICY "mowi_state_own" ON mowi_state FOR ALL USING (auth.uid() = user_id);
-- NOTE: teachers_view_mowi_state は class_members 作成後に追加

-- checkins
CREATE TABLE checkins (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type             TEXT NOT NULL CHECK (type IN ('morning', 'evening')),
    feeling          TEXT CHECK (feeling IN ('morning_confident','morning_okay','morning_anxious','morning_unsure')),
    result           TEXT CHECK (result IN ('evening_said_it','evening_fun','evening_hard','evening_not_quite')),
    mowi_quote       TEXT,
    session_ref_id   UUID,
    streak_at_checkin INTEGER,
    checkin_date     DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX checkins_user_date_idx ON checkins(user_id, checkin_date DESC);
CREATE INDEX checkins_user_type_idx ON checkins(user_id, type, checkin_date DESC);
CREATE INDEX checkins_feeling_idx   ON checkins(feeling, checkin_date DESC);
ALTER TABLE checkins ENABLE ROW LEVEL SECURITY;
CREATE POLICY "checkins_own" ON checkins FOR ALL USING (auth.uid() = user_id);
-- NOTE: teachers_view_checkins は class_members 作成後に追加


-- ========== STEP 2: パターン図鑑・コンテンツ ==========

CREATE TABLE patterns (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_no               TEXT NOT NULL UNIQUE CHECK (pattern_no ~ '^P[0-9]{3}$'),
    pattern_text             TEXT NOT NULL,
    pattern_short            TEXT NOT NULL,
    japanese                 TEXT NOT NULL,
    rarity                   INTEGER NOT NULL DEFAULT 1 CHECK (rarity BETWEEN 1 AND 5),
    area                     TEXT NOT NULL DEFAULT 'area1'
                             CHECK (area IN ('area1','area2','area3','area4','area5')),
    evolution_of             TEXT REFERENCES patterns(pattern_no),
    evolution_forms          TEXT[] DEFAULT '{}',
    evolution_label          TEXT[],
    unlock_condition_pattern TEXT REFERENCES patterns(pattern_no),
    unlock_condition_stars   INTEGER CHECK (unlock_condition_stars BETWEEN 1 AND 5),
    scene_tags               TEXT[] DEFAULT '{}',
    audio_voice_male         TEXT NOT NULL DEFAULT 'en-US-Neural2-D',
    audio_voice_female       TEXT NOT NULL DEFAULT 'en-US-Neural2-F',
    is_mvp                   BOOLEAN NOT NULL DEFAULT FALSE,
    is_free                  BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order               INTEGER NOT NULL DEFAULT 0,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX patterns_area_idx   ON patterns(area, sort_order);
CREATE INDEX patterns_rarity_idx ON patterns(rarity);
CREATE INDEX patterns_mvp_idx    ON patterns(is_mvp) WHERE is_mvp = TRUE;
CREATE INDEX patterns_free_idx   ON patterns(is_free) WHERE is_free = TRUE;
ALTER TABLE patterns ENABLE ROW LEVEL SECURITY;
CREATE POLICY "patterns_select_all" ON patterns FOR SELECT USING (TRUE);
CREATE POLICY "patterns_admin_all"  ON patterns FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));

-- pattern_content
CREATE TABLE pattern_content (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pattern_no       TEXT NOT NULL REFERENCES patterns(pattern_no) ON DELETE CASCADE,
    layer            INTEGER NOT NULL CHECK (layer BETWEEN 0 AND 4),
    question_order   INTEGER NOT NULL DEFAULT 1,
    question_type    TEXT NOT NULL CHECK (question_type IN (
                         'sound_compare','sound_match','slot_fill','audio_predict','tile_select','keyboard_input','scene_challenge'
                     )),
    prompt_ja        TEXT,
    prompt_en        TEXT,
    display_text     TEXT,
    context_text     TEXT,
    audio_url_a      TEXT,
    audio_url_b      TEXT,
    audio_url_main   TEXT,
    choices          JSONB,
    correct_answer   TEXT,
    alternate_answers TEXT[],
    explanation_ja   TEXT,
    mowi_quote_correct TEXT,
    mowi_quote_wrong   TEXT,
    time_limit_sec   INTEGER DEFAULT 8,
    pass_threshold   INTEGER,
    tts_text_a       TEXT,
    tts_text_b       TEXT,
    tts_speed_a      NUMERIC(3,2) DEFAULT 0.75,
    tts_speed_b      NUMERIC(3,2) DEFAULT 1.00,
    tts_voice        TEXT DEFAULT 'en-US-Neural2-D',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (pattern_no, layer, question_order)
);
CREATE INDEX pattern_content_pattern_layer_idx ON pattern_content(pattern_no, layer, question_order);
CREATE INDEX pattern_content_type_idx          ON pattern_content(question_type);
ALTER TABLE pattern_content ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pattern_content_select_all" ON pattern_content FOR SELECT USING (TRUE);
CREATE POLICY "pattern_content_admin_all"  ON pattern_content FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));

-- pattern_progress
CREATE TABLE pattern_progress (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pattern_no               TEXT NOT NULL REFERENCES patterns(pattern_no) ON DELETE CASCADE,
    mastery_level            INTEGER NOT NULL DEFAULT 0 CHECK (mastery_level BETWEEN 0 AND 5),
    layer0_done              BOOLEAN NOT NULL DEFAULT FALSE,
    layer1_done              BOOLEAN NOT NULL DEFAULT FALSE,
    layer2_done              BOOLEAN NOT NULL DEFAULT FALSE,
    layer3_done              BOOLEAN NOT NULL DEFAULT FALSE,
    layer4_done              BOOLEAN NOT NULL DEFAULT FALSE,
    correct_count            INTEGER NOT NULL DEFAULT 0 CHECK (correct_count >= 0),
    total_attempts           INTEGER NOT NULL DEFAULT 0 CHECK (total_attempts >= 0),
    correct_rate             NUMERIC(5,3) NOT NULL DEFAULT 0 CHECK (correct_rate BETWEEN 0 AND 1),
    avg_response_ms          INTEGER CHECK (avg_response_ms > 0),
    timeout_rate             NUMERIC(5,3) NOT NULL DEFAULT 0 CHECK (timeout_rate BETWEEN 0 AND 1),
    flash_output_difficulty  INTEGER NOT NULL DEFAULT 1 CHECK (flash_output_difficulty BETWEEN 1 AND 3),
    next_review_date         DATE,
    interval_days            INTEGER NOT NULL DEFAULT 1 CHECK (interval_days >= 1),
    ease_factor              NUMERIC(4,2) NOT NULL DEFAULT 2.50 CHECK (ease_factor BETWEEN 1.30 AND 5.00),
    times_seen               INTEGER NOT NULL DEFAULT 0 CHECK (times_seen >= 0),
    last_quality_rating      INTEGER CHECK (last_quality_rating BETWEEN 0 AND 5),
    is_daily_reinforced      BOOLEAN NOT NULL DEFAULT FALSE,
    consecutive_wrong        INTEGER NOT NULL DEFAULT 0 CHECK (consecutive_wrong >= 0),
    last_practiced_at        TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, pattern_no)
);
CREATE INDEX pp_user_mastery_idx    ON pattern_progress(user_id, mastery_level DESC);
CREATE INDEX pp_user_review_idx     ON pattern_progress(user_id, next_review_date ASC) WHERE next_review_date IS NOT NULL;
CREATE INDEX pp_user_correct_idx    ON pattern_progress(user_id, correct_rate ASC);
CREATE INDEX pp_pattern_idx         ON pattern_progress(pattern_no);
CREATE INDEX pp_daily_reinforce_idx ON pattern_progress(user_id, is_daily_reinforced) WHERE is_daily_reinforced = TRUE;
ALTER TABLE pattern_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "pp_own" ON pattern_progress FOR ALL USING (auth.uid() = user_id);
-- NOTE: teachers_view_pp は class_members 作成後に追加


-- ========== STEP 3: クラス関連 ==========

CREATE TABLE classes (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    teacher_id                  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_name                  TEXT NOT NULL,
    class_code                  TEXT NOT NULL UNIQUE,
    description                 TEXT,
    assigned_pattern_ids        TEXT[] NOT NULL DEFAULT '{}',
    current_pattern_range_start TEXT REFERENCES patterns(pattern_no),
    current_pattern_range_end   TEXT REFERENCES patterns(pattern_no),
    unlocked_areas              TEXT[] NOT NULL DEFAULT ARRAY['area1'],
    status                      TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active','archived')),
    max_students                INTEGER NOT NULL DEFAULT 30,
    created_at                  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX classes_code_idx ON classes(class_code);
CREATE INDEX classes_teacher_idx     ON classes(teacher_id);
CREATE INDEX classes_status_idx      ON classes(status);
ALTER TABLE classes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "teachers_manage_classes" ON classes FOR ALL USING (auth.uid() = teacher_id);
-- NOTE: students_view_own_class は class_members 作成後に追加

CREATE TABLE class_members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id        UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','removed')),
    approved_by     UUID REFERENCES users(id),
    approved_at     TIMESTAMPTZ,
    joined_via_code TEXT,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (class_id, user_id)
);
CREATE INDEX cm_class_idx ON class_members(class_id, status);
CREATE INDEX cm_user_idx  ON class_members(user_id, status);
ALTER TABLE class_members ENABLE ROW LEVEL SECURITY;
CREATE POLICY "members_view_own"        ON class_members FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "teachers_manage_members" ON class_members FOR ALL
    USING (EXISTS (SELECT 1 FROM classes WHERE id = class_members.class_id AND teacher_id = auth.uid()));
CREATE POLICY "students_join_class"     ON class_members FOR INSERT WITH CHECK (auth.uid() = user_id);

-- ここから class_members を参照するポリシーをまとめて追加
CREATE POLICY "teachers_select_class_members" ON users FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = users.id AND c.teacher_id = auth.uid()
    ));
CREATE POLICY "teachers_view_mowi_state" ON mowi_state FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = mowi_state.user_id AND c.teacher_id = auth.uid()
    ));
CREATE POLICY "teachers_view_checkins" ON checkins FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = checkins.user_id AND c.teacher_id = auth.uid()
    ));
CREATE POLICY "teachers_view_pp" ON pattern_progress FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = pattern_progress.user_id AND c.teacher_id = auth.uid()
    ));
CREATE POLICY "students_view_own_class" ON classes FOR SELECT
    USING (EXISTS (SELECT 1 FROM class_members WHERE class_id = classes.id AND user_id = auth.uid()));

CREATE TABLE chart_badges (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id           UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    class_id             UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    area                 TEXT NOT NULL CHECK (area IN ('area1','area2','area3','area4','area5')),
    badge_name           TEXT NOT NULL,
    status               TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','approved','rejected')),
    mastery_avg_at_apply NUMERIC(4,2),
    approved_by          UUID REFERENCES users(id),
    approved_at          TIMESTAMPTZ,
    rejection_reason     TEXT,
    applied_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (student_id, class_id, area)
);
CREATE INDEX chart_badges_student_idx ON chart_badges(student_id, status);
CREATE INDEX chart_badges_class_idx   ON chart_badges(class_id, status);
CREATE INDEX chart_badges_teacher_idx ON chart_badges(approved_by);
ALTER TABLE chart_badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "students_manage_own_badges"   ON chart_badges FOR ALL USING (auth.uid() = student_id);
CREATE POLICY "teachers_manage_class_badges" ON chart_badges FOR ALL
    USING (EXISTS (SELECT 1 FROM classes WHERE id = chart_badges.class_id AND teacher_id = auth.uid()));


-- ========== STEP 4: バトルシステム ==========

CREATE TABLE class_battles (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id        UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id      UUID NOT NULL REFERENCES users(id),
    title           TEXT NOT NULL,
    pattern_ids     TEXT[] NOT NULL DEFAULT '{}',
    question_count  INTEGER NOT NULL DEFAULT 15,
    time_limit_sec  INTEGER NOT NULL DEFAULT 8,
    start_date      DATE NOT NULL,
    end_date        DATE NOT NULL,
    status          TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','active','finished')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX cb_class_status_idx ON class_battles(class_id, status, end_date DESC);
ALTER TABLE class_battles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "teachers_manage_cb" ON class_battles FOR ALL USING (auth.uid() = teacher_id);
CREATE POLICY "students_view_cb"   ON class_battles FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members
        WHERE class_id = class_battles.class_id AND user_id = auth.uid() AND status = 'approved'
    ));

CREATE TABLE raids (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id             UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id           UUID NOT NULL REFERENCES users(id),
    title                TEXT NOT NULL,
    boss_name            TEXT NOT NULL,
    pattern_ids          TEXT[] NOT NULL DEFAULT '{}',
    boss_hp              INTEGER NOT NULL CHECK (boss_hp > 0),
    current_hp           INTEGER NOT NULL,
    total_damage_dealt   INTEGER NOT NULL DEFAULT 0,
    normal_damage        INTEGER NOT NULL DEFAULT 1,
    combo_damage         INTEGER NOT NULL DEFAULT 2,
    daily_question_limit INTEGER NOT NULL DEFAULT 10,
    start_date           DATE NOT NULL,
    end_date             DATE NOT NULL,
    status               TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled','active','finished')),
    result               TEXT CHECK (result IN ('victory','defeat')),
    finished_at          TIMESTAMPTZ,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX raids_class_status_idx ON raids(class_id, status, end_date DESC);
ALTER TABLE raids ENABLE ROW LEVEL SECURITY;
CREATE POLICY "teachers_manage_raids" ON raids FOR ALL USING (auth.uid() = teacher_id);
CREATE POLICY "students_view_raids"   ON raids FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members
        WHERE class_id = raids.class_id AND user_id = auth.uid() AND status = 'approved'
    ));

CREATE TABLE battles (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    battle_type      TEXT NOT NULL CHECK (battle_type IN ('daily','class','raid')),
    battle_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    class_battle_id  UUID REFERENCES class_battles(id) ON DELETE SET NULL,
    raid_id          UUID REFERENCES raids(id) ON DELETE SET NULL,
    ai_level         INTEGER CHECK (ai_level BETWEEN 0 AND 4),
    question_count   INTEGER NOT NULL DEFAULT 7,
    time_limit_sec   INTEGER NOT NULL DEFAULT 8,
    morning_mood     TEXT CHECK (morning_mood IN ('morning_confident','morning_okay','morning_anxious','morning_unsure')),
    combo_multiplier NUMERIC(4,2) NOT NULL DEFAULT 1.00,
    time_multiplier  NUMERIC(4,2) NOT NULL DEFAULT 1.00,
    hint_bonus       INTEGER NOT NULL DEFAULT 0,
    score            INTEGER NOT NULL DEFAULT 0 CHECK (score >= 0),
    accuracy_rate    NUMERIC(5,3) NOT NULL DEFAULT 0 CHECK (accuracy_rate BETWEEN 0 AND 1),
    avg_response_ms  INTEGER,
    max_combo        INTEGER NOT NULL DEFAULT 0 CHECK (max_combo >= 0),
    correct_count    INTEGER NOT NULL DEFAULT 0,
    total_questions  INTEGER NOT NULL DEFAULT 0,
    ai_target_score  INTEGER,
    battle_won       BOOLEAN,
    status           TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress','completed','abandoned')),
    started_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at         TIMESTAMPTZ,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX battles_user_type_date_idx ON battles(user_id, battle_type, battle_date DESC);
CREATE INDEX battles_class_battle_idx   ON battles(class_battle_id) WHERE class_battle_id IS NOT NULL;
CREATE INDEX battles_raid_idx           ON battles(raid_id) WHERE raid_id IS NOT NULL;
CREATE INDEX battles_status_idx         ON battles(user_id, status);
ALTER TABLE battles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "battles_own" ON battles FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "teachers_view_class_battles" ON battles FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = battles.user_id AND c.teacher_id = auth.uid()
    ));

CREATE TABLE battle_logs (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    battle_id        UUID NOT NULL REFERENCES battles(id) ON DELETE CASCADE,
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pattern_no       TEXT NOT NULL,
    layer            INTEGER NOT NULL DEFAULT 3 CHECK (layer BETWEEN 0 AND 4),
    question_order   INTEGER NOT NULL,
    is_correct       BOOLEAN NOT NULL,
    response_time_ms INTEGER NOT NULL DEFAULT 0,
    was_timeout      BOOLEAN NOT NULL DEFAULT FALSE,
    hint_used        BOOLEAN NOT NULL DEFAULT FALSE,
    base_score       INTEGER NOT NULL DEFAULT 0,
    speed_bonus      NUMERIC(4,2) NOT NULL DEFAULT 1.00,
    combo_at_time    INTEGER NOT NULL DEFAULT 0,
    combo_multiplier NUMERIC(4,2) NOT NULL DEFAULT 1.00,
    question_score   INTEGER NOT NULL DEFAULT 0,
    answered_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX bl_battle_order_idx ON battle_logs(battle_id, question_order);
CREATE INDEX bl_user_pattern_idx ON battle_logs(user_id, pattern_no, answered_at DESC);
ALTER TABLE battle_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "bl_own" ON battle_logs FOR ALL USING (auth.uid() = user_id);

CREATE TABLE flash_output_logs (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pattern_no       TEXT NOT NULL REFERENCES patterns(pattern_no) ON DELETE CASCADE,
    session_id       UUID NOT NULL,
    layer            INTEGER NOT NULL DEFAULT 3 CHECK (layer = 3),
    question_type    TEXT NOT NULL CHECK (question_type IN ('tile_select','keyboard_input')),
    question_order   INTEGER NOT NULL,
    prompt_ja        TEXT,
    correct_answer   TEXT,
    user_answer      TEXT,
    is_correct       BOOLEAN NOT NULL,
    was_timeout      BOOLEAN NOT NULL DEFAULT FALSE,
    hint_used        BOOLEAN NOT NULL DEFAULT FALSE,
    response_time_ms INTEGER NOT NULL DEFAULT 0,
    time_limit_ms    INTEGER NOT NULL DEFAULT 8000,
    combo_at_time    INTEGER NOT NULL DEFAULT 0,
    quality_rating   INTEGER NOT NULL DEFAULT 0 CHECK (quality_rating BETWEEN 0 AND 5),
    game_mode        TEXT DEFAULT 'standard' CHECK (game_mode IN ('standard','sprint','review','battle')),
    battle_id        UUID REFERENCES battles(id) ON DELETE SET NULL,
    answered_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX fol_user_pattern_idx ON flash_output_logs(user_id, pattern_no, answered_at DESC);
CREATE INDEX fol_session_idx      ON flash_output_logs(session_id, question_order);
CREATE INDEX fol_user_correct_idx ON flash_output_logs(user_id, is_correct, answered_at DESC);
CREATE INDEX fol_timeout_idx      ON flash_output_logs(user_id, was_timeout) WHERE was_timeout = TRUE;
ALTER TABLE flash_output_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "fol_own"           ON flash_output_logs FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "teachers_view_fol" ON flash_output_logs FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = flash_output_logs.user_id AND c.teacher_id = auth.uid()
    ));


-- ========== STEP 5: トリガー ==========

-- T-01: auth.users 作成時に users / mowi_state を自動初期化
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO users (id, email, display_name, role, plan, mowi_level, total_xp, streak_days, max_streak_days)
    VALUES (
        NEW.id, NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'display_name', split_part(NEW.email, '@', 1)),
        'student', 'free', 1, 0, 0, 0
    ) ON CONFLICT (id) DO NOTHING;

    INSERT INTO mowi_state (user_id, happiness, growth_stage, current_emotion, current_combo, last_interaction_at)
    VALUES (NEW.id, 50, 0, 'idle', 0, now())
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- T-02: updated_at 自動更新
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at            BEFORE UPDATE ON users          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_mowi_state_updated_at       BEFORE UPDATE ON mowi_state     FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_pattern_progress_updated_at BEFORE UPDATE ON pattern_progress FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_classes_updated_at          BEFORE UPDATE ON classes        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_class_members_updated_at    BEFORE UPDATE ON class_members  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_chart_badges_updated_at     BEFORE UPDATE ON chart_badges   FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_class_battles_updated_at    BEFORE UPDATE ON class_battles  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_raids_updated_at            BEFORE UPDATE ON raids          FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- T-03: レイドHP自動更新
CREATE OR REPLACE FUNCTION update_raid_hp()
RETURNS TRIGGER AS $$
DECLARE v_damage INTEGER;
BEGIN
    IF NEW.battle_type = 'raid' AND NEW.status = 'completed' AND NEW.raid_id IS NOT NULL AND OLD.status = 'in_progress' THEN
        SELECT COALESCE(SUM(CASE WHEN bl.combo_at_time >= 5 THEN 2 ELSE 1 END), 0)
        INTO v_damage FROM battle_logs bl WHERE bl.battle_id = NEW.id AND bl.is_correct = TRUE;

        UPDATE raids SET current_hp = GREATEST(0, current_hp - v_damage), total_damage_dealt = total_damage_dealt + v_damage, updated_at = now() WHERE id = NEW.raid_id;
        UPDATE raids SET status = 'finished', result = 'victory', finished_at = now() WHERE id = NEW.raid_id AND current_hp <= 0 AND status = 'active';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_battle_complete_update_raid
    AFTER UPDATE ON battles FOR EACH ROW
    WHEN (OLD.status = 'in_progress' AND NEW.status = 'completed')
    EXECUTE FUNCTION update_raid_hp();

-- T-04: ストリーク日数自動更新
CREATE OR REPLACE FUNCTION update_streak_on_checkin()
RETURNS TRIGGER AS $$
DECLARE
    v_last_checkin_date DATE;
    v_current_streak    INTEGER;
BEGIN
    IF NEW.type != 'evening' THEN RETURN NEW; END IF;

    SELECT checkin_date INTO v_last_checkin_date
    FROM checkins WHERE user_id = NEW.user_id AND type = 'evening' AND checkin_date < NEW.checkin_date
    ORDER BY checkin_date DESC LIMIT 1;

    SELECT streak_days INTO v_current_streak FROM users WHERE id = NEW.user_id;

    IF v_last_checkin_date IS NULL THEN
        v_current_streak := 1;
    ELSIF v_last_checkin_date = NEW.checkin_date - INTERVAL '1 day' THEN
        v_current_streak := v_current_streak + 1;
    ELSE
        v_current_streak := 1;
    END IF;

    UPDATE users SET streak_days = v_current_streak, max_streak_days = GREATEST(max_streak_days, v_current_streak), last_practice_at = now() WHERE id = NEW.user_id;
    NEW.streak_at_checkin := v_current_streak;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_evening_checkin_update_streak
    BEFORE INSERT ON checkins FOR EACH ROW
    EXECUTE FUNCTION update_streak_on_checkin();


-- ========== STEP 6: ビュー ==========

CREATE OR REPLACE VIEW student_class_summary AS
SELECT
    cm.class_id,
    cm.user_id                                                          AS student_id,
    u.display_name, u.mowi_level, u.streak_days, u.last_practice_at,
    COUNT(pp.id)                                                        AS total_patterns_started,
    AVG(pp.mastery_level)                                               AS avg_mastery_level,
    SUM(CASE WHEN pp.mastery_level = 5 THEN 1 ELSE 0 END)              AS patterns_mastered,
    AVG(pp.correct_rate)                                                AS avg_correct_rate,
    (SELECT feeling FROM checkins WHERE user_id = cm.user_id AND type = 'morning' ORDER BY created_at DESC LIMIT 1) AS latest_morning_mood,
    (SELECT COUNT(*) FROM checkins WHERE user_id = cm.user_id AND type = 'morning' AND feeling = 'morning_anxious' AND checkin_date >= CURRENT_DATE - INTERVAL '3 days') AS anxious_days_last_3,
    (SELECT COUNT(*) FROM chart_badges gb WHERE gb.student_id = cm.user_id AND gb.class_id = cm.class_id AND gb.status = 'approved') AS approved_badges
FROM class_members cm
JOIN users u ON cm.user_id = u.id
LEFT JOIN pattern_progress pp ON pp.user_id = cm.user_id
WHERE cm.status = 'approved'
GROUP BY cm.class_id, cm.user_id, u.display_name, u.mowi_level, u.streak_days, u.last_practice_at;


-- ========== STEP 7: 初期データ（patterns P001〜P005） ==========

INSERT INTO patterns (pattern_no, pattern_text, pattern_short, japanese, rarity, area, is_mvp, is_free, sort_order) VALUES
    ('P001', '[代名詞] + be動詞 + [名前/形容詞/名詞]', 'I''m [形容詞].', '〜は…です',       1, 'area1', TRUE, TRUE, 1),
    ('P002', 'This is [名詞].',                       'This is [名詞].', 'これは〜です',     1, 'area1', TRUE, TRUE, 2),
    ('P003', 'I like [名詞/動名詞].',                  'I like [名詞].',   '〜が好きです',     1, 'area1', TRUE, TRUE, 3),
    ('P004', 'I want [名詞].',                        'I want [名詞].',   '〜が欲しいです',   1, 'area1', TRUE, TRUE, 4),
    ('P005', 'I have [名詞].',                        'I have [名詞].',   '〜を持っています', 1, 'area1', TRUE, TRUE, 5);

UPDATE patterns SET unlock_condition_pattern = 'P001', unlock_condition_stars = 2 WHERE pattern_no IN ('P002', 'P003');
UPDATE patterns SET unlock_condition_pattern = 'P002', unlock_condition_stars = 2 WHERE pattern_no = 'P004';

-- ============================================================
-- 完了！
-- ============================================================
