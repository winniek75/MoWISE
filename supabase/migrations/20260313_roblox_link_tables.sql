-- =====================================================
-- MoWISE Roblox連動: アカウント連携テーブル
-- Migration: 20260313_roblox_link_tables
-- =====================================================

-- テーブル: roblox_link_codes
-- 用途: アカウント連携コードの一時保存（6桁コード、5分有効）
CREATE TABLE IF NOT EXISTS roblox_link_codes (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code                VARCHAR(6) NOT NULL,
    roblox_user_id      BIGINT NOT NULL,
    roblox_display_name TEXT,
    status              TEXT NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending', 'used', 'expired')),
    expires_at          TIMESTAMPTZ NOT NULL,
    used_by             UUID REFERENCES auth.users(id),
    used_at             TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- pending状態のコード検索用
CREATE INDEX IF NOT EXISTS idx_link_codes_code
    ON roblox_link_codes(code) WHERE status = 'pending';
-- Roblox User ID 検索用
CREATE INDEX IF NOT EXISTS idx_link_codes_roblox_id
    ON roblox_link_codes(roblox_user_id);


-- テーブル: roblox_links
-- 用途: 連携済みアカウントの永続管理
CREATE TABLE IF NOT EXISTS roblox_links (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    roblox_user_id      BIGINT NOT NULL,
    roblox_display_name TEXT,
    link_token          TEXT NOT NULL UNIQUE,
    status              TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'inactive')),
    token_expires_at    TIMESTAMPTZ NOT NULL,
    last_sync_at        TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE(user_id),
    UNIQUE(roblox_user_id)
);

-- アクティブなトークン検索用
CREATE INDEX IF NOT EXISTS idx_roblox_links_token
    ON roblox_links(link_token) WHERE status = 'active';
-- Roblox User ID 検索用
CREATE INDEX IF NOT EXISTS idx_roblox_links_roblox_id
    ON roblox_links(roblox_user_id);


-- テーブル: roblox_sessions
-- 用途: Roblox側プレイセッションの記録
CREATE TABLE IF NOT EXISTS roblox_sessions (
    id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                 UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    roblox_user_id          BIGINT NOT NULL,

    started_at              TIMESTAMPTZ NOT NULL,
    ended_at                TIMESTAMPTZ,
    duration_seconds        INTEGER,

    -- Flash Output 統計
    flash_output_total      INTEGER NOT NULL DEFAULT 0,
    flash_output_correct    INTEGER NOT NULL DEFAULT 0,
    max_combo               INTEGER NOT NULL DEFAULT 0,

    -- 経済
    word_coins_earned       INTEGER NOT NULL DEFAULT 0,
    word_coins_spent        INTEGER NOT NULL DEFAULT 0,

    -- 建設
    buildings_built         TEXT[] DEFAULT '{}',
    npc_missions_done       TEXT[] DEFAULT '{}',

    -- パターン更新
    pattern_updates         JSONB DEFAULT '[]',

    -- 街の状態スナップショット
    town_state              JSONB DEFAULT '{}',

    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_roblox_sessions_user
    ON roblox_sessions(user_id, started_at DESC);


-- テーブル: roblox_town_state
-- 用途: ユーザーの街の永続状態
CREATE TABLE IF NOT EXISTS roblox_town_state (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id                     UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,

    -- Word Coins 残高
    word_coins                  INTEGER NOT NULL DEFAULT 0
                                CHECK (word_coins >= 0),

    -- ゾーン別建物状態（JSONB）
    buildings                   JSONB NOT NULL DEFAULT '{}',

    -- ゾーン解禁状態
    zones_unlocked              INTEGER[] NOT NULL DEFAULT '{1}',

    -- NPC友好度合計
    total_npc_friendship        INTEGER NOT NULL DEFAULT 0,

    -- 統計
    total_buildings_built       INTEGER NOT NULL DEFAULT 0,
    total_missions_completed    INTEGER NOT NULL DEFAULT 0,
    total_play_time_seconds     INTEGER NOT NULL DEFAULT 0,

    updated_at                  TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- =====================================================
-- 既存テーブル拡張
-- =====================================================

-- users テーブルに Roblox 関連カラム追加
ALTER TABLE users ADD COLUMN IF NOT EXISTS
    roblox_linked BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS
    roblox_user_id BIGINT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS
    roblox_last_played_at TIMESTAMPTZ;

-- pattern_progress テーブルに Roblox 由来の統計追加
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'pattern_progress') THEN
        ALTER TABLE pattern_progress ADD COLUMN IF NOT EXISTS
            roblox_flash_output_count INTEGER NOT NULL DEFAULT 0;
        ALTER TABLE pattern_progress ADD COLUMN IF NOT EXISTS
            roblox_npc_missions_done INTEGER NOT NULL DEFAULT 0;
        ALTER TABLE pattern_progress ADD COLUMN IF NOT EXISTS
            roblox_mastery_bonus DECIMAL(3,2) NOT NULL DEFAULT 0.0;
    END IF;
END $$;

-- mowi_state テーブルに Roblox 同期フィールド追加
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'mowi_state') THEN
        ALTER TABLE mowi_state ADD COLUMN IF NOT EXISTS
            roblox_brightness_override INTEGER;
        ALTER TABLE mowi_state ADD COLUMN IF NOT EXISTS
            last_roblox_sync_at TIMESTAMPTZ;
    END IF;
END $$;


-- =====================================================
-- RLS ポリシー
-- =====================================================

ALTER TABLE roblox_link_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE roblox_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE roblox_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE roblox_town_state ENABLE ROW LEVEL SECURITY;

-- roblox_links: ユーザーは自分の連携のみ参照可能
CREATE POLICY "Users can view own roblox links"
    ON roblox_links FOR SELECT
    USING (auth.uid() = user_id);

-- roblox_sessions: ユーザーは自分のセッションのみ参照可能
CREATE POLICY "Users can view own roblox sessions"
    ON roblox_sessions FOR SELECT
    USING (auth.uid() = user_id);

-- roblox_town_state: ユーザーは自分の街状態のみ参照可能
CREATE POLICY "Users can view own town state"
    ON roblox_town_state FOR SELECT
    USING (auth.uid() = user_id);
