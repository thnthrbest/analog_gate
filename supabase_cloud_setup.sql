-- One-shot setup for a NEW Supabase project. Paste into the SQL Editor and Run once.
-- Contains: database_schema.sql + the signup trigger from database_setup.sql + progress_rpc.sql.
-- Do NOT run sql_tests/ here. Do NOT run missions_setup.sql or progress_setup.sql (they overlap).

-- ==========================================
-- Database Schema for Analog Gate
-- ==========================================

-- 1. Create Profiles Table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT,
    avatar_url TEXT,
    total_xp INTEGER NOT NULL DEFAULT 0,
    current_streak INTEGER NOT NULL DEFAULT 0,
    last_active_date DATE,
    today_completed JSONB DEFAULT '[]'::jsonb,
    today_unlocked JSONB DEFAULT '[]'::jsonb,
    week_history JSONB DEFAULT '[false,false,false,false,false,false,false]'::jsonb,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS total_xp INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS current_streak INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS last_active_date DATE,
  ADD COLUMN IF NOT EXISTS today_completed JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS today_unlocked JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN IF NOT EXISTS week_history JSONB DEFAULT '[false,false,false,false,false,false,false]'::jsonb;

-- Enable RLS for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile" 
    ON public.profiles FOR SELECT 
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" 
    ON public.profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" 
    ON public.profiles FOR UPDATE 
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 2. Create Missions Table
CREATE TABLE IF NOT EXISTS public.missions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    photo_prompt TEXT NOT NULL,
    difficulty TEXT NOT NULL,
    category TEXT NOT NULL,
    xp INTEGER NOT NULL DEFAULT 10,
    duration INTEGER NOT NULL DEFAULT 10,
    ai_labels JSONB DEFAULT '[]'::jsonb,
    icon_name TEXT DEFAULT 'walk',
    color_name TEXT DEFAULT 'accent'
);

-- Enable RLS for missions
ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;

-- Missions Policies (Users can read, but only admins can modify via Supabase dashboard)
DROP POLICY IF EXISTS "Missions are viewable by authenticated users" ON public.missions;
CREATE POLICY "Missions are viewable by authenticated users" 
    ON public.missions FOR SELECT 
    TO authenticated 
    USING (true);

-- 3. Set up Storage for Avatars
-- (Run this if you haven't created the 'avatars' bucket in the dashboard)
INSERT INTO storage.buckets (id, name, public) 
VALUES ('avatars', 'avatars', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policies for Avatars
-- Allow public viewing
DROP POLICY IF EXISTS "Avatar images are publicly accessible" ON storage.objects;
CREATE POLICY "Avatar images are publicly accessible" 
    ON storage.objects FOR SELECT 
    USING (bucket_id = 'avatars');

-- Allow users to upload their own avatar
-- The file name in flutter is formatted as: {user.id}_{timestamp}.{ext}
DROP POLICY IF EXISTS "Users can upload their own avatar" ON storage.objects;
CREATE POLICY "Users can upload their own avatar" 
    ON storage.objects FOR INSERT 
    TO authenticated 
    WITH CHECK (
        bucket_id = 'avatars' AND
        (string_to_array(name, '_'))[1] = auth.uid()::text
    );

-- Allow users to update their own avatar
DROP POLICY IF EXISTS "Users can update their own avatar" ON storage.objects;
CREATE POLICY "Users can update their own avatar" 
    ON storage.objects FOR UPDATE 
    TO authenticated 
    USING (
        bucket_id = 'avatars' AND
        (string_to_array(name, '_'))[1] = auth.uid()::text
    );

-- Allow users to delete their own avatar
DROP POLICY IF EXISTS "Users can delete their own avatar" ON storage.objects;
CREATE POLICY "Users can delete their own avatar" 
    ON storage.objects FOR DELETE 
    TO authenticated 
    USING (
        bucket_id = 'avatars' AND
        (string_to_array(name, '_'))[1] = auth.uid()::text
    );

-- 4. Initial Mission Data Seed (Optional)
INSERT INTO public.missions (id, title, description, photo_prompt, difficulty, category, xp, duration, ai_labels, icon_name, color_name) VALUES
('walk_outside', 'Take a short walk', 'Step outside for at least 5 minutes. Breathe.', 'Take a photo of outdoors — sky, street, park, anything outside.', 'easy', 'outdoor', 30, 5, '["sky","outdoor","nature","tree","plant","grass","road","building","street"]', 'walk', 'accent'),
('find_tree', 'Find a tree or plant', 'Locate something green growing in the real world.', 'Photo of a tree, shrub, flower, or any plant.', 'easy', 'outdoor', 20, 10, '["tree","plant","flower","grass","vegetation","leaf","garden","forest"]', 'tree', 'green'),
('sky_photo', 'Look up at the sky', 'Notice clouds, color, or light. Then photograph it.', 'A photo showing the sky — clouds, sun, stars, or just blue.', 'easy', 'outdoor', 20, 15, '["sky","cloud","atmosphere","daytime","sunset","sunrise","blue sky"]', 'sun', 'amber'),
('basketball', 'Play basketball', 'Shoot some hoops — at least 10 shots.', 'A basketball, hoop, or court in the photo.', 'medium', 'movement', 50, 25, '["basketball","sport","ball","court","hoop","sports equipment"]', 'basketball', 'amber'),
('open_book', 'Open a physical book', 'Real pages. Not a PDF. Spend at least 5 minutes.', 'A photo of an open physical book showing the pages.', 'medium', 'reading', 50, 20, '["book","text","publication","paper","library","paperback"]', 'book', 'amber')
ON CONFLICT (id) DO NOTHING;

-- 6. Trigger to automatically create a profile when a new user signs up
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, username, avatar_url)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'User'),
    new.raw_user_meta_data->>'avatar_url'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ==========================================
