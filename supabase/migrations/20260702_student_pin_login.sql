-- ============================================================
-- Student PIN Login: Teachers create student accounts with PIN
-- Students login with class_code + PIN (no email required)
-- 2026-07-02
-- ============================================================

-- ========== student_pins: PIN storage per class ==========
CREATE TABLE IF NOT EXISTS student_pins (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id   UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pin        TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (class_id, pin),
    UNIQUE (user_id)
);
CREATE INDEX student_pins_class_idx ON student_pins(class_id);
ALTER TABLE student_pins ENABLE ROW LEVEL SECURITY;

-- Teachers can read PINs for their own classes
CREATE POLICY "teachers_read_pins" ON student_pins FOR SELECT
    USING (EXISTS (
        SELECT 1 FROM classes c WHERE c.id = student_pins.class_id AND c.teacher_id = auth.uid()
    ));

-- Students can read their own PIN
CREATE POLICY "students_read_own_pin" ON student_pins FOR SELECT
    USING (auth.uid() = user_id);

-- ========== create_student_account: RPC function ==========
CREATE OR REPLACE FUNCTION create_student_account(
    p_class_id UUID,
    p_student_name TEXT
) RETURNS JSONB
SECURITY DEFINER
SET search_path = public, auth, extensions
LANGUAGE plpgsql AS $$
DECLARE
    v_pin TEXT;
    v_class_code TEXT;
    v_email TEXT;
    v_password TEXT;
    v_user_id UUID;
    v_teacher_id UUID;
    v_hashed_password TEXT;
BEGIN
    -- 1. Verify caller is the teacher of this class
    SELECT c.class_code, c.teacher_id INTO v_class_code, v_teacher_id
    FROM classes c WHERE c.id = p_class_id;

    IF v_class_code IS NULL THEN
        RAISE EXCEPTION 'Class not found';
    END IF;

    IF v_teacher_id != auth.uid() THEN
        RAISE EXCEPTION 'Unauthorized: not the teacher of this class';
    END IF;

    -- 2. Generate unique 4-digit PIN within the class
    LOOP
        v_pin := lpad(floor(random() * 10000)::text, 4, '0');
        EXIT WHEN NOT EXISTS (
            SELECT 1 FROM student_pins WHERE class_id = p_class_id AND pin = v_pin
        );
    END LOOP;

    -- 3. Create auth user with generated email
    v_user_id := gen_random_uuid();
    v_email := lower(v_class_code) || '-' || v_pin || '@s.mowise.app';
    v_password := v_class_code || v_pin;
    v_hashed_password := crypt(v_password, gen_salt('bf'));

    INSERT INTO auth.users (
        id, instance_id, email, encrypted_password,
        email_confirmed_at, role, aud,
        created_at, updated_at,
        raw_user_meta_data, raw_app_meta_data,
        is_super_admin, confirmation_token
    ) VALUES (
        v_user_id,
        '00000000-0000-0000-0000-000000000000',
        v_email,
        v_hashed_password,
        now(),
        'authenticated',
        'authenticated',
        now(), now(),
        jsonb_build_object('display_name', p_student_name, 'role', 'student'),
        jsonb_build_object('provider', 'email', 'providers', ARRAY['email']),
        false,
        ''
    );

    -- 4. Create identity (required for signInWithPassword)
    INSERT INTO auth.identities (
        id, user_id, provider_id, identity_data, provider,
        last_sign_in_at, created_at, updated_at
    ) VALUES (
        v_user_id,
        v_user_id,
        v_email,
        jsonb_build_object('sub', v_user_id::text, 'email', v_email, 'email_verified', true),
        'email',
        now(), now(), now()
    );

    -- 5. Create public.users row
    INSERT INTO users (id, email, display_name, role)
    VALUES (v_user_id, v_email, p_student_name, 'student');

    -- 6. Add to class as approved member
    INSERT INTO class_members (class_id, user_id, status, approved_by, approved_at)
    VALUES (p_class_id, v_user_id, 'approved', v_teacher_id, now());

    -- 7. Store PIN
    INSERT INTO student_pins (class_id, user_id, pin)
    VALUES (p_class_id, v_user_id, v_pin);

    RETURN jsonb_build_object(
        'user_id', v_user_id,
        'pin', v_pin,
        'class_code', v_class_code,
        'display_name', p_student_name
    );
END;
$$;
