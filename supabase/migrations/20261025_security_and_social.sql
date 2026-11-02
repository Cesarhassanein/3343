-- Safe hardening migration for projects that already applied an earlier schema.sql.
-- Review on staging before production. This migration does not drop application data.

-- PostgreSQL rejects volatile functions such as now() in partial-index predicates.
DROP INDEX IF EXISTS public.idx_active_posts;
CREATE INDEX IF NOT EXISTS idx_posts_expires_created ON public.posts (expires_at, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_author_created ON public.posts (author_id, created_at DESC);

ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_reports ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  ALTER TABLE public.moderation_reports ADD CONSTRAINT moderation_reports_target_type_allowed
    CHECK (target_type IN ('post', 'reel', 'message', 'user', 'conversation', 'channel')) NOT VALID;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS is_voice BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE public.messages ADD COLUMN IF NOT EXISTS voice_duration_seconds INT;
-- Older UI versions inserted a text placeholder as a fake voice recording. Do not keep it marked as real audio.
UPDATE public.messages SET is_voice = FALSE, voice_duration_seconds = NULL
WHERE is_voice = TRUE AND media_url IS NULL;
DO $$ BEGIN
  ALTER TABLE public.messages ADD CONSTRAINT messages_voice_requires_media
    CHECK (NOT is_voice OR media_url IS NOT NULL);
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION public.is_conversation_participant(p_conversation_id UUID)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.conversation_participants cp
    WHERE cp.conversation_id = p_conversation_id AND cp.user_id = auth.uid()
  );
$$;
REVOKE ALL ON FUNCTION public.is_conversation_participant(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_conversation_participant(UUID) TO authenticated;

CREATE OR REPLACE FUNCTION public.guard_profile_role()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public
AS $$
DECLARE request_role TEXT := coalesce(current_setting('request.jwt.claim.role', true), '');
BEGIN
  IF TG_OP = 'INSERT' THEN
    IF NEW.role NOT IN ('طالب', 'أستاذ') AND request_role <> 'service_role' THEN
      NEW.role := 'طالب';
    END IF;
  ELSIF NEW.role IS DISTINCT FROM OLD.role AND request_role NOT IN ('service_role', 'postgres') THEN
    RAISE EXCEPTION 'تغيير صلاحية الحساب غير مسموح من التطبيق';
  END IF;
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;
DROP TRIGGER IF EXISTS profiles_guard_role ON public.profiles;
CREATE TRIGGER profiles_guard_role
BEFORE INSERT OR UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.guard_profile_role();
REVOKE UPDATE ON TABLE public.profiles FROM anon, authenticated, PUBLIC;
GRANT UPDATE (username, full_name, avatar_url, bio) ON TABLE public.profiles TO authenticated;

DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can create their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Participants can view conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Participants can view membership" ON public.conversation_participants;
DROP POLICY IF EXISTS "Creator can add initial participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Participants can view messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can insert messages" ON public.messages;
DROP POLICY IF EXISTS "Users can submit reports" ON public.moderation_reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON public.moderation_reports;

CREATE POLICY "Participants can view conversations" ON public.conversations
  FOR SELECT USING (created_by = auth.uid() OR public.is_conversation_participant(id));
CREATE POLICY "Users can create conversations" ON public.conversations
  FOR INSERT WITH CHECK (auth.uid() = created_by);
CREATE POLICY "Participants can view membership" ON public.conversation_participants
  FOR SELECT USING (user_id = auth.uid() OR public.is_conversation_participant(conversation_id));
CREATE POLICY "Creator can add initial participants" ON public.conversation_participants
  FOR INSERT WITH CHECK (EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = conversation_id AND c.created_by = auth.uid()
  ));
CREATE POLICY "Participants can view messages" ON public.messages
  FOR SELECT USING (public.is_conversation_participant(conversation_id));
CREATE POLICY "Participants can insert messages" ON public.messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id AND public.is_conversation_participant(conversation_id));
CREATE POLICY "Users can submit reports" ON public.moderation_reports
  FOR INSERT WITH CHECK (auth.uid() = reported_by);
CREATE POLICY "Users can view their own reports" ON public.moderation_reports
  FOR SELECT USING (auth.uid() = reported_by);

CREATE OR REPLACE FUNCTION public.renew_post(post_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE post_record public.posts%ROWTYPE;
BEGIN
  SELECT * INTO post_record FROM public.posts WHERE id = post_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'المنشور غير موجود أو غير متاح'; END IF;
  IF post_record.author_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'غير مصرح بتجديد هذا المنشور';
  END IF;
  IF post_record.created_at > now() - interval '24 hours' THEN
    RAISE EXCEPTION 'لا يمكن تجديد المنشور قبل مرور 24 ساعة على إنشائه';
  END IF;
  IF post_record.renewed_at IS NOT NULL AND post_record.renewed_at >= now() - interval '24 hours' THEN
    RAISE EXCEPTION 'لا يمكن تجديد المنشور إلا بعد مرور 24 ساعة من آخر تجديد';
  END IF;
  UPDATE public.posts SET expires_at = now() + interval '10 days', renewed_at = now() WHERE id = post_id;
  RETURN true;
END;
$$;
REVOKE ALL ON FUNCTION public.renew_post(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.renew_post(UUID) TO authenticated;
