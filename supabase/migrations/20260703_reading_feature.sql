-- MoWISE Reading: レベル別多読機能 (spec v1.0 §5)
-- ※ 2026-07-03 に本番 (mowisse) へ適用済み。このファイルは記録用。
CREATE TABLE IF NOT EXISTS reading_books (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_no       TEXT NOT NULL UNIQUE CHECK (book_no ~ '^B[0-9]{3}$'),
    level         INTEGER NOT NULL CHECK (level BETWEEN 1 AND 6),
    level_code    TEXT NOT NULL CHECK (level_code IN ('seed','sprout','leaf','branch','tree','summit')),
    title         TEXT NOT NULL,
    title_ja      TEXT NOT NULL DEFAULT '',
    genre         TEXT NOT NULL DEFAULT 'story'
                  CHECK (genre IN ('story','nonfiction','email','article','notice','essay')),
    word_count    INTEGER NOT NULL DEFAULT 0,
    cover_url     TEXT,
    is_free       BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order    INTEGER NOT NULL DEFAULT 0,
    is_published  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS reading_books_level_idx ON reading_books(level, sort_order);
ALTER TABLE reading_books ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_books_select_all" ON reading_books FOR SELECT USING (is_published = TRUE);
CREATE POLICY "reading_books_admin_all"  ON reading_books FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));

CREATE TABLE IF NOT EXISTS reading_pages (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id       UUID NOT NULL REFERENCES reading_books(id) ON DELETE CASCADE,
    page_no       INTEGER NOT NULL,
    body          TEXT NOT NULL,
    image_url     TEXT,
    audio_url     TEXT,
    UNIQUE (book_id, page_no)
);
CREATE INDEX IF NOT EXISTS reading_pages_book_idx ON reading_pages(book_id, page_no);
ALTER TABLE reading_pages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_pages_select_all" ON reading_pages FOR SELECT
    USING (EXISTS (SELECT 1 FROM reading_books b WHERE b.id = book_id AND b.is_published = TRUE));

CREATE TABLE IF NOT EXISTS reading_quizzes (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    book_id       UUID NOT NULL REFERENCES reading_books(id) ON DELETE CASCADE,
    question_no   INTEGER NOT NULL,
    format        TEXT NOT NULL CHECK (format IN
                  ('match_picture','true_false','vocab_mc','cloze_mc','comprehension_mc')),
    question      TEXT NOT NULL,
    choices       JSONB NOT NULL,
    answer_index  INTEGER NOT NULL CHECK (answer_index BETWEEN 0 AND 3),
    explanation_ja TEXT NOT NULL DEFAULT '',
    UNIQUE (book_id, question_no)
);
CREATE INDEX IF NOT EXISTS reading_quizzes_book_idx ON reading_quizzes(book_id, question_no);
ALTER TABLE reading_quizzes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_quizzes_select_all" ON reading_quizzes FOR SELECT
    USING (EXISTS (SELECT 1 FROM reading_books b WHERE b.id = book_id AND b.is_published = TRUE));

CREATE TABLE IF NOT EXISTS reading_progress (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id        UUID NOT NULL REFERENCES reading_books(id) ON DELETE CASCADE,
    status         TEXT NOT NULL DEFAULT 'reading'
                   CHECK (status IN ('reading','read','quiz_done')),
    quiz_score     INTEGER CHECK (quiz_score BETWEEN 0 AND 5),
    quiz_attempts  INTEGER NOT NULL DEFAULT 0,
    listened       BOOLEAN NOT NULL DEFAULT FALSE,
    completed_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, book_id)
);
CREATE INDEX IF NOT EXISTS reading_progress_user_idx ON reading_progress(user_id, updated_at DESC);
ALTER TABLE reading_progress ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_progress_own" ON reading_progress FOR ALL USING (auth.uid() = user_id);

CREATE TABLE IF NOT EXISTS reading_recordings (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    book_id       UUID NOT NULL REFERENCES reading_books(id) ON DELETE CASCADE,
    audio_path     TEXT NOT NULL,
    duration_sec   INTEGER,
    accuracy_score INTEGER CHECK (accuracy_score BETWEEN 0 AND 100),
    score_detail   JSONB,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS reading_recordings_user_idx ON reading_recordings(user_id, created_at DESC);
ALTER TABLE reading_recordings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reading_recordings_own" ON reading_recordings FOR ALL USING (auth.uid() = user_id);

CREATE OR REPLACE FUNCTION reading_add_xp(amount INTEGER)
RETURNS void
LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
  UPDATE users SET total_xp = total_xp + GREATEST(amount, 0), updated_at = now()
  WHERE id = auth.uid();
$$;

INSERT INTO storage.buckets (id, name, public) VALUES ('reading', 'reading', TRUE)
ON CONFLICT (id) DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('recordings', 'recordings', FALSE)
ON CONFLICT (id) DO NOTHING;
CREATE POLICY "recordings_own_insert" ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'recordings' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "recordings_own_select" ON storage.objects FOR SELECT
    USING (bucket_id = 'recordings' AND (storage.foldername(name))[1] = auth.uid()::text);
CREATE POLICY "reading_public_read" ON storage.objects FOR SELECT USING (bucket_id = 'reading');
