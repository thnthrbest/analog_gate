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

-- Enable RLS for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Users can view own profile" 
    ON public.profiles FOR SELECT 
    USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" 
    ON public.profiles FOR INSERT 
    WITH CHECK (auth.uid() = id);

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
CREATE POLICY "Avatar images are publicly accessible" 
    ON storage.objects FOR SELECT 
    USING (bucket_id = 'avatars');

-- Allow users to upload their own avatar
-- The file name in flutter is formatted as: {user.id}_{timestamp}.{ext}
CREATE POLICY "Users can upload their own avatar" 
    ON storage.objects FOR INSERT 
    TO authenticated 
    WITH CHECK (
        bucket_id = 'avatars' AND
        (string_to_array(name, '_'))[1] = auth.uid()::text
    );

-- Allow users to update their own avatar
CREATE POLICY "Users can update their own avatar" 
    ON storage.objects FOR UPDATE 
    TO authenticated 
    USING (
        bucket_id = 'avatars' AND
        (string_to_array(name, '_'))[1] = auth.uid()::text
    );

-- Allow users to delete their own avatar
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
