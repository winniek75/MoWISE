-- =====================================================
-- C-1.3: Town Talk 基盤テーブル + RLS + Storage
-- Migration: 20260504_town_talk_tables
--
-- 主参照: MoWISE_TownTalk仕様書_v1_2_脚本統合版.md §4
-- 採用基準: 既存スキーマ class_members + classes（teacher_id 直接判定方式）
-- 教師判定パターン:
--   EXISTS (
--     SELECT 1 FROM class_members cm
--     JOIN classes c ON c.id = cm.class_id
--     WHERE cm.user_id = {対象}.user_id
--       AND cm.status = 'approved'
--       AND c.teacher_id = auth.uid()
--   )
-- =====================================================


-- =====================================================
-- 1. town_talk_scenarios（シナリオ本体）
-- =====================================================
CREATE TABLE town_talk_scenarios (
  scenario_id        TEXT PRIMARY KEY,
  pattern_no         TEXT NOT NULL,
  npc_id             TEXT NOT NULL CHECK (npc_id IN ('maria','sam','lily')),
  place              TEXT NOT NULL,
  theme              TEXT NOT NULL,
  difficulty         TEXT NOT NULL CHECK (difficulty IN ('jh1','jh2','jh3')),
  reward_coins       INT  NOT NULL,
  reward_friendship  INT  NOT NULL,
  mowi_message       TEXT NOT NULL,
  total_turns        INT  NOT NULL DEFAULT 5,
  payload_json       JSONB NOT NULL,
  is_active          BOOLEAN NOT NULL DEFAULT true,
  version            INT  NOT NULL DEFAULT 1,
  created_at         TIMESTAMPTZ DEFAULT now(),
  updated_at         TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_town_talk_scenarios_npc      ON town_talk_scenarios(npc_id);
CREATE INDEX idx_town_talk_scenarios_pattern  ON town_talk_scenarios(pattern_no);
CREATE INDEX idx_town_talk_scenarios_active   ON town_talk_scenarios(is_active);

ALTER TABLE town_talk_scenarios ENABLE ROW LEVEL SECURITY;

-- 認証済みユーザーは全シナリオを読める。書き込みは service_role のみ（policy 不要）。
CREATE POLICY town_talk_scenarios_read_all ON town_talk_scenarios
  FOR SELECT
  USING (auth.role() = 'authenticated');


-- =====================================================
-- 2. town_talk_logs（プレイログ）
-- =====================================================
CREATE TABLE town_talk_logs (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id            UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scenario_id        TEXT NOT NULL REFERENCES town_talk_scenarios(scenario_id),
  pattern_no         TEXT NOT NULL,
  npc_id             TEXT NOT NULL,

  -- 結果
  total_turns        INT  NOT NULL,
  correct_count      INT  NOT NULL,
  acceptable_count   INT  NOT NULL DEFAULT 0,  -- △ の数
  fail_count         INT  NOT NULL DEFAULT 0,
  is_completed       BOOLEAN NOT NULL DEFAULT false,

  -- 詳細（JSON）
  selections         JSONB NOT NULL,
  audio_urls         JSONB,                    -- 直近100件のみ。LRU で NULL 化される

  -- 承認フロー（C-4 連携）
  approval_status    TEXT NOT NULL DEFAULT 'auto_passed'
                     CHECK (approval_status IN ('auto_passed','pending_review','approved','rejected')),
  approved_by        UUID REFERENCES auth.users(id),
  approved_at        TIMESTAMPTZ,
  rejected_reason    TEXT,

  -- メタ
  played_from        TEXT NOT NULL DEFAULT 'roblox' CHECK (played_from IN ('roblox','app','cluster','webgl')),
  duration_sec       INT,
  created_at         TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_town_talk_logs_user      ON town_talk_logs(user_id);
CREATE INDEX idx_town_talk_logs_scenario  ON town_talk_logs(scenario_id);
CREATE INDEX idx_town_talk_logs_status    ON town_talk_logs(approval_status);
CREATE INDEX idx_town_talk_logs_created   ON town_talk_logs(created_at DESC);

ALTER TABLE town_talk_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY town_talk_logs_self_read ON town_talk_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY town_talk_logs_self_write ON town_talk_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 教師: 自クラスの承認済み生徒のログを参照可能
CREATE POLICY town_talk_logs_teacher_read ON town_talk_logs
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM class_members cm
      JOIN classes c ON c.id = cm.class_id
      WHERE cm.user_id = town_talk_logs.user_id
        AND cm.status = 'approved'
        AND c.teacher_id = auth.uid()
    )
  );

