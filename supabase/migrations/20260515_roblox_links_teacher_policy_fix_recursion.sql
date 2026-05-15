-- =====================================================
-- パイロット準備6 緊急修正：
-- teachers_read_class_roblox_links が class_members × classes の RLS と
-- 無限再帰を起こすため、SECURITY DEFINER 関数経由に書き換える。
-- 既存 is_teacher_of() には approved 条件が無いため、
-- approved 限定の新関数 is_teacher_of_approved() を追加してそれを使う。
--
-- Migration: 20260515_roblox_links_teacher_policy_fix_recursion
-- 背景: Web 側 fetchLinkStatus（先生アカウント）で 500
--       "infinite recursion detected in policy for relation class_members"
-- =====================================================

CREATE OR REPLACE FUNCTION public.is_teacher_of_approved(p_user_id uuid)
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM class_members cm
    JOIN classes c ON cm.class_id = c.id
    WHERE cm.user_id = p_user_id
      AND cm.status = 'approved'
      AND c.teacher_id = auth.uid()
  );
$$;

DROP POLICY IF EXISTS "teachers_read_class_roblox_links" ON roblox_links;
DROP POLICY IF EXISTS "Teachers can view class students roblox links" ON roblox_links;

CREATE POLICY "teachers_read_class_roblox_links"
  ON roblox_links FOR SELECT
  USING (is_teacher_of_approved(user_id));
