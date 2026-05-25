-- 1. Create missions table
CREATE TABLE public.missions (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  photo_prompt TEXT NOT NULL,
  difficulty TEXT NOT NULL, -- 'easy', 'medium', 'hard'
  category TEXT NOT NULL, -- 'outdoor', 'reading', 'movement', 'creativity', 'mindfulness'
  xp INTEGER NOT NULL,
  duration INTEGER NOT NULL DEFAULT 10,
  ai_labels JSONB NOT NULL,
  icon_name TEXT NOT NULL, -- 'walk', 'tree', 'sun', 'basketball', etc.
  color_name TEXT NOT NULL -- 'accent', 'green', 'amber', 'teal', 'pink', 'purple'
);

-- 2. Enable RLS
ALTER TABLE public.missions ENABLE ROW LEVEL SECURITY;

-- 3. Public Select Policy (everyone can view missions)
CREATE POLICY "Missions are publicly readable" 
ON public.missions FOR SELECT USING (true);

-- 4. Seed Missions (Original + New Medical Ones)
INSERT INTO public.missions (id, title, description, photo_prompt, difficulty, category, xp, duration, ai_labels, icon_name, color_name) VALUES
-- Original Outdoor
('walk_outside', 'Take a short walk', 'Step outside for at least 5 minutes. Breathe.', 'Take a photo of outdoors — sky, street, park, anything outside.', 'easy', 'outdoor', 30, 5, '["sky","outdoor","nature","tree","plant","grass","road","building","street"]'::jsonb, 'walk', 'accent'),
('find_tree', 'Find a tree or plant', 'Locate something green growing in the real world.', 'Photo of a tree, shrub, flower, or any plant.', 'easy', 'outdoor', 20, 10, '["tree","plant","flower","grass","vegetation","leaf","garden","forest"]'::jsonb, 'tree', 'green'),
('sky_photo', 'Look up at the sky', 'Notice clouds, color, or light. Then photograph it.', 'A photo showing the sky — clouds, sun, stars, or just blue.', 'easy', 'outdoor', 20, 15, '["sky","cloud","atmosphere","daytime","sunset","sunrise"]'::jsonb, 'sun', 'amber'),
('basketball', 'Play basketball', 'Shoot some hoops — at least 10 shots.', 'A basketball, hoop, or court in the photo.', 'medium', 'movement', 50, 25, '["basketball","sport","ball","court","hoop","sports equipment"]'::jsonb, 'basketball', 'amber'),

-- Original Reading
('open_book', 'Open a physical book', 'Real pages. Not a PDF. Spend at least 5 minutes.', 'A photo of an open physical book showing the pages.', 'medium', 'reading', 50, 20, '["book","text","publication","paper","library","paperback"]'::jsonb, 'book', 'amber'),
('newspaper', 'Read a physical newspaper', 'Ink on paper. Notice how slow and satisfying it is.', 'Photo of a printed newspaper or magazine.', 'medium', 'reading', 40, 15, '["newspaper","magazine","publication","text","paper","news"]'::jsonb, 'article', 'teal'),

-- Original Creativity
('draw_something', 'Draw or doodle something', 'Pen and paper. No eraser required. 5 minutes.', 'Photo of your drawing or doodle on paper.', 'medium', 'creativity', 40, 10, '["drawing","sketch","art","paper","pen","pencil","handwriting"]'::jsonb, 'draw', 'pink'),
('write_journal', 'Write 3 sentences in a journal', 'Handwritten. Any 3 sentences about your day or thoughts.', 'Photo of your handwritten journal or notebook.', 'medium', 'creativity', 45, 12, '["handwriting","notebook","paper","text","writing","journal"]'::jsonb, 'edit', 'purple'),

-- Original Mindfulness
('make_tea', 'Make a cup of tea or coffee', 'The slow way. No instant. Notice the process.', 'Photo of your cup of tea or coffee.', 'easy', 'mindfulness', 25, 8, '["cup","coffee","tea","drink","mug","beverage"]'::jsonb, 'coffee', 'amber'),
('stretching', 'Do 5 minutes of stretching', 'Stand up, reach, breathe. Your body will thank you.', 'Photo of your space — mat, floor, or open area.', 'easy', 'movement', 30, 5, '["floor","mat","room","indoor","yoga mat","carpet"]'::jsonb, 'stretch', 'teal'),

-- NEW Medical/Screen-Addiction Breaks
('eye_break_20', '20-20-20 Eye Strain Break', 'Look at something 20 feet away (out of a window) for 20 seconds to relax your eye muscles.', 'Photo of sky or view through a window.', 'easy', 'mindfulness', 15, 1, '["sky","cloud","window","outdoor","nature","tree"]'::jsonb, 'eye', 'purple'),
('posture_stretch', 'Ergonomic Posture Stretch', 'Stand up, roll your shoulders, and look at your feet. Correct your posture from screen slouching.', 'Photo of your feet on the floor, carpet, or mat.', 'easy', 'movement', 20, 2, '["foot","shoes","floor","carpet","tile","ground"]'::jsonb, 'stretch', 'green'),
('hydration_refuel', 'Hydration Refresh Break', 'Step away from your screen to grab and drink a glass of water. Flush out fatigue.', 'Photo of a glass, mug, or bottle of water.', 'easy', 'mindfulness', 15, 2, '["glass","cup","bottle","mug","water","drink","beverage"]'::jsonb, 'water', 'teal'),
('wrist_relief', 'Carpal Tunnel Wrist Relief', 'Extend your arms, pull your fingers back, and stretch your wrists. Counteract scrolling tension.', 'Photo of your hands or palms.', 'easy', 'movement', 15, 3, '["hand","palm","finger","skin"]'::jsonb, 'wrist', 'pink'),
('fresh_air_balcony', 'Balcony Fresh Air Break', 'Walk to the balcony, terrace, or garden. Expose your eyes to natural daylight to regulate cortisol.', 'Photo of outdoor plants, balcony railing, or garden.', 'easy', 'outdoor', 25, 5, '["plant","outdoor","sky","tree","flower","balcony","garden"]'::jsonb, 'walk', 'teal')
ON CONFLICT (id) DO NOTHING;