-- 教師: 承認ステータス遷移用 UPDATE（pending_review/approved/rejected の範囲のみ）
CREATE POLICY town_talk_logs_teacher_approve ON town_talk_logs
  FOR UPDATE USING (
    approval_status IN ('pending_review','approved','rejected')
    AND EXISTS (
      SELECT 1 FROM class_members cm
      JOIN classes c ON c.id = cm.class_id
      WHERE cm.user_id = town_talk_logs.user_id
        AND cm.status = 'approved'
        AND c.teacher_id = auth.uid()
    )
  );


-- =====================================================
-- 3. town_talk_progress（生徒×シナリオ進捗）
-- =====================================================
CREATE TABLE town_talk_progress (
  user_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  scenario_id          TEXT NOT NULL REFERENCES town_talk_scenarios(scenario_id),

  play_count           INT  NOT NULL DEFAULT 0,
  success_count        INT  NOT NULL DEFAULT 0,
  last_played_at       TIMESTAMPTZ,
  last_success_at      TIMESTAMPTZ,
  next_review_at       TIMESTAMPTZ,
  spaced_interval_days INT NOT NULL DEFAULT 1,

  friendship_npc       INT NOT NULL DEFAULT 0,

  created_at           TIMESTAMPTZ DEFAULT now(),
  updated_at           TIMESTAMPTZ DEFAULT now(),

  PRIMARY KEY (user_id, scenario_id)
);

CREATE INDEX idx_town_talk_progress_user    ON town_talk_progress(user_id);
CREATE INDEX idx_town_talk_progress_review  ON town_talk_progress(next_review_at);

ALTER TABLE town_talk_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY town_talk_progress_self_all ON town_talk_progress
  FOR ALL USING (auth.uid() = user_id);

-- 教師: 自クラスの承認済み生徒の進捗を参照可能
CREATE POLICY town_talk_progress_teacher_read ON town_talk_progress
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM class_members cm
      JOIN classes c ON c.id = cm.class_id
      WHERE cm.user_id = town_talk_progress.user_id
        AND cm.status = 'approved'
        AND c.teacher_id = auth.uid()
    )
  );


-- =====================================================
-- 4. Storage bucket（town-talk-recordings）
-- =====================================================
-- ファイルパス規則: {user_id}/{log_id}/{turn_no}.webm
INSERT INTO storage.buckets (id, name, public)
VALUES ('town-talk-recordings', 'town-talk-recordings', false)
ON CONFLICT (id) DO NOTHING;

-- 本人: 自分のフォルダのみ全権限
CREATE POLICY town_talk_recordings_self_all ON storage.objects
  FOR ALL USING (
    bucket_id = 'town-talk-recordings'
    AND auth.uid()::text = (storage.foldername(name))[1]
  );

-- 教師: 自クラスの承認済み生徒のフォルダを参照可能
CREATE POLICY town_talk_recordings_teacher_read ON storage.objects
  FOR SELECT USING (
    bucket_id = 'town-talk-recordings'
    AND EXISTS (
      SELECT 1 FROM class_members cm
      JOIN classes c ON c.id = cm.class_id
      WHERE cm.user_id::text = (storage.foldername(name))[1]
        AND cm.status = 'approved'
        AND c.teacher_id = auth.uid()
    )
  );
