-- Rename reserved table name user to app_user and adjust constraints
ALTER TABLE IF EXISTS public."user" RENAME TO app_user;

-- Rename sequence if it exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.sequences WHERE sequence_name = 'user_seq') THEN
        ALTER SEQUENCE user_seq RENAME TO app_user_seq;
    END IF;
END $$;

-- Update constraints referencing old table name if needed
-- (PostgreSQL automatically updates most constraints on table rename)

-- Ensure unique constraints exist
ALTER TABLE public.app_user RENAME CONSTRAINT uc_user_email TO uc_app_user_email;
ALTER TABLE public.app_user RENAME CONSTRAINT uc_user_username TO uc_app_user_username;