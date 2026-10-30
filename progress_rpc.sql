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
