-- ============================================================
-- MoWISE for Teachers: SaaS Platform Tables
-- 2026-06-24
-- ============================================================

-- ========== game_catalog: 20 games registry ==========
CREATE TABLE IF NOT EXISTS game_catalog (
    id          TEXT PRIMARY KEY,  -- e.g. 'eiken-game'
    title       TEXT NOT NULL,
    title_ja    TEXT NOT NULL,
    description TEXT,
    description_ja TEXT,
    category    TEXT NOT NULL DEFAULT 'vocabulary'
                CHECK (category IN ('vocabulary','grammar','phonics','writing','listening','mixed')),
    icon        TEXT NOT NULL DEFAULT '🎮',
    url         TEXT NOT NULL,  -- Vercel deployment URL
    thumbnail   TEXT,
    difficulty  TEXT NOT NULL DEFAULT 'all'
                CHECK (difficulty IN ('beginner','intermediate','advanced','all')),
    is_free     BOOLEAN NOT NULL DEFAULT TRUE,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE game_catalog ENABLE ROW LEVEL SECURITY;
CREATE POLICY "game_catalog_public_read" ON game_catalog FOR SELECT USING (TRUE);
CREATE POLICY "game_catalog_admin_write" ON game_catalog FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));

-- Seed game catalog
INSERT INTO game_catalog (id, title, title_ja, description_ja, category, icon, url, sort_order, is_free) VALUES
('eiken-game',         'Eiken Quiz',          '英検クイズ',          '英検の語彙問題をゲーム形式で学習', 'vocabulary', '📝', 'https://eiken-game-winniek75s-projects.vercel.app', 1, true),
('fallingwordbattle',  'Falling Word Battle', '落下ワードバトル',     '落ちてくる英単語の意味を素早く選択', 'vocabulary', '⬇️', 'https://fallingwordbattle-winniek75s-projects.vercel.app', 2, true),
('verbform-battle',    'Verb Form Battle',    '動詞活用バトル',      '動詞の正しい活用形を瞬時に判断', 'grammar',    '⚔️', 'https://verbform-battle-winniek75s-projects.vercel.app', 3, true),
('flashinput',         'Flash Input',         'フラッシュ入力',      '英単語を素早くタイピング', 'vocabulary',  '⚡', 'https://flashinput-winniek75s-projects.vercel.app', 4, false),
('grammar-drill',      'Grammar Drill',       '文法ドリル',          '文法問題を繰り返し練習', 'grammar',     '📖', 'https://grammar-drill-winniek75s-projects.vercel.app', 5, false),
('grammar-app',        'Grammar Classroom',   '文法クラスルーム',     '教室向け文法学習', 'grammar',     '🏫', 'https://grammar-app-winniek75s-projects.vercel.app', 6, false),
('eiken-grammar-game', 'Eiken Grammar',       '英検文法',            '英検の文法問題に挑戦', 'grammar',     '🎯', 'https://eiken-grammar-game-winniek75s-projects.vercel.app', 7, false),
('aredo-game',         'Aredo Quiz',          'アレドクイズ',        '文法クイズに挑戦', 'grammar',     '🧩', 'https://aredo-game-winniek75s-projects.vercel.app', 8, false),
('phonics',            'Phonics Games',       'フォニックスゲーム',   '8種類のフォニックスゲーム', 'phonics',     '🔤', 'https://phonics-winniek75s-projects.vercel.app', 9, false),
('phonics-battle',     'Phonics Battle',      'フォニックスバトル',   'フォニックスで対戦', 'phonics',     '🥊', 'https://phonics-battle-winniek75s-projects.vercel.app', 10, false),
('Phonics-sounds',     'Phonics Sounds',      'フォニックスサウンド', '音を聴いて学ぶフォニックス', 'phonics',     '🔊', 'https://phonics-sounds-winniek75s-projects.vercel.app', 11, false),
('sight-words-memory', 'Sight Words Memory',  'サイトワード記憶',    'サイトワードの記憶ゲーム', 'phonics',     '🧠', 'https://sight-words-memory-winniek75s-projects.vercel.app', 12, false),
('instant-english-app','Instant English',     'インスタント英語',    'AI活用の英作文練習', 'writing',     '✍️', 'https://instant-english-app-winniek75s-projects.vercel.app', 13, false),
('sentence-dash',      'Sentence Dash',       'センテンスダッシュ',   '文を素早く組み立てるゲーム', 'writing',     '🏃', 'https://sentence-dash-winniek75s-projects.vercel.app', 14, false),
('wh-questiongame',    'WH Question Game',    'WH質問ゲーム',       'WH疑問文を学ぶクイズ', 'grammar',     '❓', 'https://wh-questiongame-winniek75s-projects.vercel.app', 15, false),
('wise-english-floor', 'The Floor',           'ザ・フロア',          'フロア型英語ゲーム', 'mixed',       '🏢', 'https://wise-english-floor-winniek75s-projects.vercel.app', 16, false),
('beat-word-crush',    'Beat Word Crush',     'ビートワードクラッシュ','リズムに合わせて英単語', 'vocabulary',  '🎵', 'https://beat-word-crush-winniek75s-projects.vercel.app', 17, false),
('eiken-sns-app',      'Eiken SNS',           '英検SNS',            'SNS形式で英検学習', 'vocabulary',  '📱', 'https://eiken-sns-app-winniek75s-projects.vercel.app', 18, false),
('eiken-challenge',    'Eiken Challenge',     '英検チャレンジ',      '英検の総合チャレンジ', 'vocabulary',  '🏆', 'https://eiken-challenge-winniek75s-projects.vercel.app', 19, false)
ON CONFLICT (id) DO NOTHING;

