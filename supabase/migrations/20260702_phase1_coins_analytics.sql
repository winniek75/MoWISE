-- ============================================================
-- Phase 1: Coins/Tickets reward system + Teacher analytics views
-- 2026-07-02
-- ============================================================

-- 1. Add coins & gacha_tickets to users
ALTER TABLE users ADD COLUMN IF NOT EXISTS coins INTEGER NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS gacha_tickets INTEGER NOT NULL DEFAULT 0;

-- 2. Function: award coins & tickets after game score insert
CREATE OR REPLACE FUNCTION award_coins_on_score()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql AS $$
DECLARE
    v_coins INTEGER;
    v_tickets INTEGER;
BEGIN
    -- Base reward: 10 coins per completed game
    v_coins := 10;
    v_tickets := 1;

    -- Bonus for high accuracy
    IF NEW.accuracy IS NOT NULL AND NEW.accuracy >= 90 THEN
        v_coins := v_coins + 10;  -- 20 total for 90%+
    END IF;

    -- Perfect score bonus
    IF NEW.accuracy IS NOT NULL AND NEW.accuracy >= 100 THEN
        v_coins := v_coins + 20;  -- 40 total for perfect
        v_tickets := v_tickets + 2;  -- 3 tickets for perfect
    END IF;

    -- Only award for completed games
    IF NEW.completed = true THEN
        UPDATE users
        SET coins = coins + v_coins,
            gacha_tickets = gacha_tickets + v_tickets,
            updated_at = now()
        WHERE id = NEW.user_id;

        -- Store reward info in metadata for frontend display
        NEW.metadata = COALESCE(NEW.metadata, '{}'::jsonb)
            || jsonb_build_object('coins_awarded', v_coins, 'tickets_awarded', v_tickets);
    END IF;

    RETURN NEW;
END;
$$;

-- Drop if exists then create trigger
DROP TRIGGER IF EXISTS trg_award_coins_on_score ON game_scores;
CREATE TRIGGER trg_award_coins_on_score
    BEFORE INSERT ON game_scores
    FOR EACH ROW
    EXECUTE FUNCTION award_coins_on_score();

-- 3. View: Game-level student analytics (for teacher dashboard)
CREATE OR REPLACE VIEW student_game_stats AS
SELECT
    gs.user_id,
    gs.game_id,
    gc.title_ja AS game_title,
    gc.category,
    cm.class_id,
    COUNT(*) AS play_count,
    MAX(gs.score) AS best_score,
    ROUND(AVG(gs.accuracy)::numeric, 1) AS avg_accuracy,
    ROUND(AVG(gs.time_spent)::numeric, 0) AS avg_time_spent,
    SUM(gs.xp_earned) AS total_xp,
    MAX(gs.played_at) AS last_played,
    COUNT(*) FILTER (WHERE gs.completed = true) AS completed_count,
    COUNT(*) FILTER (WHERE gs.accuracy >= 90) AS high_accuracy_count
FROM game_scores gs
JOIN game_catalog gc ON gc.id = gs.game_id
LEFT JOIN class_members cm ON cm.user_id = gs.user_id AND cm.status = 'approved'
GROUP BY gs.user_id, gs.game_id, gc.title_ja, gc.category, cm.class_id;

-- 4. View: Assignment completion tracking
CREATE OR REPLACE VIEW assignment_completion AS
SELECT
    a.id AS assignment_id,
    a.class_id,
    a.game_id,
    a.title AS assignment_title,
    a.due_date,
    a.status AS assignment_status,
    gc.title_ja AS game_title,
    cm.user_id AS student_id,
    u.display_name,
    COALESCE(
        (SELECT TRUE FROM game_scores gs
         WHERE gs.user_id = cm.user_id
           AND gs.game_id = a.game_id
           AND gs.assignment_id = a.id
           AND gs.completed = true
         LIMIT 1),
        FALSE
    ) AS is_completed,
    (SELECT MAX(gs.score) FROM game_scores gs
     WHERE gs.user_id = cm.user_id
       AND gs.game_id = a.game_id
       AND gs.assignment_id = a.id) AS best_score,
    (SELECT MAX(gs.accuracy) FROM game_scores gs
     WHERE gs.user_id = cm.user_id
       AND gs.game_id = a.game_id
       AND gs.assignment_id = a.id) AS best_accuracy,
    (SELECT MAX(gs.played_at) FROM game_scores gs
     WHERE gs.user_id = cm.user_id
       AND gs.game_id = a.game_id
       AND gs.assignment_id = a.id) AS last_attempt
FROM assignments a
JOIN game_catalog gc ON gc.id = a.game_id
JOIN class_members cm ON cm.class_id = a.class_id AND cm.status = 'approved'
JOIN users u ON u.id = cm.user_id;

-- 5. View: Weekly progress per student (last 4 weeks)
CREATE OR REPLACE VIEW student_weekly_progress AS
SELECT
    gs.user_id,
    cm.class_id,
    date_trunc('week', gs.played_at)::date AS week_start,
    COUNT(*) AS games_played,
    ROUND(AVG(gs.accuracy)::numeric, 1) AS avg_accuracy,
    SUM(gs.xp_earned) AS total_xp,
    COUNT(DISTINCT gs.game_id) AS unique_games,
    SUM(gs.time_spent) AS total_time_seconds
FROM game_scores gs
JOIN class_members cm ON cm.user_id = gs.user_id AND cm.status = 'approved'
WHERE gs.played_at >= now() - interval '28 days'
GROUP BY gs.user_id, cm.class_id, date_trunc('week', gs.played_at)::date;

-- 6. View: Category weakness detection
CREATE OR REPLACE VIEW student_category_weakness AS
SELECT
    gs.user_id,
    cm.class_id,
    gc.category,
    COUNT(*) AS play_count,
    ROUND(AVG(gs.accuracy)::numeric, 1) AS avg_accuracy,
    CASE
        WHEN AVG(gs.accuracy) < 50 THEN 'weak'
        WHEN AVG(gs.accuracy) < 70 THEN 'needs_work'
        WHEN AVG(gs.accuracy) < 85 THEN 'ok'
        ELSE 'strong'
    END AS strength_level
FROM game_scores gs
JOIN game_catalog gc ON gc.id = gs.game_id
JOIN class_members cm ON cm.user_id = gs.user_id AND cm.status = 'approved'
WHERE gs.completed = true
GROUP BY gs.user_id, cm.class_id, gc.category;
