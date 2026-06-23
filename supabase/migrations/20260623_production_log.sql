-- =====================================================
-- production_log: 自己産出ゲート (star 3->4) の記録
-- 設計書: MoWISE_習得メカニズム強化_引き継ぎ_v0_2.md §3-3
-- =====================================================

CREATE TABLE IF NOT EXISTS production_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    pattern_id      TEXT NOT NULL,            -- 'P001' etc.
    sentence        TEXT NOT NULL,            -- user's produced sentence
    passed          BOOLEAN NOT NULL DEFAULT FALSE,
    ai_feedback     TEXT,                     -- short positive feedback from AI
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX production_log_user_pattern_idx
    ON production_log(user_id, pattern_id, created_at DESC);

CREATE INDEX production_log_user_passed_idx
    ON production_log(user_id, passed, created_at DESC);

-- RLS
ALTER TABLE production_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert own production_log"
    ON production_log FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can read own production_log"
    ON production_log FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Teachers can view student production_log"
    ON production_log FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members cm
            JOIN classes c ON cm.class_id = c.id
            WHERE cm.user_id = production_log.user_id
              AND c.teacher_id = auth.uid()
        )
    );
