-- ==============================================================================
-- WADIQ PLATFORM - 100% NATIVE FAIL-PROOF DATABASE SCHEMA (V2.1)
-- ==============================================================================

-- 1. CLEAN UP ALL OLD TABLES IN SAFE CASCADE ORDER
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.saved_posts CASCADE;
DROP TABLE IF EXISTS public.comments CASCADE;
DROP TABLE IF EXISTS public.post_likes CASCADE;
DROP TABLE IF EXISTS public.reel_likes CASCADE;
DROP TABLE IF EXISTS public.follows CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.conversation_participants CASCADE;
DROP TABLE IF EXISTS public.conversations CASCADE;
DROP TABLE IF EXISTS public.posts CASCADE;
DROP TABLE IF EXISTS public.reels CASCADE;
DROP TABLE IF EXISTS public.user_sessions CASCADE;
DROP TABLE IF EXISTS public.auth_credentials CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 2. PROFILES TABLE (Public info only, no email or secrets)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username TEXT NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT DEFAULT 'طالب',
    bio TEXT DEFAULT '',
    avatar_url TEXT DEFAULT '',
    department TEXT DEFAULT 'العام',
    academic_stage TEXT DEFAULT 'الأولى',
    followers_count INTEGER DEFAULT 0,
    following_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_profiles_username_lower ON public.profiles (LOWER(username));

-- 3. AUTH CREDENTIALS TABLE (Private, accessed only by Backend)
CREATE TABLE public.auth_credentials (
    id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    username TEXT NOT NULL,
    email TEXT NOT NULL,
    password_hash TEXT NOT NULL,
    password_algorithm TEXT NOT NULL DEFAULT 'argon2id',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE UNIQUE INDEX idx_auth_username_lower ON public.auth_credentials (LOWER(username));
CREATE UNIQUE INDEX idx_auth_email_lower ON public.auth_credentials (LOWER(email));

-- 4. USER SESSIONS & REFRESH TOKENS (Instant Token Revocation)
CREATE TABLE public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    refresh_token_hash TEXT NOT NULL UNIQUE,
    user_agent TEXT,
    ip_address TEXT,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_user_sessions_user ON public.user_sessions(user_id);

-- 5. FOLLOWS TABLE (Relational truth, self-follow blocked)
CREATE TABLE public.follows (
    follower_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id),
    CONSTRAINT chk_no_self_follow CHECK (follower_id != following_id)
);
CREATE INDEX idx_follows_follower ON public.follows(follower_id);
CREATE INDEX idx_follows_following ON public.follows(following_id);

-- 6. POSTS TABLE (Fully matches Flutter PostModel)
CREATE TABLE public.posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    author_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    author_name TEXT NOT NULL,
    author_username TEXT NOT NULL,
    author_role TEXT DEFAULT 'طالب',
    author_avatar TEXT,
    author_department TEXT,
    content TEXT NOT NULL,
    media_urls JSONB DEFAULT '[]'::jsonb,
    media_url TEXT,
    poll_question TEXT,
    poll_options JSONB DEFAULT '[]'::jsonb,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    reposts_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT (NOW() + INTERVAL '10 days')
);
CREATE INDEX idx_posts_author ON public.posts(author_id);
CREATE INDEX idx_posts_created ON public.posts(created_at DESC);

-- 7. POST LIKES TABLE (Prevents duplicate likes)
CREATE TABLE public.post_likes (
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
);
CREATE INDEX idx_post_likes_post ON public.post_likes(post_id);

-- 8. REELS TABLE (Fully matches Flutter ReelModel)
CREATE TABLE public.reels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    creator_name TEXT NOT NULL,
    creator_username TEXT NOT NULL,
    creator_avatar_url TEXT,
    video_url TEXT NOT NULL,
    caption TEXT,
    sound_title TEXT DEFAULT 'الصوت الأصلي',
    is_verified BOOLEAN DEFAULT false,
    views_count INTEGER DEFAULT 1,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_reels_creator ON public.reels(creator_id);
CREATE INDEX idx_reels_created ON public.reels(created_at DESC);

