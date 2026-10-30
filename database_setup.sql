            -- 1. Create profiles table
            CREATE TABLE public.profiles (
              id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
              username TEXT,
              avatar_url TEXT,
              updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
            );

            -- 2. Enable RLS (Row Level Security) for safety
            ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

            -- 3. Create policies so users can only read/edit their own profile
            CREATE POLICY "Users can view own profile" 
            ON public.profiles FOR SELECT USING (auth.uid() = id);

            CREATE POLICY "Users can insert own profile" 
            ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

            CREATE POLICY "Users can update own profile" 
            ON public.profiles FOR UPDATE USING (auth.uid() = id);

            -- 4. Create storage bucket for avatars (handles conflict if already exists)
            INSERT INTO storage.buckets (id, name, public)
            VALUES ('avatars', 'avatars', true)
            ON CONFLICT (id) DO NOTHING;

            -- 5. Storage Policies
            CREATE POLICY "Avatar images are publicly accessible."
            ON storage.objects FOR SELECT USING (bucket_id = 'avatars');

            CREATE POLICY "Users can upload their own avatar."
            ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.uid() = owner);

            CREATE POLICY "Users can update their own avatar."
            ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.uid() = owner);

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

