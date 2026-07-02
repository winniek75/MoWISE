-- ============================================================
-- Fix game_catalog: rename vocabulary -> eiken, fix grammar titles
-- 2026-07-02
-- Applied manually via Supabase SQL Editor (project: yytxgxlhgotscwztlsqj)
-- ============================================================

-- 1. Remove old constraint, update default, rename vocabulary -> eiken
ALTER TABLE game_catalog DROP CONSTRAINT IF EXISTS game_catalog_category_check;
ALTER TABLE game_catalog ALTER COLUMN category SET DEFAULT 'eiken';
UPDATE game_catalog SET category = 'eiken' WHERE category = 'vocabulary';

-- 3. Fix grammar section titles and descriptions to match actual content
UPDATE game_catalog SET
  title = 'To/Ing Battle',
  title_ja = 'to/ing判別バトル',
  description_ja = 'to不定詞と動名詞(-ing)の使い分けを瞬時に判断'
WHERE id = 'verbform-battle';

UPDATE game_catalog SET
  title = 'Relative Clause & Participle Drill',
  title_ja = '関係詞・分詞ドリル',
  description_ja = '関係代名詞・関係副詞・分詞の108問ドリル（英検3級〜準2級）'
WHERE id = 'grammar-drill';

UPDATE game_catalog SET
  description_ja = '中学1〜3年の文法300問をライブレッスンで出題'
WHERE id = 'grammar-app';

UPDATE game_catalog SET
  title = 'Tense & Passive Drill',
  title_ja = '時制・受動態ドリル',
  description_ja = '現在完了・過去形・受動態の文法問題に挑戦'
WHERE id = 'eiken-grammar-game';

UPDATE game_catalog SET
  title = 'Are/Do Quiz',
  title_ja = 'Are/Do判別クイズ',
  description_ja = 'be動詞(Are)と一般動詞(Do)の疑問文を瞬時に判別'
WHERE id = 'aredo-game';

UPDATE game_catalog SET
  description_ja = '13種類の疑問詞（What/Who/Where等）を画像付きで学習'
WHERE id = 'wh-questiongame';

-- 4. Fix eiken section descriptions to be more descriptive
UPDATE game_catalog SET
  description_ja = '英検5〜3級の語彙問題をアーケード形式で学習'
WHERE id = 'eiken-game';

UPDATE game_catalog SET
  description_ja = '英検5〜2級の英単語が落下！正しい意味を素早く選択'
WHERE id = 'fallingwordbattle';

UPDATE game_catalog SET
  description_ja = '認知科学に基づく語彙インプット（画像・音声・文脈の5段階学習）'
WHERE id = 'flashinput';

UPDATE game_catalog SET
  description_ja = 'リズムに合わせて英検語彙をタップ！ビートシンク型パズル'
WHERE id = 'beat-word-crush';

UPDATE game_catalog SET
  description_ja = 'SNS風チャットで英検の文法200問＋語彙750問に挑戦'
WHERE id = 'eiken-sns-app';

UPDATE game_catalog SET
  description_ja = '英検5〜3級の筆記＋リスニング模擬試験シミュレーター'
WHERE id = 'eiken-challenge';