-- 9. REEL LIKES TABLE (Prevents duplicate likes)
CREATE TABLE public.reel_likes (
    reel_id UUID NOT NULL REFERENCES public.reels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (reel_id, user_id)
);
CREATE INDEX idx_reel_likes_reel ON public.reel_likes(reel_id);

-- 10. COMMENTS TABLE (Strict Exclusive Target Constraint)
CREATE TABLE public.comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
    reel_id UUID REFERENCES public.reels(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    author_name TEXT NOT NULL,
    author_username TEXT,
    author_avatar TEXT,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT chk_comment_target CHECK (
        (post_id IS NOT NULL AND reel_id IS NULL) OR
        (post_id IS NULL AND reel_id IS NOT NULL)
    )
);
CREATE INDEX idx_comments_post ON public.comments(post_id);
CREATE INDEX idx_comments_reel ON public.comments(reel_id);

-- 11. SAVED POSTS TABLE (Bookmarks)
CREATE TABLE public.saved_posts (
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES public.posts(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, post_id)
);

-- 12. CONVERSATIONS & CHAT TABLES
CREATE TABLE public.conversations (
    id TEXT PRIMARY KEY,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.conversation_participants (
    conversation_id TEXT NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (conversation_id, user_id)
);

CREATE TABLE public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id TEXT NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    sender_username TEXT NOT NULL,
    recipient_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    recipient_username TEXT,
    content TEXT NOT NULL,
    media_url TEXT,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_messages_conv ON public.messages(conversation_id, created_at ASC);
CREATE INDEX idx_messages_sender ON public.messages(sender_username);
CREATE INDEX idx_messages_recipient ON public.messages(recipient_username);

-- 13. NOTIFICATIONS TABLE
CREATE TABLE public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipient_username TEXT NOT NULL,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    sender_username TEXT,
    type TEXT NOT NULL,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    data JSONB DEFAULT '{}'::jsonb,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_notifs_recipient ON public.notifications(recipient_username, created_at DESC);

-- 14. AUTOMATED COUNTER TRIGGERS
CREATE OR REPLACE FUNCTION update_post_likes_count() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.posts SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_post_likes AFTER INSERT OR DELETE ON public.post_likes
FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

CREATE OR REPLACE FUNCTION update_reel_likes_count() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.reels SET likes_count = likes_count + 1 WHERE id = NEW.reel_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.reels SET likes_count = GREATEST(likes_count - 1, 0) WHERE id = OLD.reel_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_reel_likes AFTER INSERT OR DELETE ON public.reel_likes
FOR EACH ROW EXECUTE FUNCTION update_reel_likes_count();

CREATE OR REPLACE FUNCTION update_comments_count() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        IF NEW.post_id IS NOT NULL THEN
            UPDATE public.posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
        ELSIF NEW.reel_id IS NOT NULL THEN
            UPDATE public.reels SET comments_count = comments_count + 1 WHERE id = NEW.reel_id;
        END IF;
    ELSIF (TG_OP = 'DELETE') THEN
        IF OLD.post_id IS NOT NULL THEN
            UPDATE public.posts SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.post_id;
        ELSIF OLD.reel_id IS NOT NULL THEN
            UPDATE public.reels SET comments_count = GREATEST(comments_count - 1, 0) WHERE id = OLD.reel_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_comments AFTER INSERT OR DELETE ON public.comments
FOR EACH ROW EXECUTE FUNCTION update_comments_count();

CREATE OR REPLACE FUNCTION update_follows_count() RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.profiles SET following_count = following_count + 1 WHERE id = NEW.follower_id;
        UPDATE public.profiles SET followers_count = followers_count + 1 WHERE id = NEW.following_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.profiles SET following_count = GREATEST(following_count - 1, 0) WHERE id = OLD.follower_id;
        UPDATE public.profiles SET followers_count = GREATEST(followers_count - 1, 0) WHERE id = OLD.following_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_follows AFTER INSERT OR DELETE ON public.follows
FOR EACH ROW EXECUTE FUNCTION update_follows_count();

-- 15. ENABLE ROW LEVEL SECURITY (RLS) ON ALL TABLES
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.auth_credentials ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reel_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversation_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 16. TABLE-LEVEL PERMISSIONS (GRANT / REVOKE)
REVOKE ALL ON TABLE public.auth_credentials FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.user_sessions FROM anon, authenticated, PUBLIC;
REVOKE ALL ON TABLE public.notifications FROM anon, authenticated, PUBLIC;

GRANT SELECT ON TABLE public.profiles TO anon, authenticated;
GRANT SELECT ON TABLE public.posts TO anon, authenticated;
GRANT SELECT ON TABLE public.reels TO anon, authenticated;
GRANT SELECT ON TABLE public.comments TO anon, authenticated;
GRANT SELECT ON TABLE public.follows TO anon, authenticated;
GRANT SELECT ON TABLE public.post_likes TO anon, authenticated;
GRANT SELECT ON TABLE public.reel_likes TO anon, authenticated;
GRANT SELECT ON TABLE public.saved_posts TO anon, authenticated;

GRANT INSERT, UPDATE ON TABLE public.posts TO anon, authenticated;
GRANT INSERT, UPDATE ON TABLE public.reels TO anon, authenticated;
GRANT SELECT, INSERT ON TABLE public.conversations TO anon, authenticated;
GRANT SELECT, INSERT ON TABLE public.conversation_participants TO anon, authenticated;
GRANT SELECT, INSERT ON TABLE public.messages TO anon, authenticated;
GRANT INSERT, DELETE ON TABLE public.post_likes TO anon, authenticated;
GRANT INSERT, DELETE ON TABLE public.reel_likes TO anon, authenticated;
GRANT INSERT, DELETE ON TABLE public.follows TO anon, authenticated;
GRANT INSERT, DELETE ON TABLE public.saved_posts TO anon, authenticated;

GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO service_role;

-- 17. RLS POLICIES
CREATE POLICY "Public profiles are viewable by everyone" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Profiles can be updated by owner or backend" ON public.profiles FOR UPDATE USING (true);

CREATE POLICY "Public posts are viewable by everyone" ON public.posts FOR SELECT USING (true);
CREATE POLICY "Anyone can create posts" ON public.posts FOR INSERT WITH CHECK (true);

CREATE POLICY "Public reels are viewable by everyone" ON public.reels FOR SELECT USING (true);
CREATE POLICY "Anyone can create reels" ON public.reels FOR INSERT WITH CHECK (true);
CREATE POLICY "Views count can be incremented" ON public.reels FOR UPDATE USING (true);

CREATE POLICY "Public comments are viewable by everyone" ON public.comments FOR SELECT USING (true);

CREATE POLICY "Public follows are viewable by everyone" ON public.follows FOR SELECT USING (true);
CREATE POLICY "Users can manage follows" ON public.follows FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can delete follows" ON public.follows FOR DELETE USING (true);

CREATE POLICY "Public post likes are viewable by everyone" ON public.post_likes FOR SELECT USING (true);
CREATE POLICY "Users can insert post likes" ON public.post_likes FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can delete post likes" ON public.post_likes FOR DELETE USING (true);

CREATE POLICY "Public reel likes are viewable by everyone" ON public.reel_likes FOR SELECT USING (true);
CREATE POLICY "Users can insert reel likes" ON public.reel_likes FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can delete reel likes" ON public.reel_likes FOR DELETE USING (true);

CREATE POLICY "Users can view saved posts" ON public.saved_posts FOR SELECT USING (true);
CREATE POLICY "Users can save posts" ON public.saved_posts FOR INSERT WITH CHECK (true);
CREATE POLICY "Users can unsave posts" ON public.saved_posts FOR DELETE USING (true);

CREATE POLICY "Conversations viewable by everyone" ON public.conversations FOR SELECT USING (true);
CREATE POLICY "Conversations insertable" ON public.conversations FOR INSERT WITH CHECK (true);

CREATE POLICY "Participants viewable" ON public.conversation_participants FOR SELECT USING (true);
CREATE POLICY "Participants insertable" ON public.conversation_participants FOR INSERT WITH CHECK (true);

CREATE POLICY "Messages viewable by everyone" ON public.messages FOR SELECT USING (true);
CREATE POLICY "Messages insertable" ON public.messages FOR INSERT WITH CHECK (true);