-- ========== assignments: homework / class game assignments ==========
CREATE TABLE IF NOT EXISTS assignments (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id     UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    game_id      TEXT NOT NULL REFERENCES game_catalog(id),
    title        TEXT,
    instructions TEXT,
    due_date     TIMESTAMPTZ,
    config       JSONB DEFAULT '{}',  -- game-specific config (grade, mode, etc.)
    status       TEXT NOT NULL DEFAULT 'active'
                 CHECK (status IN ('active','completed','archived')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX assignments_class_idx ON assignments(class_id, status);
CREATE INDEX assignments_teacher_idx ON assignments(teacher_id);
CREATE INDEX assignments_due_idx ON assignments(due_date) WHERE due_date IS NOT NULL;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
CREATE POLICY "teachers_manage_assignments" ON assignments FOR ALL
    USING (auth.uid() = teacher_id);
CREATE POLICY "students_view_assignments" ON assignments FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm
        WHERE cm.class_id = assignments.class_id
          AND cm.user_id = auth.uid()
          AND cm.status = 'approved'
    ));

-- ========== game_scores: unified score recording ==========
CREATE TABLE IF NOT EXISTS game_scores (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    game_id       TEXT NOT NULL REFERENCES game_catalog(id),
    assignment_id UUID REFERENCES assignments(id) ON DELETE SET NULL,
    class_id      UUID REFERENCES classes(id) ON DELETE SET NULL,
    score         INTEGER NOT NULL DEFAULT 0,
    max_score     INTEGER,
    accuracy      NUMERIC(5,2),  -- percentage 0-100
    time_spent    INTEGER,       -- seconds
    xp_earned     INTEGER NOT NULL DEFAULT 0,
    coins_earned  INTEGER NOT NULL DEFAULT 0,
    completed     BOOLEAN NOT NULL DEFAULT FALSE,
    metadata      JSONB DEFAULT '{}',  -- game-specific data
    played_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX gs_user_game_idx ON game_scores(user_id, game_id, played_at DESC);
CREATE INDEX gs_class_idx ON game_scores(class_id, game_id, played_at DESC);
CREATE INDEX gs_assignment_idx ON game_scores(assignment_id) WHERE assignment_id IS NOT NULL;
ALTER TABLE game_scores ENABLE ROW LEVEL SECURITY;
CREATE POLICY "gs_own_insert" ON game_scores FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "gs_own_select" ON game_scores FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "gs_teacher_select" ON game_scores FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = game_scores.user_id
          AND c.teacher_id = auth.uid()
    ));

-- ========== subscriptions: teacher subscription management ==========
CREATE TABLE IF NOT EXISTS subscriptions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE UNIQUE,
    plan                TEXT NOT NULL DEFAULT 'free'
                        CHECK (plan IN ('free','basic','pro')),
    stripe_customer_id  TEXT,
    stripe_subscription_id TEXT,
    status              TEXT NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active','past_due','canceled','trialing')),
    current_period_start TIMESTAMPTZ,
    current_period_end   TIMESTAMPTZ,
    max_students        INTEGER NOT NULL DEFAULT 5,
    max_classes         INTEGER NOT NULL DEFAULT 1,
    max_games           INTEGER NOT NULL DEFAULT 3,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "sub_own" ON subscriptions FOR ALL USING (auth.uid() = user_id);

