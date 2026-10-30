// Checks a mission photo with an OpenRouter vision model and records the mission
// only when the photo passes. The app never sees the API key.
import { createClient } from 'npm:@supabase/supabase-js@2';
import { encodeBase64 } from 'jsr:@std/encoding@1/base64';

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const AVATAR_PREFIX = `${SUPABASE_URL}/storage/v1/object/public/avatars/`;
const MODEL = Deno.env.get('VERIFY_MODEL') ?? 'google/gemini-2.5-flash';
const MAX_IMAGE_CHARS = 4_000_000; // the app sends 800px JPEGs, about 100-300 KB

Deno.serve(async (req) => {
  if (req.method !== 'POST') return json({ error: 'POST only' }, 405);

  const apiKey = Deno.env.get('OPENROUTER_API_KEY');
  if (!apiKey) return json({ error: 'OPENROUTER_API_KEY is not set' }, 500);

  // Act as the signed-in user: RLS applies to every read below.
  const userDb = createClient(SUPABASE_URL, Deno.env.get('SUPABASE_ANON_KEY')!, {
    global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } },
  });
  const { data: { user } } = await userDb.auth.getUser();
  if (!user) return json({ error: 'sign in first' }, 401);

  const body = await req.json().catch(() => null);
  const missionId = body?.missionId;
  const imageBase64 = body?.imageBase64;
  if (typeof missionId !== 'string' || typeof imageBase64 !== 'string' ||
      imageBase64.length === 0 || imageBase64.length > MAX_IMAGE_CHARS) {
    return json({ error: 'missionId and imageBase64 are required' }, 400);
  }

  // The required object comes from the database, not from the app.
  const { data: mission } = await userDb.from('missions')
    .select('title, ai_labels').eq('id', missionId).maybeSingle();
  if (!mission) return json({ error: 'mission not found' }, 404);
  const labels = Array.isArray(mission.ai_labels) ? mission.ai_labels : [];
  const required = labels.length > 0 ? String(labels[0]) : mission.title;

  // Face match only when the profile avatar is one of our own uploads.
  // Fetching any URL here would let a user point the server at arbitrary hosts.
  const { data: profile } = await userDb.from('profiles')
    .select('avatar_url').eq('id', user.id).maybeSingle();
  let avatarBase64: string | null = null;
  if (profile?.avatar_url?.startsWith(AVATAR_PREFIX)) {
    const res = await fetch(profile.avatar_url);
    if (res.ok) avatarBase64 = encodeBase64(new Uint8Array(await res.arrayBuffer()));
  }

  const parts: unknown[] = [];
  let prompt: string;
  if (avatarBase64) {
    parts.push({ type: 'image_url', image_url: { url: `data:image/jpeg;base64,${avatarBase64}` } });
    prompt = 'Image 1 is the profile photo. Image 2 is the new photo. Answer YES only if BOTH are true: ' +
      `(1) both photos show the same person, (2) Image 2 clearly shows a "${required}". ` +
      'Otherwise answer NO followed by a short reason.';
  } else {
    prompt = `Does this photo clearly show a "${required}"? Answer YES, or NO followed by a short reason.`;
  }
  parts.push({ type: 'image_url', image_url: { url: `data:image/jpeg;base64,${imageBase64}` } });
  parts.push({ type: 'text', text: prompt });

  const aiRes = await fetch('https://openrouter.ai/api/v1/chat/completions', {
    method: 'POST',
    headers: { Authorization: `Bearer ${apiKey}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      model: MODEL,
      temperature: 0,
      max_tokens: 80,
      messages: [{ role: 'user', content: parts }],
    }),
  });
  if (!aiRes.ok) return json({ error: 'verifier unavailable, try again' }, 502);
  const ai = await aiRes.json();
  const answer = String(ai.choices?.[0]?.message?.content ?? '').trim();
  const verified = answer.toUpperCase().startsWith('YES');

  if (!verified) {
    return json({ verified: false, label: required, message: answer || 'Photo did not match.' });
  }

  // Only the service role can complete a mission (see progress_rpc.sql).
  const admin = createClient(SUPABASE_URL, Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!);
  const { data, error } = await admin.rpc('complete_mission', {
    p_user_id: user.id,
    p_mission_id: missionId,
  });
  if (error) return json({ error: 'could not record the mission' }, 500);

  return json({ verified: true, label: required, message: 'Verification Successful!', ...data });
});
