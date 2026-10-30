-- Scratch-database test for progress_rpc.sql. Never run against the real Supabase project.
-- Usage (from the analog_gate folder):
--   psql -h localhost -U postgres -d ag_rpc_test -v ON_ERROR_STOP=1 -f sql_tests/progress_rpc_test.sql
-- Stubs Supabase's roles and auth.uid(), then checks the functions and column grants.

DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN CREATE ROLE anon NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'authenticated') THEN CREATE ROLE authenticated NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'service_role') THEN CREATE ROLE service_role NOLOGIN; END IF;
END $$;

DROP SCHEMA IF EXISTS auth CASCADE;
CREATE SCHEMA auth;
CREATE FUNCTION auth.uid() RETURNS uuid LANGUAGE sql STABLE
  AS $$ SELECT NULLIF(current_setting('test.uid', true), '')::uuid $$;

DROP TABLE IF EXISTS public.profiles, public.missions;
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY,
  username TEXT, avatar_url TEXT,
  total_xp INTEGER NOT NULL DEFAULT 0,
  current_streak INTEGER NOT NULL DEFAULT 0,
  last_active_date DATE,
  today_completed JSONB DEFAULT '[]'::jsonb,
  today_unlocked JSONB DEFAULT '[]'::jsonb,
  week_history JSONB DEFAULT '[false,false,false,false,false,false,false]'::jsonb,
  updated_at TIMESTAMPTZ DEFAULT now()
);
CREATE TABLE public.missions (id TEXT PRIMARY KEY, xp INTEGER NOT NULL);
INSERT INTO public.missions VALUES ('walk_outside', 30), ('basketball', 50), ('find_tree', 20);

-- Supabase gives the API roles full table access by default; the script under test must take it back.
GRANT USAGE ON SCHEMA public, auth TO anon, authenticated, service_role;
GRANT ALL ON public.profiles, public.missions TO anon, authenticated, service_role;
GRANT EXECUTE ON FUNCTION auth.uid() TO PUBLIC;

\i progress_rpc.sql

CREATE FUNCTION pg_temp.check(label TEXT, got TEXT, want TEXT) RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  IF got IS DISTINCT FROM want THEN
    RAISE EXCEPTION 'FAIL %: got % want %', label, got, want;
  END IF;
  RAISE NOTICE 'ok  %', label;
END $$;

CREATE FUNCTION pg_temp.expect_error(label TEXT, stmt TEXT, want_state TEXT) RETURNS void LANGUAGE plpgsql AS $$
DECLARE msg TEXT; st TEXT;
BEGIN
  BEGIN
    EXECUTE stmt;
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS msg = MESSAGE_TEXT, st = RETURNED_SQLSTATE;
    IF st <> want_state THEN
      RAISE EXCEPTION 'FAIL %: got % (%), want %', label, msg, st, want_state;
    END IF;
    RAISE NOTICE 'ok  % (%)', label, msg;
    RETURN;
  END;
  RAISE EXCEPTION 'FAIL %: no error', label;
END $$;

-- User A: a fresh account
SELECT set_config('test.uid', '11111111-1111-1111-1111-111111111111', false);
DO $$ DECLARE r jsonb; BEGIN
  r := public.complete_mission(auth.uid(), 'walk_outside');
  PERFORM pg_temp.check('first mission xp_earned', r->>'xp_earned', '30');
  PERFORM pg_temp.check('first mission streak', r->>'streak', '1');
  PERFORM pg_temp.check('first mission total', r->>'total_xp', '30');
  r := public.complete_mission(auth.uid(), 'walk_outside');
  PERFORM pg_temp.check('repeat is refused', r->>'success', 'false');
  PERFORM pg_temp.check('repeat adds no xp', (SELECT total_xp::text FROM public.profiles WHERE id = auth.uid()), '30');
  r := public.complete_mission(auth.uid(), 'basketball');
  PERFORM pg_temp.check('second mission same day keeps streak', r->>'streak', '1');
  PERFORM pg_temp.check('today list has both', (SELECT jsonb_array_length(today_completed)::text FROM public.profiles WHERE id = auth.uid()), '2');
  PERFORM pg_temp.check('today week slot set', (SELECT count(*)::text FROM jsonb_array_elements((SELECT week_history FROM public.profiles WHERE id = auth.uid())) e WHERE e = 'true'), '1');
