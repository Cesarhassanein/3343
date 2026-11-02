-- Run in the SQL editor against a test/staging Supabase database after schema.sql + migrations.
DO $$
DECLARE index_def TEXT;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname = 'public' AND indexname = 'idx_posts_expires_created'
  ) THEN
    RAISE EXCEPTION 'Expected idx_posts_expires_created index is missing';
  END IF;

  SELECT indexdef INTO index_def FROM pg_indexes
  WHERE schemaname = 'public' AND indexname = 'idx_active_posts';
  IF index_def IS NOT NULL AND position('WHERE' IN upper(index_def)) > 0 THEN
    RAISE EXCEPTION 'Legacy partial index idx_active_posts still exists';
  END IF;

  IF has_column_privilege('authenticated', 'public.profiles', 'role', 'UPDATE') THEN
    RAISE EXCEPTION 'authenticated still has UPDATE privilege on profiles.role';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'profiles'
      AND t.tgname = 'profiles_guard_role' AND NOT t.tgisinternal
  ) THEN
    RAISE EXCEPTION 'profiles_guard_role trigger is missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'is_voice'
  ) OR NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'messages' AND column_name = 'voice_duration_seconds'
  ) THEN
    RAISE EXCEPTION 'Message voice metadata columns are missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'moderation_reports'
      AND policyname = 'Users can submit reports' AND cmd = 'INSERT'
  ) THEN
    RAISE EXCEPTION 'Moderation report insert policy is missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public' AND p.proname = 'is_conversation_participant'
      AND p.prosecdef
  ) THEN
    RAISE EXCEPTION 'Non-recursive SECURITY DEFINER membership helper is missing';
  END IF;
END $$;
