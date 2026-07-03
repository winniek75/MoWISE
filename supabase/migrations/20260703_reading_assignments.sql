-- Reading assignments: teachers assign books to classes
CREATE TABLE IF NOT EXISTS reading_assignments (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id      UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    book_id       UUID NOT NULL REFERENCES reading_books(id) ON DELETE CASCADE,
    teacher_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    due_date      DATE,
    instructions  TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS reading_assignments_class_idx ON reading_assignments(class_id, created_at DESC);
ALTER TABLE reading_assignments ENABLE ROW LEVEL SECURITY;

-- Teachers can manage their own assignments
CREATE POLICY "reading_assignments_teacher" ON reading_assignments FOR ALL
    USING (auth.uid() = teacher_id);

-- Students can see assignments for their classes
CREATE POLICY "reading_assignments_student_read" ON reading_assignments FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm
        WHERE cm.class_id = reading_assignments.class_id
        AND cm.user_id = auth.uid()
    ));

-- Teachers can view reading_progress of their students
CREATE POLICY "reading_progress_teacher_view" ON reading_progress FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm
        JOIN classes c ON c.id = cm.class_id
        WHERE cm.user_id = reading_progress.user_id
        AND c.teacher_id = auth.uid()
    ));

-- Teachers can view reading_recordings of their students
CREATE POLICY "reading_recordings_teacher_view" ON reading_recordings FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM class_members cm
        JOIN classes c ON c.id = cm.class_id
        WHERE cm.user_id = reading_recordings.user_id
        AND c.teacher_id = auth.uid()
    ));

-- Teachers can access student recording files
CREATE POLICY "recordings_teacher_select" ON storage.objects FOR SELECT
    USING (
        bucket_id = 'recordings'
        AND EXISTS (
            SELECT 1 FROM class_members cm
            JOIN classes c ON c.id = cm.class_id
            WHERE cm.user_id::text = (storage.foldername(name))[1]
            AND c.teacher_id = auth.uid()
        )
    );
