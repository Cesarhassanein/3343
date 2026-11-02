-- Wadiq / Supabase schema. Apply to a fresh Supabase project.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'طالب',
  avatar_url TEXT,
  bio TEXT,
  followers_count INT NOT NULL DEFAULT 0,
  following_count INT NOT NULL DEFAULT 0,
  likes_count INT NOT NULL DEFAULT 0,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT profiles_role_allowed CHECK (role IN ('طالب', 'أستاذ', 'مشرف', 'موثق'))
);

CREATE TABLE IF NOT EXISTS public.posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  author_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  media_urls TEXT[] NOT NULL DEFAULT '{}',
  tags TEXT[] NOT NULL DEFAULT '{}',
  likes_count INT NOT NULL DEFAULT 0,
  comments_count INT NOT NULL DEFAULT 0,
  reposts_count INT NOT NULL DEFAULT 0,
  is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (now() + interval '10 days'),
  renewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Partial-index predicates must be immutable. Keep a normal index and filter active posts at query time.
CREATE INDEX IF NOT EXISTS idx_posts_expires_created ON public.posts (expires_at, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_author_created ON public.posts (author_id, created_at DESC);

CREATE TABLE IF NOT EXISTS public.reels (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  creator_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  video_url TEXT NOT NULL,
  thumbnail_url TEXT,
  caption TEXT,
  sound_title TEXT NOT NULL DEFAULT 'الصوت الأصلي',
  duration_seconds INT NOT NULL DEFAULT 30,
  likes_count INT NOT NULL DEFAULT 0,
  comments_count INT NOT NULL DEFAULT 0,
  saves_count INT NOT NULL DEFAULT 0,
  shares_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DO $$ BEGIN
  CREATE TYPE public.conversation_type AS ENUM ('direct', 'group', 'channel');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

CREATE TABLE IF NOT EXISTS public.conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  type public.conversation_type NOT NULL DEFAULT 'direct',
  name TEXT,
  avatar_url TEXT,
  description TEXT,
  created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.conversation_participants (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (conversation_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  media_url TEXT,
  is_voice BOOLEAN NOT NULL DEFAULT FALSE,
  voice_duration_seconds INT,
  reactions JSONB NOT NULL DEFAULT '[]'::jsonb,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT messages_voice_requires_media CHECK (NOT is_voice OR media_url IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS public.courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  instructor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  description TEXT,
  progress_percentage INT NOT NULL DEFAULT 0,
  lessons_count INT NOT NULL DEFAULT 0,
  icon_name TEXT NOT NULL DEFAULT 'menu_book',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.moderation_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  reported_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  target_type TEXT NOT NULL CHECK (target_type IN ('post', 'reel', 'message', 'user', 'conversation', 'channel')),
  target_id UUID NOT NULL,
  reason TEXT NOT NULL CHECK (length(trim(reason)) > 0),
  team_assigned TEXT NOT NULL DEFAULT 'Team Ashura',
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
  action_taken TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_messages_conversation_created ON public.messages (conversation_id, created_at);
CREATE INDEX IF NOT EXISTS idx_reports_status_created ON public.moderation_reports (status, created_at DESC);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.moderation_reports ENABLE ROW LEVEL SECURITY;

-- RLS helper avoids a recursive policy querying conversation_participants through its own RLS.
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

-- Prevent client-side privilege escalation through profiles.role.
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

-- Even with RLS, limit which profile columns authenticated users can update.
REVOKE UPDATE ON TABLE public.profiles FROM anon, authenticated, PUBLIC;
GRANT UPDATE (username, full_name, avatar_url, bio) ON TABLE public.profiles TO authenticated;

-- Policies are dropped first to keep this schema safe to re-apply in a dev project.
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
DROP POLICY IF EXISTS "Users can create their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
DROP POLICY IF EXISTS "Active posts are viewable by everyone" ON public.posts;
DROP POLICY IF EXISTS "Users can insert their own posts" ON public.posts;
DROP POLICY IF EXISTS "Authors can update their posts" ON public.posts;
DROP POLICY IF EXISTS "Authors can delete their posts" ON public.posts;
DROP POLICY IF EXISTS "Reels are viewable by everyone" ON public.reels;
DROP POLICY IF EXISTS "Users can insert their own reels" ON public.reels;
DROP POLICY IF EXISTS "Courses are viewable by everyone" ON public.courses;
DROP POLICY IF EXISTS "Participants can view conversations" ON public.conversations;
DROP POLICY IF EXISTS "Users can create conversations" ON public.conversations;
DROP POLICY IF EXISTS "Participants can view membership" ON public.conversation_participants;
DROP POLICY IF EXISTS "Creator can add initial participants" ON public.conversation_participants;
DROP POLICY IF EXISTS "Participants can view messages" ON public.messages;
DROP POLICY IF EXISTS "Participants can insert messages" ON public.messages;
DROP POLICY IF EXISTS "Users can submit reports" ON public.moderation_reports;
DROP POLICY IF EXISTS "Users can view their own reports" ON public.moderation_reports;

CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles
  FOR SELECT USING (true);
CREATE POLICY "Users can create their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "Active posts are viewable by everyone" ON public.posts
  FOR SELECT USING (expires_at > now() OR author_id = auth.uid());
CREATE POLICY "Users can insert their own posts" ON public.posts
  FOR INSERT WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Authors can update their posts" ON public.posts
  FOR UPDATE USING (auth.uid() = author_id) WITH CHECK (auth.uid() = author_id);
CREATE POLICY "Authors can delete their posts" ON public.posts
  FOR DELETE USING (auth.uid() = author_id);

CREATE POLICY "Reels are viewable by everyone" ON public.reels FOR SELECT USING (true);
CREATE POLICY "Users can insert their own reels" ON public.reels FOR INSERT WITH CHECK (auth.uid() = creator_id);
CREATE POLICY "Courses are viewable by everyone" ON public.courses FOR SELECT USING (true);

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
  UPDATE public.posts
  SET expires_at = now() + interval '10 days', renewed_at = now()
  WHERE id = post_id;
  RETURN true;
END;
$$;
REVOKE ALL ON FUNCTION public.renew_post(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.renew_post(UUID) TO authenticated;

-- Supabase Realtime publication membership is checked before adding to avoid duplicate-object errors.
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.posts;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