END $$;
SELECT pg_temp.expect_error('unknown mission', $q$SELECT public.complete_mission(auth.uid(), 'nope')$q$, 'P0001');

-- Yesterday's activity: streak goes up and the day's list starts over
UPDATE public.profiles SET last_active_date = (now() AT TIME ZONE 'Asia/Bangkok')::date - 1 WHERE id = '11111111-1111-1111-1111-111111111111';
DO $$ DECLARE r jsonb; BEGIN
  r := public.complete_mission(auth.uid(), 'find_tree');
  PERFORM pg_temp.check('next day streak', r->>'streak', '2');
  PERFORM pg_temp.check('next day list reset', (SELECT today_completed::text FROM public.profiles WHERE id = auth.uid()), '["find_tree"]');
  PERFORM pg_temp.check('next day total kept', r->>'total_xp', '120');
END $$;

-- Missed days: streak restarts and the week history clears
UPDATE public.profiles SET last_active_date = (now() AT TIME ZONE 'Asia/Bangkok')::date - 3 WHERE id = '11111111-1111-1111-1111-111111111111';
DO $$ DECLARE r jsonb; BEGIN
  r := public.complete_mission(auth.uid(), 'walk_outside');
  PERFORM pg_temp.check('gap resets streak', r->>'streak', '1');
  PERFORM pg_temp.check('gap clears week to one day', (SELECT count(*)::text FROM jsonb_array_elements((SELECT week_history FROM public.profiles WHERE id = auth.uid())) e WHERE e = 'true'), '1');
END $$;

-- User B: unlocking needs a mission done today
SELECT set_config('test.uid', '22222222-2222-2222-2222-222222222222', false);
SELECT pg_temp.expect_error('unlock before any mission', $q$SELECT public.unlock_app('instagram')$q$, 'P0001');
SELECT public.complete_mission(auth.uid(), 'basketball');
DO $$ DECLARE r jsonb; BEGIN
  r := public.unlock_app('instagram');
  PERFORM pg_temp.check('unlock after mission', r->>'success', 'true');
  PERFORM pg_temp.check('unlock stored', (SELECT today_unlocked::text FROM public.profiles WHERE id = auth.uid()), '["instagram"]');
  r := public.unlock_app('instagram');
  PERFORM pg_temp.check('unlock twice is harmless', r->>'message', 'Already unlocked');
END $$;

-- Client-side access: no direct progress writes and no direct mission completion
SET ROLE authenticated;
SELECT pg_temp.expect_error('client cannot set xp', $q$UPDATE public.profiles SET total_xp = 999 WHERE id = '22222222-2222-2222-2222-222222222222'$q$, '42501');
SELECT pg_temp.expect_error('client cannot set streak', $q$UPDATE public.profiles SET current_streak = 99 WHERE id = '22222222-2222-2222-2222-222222222222'$q$, '42501');
SELECT pg_temp.expect_error('client cannot insert xp', $q$INSERT INTO public.profiles (id, total_xp) VALUES ('33333333-3333-3333-3333-333333333333', 999)$q$, '42501');
SELECT pg_temp.expect_error('authenticated cannot complete mission directly', $q$SELECT public.complete_mission('22222222-2222-2222-2222-222222222222'::uuid, 'walk_outside')$q$, '42501');
UPDATE public.profiles SET username = 'tester' WHERE id = '22222222-2222-2222-2222-222222222222';
RESET ROLE;
SET ROLE anon;
SELECT pg_temp.expect_error('anon cannot complete mission', $q$SELECT public.complete_mission('22222222-2222-2222-2222-222222222222'::uuid, 'walk_outside')$q$, '42501');
RESET ROLE;
SET ROLE service_role;
SELECT public.complete_mission('33333333-3333-3333-3333-333333333333'::uuid, 'find_tree');
RESET ROLE;
DO $$ BEGIN PERFORM pg_temp.check('client can still set username', (SELECT username FROM public.profiles WHERE id = '22222222-2222-2222-2222-222222222222'), 'tester'); END $$;
DO $$ BEGIN PERFORM pg_temp.check('service role completes for given user', (SELECT total_xp::text FROM public.profiles WHERE id = '33333333-3333-3333-3333-333333333333'), '20'); END $$;

SELECT 'ALL PROGRESS RPC TESTS PASSED' AS result;
