-- =====================================================
-- Teacher RLS: 教師がクラス生徒のRobloxデータを参照可能にする
-- Migration: 20260402_roblox_teacher_rls
-- =====================================================

-- 1. roblox_links: 教師は自クラスの承認済み生徒の連携情報を参照可能
CREATE POLICY "Teachers can view class students roblox links"
    ON roblox_links FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members cm
            JOIN classes c ON c.id = cm.class_id
            WHERE cm.user_id = roblox_links.user_id
              AND cm.status = 'approved'
              AND c.teacher_id = auth.uid()
        )
    );

-- 2. roblox_sessions: 教師は自クラスの承認済み生徒のセッションを参照可能
CREATE POLICY "Teachers can view class students roblox sessions"
    ON roblox_sessions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members cm
            JOIN classes c ON c.id = cm.class_id
            WHERE cm.user_id = roblox_sessions.user_id
              AND cm.status = 'approved'
              AND c.teacher_id = auth.uid()
        )
    );

-- 3. roblox_town_state: 教師は自クラスの承認済み生徒の街状態を参照可能
CREATE POLICY "Teachers can view class students town state"
    ON roblox_town_state FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members cm
            JOIN classes c ON c.id = cm.class_id
            WHERE cm.user_id = roblox_town_state.user_id
              AND cm.status = 'approved'
              AND c.teacher_id = auth.uid()
        )
    );
