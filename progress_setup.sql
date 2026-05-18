-- Add progress tracking columns to the existing profiles table
ALTER TABLE public.profiles 
  ADD COLUMN total_xp INTEGER DEFAULT 0,
  ADD COLUMN current_streak INTEGER DEFAULT 0,
  ADD COLUMN last_active_date DATE,
  ADD COLUMN today_completed JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN today_unlocked JSONB DEFAULT '[]'::jsonb,
  ADD COLUMN week_history JSONB DEFAULT '[false,false,false,false,false,false,false]'::jsonb;