-- ========== badge_definitions: achievement badges ==========
CREATE TABLE IF NOT EXISTS badge_definitions (
    id          TEXT PRIMARY KEY,
    title       TEXT NOT NULL,
    title_ja    TEXT NOT NULL,
    description TEXT,
    description_ja TEXT,
    icon        TEXT NOT NULL DEFAULT '🏅',
    category    TEXT NOT NULL DEFAULT 'general'
                CHECK (category IN ('general','game','streak','social','special')),
    condition   JSONB NOT NULL DEFAULT '{}',  -- { type: 'games_played', count: 10 }
    sort_order  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "badges_public_read" ON badge_definitions FOR SELECT USING (TRUE);

-- Seed some badges
INSERT INTO badge_definitions (id, title, title_ja, icon, category, condition, sort_order) VALUES
('first_game',    'First Step',     '最初の一歩',     '👣', 'general', '{"type":"games_played","count":1}', 1),
('ten_games',     'Getting Started','やる気満々',     '🔥', 'general', '{"type":"games_played","count":10}', 2),
('fifty_games',   'Game Master',    'ゲームマスター', '🎮', 'general', '{"type":"games_played","count":50}', 3),
('perfect_score', 'Perfect!',       'パーフェクト',   '💯', 'game',    '{"type":"perfect_score","count":1}', 4),
('streak_7',      'Week Warrior',   '一週間戦士',     '📅', 'streak',  '{"type":"streak_days","count":7}', 5),
('streak_30',     'Monthly Hero',   '月間ヒーロー',   '🌟', 'streak',  '{"type":"streak_days","count":30}', 6),
('all_games',     'Explorer',       '冒険家',         '🗺️', 'special', '{"type":"unique_games","count":10}', 7),
('high_accuracy', 'Sharp Shooter',  'シャープシューター','🎯', 'game', '{"type":"avg_accuracy","min":90}', 8)
ON CONFLICT (id) DO NOTHING;

-- ========== user_badges: earned badges ==========
CREATE TABLE IF NOT EXISTS user_badges (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    badge_id   TEXT NOT NULL REFERENCES badge_definitions(id),
    earned_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, badge_id)
);
CREATE INDEX ub_user_idx ON user_badges(user_id);
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ub_own_select" ON user_badges FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ub_own_insert" ON user_badges FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "ub_teacher_select" ON user_badges FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = user_badges.user_id AND c.teacher_id = auth.uid()
    ));

-- ========== Views for leaderboard ==========
CREATE OR REPLACE VIEW class_leaderboard AS
SELECT
    gs.class_id,
    gs.user_id,
    u.display_name,
    u.avatar_url,
    COUNT(*) as games_played,
    SUM(gs.score) as total_score,
    SUM(gs.xp_earned) as total_xp,
    AVG(gs.accuracy) as avg_accuracy,
    MAX(gs.played_at) as last_played
FROM game_scores gs
JOIN users u ON u.id = gs.user_id
WHERE gs.class_id IS NOT NULL
GROUP BY gs.class_id, gs.user_id, u.display_name, u.avatar_url;

-- ========== View for assignment progress ==========
CREATE OR REPLACE VIEW assignment_progress AS
SELECT
    a.id as assignment_id,
    a.class_id,
    a.game_id,
    a.title as assignment_title,
    a.due_date,
    cm.user_id as student_id,
    u.display_name as student_name,
    COALESCE(gs.completed, false) as completed,
    gs.score as best_score,
    gs.accuracy as best_accuracy,
    gs.played_at as last_attempt
FROM assignments a
JOIN class_members cm ON cm.class_id = a.class_id AND cm.status = 'approved'
JOIN users u ON u.id = cm.user_id
LEFT JOIN LATERAL (
    SELECT score, accuracy, completed, played_at
    FROM game_scores
    WHERE user_id = cm.user_id
      AND assignment_id = a.id
    ORDER BY score DESC
    LIMIT 1
) gs ON true;
