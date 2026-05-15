-- =====================================================
-- MoWISE Roblox連動: 連携解除のための UPDATE ポリシー追加
-- Migration: 20260515_roblox_links_user_update_policy
-- 背景: パイロット準備項目6 Phase 0 調査で、roblox_links に UPDATE ポリシーが
--       未定義だったため、Web 側からの連携解除（status='inactive' への UPDATE）が
--       RLS で拒否される問題を解消する。
-- =====================================================

CREATE POLICY "Users can update own roblox links"
    ON roblox_links FOR UPDATE
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);
