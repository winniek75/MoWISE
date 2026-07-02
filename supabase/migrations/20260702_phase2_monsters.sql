-- ============================================================
-- Phase 2: Monster system — DB schema + seed data (dummy)
-- 2026-07-02
-- ============================================================

-- 1. Monster species definitions
CREATE TABLE IF NOT EXISTS monster_species (
    id          TEXT PRIMARY KEY,           -- e.g. 'gram-fox'
    name_ja     TEXT NOT NULL,
    name_en     TEXT NOT NULL,
    category    TEXT NOT NULL               -- matches game_catalog category
                CHECK (category IN ('eiken','grammar','phonics','writing','mixed','special')),
    rarity      INTEGER NOT NULL DEFAULT 1  -- 1=Normal, 2=Rare, 3=SR, 4=Legend
                CHECK (rarity BETWEEN 1 AND 4),
    stage1_img  TEXT DEFAULT '/monsters/placeholder.svg',
    stage2_img  TEXT DEFAULT '/monsters/placeholder.svg',
    stage3_img  TEXT DEFAULT '/monsters/placeholder.svg',
    evolve_lv2  INTEGER NOT NULL DEFAULT 10,   -- level to evolve to stage 2
    evolve_lv3  INTEGER NOT NULL DEFAULT 25,   -- level to evolve to stage 3
    max_level   INTEGER NOT NULL DEFAULT 50,
    description_ja TEXT,
    sort_order  INTEGER NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE monster_species ENABLE ROW LEVEL SECURITY;
CREATE POLICY "monster_species_public_read" ON monster_species FOR SELECT USING (TRUE);

-- 2. User's monster collection
CREATE TABLE IF NOT EXISTS user_monsters (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    species_id  TEXT NOT NULL REFERENCES monster_species(id),
    nickname    TEXT,                          -- optional custom name
    level       INTEGER NOT NULL DEFAULT 1,
    exp         INTEGER NOT NULL DEFAULT 0,
    stage       INTEGER NOT NULL DEFAULT 1    -- 1, 2, or 3
                CHECK (stage BETWEEN 1 AND 3),
    is_buddy    BOOLEAN NOT NULL DEFAULT FALSE,  -- active companion
    obtained_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    obtained_via TEXT NOT NULL DEFAULT 'gacha'   -- gacha, starter, reward, event
                CHECK (obtained_via IN ('gacha','starter','reward','event')),
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX user_monsters_user_idx ON user_monsters(user_id);
CREATE INDEX user_monsters_buddy_idx ON user_monsters(user_id) WHERE is_buddy = TRUE;
ALTER TABLE user_monsters ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_monsters_select" ON user_monsters FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "own_monsters_update" ON user_monsters FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "own_monsters_insert" ON user_monsters FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Teachers can view their students' monsters
CREATE POLICY "teachers_view_student_monsters" ON user_monsters FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm JOIN classes c ON cm.class_id = c.id
        WHERE cm.user_id = user_monsters.user_id AND c.teacher_id = auth.uid()
    ));

