-- =====================================================
-- C-3.1 先生 NPC 引き継ぎ最小版（Stage 1）
-- academy_npc_takeovers テーブル + RLS
--
-- 主参照:
--   - ClaudeCode_C3-1_TeacherTakeover実装_実装ガイド.md §4-1-1
--   - MoWISE_C3_先生バーチャル臨場機能_構想書_v1_0.md §7-1
--
-- 設計判断:
--   - 軽量 7 列版（teacher_messages / rewards_granted JSONB は Stage 2 へ繰延）
--   - RLS パターン: classes.teacher_id = auth.uid() 直接判定
--     （class_members JOIN は class_id を直接保持しているため省略可能）
-- =====================================================

CREATE TABLE academy_npc_takeovers (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id    UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  student_id    UUID REFERENCES auth.users(id) ON DELETE SET NULL,  -- NULL 可（複数生徒対象 or 不特定の場合）
  class_id      UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  npc_id        TEXT NOT NULL CHECK (npc_id IN ('maria', 'sam', 'lily')),
  started_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at      TIMESTAMPTZ,                          -- NULL = アクティブ中
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_takeovers_teacher  ON academy_npc_takeovers(teacher_id, started_at DESC);
CREATE INDEX idx_takeovers_class    ON academy_npc_takeovers(class_id, started_at DESC);
CREATE INDEX idx_takeovers_active   ON academy_npc_takeovers(npc_id) WHERE ended_at IS NULL;

ALTER TABLE academy_npc_takeovers ENABLE ROW LEVEL SECURITY;

-- 先生は自分の担当クラスの引き継ぎ記録を全操作可
CREATE POLICY "takeovers_teacher_all"
  ON academy_npc_takeovers FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM classes
      WHERE id = academy_npc_takeovers.class_id
        AND teacher_id = auth.uid()
    )
  );

-- 生徒は自分が対象になった引き継ぎ記録のみ閲覧可
CREATE POLICY "takeovers_student_read"
  ON academy_npc_takeovers FOR SELECT
  USING (auth.uid() = student_id);
