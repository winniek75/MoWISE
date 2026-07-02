-- ============================================================
-- Phase 3: Daily Missions + Streak Rewards (replaces checkin)
-- 2026-07-02
-- ============================================================

-- 1. Daily mission definitions
CREATE TABLE IF NOT EXISTS mission_definitions (
    id          TEXT PRIMARY KEY,
    title_ja    TEXT NOT NULL,
    description_ja TEXT NOT NULL,
    condition_type TEXT NOT NULL
                CHECK (condition_type IN ('play_game','complete_game','accuracy_above','play_category','play_minutes','feed_monster','pull_gacha')),
    condition_value INTEGER NOT NULL DEFAULT 1,  -- e.g. play 1 game, accuracy > 80
    condition_extra TEXT,                         -- e.g. category name
    reward_type TEXT NOT NULL DEFAULT 'coins'
                CHECK (reward_type IN ('coins','tickets','food')),
    reward_amount INTEGER NOT NULL DEFAULT 10,
    difficulty  INTEGER NOT NULL DEFAULT 1        -- 1=easy, 2=medium, 3=hard
                CHECK (difficulty BETWEEN 1 AND 3),
    is_active   BOOLEAN NOT NULL DEFAULT TRUE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE mission_definitions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "missions_public_read" ON mission_definitions FOR SELECT USING (TRUE);

-- 2. Daily mission assignments (generated per user per day)
CREATE TABLE IF NOT EXISTS user_daily_missions (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mission_id  TEXT NOT NULL REFERENCES mission_definitions(id),
    mission_date DATE NOT NULL DEFAULT CURRENT_DATE,
    progress    INTEGER NOT NULL DEFAULT 0,
    target      INTEGER NOT NULL DEFAULT 1,
    completed   BOOLEAN NOT NULL DEFAULT FALSE,
    reward_claimed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at TIMESTAMPTZ,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, mission_id, mission_date)
);
CREATE INDEX udm_user_date_idx ON user_daily_missions(user_id, mission_date);
ALTER TABLE user_daily_missions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_missions_select" ON user_daily_missions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "own_missions_update" ON user_daily_missions FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "own_missions_insert" ON user_daily_missions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Teachers can view student missions
CREATE POLICY "teachers_view_student_missions" ON user_daily_missions FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = user_daily_missions.user_id AND c.teacher_id = auth.uid()
    ));