-- 3. Gacha history log
CREATE TABLE IF NOT EXISTS gacha_history (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    species_id  TEXT NOT NULL REFERENCES monster_species(id),
    rarity      INTEGER NOT NULL,
    tickets_spent INTEGER NOT NULL DEFAULT 1,
    is_new      BOOLEAN NOT NULL DEFAULT TRUE,  -- first time getting this species
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX gacha_history_user_idx ON gacha_history(user_id, created_at DESC);
ALTER TABLE gacha_history ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own_gacha_select" ON gacha_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "own_gacha_insert" ON gacha_history FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 4. Feed monster (give EXP) function
CREATE OR REPLACE FUNCTION feed_monster(
    p_monster_id UUID,
    p_food_amount INTEGER DEFAULT 1  -- 1 food = 10 EXP
) RETURNS JSONB
SECURITY DEFINER
LANGUAGE plpgsql AS $$
DECLARE
    v_monster user_monsters%ROWTYPE;
    v_species monster_species%ROWTYPE;
    v_exp_gain INTEGER;
    v_new_exp INTEGER;
    v_new_level INTEGER;
    v_new_stage INTEGER;
    v_evolved BOOLEAN := FALSE;
    v_cost INTEGER;
BEGIN
    -- Fetch monster
    SELECT * INTO v_monster FROM user_monsters WHERE id = p_monster_id AND user_id = auth.uid();
    IF v_monster.id IS NULL THEN
        RAISE EXCEPTION 'Monster not found';
    END IF;

    -- Fetch species for evolution thresholds
    SELECT * INTO v_species FROM monster_species WHERE id = v_monster.species_id;

    -- Cost: 1 food = 5 coins
    v_cost := p_food_amount * 5;

    -- Check coins
    IF (SELECT coins FROM users WHERE id = auth.uid()) < v_cost THEN
        RAISE EXCEPTION 'Not enough coins';
    END IF;

    -- Deduct coins
    UPDATE users SET coins = coins - v_cost, updated_at = now() WHERE id = auth.uid();

    -- Calculate EXP
    v_exp_gain := p_food_amount * 10;
    v_new_exp := v_monster.exp + v_exp_gain;

    -- Calculate level (100 EXP per level)
    v_new_level := LEAST(1 + (v_new_exp / 100), v_species.max_level);

    -- Check evolution
    v_new_stage := v_monster.stage;
    IF v_monster.stage = 1 AND v_new_level >= v_species.evolve_lv2 THEN
        v_new_stage := 2;
        v_evolved := TRUE;
    ELSIF v_monster.stage = 2 AND v_new_level >= v_species.evolve_lv3 THEN
        v_new_stage := 3;
        v_evolved := TRUE;
    END IF;

    -- Update monster
    UPDATE user_monsters
    SET exp = v_new_exp, level = v_new_level, stage = v_new_stage
    WHERE id = p_monster_id;

    RETURN jsonb_build_object(
        'monster_id', p_monster_id,
        'exp_gained', v_exp_gain,
        'new_exp', v_new_exp,
        'new_level', v_new_level,
        'new_stage', v_new_stage,
        'evolved', v_evolved,
        'coins_spent', v_cost
    );
END;
$$;

-- 5. Gacha pull function
CREATE OR REPLACE FUNCTION pull_gacha(
    p_ticket_type TEXT DEFAULT 'normal'  -- normal, rare_guaranteed, sr_guaranteed
) RETURNS JSONB
SECURITY DEFINER
LANGUAGE plpgsql AS $$
DECLARE
    v_roll FLOAT;
    v_rarity INTEGER;
    v_species monster_species%ROWTYPE;
    v_is_new BOOLEAN;
    v_tickets_cost INTEGER := 1;
    v_user_tickets INTEGER;
BEGIN
    -- Check tickets
    SELECT gacha_tickets INTO v_user_tickets FROM users WHERE id = auth.uid();
    IF v_user_tickets < v_tickets_cost THEN
        RAISE EXCEPTION 'Not enough tickets';
    END IF;

    -- Roll rarity
    v_roll := random();
    IF p_ticket_type = 'sr_guaranteed' THEN
        IF v_roll < 0.20 THEN v_rarity := 4;       -- 20% Legend
        ELSE v_rarity := 3;                          -- 80% SR
        END IF;
    ELSIF p_ticket_type = 'rare_guaranteed' THEN
        IF v_roll < 0.05 THEN v_rarity := 4;        -- 5% Legend
        ELSIF v_roll < 0.25 THEN v_rarity := 3;     -- 20% SR
        ELSE v_rarity := 2;                          -- 75% Rare
        END IF;
    ELSE  -- normal
        IF v_roll < 0.03 THEN v_rarity := 4;        -- 3% Legend
        ELSIF v_roll < 0.15 THEN v_rarity := 3;     -- 12% SR
        ELSIF v_roll < 0.40 THEN v_rarity := 2;     -- 25% Rare
        ELSE v_rarity := 1;                          -- 60% Normal
        END IF;
    END IF;

    -- Pick random species of that rarity
    SELECT * INTO v_species FROM monster_species
    WHERE rarity = v_rarity
    ORDER BY random()
    LIMIT 1;

    -- Fallback to any species if none found at that rarity
    IF v_species.id IS NULL THEN
        SELECT * INTO v_species FROM monster_species ORDER BY random() LIMIT 1;
    END IF;

    -- Check if new
    v_is_new := NOT EXISTS (
        SELECT 1 FROM user_monsters WHERE user_id = auth.uid() AND species_id = v_species.id
    );

    -- Deduct ticket
    UPDATE users SET gacha_tickets = gacha_tickets - v_tickets_cost, updated_at = now() WHERE id = auth.uid();

    -- Add monster to collection
    INSERT INTO user_monsters (user_id, species_id, obtained_via)
    VALUES (auth.uid(), v_species.id, 'gacha');

    -- Log gacha
    INSERT INTO gacha_history (user_id, species_id, rarity, tickets_spent, is_new)
    VALUES (auth.uid(), v_species.id, v_rarity, v_tickets_cost, v_is_new);

    RETURN jsonb_build_object(
        'species_id', v_species.id,
        'name_ja', v_species.name_ja,
        'name_en', v_species.name_en,
        'rarity', v_rarity,
        'category', v_species.category,
        'is_new', v_is_new,
        'stage1_img', v_species.stage1_img
    );
END;
$$;

-- 6. Set buddy function
CREATE OR REPLACE FUNCTION set_buddy_monster(p_monster_id UUID)
RETURNS VOID
SECURITY DEFINER
LANGUAGE plpgsql AS $$
BEGIN
    -- Clear current buddy
    UPDATE user_monsters SET is_buddy = FALSE WHERE user_id = auth.uid() AND is_buddy = TRUE;
    -- Set new buddy
    UPDATE user_monsters SET is_buddy = TRUE WHERE id = p_monster_id AND user_id = auth.uid();
END;
$$;

-- 7. Seed dummy monster species (24 species: 4 per category, mixed rarities)
INSERT INTO monster_species (id, name_ja, name_en, category, rarity, evolve_lv2, evolve_lv3, description_ja, sort_order) VALUES
-- Eiken (英検対策)
('eiken-owl',      'エイケンフクロウ',    'Eiken Owl',       'eiken',   1, 10, 25, '英検の知識を蓄える賢いフクロウ', 1),
('vocab-fox',      'ボキャブラフォックス', 'Vocab Fox',       'eiken',   2, 12, 28, '単語の意味を瞬時に嗅ぎ分ける', 2),
('test-dragon',    'テストドラゴン',      'Test Dragon',     'eiken',   3, 15, 30, '模擬試験の炎を吐く強者', 3),
('eiken-phoenix',  'エイケンフェニックス', 'Eiken Phoenix',   'eiken',   4, 20, 35, '合格の炎で蘇る伝説の鳥', 4),

-- Grammar (文法)
('gram-cat',       'グラマーキャット',    'Grammar Cat',     'grammar', 1, 10, 25, '文法のルールを猫なで声で教える', 5),
('syntax-wolf',    'シンタックスウルフ',   'Syntax Wolf',     'grammar', 2, 12, 28, '文の構造を狼の目で見抜く', 6),
('tense-tiger',    'テンスタイガー',      'Tense Tiger',     'grammar', 3, 15, 30, '時制を操る虎', 7),
('gram-unicorn',   'グラマーユニコーン',   'Grammar Unicorn', 'grammar', 4, 20, 35, '完璧な文法で世界を浄化する', 8),

-- Phonics (フォニックス)
('phon-rabbit',    'フォニクスラビット',   'Phonics Rabbit',  'phonics', 1, 10, 25, '音の違いを長い耳で聞き分ける', 9),
('sound-dolphin',  'サウンドドルフィン',   'Sound Dolphin',   'phonics', 2, 12, 28, '音波で正しい発音を伝える', 10),
('rhyme-eagle',    'ライムイーグル',      'Rhyme Eagle',     'phonics', 3, 15, 30, '韻を踏んで空を舞う', 11),
('phon-dragon',    'フォニクスドラゴン',   'Phonics Dragon',  'phonics', 4, 20, 35, '全ての音を支配する龍', 12),

-- Writing (ライティング)
('write-panda',    'ライトパンダ',        'Write Panda',     'writing', 1, 10, 25, '竹ペンで英文を書く', 13),
('sentence-hawk',  'センテンスホーク',    'Sentence Hawk',   'writing', 2, 12, 28, '文を組み立てる鷹の目', 14),
('essay-lion',     'エッセイライオン',     'Essay Lion',      'writing', 3, 15, 30, '雄弁なエッセイを書く百獣の王', 15),
('write-phoenix',  'ライトフェニックス',   'Write Phoenix',   'writing', 4, 20, 35, 'ペンから炎の文章が生まれる', 16),

-- Mixed (ミックス)
('mix-hamster',    'ミックスハムスター',   'Mix Hamster',     'mixed',  1, 10, 25, '何でもかじって覚える', 17),
('allround-bear',  'オールラウンドベア',   'Allround Bear',   'mixed',  2, 12, 28, '全科目バランス型の熊', 18),
('master-snake',   'マスタースネーク',    'Master Snake',    'mixed',  3, 15, 30, '知恵の蛇が全てを見通す', 19),
('omni-turtle',    'オムニタートル',      'Omni Turtle',     'mixed',  4, 20, 35, '万能の亀、ゆっくり確実に', 20),

-- Special (限定)
('starter-slime',  'スターターすらいむ',   'Starter Slime',   'special', 1, 8, 20, '最初の仲間。小さいけど成長する', 21),
('lucky-cat',      'ラッキーキャット',    'Lucky Cat',       'special', 2, 12, 28, '幸運を呼ぶ招き猫', 22),
('sensei-crane',   'センセイクレーン',    'Sensei Crane',    'special', 3, 15, 30, '先生の知恵を持つ鶴', 23),
('legend-kirin',   'レジェンドキリン',    'Legend Kirin',    'special', 4, 20, 35, '伝説の麒麟。全てを超越する', 24)
ON CONFLICT (id) DO NOTHING;

-- 8. Auto-give starter monster on first student login
CREATE OR REPLACE FUNCTION give_starter_monster()
RETURNS TRIGGER
SECURITY DEFINER
LANGUAGE plpgsql AS $$
BEGIN
    -- Only for students, only if they have no monsters yet
    IF NEW.role = 'student' THEN
        IF NOT EXISTS (SELECT 1 FROM user_monsters WHERE user_id = NEW.id) THEN
            INSERT INTO user_monsters (user_id, species_id, is_buddy, obtained_via)
            VALUES (NEW.id, 'starter-slime', TRUE, 'starter');
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_give_starter_monster ON users;
CREATE TRIGGER trg_give_starter_monster
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION give_starter_monster();