-- Progress writes go through server-side functions.
-- Run once in the Supabase SQL Editor (after database_schema.sql).
-- Days are counted in Asia/Bangkok.
-- shortcut: fixed timezone, upgrade to a per-user timezone column when users outside Thailand appear
-- ==========================================

-- 1. Clients may no longer write XP, streak or daily lists directly.
REVOKE INSERT, UPDATE ON public.profiles FROM anon, authenticated;
GRANT INSERT (id, username, avatar_url, updated_at) ON public.profiles TO authenticated;
GRANT UPDATE (username, avatar_url, updated_at) ON public.profiles TO authenticated;

-- 2. Completing a mission: only the verify-photo Edge Function (service_role) calls this,
-- after the photo passed. XP comes from the missions table, not from the caller.
DROP FUNCTION IF EXISTS public.complete_mission(TEXT);
CREATE OR REPLACE FUNCTION public.complete_mission(p_user_id UUID, p_mission_id TEXT)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  uid        UUID := p_user_id;
  today      DATE := (now() AT TIME ZONE 'Asia/Bangkok')::date;
  m_xp       INTEGER;
  p          public.profiles%ROWTYPE;
  v_completed JSONB;
  v_unlocked  JSONB;
  v_streak    INTEGER;
  v_week      JSONB;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

  SELECT xp INTO m_xp FROM public.missions WHERE id = p_mission_id;
  IF m_xp IS NULL THEN RAISE EXCEPTION 'mission not found'; END IF;

  INSERT INTO public.profiles (id) VALUES (uid) ON CONFLICT (id) DO NOTHING;
  SELECT * INTO p FROM public.profiles WHERE id = uid FOR UPDATE;

  -- A new day drops yesterday's lists.
  IF p.last_active_date IS DISTINCT FROM today THEN
    v_completed := '[]'::jsonb;
    v_unlocked  := '[]'::jsonb;
  ELSE
    v_completed := COALESCE(p.today_completed, '[]'::jsonb);
    v_unlocked  := COALESCE(p.today_unlocked, '[]'::jsonb);
  END IF;

  IF v_completed @> jsonb_build_array(p_mission_id) THEN
    RETURN jsonb_build_object('success', false, 'xp_earned', 0,
      'total_xp', COALESCE(p.total_xp, 0), 'streak', COALESCE(p.current_streak, 0),
      'message', 'Mission already completed today');
  END IF;

  IF p.last_active_date = today THEN
    v_streak := COALESCE(p.current_streak, 0);
  ELSIF p.last_active_date = today - 1 THEN
    v_streak := COALESCE(p.current_streak, 0) + 1;
  ELSE
    v_streak := 1;
  END IF;

  -- Missed a day or more: the week history starts over. Index 0 = Sunday, as in the app.
  IF p.last_active_date IS NULL OR p.last_active_date < today - 1 THEN
    v_week := '[false,false,false,false,false,false,false]'::jsonb;
  ELSE
    v_week := COALESCE(p.week_history, '[false,false,false,false,false,false,false]'::jsonb);
  END IF;
  v_week := jsonb_set(v_week, ARRAY[EXTRACT(DOW FROM today)::int::text], 'true');

  UPDATE public.profiles SET
    total_xp         = COALESCE(p.total_xp, 0) + m_xp,
    current_streak   = v_streak,
    last_active_date = today,
    today_completed  = v_completed || jsonb_build_array(p_mission_id),
    today_unlocked   = v_unlocked,
    week_history     = v_week,
    updated_at       = now()
  WHERE id = uid;

  RETURN jsonb_build_object('success', true, 'xp_earned', m_xp,
    'total_xp', COALESCE(p.total_xp, 0) + m_xp, 'streak', v_streak,
    'message', 'Mission complete! +' || m_xp || ' XP');
END;
$$;

-- 3. Unlocking an app: needs at least one mission completed today.
CREATE OR REPLACE FUNCTION public.unlock_app(p_app_id TEXT)
RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  uid         UUID := auth.uid();
  today       DATE := (now() AT TIME ZONE 'Asia/Bangkok')::date;
  p           public.profiles%ROWTYPE;
  v_completed JSONB;
  v_unlocked  JSONB;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'not authenticated'; END IF;

  INSERT INTO public.profiles (id) VALUES (uid) ON CONFLICT (id) DO NOTHING;
  SELECT * INTO p FROM public.profiles WHERE id = uid FOR UPDATE;

  IF p.last_active_date IS DISTINCT FROM today THEN
    v_completed := '[]'::jsonb;
    v_unlocked  := '[]'::jsonb;
  ELSE
    v_completed := COALESCE(p.today_completed, '[]'::jsonb);
    v_unlocked  := COALESCE(p.today_unlocked, '[]'::jsonb);
  END IF;

  IF jsonb_array_length(v_completed) = 0 THEN
    RAISE EXCEPTION 'complete a mission first';
  END IF;

  IF v_unlocked @> jsonb_build_array(p_app_id) THEN
    RETURN jsonb_build_object('success', true, 'message', 'Already unlocked');
  END IF;

  UPDATE public.profiles SET
    today_unlocked = v_unlocked || jsonb_build_array(p_app_id),
    updated_at     = now()
  WHERE id = uid;

  RETURN jsonb_build_object('success', true, 'message', p_app_id || ' unlocked');
END;
$$;

REVOKE ALL ON FUNCTION public.complete_mission(UUID, TEXT) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.complete_mission(UUID, TEXT) TO service_role;
REVOKE ALL ON FUNCTION public.unlock_app(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.unlock_app(TEXT) TO authenticated;