-- 3. Login streak table (replaces checkin-based streaks)
CREATE TABLE IF NOT EXISTS login_streaks (
    user_id     UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    current_streak INTEGER NOT NULL DEFAULT 0,
    max_streak    INTEGER NOT NULL DEFAULT 0,
    last_login_date DATE,
    streak_reward_claimed_at DATE,  -- last date streak reward was claimed
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE login_streaks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_streak_select" ON login_streaks FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "own_streak_update" ON login_streaks FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "own_streak_insert" ON login_streaks FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. Seed mission definitions (9 missions, 3 per difficulty)
INSERT INTO mission_definitions (id, title_ja, description_ja, condition_type, condition_value, condition_extra, reward_type, reward_amount, difficulty) VALUES
-- Easy (daily staples)
('daily-play-1',     '今日のウォームアップ',   'ゲームを1回プレイしよう',           'play_game',      1, NULL,      'coins',   10, 1),
('daily-complete-1', 'ゲームクリア！',         'ゲームを1回クリアしよう',           'complete_game',  1, NULL,      'coins',   15, 1),
('daily-feed-1',     'モンスターのお世話',     'モンスターにエサを1回あげよう',      'feed_monster',   1, NULL,      'coins',   10, 1),

-- Medium
('daily-complete-3', 'ゲームマスター',         'ゲームを3回クリアしよう',           'complete_game',  3, NULL,      'tickets', 1,  2),
('daily-accuracy',   'シャープシューター',     '正答率80%以上でクリアしよう',        'accuracy_above', 80, NULL,     'coins',   25, 2),
('daily-category',   'カテゴリチャレンジ',     '2つの異なるカテゴリのゲームをプレイ', 'play_category',  2, NULL,      'coins',   20, 2),

-- Hard
('daily-perfect',    'パーフェクト！',         '正答率100%を達成しよう',            'accuracy_above', 100, NULL,    'tickets', 2,  3),
('daily-complete-5', 'ゲームの鬼',             'ゲームを5回クリアしよう',           'complete_game',  5, NULL,      'tickets', 2,  3),
('daily-gacha',      'ガチャコレクター',       'ガチャを1回回そう',                'pull_gacha',     1, NULL,      'coins',   30, 3)
ON CONFLICT (id) DO NOTHING;

-- 5. Generate daily missions for a user (picks 3: 1 easy, 1 medium, 1 hard)
CREATE OR REPLACE FUNCTION generate_daily_missions(p_user_id UUID)
RETURNS SETOF user_daily_missions
SECURITY DEFINER
LANGUAGE plpgsql AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
    v_mission mission_definitions%ROWTYPE;
    v_existing INTEGER;
BEGIN
    -- Check if already generated today
    SELECT COUNT(*) INTO v_existing FROM user_daily_missions
    WHERE user_id = p_user_id AND mission_date = v_today;
    IF v_existing > 0 THEN
        RETURN QUERY SELECT * FROM user_daily_missions
        WHERE user_id = p_user_id AND mission_date = v_today
        ORDER BY (SELECT difficulty FROM mission_definitions WHERE id = mission_id);
        RETURN;
    END IF;

    -- Pick 1 easy
    SELECT * INTO v_mission FROM mission_definitions WHERE difficulty = 1 AND is_active ORDER BY random() LIMIT 1;
    IF v_mission.id IS NOT NULL THEN
        INSERT INTO user_daily_missions (user_id, mission_id, mission_date, target)
        VALUES (p_user_id, v_mission.id, v_today, v_mission.condition_value);
    END IF;

    -- Pick 1 medium
    SELECT * INTO v_mission FROM mission_definitions WHERE difficulty = 2 AND is_active ORDER BY random() LIMIT 1;
    IF v_mission.id IS NOT NULL THEN
        INSERT INTO user_daily_missions (user_id, mission_id, mission_date, target)
        VALUES (p_user_id, v_mission.id, v_today, v_mission.condition_value);
    END IF;

    -- Pick 1 hard
    SELECT * INTO v_mission FROM mission_definitions WHERE difficulty = 3 AND is_active ORDER BY random() LIMIT 1;
    IF v_mission.id IS NOT NULL THEN
        INSERT INTO user_daily_missions (user_id, mission_id, mission_date, target)
        VALUES (p_user_id, v_mission.id, v_today, v_mission.condition_value);
    END IF;

    RETURN QUERY SELECT * FROM user_daily_missions
    WHERE user_id = p_user_id AND mission_date = v_today
    ORDER BY (SELECT difficulty FROM mission_definitions WHERE id = mission_id);
END;
$$;

-- 6. Claim mission reward
CREATE OR REPLACE FUNCTION claim_mission_reward(p_mission_id UUID)
RETURNS JSONB
SECURITY DEFINER
LANGUAGE plpgsql AS $$
DECLARE
    v_mission user_daily_missions%ROWTYPE;
    v_def mission_definitions%ROWTYPE;
BEGIN
    SELECT * INTO v_mission FROM user_daily_missions
    WHERE id = p_mission_id AND user_id = auth.uid();
    IF v_mission.id IS NULL THEN RAISE EXCEPTION 'Mission not found'; END IF;
    IF NOT v_mission.completed THEN RAISE EXCEPTION 'Mission not completed'; END IF;
    IF v_mission.reward_claimed THEN RAISE EXCEPTION 'Reward already claimed'; END IF;

    SELECT * INTO v_def FROM mission_definitions WHERE id = v_mission.mission_id;

    -- Give reward
    IF v_def.reward_type = 'coins' THEN
        UPDATE users SET coins = coins + v_def.reward_amount, updated_at = now() WHERE id = auth.uid();
    ELSIF v_def.reward_type = 'tickets' THEN
        UPDATE users SET gacha_tickets = gacha_tickets + v_def.reward_amount, updated_at = now() WHERE id = auth.uid();
    END IF;

    -- Mark claimed
    UPDATE user_daily_missions SET reward_claimed = TRUE WHERE id = p_mission_id;

    RETURN jsonb_build_object(
        'reward_type', v_def.reward_type,
        'reward_amount', v_def.reward_amount,
        'mission_title', v_def.title_ja
    );
END;
$$;

-- 7. Update login streak
CREATE OR REPLACE FUNCTION update_login_streak(p_user_id UUID)
RETURNS JSONB
SECURITY DEFINER
LANGUAGE plpgsql AS $$
DECLARE
    v_streak login_streaks%ROWTYPE;
    v_today DATE := CURRENT_DATE;
    v_new_streak INTEGER;
    v_reward_coins INTEGER := 0;
    v_reward_tickets INTEGER := 0;
    v_milestone TEXT := NULL;
BEGIN
    SELECT * INTO v_streak FROM login_streaks WHERE user_id = p_user_id;

    IF v_streak.user_id IS NULL THEN
        -- First login ever
        INSERT INTO login_streaks (user_id, current_streak, max_streak, last_login_date)
        VALUES (p_user_id, 1, 1, v_today);
        v_new_streak := 1;
    ELSIF v_streak.last_login_date = v_today THEN
        -- Already logged in today
        RETURN jsonb_build_object('streak', v_streak.current_streak, 'already_logged', true);
    ELSIF v_streak.last_login_date = v_today - 1 THEN
        -- Consecutive day
        v_new_streak := v_streak.current_streak + 1;
        UPDATE login_streaks
        SET current_streak = v_new_streak,
            max_streak = GREATEST(v_streak.max_streak, v_new_streak),
            last_login_date = v_today,
            updated_at = now()
        WHERE user_id = p_user_id;
    ELSE
        -- Streak broken
        v_new_streak := 1;
        UPDATE login_streaks
        SET current_streak = 1, last_login_date = v_today, updated_at = now()
        WHERE user_id = p_user_id;
    END IF;

    -- Streak milestones
    IF v_new_streak = 3 THEN
        v_reward_coins := 30; v_milestone := '3日連続ログイン！';
    ELSIF v_new_streak = 7 THEN
        v_reward_coins := 50; v_reward_tickets := 1; v_milestone := '7日連続ログイン！';
    ELSIF v_new_streak = 14 THEN
        v_reward_coins := 100; v_reward_tickets := 2; v_milestone := '14日連続ログイン！';
    ELSIF v_new_streak = 30 THEN
        v_reward_coins := 200; v_reward_tickets := 3; v_milestone := '30日連続ログイン！';
    ELSIF v_new_streak % 10 = 0 AND v_new_streak > 30 THEN
        v_reward_coins := 100; v_reward_tickets := 1; v_milestone := v_new_streak || '日連続ログイン！';
    END IF;

    -- Award streak rewards
    IF v_reward_coins > 0 OR v_reward_tickets > 0 THEN
        UPDATE users
        SET coins = coins + v_reward_coins,
            gacha_tickets = gacha_tickets + v_reward_tickets,
            updated_at = now()
        WHERE id = p_user_id;
    END IF;

    -- Update users streak fields too
    UPDATE users SET streak_days = v_new_streak, last_login_at = now(), updated_at = now() WHERE id = p_user_id;

    RETURN jsonb_build_object(
        'streak', v_new_streak,
        'milestone', v_milestone,
        'reward_coins', v_reward_coins,
        'reward_tickets', v_reward_tickets
    );
END;
$$;
