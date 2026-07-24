# Reading Book Image Prompts (NanoBanana)

## Upload Instructions

### Storage Location
Supabase Storage > `reading` bucket (public)

### File Structure
```
reading/
  B001/
    cover.png    (cover image, 512x512 or 1:1)
    p1.png       (page 1 illustration)
    p2.png       (page 2 illustration)
    p3.png       (page 3 illustration)
  B002/
    cover.png
    p1.png
    ...
```

### After Upload: Update DB
Once images are uploaded, run this SQL to set URLs (replace `PROJECT_URL` with `https://nrkhfkxzfaycehaxfdek.supabase.co`):

```sql
-- Example for B001
UPDATE reading_books SET cover_url = 'https://nrkhfkxzfaycehaxfdek.supabase.co/storage/v1/object/public/reading/B001/cover.png' WHERE book_no = 'B001';
UPDATE reading_pages SET image_url = 'https://nrkhfkxzfaycehaxfdek.supabase.co/storage/v1/object/public/reading/B001/p1.png' WHERE book_id = (SELECT id FROM reading_books WHERE book_no='B001') AND page_no = 1;
-- etc.
```

Full update SQL is at the bottom of this file.

---

## Style Guide (All Books)
- Style: Soft, friendly children's book illustration, flat colors, clean lines
- Background: Simple, not too busy
- No text in images
- Format: PNG, 512x512 recommended
- Level 1-3: Cute, kawaii-style, bright colors
- Level 4-6: Slightly more realistic, watercolor or digital painting style

---

## Level 1: Seed (English 5)

### B001 - My Dog Max

**Cover:**
```
A happy brown dog sitting in a green park, wagging its tail, children's book illustration style, soft colors, cute kawaii style, simple background with blue sky
```

**Page 1:** "I have a dog. His name is Max. Max is big and brown."
```
A big friendly brown dog standing next to a small boy, both smiling, simple house in background, children's book illustration, kawaii style, bright cheerful colors
```

**Page 2:** "Max likes to run in the park. He likes to play with me."
```
A brown dog running joyfully in a green park, a boy chasing after him laughing, trees and flowers in background, children's book illustration, kawaii style, dynamic playful scene
```

**Page 3:** "I love Max. Max is my best friend. Good boy, Max!"
```
A boy hugging a big brown dog, both looking happy, hearts floating around them, warm sunset background, children's book illustration, kawaii style, warm cozy feeling
```

---

### B002 - The Red Ball

**Cover:**
```
A bright red ball bouncing in a sunny backyard, children's book illustration, kawaii style, cheerful colors, simple clean design
```

**Page 1:** "I have a red ball. It is round and big."
```
A child holding a large shiny red ball, looking proud, simple yard background with grass and fence, children's book illustration, kawaii style, bright colors
```

**Page 2:** "I throw the ball. My sister catches it. We play in the yard."
```
Two children playing catch with a red ball in a backyard, one throwing one catching, green grass and blue sky, children's book illustration, kawaii style, fun energetic scene
```

**Page 3:** "Oh no! The ball is in the tree. Dad helps us."
```
A red ball stuck in a tall tree, a father reaching up to get it while two children look up hopefully, garden setting, children's book illustration, kawaii style, slightly dramatic but cheerful
```

---

### B003 - I Like Food

**Cover:**
```
A colorful plate of various foods - apple, rice, fish, ice cream - arranged in a fun circle pattern, children's book illustration, kawaii style, bright appetizing colors, food with cute faces
```

**Page 1:** "I like apples. They are sweet and red."
```
A child happily biting into a red apple, basket of shiny red apples nearby, orchard background with apple tree, children's book illustration, kawaii style, fresh bright colors
```

**Page 2:** "I like rice and fish. My mom makes it for dinner."
```
A Japanese mother serving dinner at a table, a bowl of rice and grilled fish on the plate, warm kitchen setting with steam rising, children's book illustration, kawaii style, cozy family scene
```

**Page 3:** "I do not like green peppers. But I like ice cream!"
```
Split scene: left side shows a child making a disgusted face at green peppers, right side shows same child happily eating a colorful ice cream cone, children's book illustration, kawaii style, funny contrast
```

---

## Level 2: Sprout (English 4)

### B004 - A Day at School

**Cover:**
```
A cheerful school building with cherry blossoms, a student with a backpack walking toward it, clock showing 7:00, children's book illustration, bright anime-inspired style
```

**Page 1:** "I wake up at seven. I eat breakfast and walk to school with Yuki."
```
Two students walking together on a path to school, morning sunlight, cherry blossom trees along the road, one carrying a school bag, children's book illustration, anime-inspired, warm morning colors
```

**Page 2:** "We have math and English. I like English because the teacher is funny."
```
A classroom scene with a funny teacher at the blackboard making students laugh, English letters on the board, students at desks smiling, children's book illustration, lively school atmosphere
```

**Page 3:** "At lunch, I eat my bento in the classroom."
```
A student opening a colorful bento box at their desk, showing rice balls, tamagoyaki, and vegetables, other students chatting in background, children's book illustration, cute detailed bento
```

**Page 4:** "School finishes at three thirty. I go to soccer practice."
```
A student in soccer uniform kicking a ball on a school field, afternoon sun, other players in background, school building visible, children's book illustration, energetic sporty scene
```

---

### B005 - The Lost Cat

**Cover:**
```
A small white cat with black spots sitting under a streetlight, looking lost but cute, neighborhood houses in background, children's book illustration, slightly emotional but hopeful
```

**Page 1:** "I found a small cat near my house. It was white with black spots."
```
A child kneeling down discovering a small white cat with black spots near a fence, the cat looks hungry and small, residential street setting, children's book illustration, gentle caring scene
```

**Page 2:** "I gave the cat some milk and fish. It ate everything quickly."
```
A white cat with black spots eagerly eating from a small dish, a child watching with a smile, saucer of milk nearby, kitchen or porch setting, children's book illustration, cute happy cat
```

**Page 3:** "I made posters. I put them around the town."
```
A child putting up a "FOUND CAT" poster on a telephone pole, the poster shows a drawing of a white cat with spots, town street with shops, children's book illustration, determined helpful child
```

**Page 4:** "A girl came to my house. That is my cat Mimi!"
```
A happy girl hugging the white cat with spots, another child smiling beside her, doorway of a house, joyful reunion scene, children's book illustration, warm emotional moment, both children happy
```

---

### B006 - My Family Trip

**Cover:**
```
A family of four looking out an airplane window at a tropical island with blue ocean below, excited expressions, children's book illustration, bright vacation colors, travel adventure feeling
```

**Page 1:** "My family went to Okinawa. We took an airplane."
```
A family sitting in airplane seats, a child pressing face against the window looking at clouds, parents smiling, first flight excitement, children's book illustration, bright sky colors
```

**Page 2:** "The beach was beautiful. The water was blue and warm."
```
Two children playing in crystal blue ocean water at a beautiful white sand beach, tropical sky, palm trees in background, children's book illustration, vibrant tropical colors, summer joy
```

**Page 3:** "We visited an aquarium. I saw dolphins and sharks."
```
A family watching dolphins swimming in a huge aquarium tank, blue light, colorful tropical fish, a shark silhouette in background, children's book illustration, wonder and amazement
```

**Page 4:** "We ate Okinawa soba. It was the best trip!"
```
A happy family sitting at a restaurant table eating bowls of Okinawa soba noodles, tropical decorations on walls, everyone smiling, children's book illustration, warm food scene, satisfaction
```

---

## Level 3: Leaf (English 3)

### B007 - The Magic Garden

**Cover:**
```
A mysterious garden with a glowing golden tree with silver leaves, magical sparkles in the air, a girl silhouette looking up in wonder, fantasy children's book illustration, enchanted atmosphere, purple and gold tones
```

**Page 1:** "Emma moved to a new house. Behind it was an old garden."
```
A girl looking at an overgrown garden with tall grass and broken flower pots, old stone wall, mysterious atmosphere, afternoon light filtering through, children's book illustration, sense of discovery
```

**Page 2:** "She found a strange seed. It was golden and warm."
```
A girl holding a glowing golden seed in her palms, her face lit up with golden light, dirt and garden tools around, children's book illustration, magical moment, warm golden glow
```

**Page 3:** "A tree grew overnight! It had silver leaves and glowing fruits."
```
A magnificent tree with silver shimmering leaves and small glowing blue-green fruits, nighttime garden scene, stars visible, magical sparkles, a girl looking up in amazement, fantasy illustration style
```

**Page 4:** "She could talk to animals! The birds told her stories."
```
A girl sitting on a branch of the silver tree, surrounded by colorful birds who appear to be talking to her, speech-like sparkles between them, magical garden below, fantasy children's book illustration, whimsical
```

---

### B008 - A Letter from Sydney

**Cover:**
```
An airmail envelope with Japanese and Australian stamps, Sydney Opera House sketch visible, a kangaroo sticker, koala sticker, children's book illustration, travel correspondence theme, warm nostalgic colors
```

**Page 1:** "I arrived in Sydney two weeks ago. It is summer here in January!"
```
A Japanese teenage boy standing in front of Sydney Opera House and Harbour Bridge, bright sunshine, wearing summer clothes in January, slightly overwhelmed but excited expression, illustrated travel scene
```

**Page 2:** "I am staying with a host family. I tried meat pie."
```
A Japanese boy sitting at a dining table with an Australian family, a meat pie on his plate, the family smiling warmly, typical Australian home interior, children's book illustration, cultural exchange scene
```

**Page 3:** "I saw a koala at a wildlife park! I also saw kangaroos."
```
A boy taking a photo of a koala in a eucalyptus tree, kangaroos hopping in the background, Australian wildlife park setting with red dirt path, children's book illustration, Australian wildlife adventure
```

**Page 4:** "School starts next week. I am nervous but I will try my best!"
```
A boy in school uniform standing at the gate of an Australian school, slightly nervous expression but determined, diverse students walking past, eucalyptus trees lining the path, children's book illustration, new beginning feeling
```

---

### B009 - Why We Recycle

**Cover:**
```
The Earth held gently in hands, surrounded by recycling symbols, green arrows, plastic bottles transforming into clothes, paper becoming notebooks, children's educational illustration, eco-friendly green and blue colors
```

**Page 1:** "We throw away many things. Most garbage goes to landfills."
```
A split image: top shows various trash items (bottles, paper, food waste), bottom shows a large landfill with garbage trucks, slightly somber but educational tone, infographic-style children's illustration
```

**Page 2:** "Landfills are bad for the environment."
```
A landfill with visible pollution seeping into ground and water, dead plants nearby, grey sky, educational but not too scary, environmental illustration for children, problem visualization
```

**Page 3:** "When we recycle, old materials become new products."
```
A transformation diagram: plastic bottles with arrows becoming a t-shirt, old newspapers becoming fresh notebooks, cans becoming bicycle parts, bright colors, positive educational illustration, circular economy visual
```

**Page 4:** "You can help! Separate your trash. Bring your own bag."
```
A child properly sorting trash into colored bins (blue for plastic, yellow for paper, green for glass), holding a reusable shopping bag, bright positive colors, empowering children's illustration, action-oriented
```

---

## Level 4: Branch (English Pre-2)

### B010 - The Time Capsule

**Cover:**
```
A metal time capsule box half-buried under a blooming cherry tree, old photos and letters visible inside, spring petals falling, nostalgic watercolor style illustration, warm sepia and pink tones
```

**Page 1:** "Her class buried a time capsule under the cherry tree."
```
A group of sixth-grade students gathered around a hole under a cherry tree, placing items into a metal box, school uniform, spring day, watercolor style, nostalgic warm scene
```

**Page 2:** "Sakura wrote a letter to her future self."
```
A twelve-year-old girl writing intently at her desk, pencil in hand, thought bubble showing her imagining her older self, classroom setting, watercolor style, thoughtful intimate moment
```

**Page 3:** "Ten years passed. She was now a university student studying art."
```
A young woman in her twenties at an art studio in Tokyo, paintings on walls, city skyline through window, modern apartment, time-skip illustrated with subtle clock/calendar motif, watercolor style
```

**Page 4:** "Old classmates gathered around the cherry tree."
```
A group of young adults standing around a now much-taller cherry tree in full bloom, some kneeling to dig, laughing and talking, reunion atmosphere, watercolor style, emotional warmth
```

**Page 5:** "Tears filled her eyes. Her younger self would be proud."
```
A young woman reading an old letter with tears of happiness, cherry blossom petals floating around her, soft golden light, watercolor style, deeply emotional moment, beautiful and touching
```

---

### B011 - Living in Finland

**Cover:**
```
A serene Finnish landscape: a red wooden cottage by a lake, northern lights in the sky, pine forest, sauna steam rising, cozy warm light from windows, digital painting style, Nordic atmosphere
```

**Page 1:** "Finland is the happiest country in the world."
```
Happy Finnish people in a bright modern city, smiling faces, clean streets, nature visible between buildings, a happiness meter or world map highlighting Finland, editorial illustration style
```

**Page 2:** "Schools give less homework. Children have more time to play."
```
Finnish children playing outdoors in a forest near their school, building things with sticks, no heavy backpacks, a small modern school building in background, relaxed educational atmosphere, Nordic illustration style
```

**Page 3:** "Finnish people love nature. Families have summer cottages."
```
A Finnish family at a lakeside cottage, someone swimming, someone fishing, a traditional wooden sauna nearby with steam, birch trees, midsummer light, peaceful Nordic landscape painting style
```

**Page 4:** "Sisu means having courage when things are difficult."
```
A person walking determinedly through a snowstorm, warm light visible ahead, concept of inner strength visualized with a subtle glow around the figure, minimalist Nordic illustration, cool blue tones with warm core
```

**Page 5:** "Winters are long and dark, but people stay positive."
```
A cozy Finnish living room in winter, candles glowing, family together, outside window shows snow and darkness, but inside is warm and bright, hygge/cozy atmosphere, Nordic illustration style, contrast of dark outside and warm inside
```

---

### B012 - The Robot Companion

**Cover:**
```
A friendly humanoid robot with soft blue LED eyes sitting next to a 12-year-old boy, both looking at each other, futuristic but warm bedroom setting, sci-fi children's book illustration, 2035 aesthetic, friendly technology
```

**Page 1:** "FutureTech created a robot named AIKO. She could understand emotions."
```
A sleek humanoid robot with a gentle face and soft blue eyes in a modern lab, scientists in background, the robot showing subtle emotional expressions, futuristic 2035 setting, clean sci-fi illustration
```

**Page 2:** "Haruto received AIKO as a birthday present."
```
A boy unwrapping a birthday present revealing the robot AIKO, surprised and amazed expression, birthday decorations, cake with candles, family watching happily, sci-fi meets everyday life illustration
```

**Page 3:** "Haruto told AIKO about his problems at school."
```
A boy sitting on his bed talking to AIKO the robot, looking sad, the robot listening attentively with compassionate expression, dim bedroom lighting, intimate emotional scene, sci-fi illustration with warm tones
```

**Page 4:** "Haruto found the courage to speak up. His teacher helped."
```
A boy talking to a kind teacher at school, AIKO visible as a small figure in his backpack, the teacher listening supportively, classroom after school, problem-solving scene, hopeful atmosphere
```

**Page 5:** "Maybe having a robot friend was not so bad after all."
```
A boy and AIKO robot smiling at each other, the boy also surrounded by human friends now, school hallway setting, balance of technology and human connection, warm optimistic ending, sci-fi children's illustration
```

---

## Level 5: Tree (English 2)

### B013 - The Midnight Library

**Cover:**
```
A magical library at midnight, books floating in the air, golden light emanating from open pages, a girl silhouette in the doorway, old wooden shelves reaching to ceiling, enchanted atmosphere, rich warm-toned digital painting
```

**Page 1:** "At midnight, the old library came alive. Books floated off shelves."
```
Interior of an old library at midnight, books lifting off shelves and floating, pages turning by themselves, warm golden magical light filling the room, dust particles glowing, atmospheric digital painting, wonder and mystery
```

**Page 2:** "Mia discovered the secret by accident one night."
```
A teenage girl peering through a library window at night, her face illuminated by the golden glow from inside, floating books visible through the glass, dark street outside, digital painting, discovery moment
```

**Page 3:** "Mr. Owens the librarian caught her watching."
```
An elderly librarian with kind eyes and glasses holding a finger to his lips in a 'shh' gesture, standing at the library door, warm light behind him, inviting mysterious expression, digital painting style
```

**Page 4:** "Characters stepped out of their pages—pirates, astronauts, princesses."
```
Various literary characters emerging from glowing books: a pirate with a sword, an astronaut floating, a princess in a gown, all semi-transparent and magical, library setting, fantastical digital painting, vibrant and dynamic
```

**Page 5:** "Stories were living things that needed to be read and remembered."
```
Mia sitting in a cozy corner of the magical library, surrounded by story characters who are fading slightly, she reads aloud from a book which glows brighter, metaphor of stories needing readers, emotional atmospheric digital painting
```

---

### B014 - The Psychology of Habits

**Cover:**
```
A human brain made of interconnected gears and pathways, some paths highlighted in gold (good habits) and red (bad habits), clean infographic-style illustration, psychology/science theme, modern editorial design
```

**Page 1:** "Why is it so hard to break bad habits?"
```
A person caught in a loop visualized as a circular path, phone/snacks/couch on the loop, frustrated expression, conceptual illustration of being stuck in a cycle, modern flat editorial style, psychology visualization
```

**Page 2:** "The habit loop: cue, routine, reward."
```
A clear circular diagram showing the three steps: CUE (alarm/trigger icon) -> ROUTINE (action figure) -> REWARD (satisfaction/dopamine icon), connected by arrows, clean infographic style, educational illustration
```

**Page 3:** "Habits cannot be erased. They must be replaced."
```
A visual of someone replacing a snack with a walking shoe on the same trigger pathway, X over old habit, checkmark over new habit, same cue and reward but different routine, clear educational illustration
```

**Page 4:** "It takes 66 days for a new behavior to become automatic."
```
A calendar or timeline showing 66 days, person getting progressively more comfortable with exercise, day 1 struggling vs day 66 doing it easily, progress visualization, motivational editorial illustration
```

**Page 5:** "Design your environment to make good habits easier."
```
A room designed for good habits: book on pillow, fruit on counter, running shoes by door, phone in a drawer, clean organized space that encourages positive behavior, interior design meets psychology illustration
```

---

### B015 - The Exchange Student

**Cover:**
```
A Japanese girl with a suitcase standing at an American high school entrance, cherry blossoms transitioning to autumn maple leaves, cultural bridge visual metaphor, emotional watercolor-digital hybrid style
```

**Page 1:** "Yuki arrived at her host family's home in Portland, Oregon."
```
A Japanese teenage girl standing with luggage in front of a large American suburban house, looking overwhelmed but curious, host family at the door waving, Pacific Northwest trees, cultural contrast illustration
```

**Page 2:** "Her first week was the hardest. She sat alone at lunch."
```
A girl sitting alone at a high school cafeteria table, other students in groups chatting and laughing around her, feeling of isolation, slightly muted colors to show loneliness, emotional school scene illustration
```

**Page 3:** "She joined the art club and met Jamie who loved manga."
```
Two girls at an art table, one Japanese one American, sharing manga drawing techniques, art supplies scattered around, both smiling and engaged, art room setting, cultural connection moment, warm brightening colors
```

**Page 4:** "Yuki's English improved. She made friends and tried the school play."
```
A montage: Yuki chatting with friends in hallway, rehearsing on a stage, eating lunch with a group, transformation from isolated to integrated, progressive improvement shown, warm illustration with growing confidence
```

**Page 5:** "Jamie gave her a farewell drawing—two girls connected by a bridge of paintbrushes."
```
Close-up of a beautiful drawing being gifted: two girls (one Japanese, one American) standing on opposite sides connected by a bridge made entirely of colorful paintbrushes, tears of happiness, farewell party background, deeply emotional artistic illustration
```

---

## Level 6: Summit (TOEIC 850)

### B016 - The Art of Negotiation

**Cover:**
```
Two business professionals at a table with a chess board between them transforming into a handshake, corporate setting with city skyline, sophisticated business illustration, blue and gold professional tones
```

**Page 1:** "Negotiation is essential. Many approach it as battles to be won."
```
Split image: left shows aggressive confrontational negotiation (pointing, red faces), right shows collaborative problem-solving (open hands, whiteboard), contrasting approaches, sophisticated business editorial illustration
```

**Page 2:** "Effective negotiators listen more than they speak."
```
A professional at a meeting table, leaning forward listening intently, ear highlighted/emphasized, speech bubbles from others flowing toward them, question marks floating (asking questions), modern business illustration
```

**Page 3:** "Principled negotiation: separate people from the problem."
```
An abstract visualization of the four principles: figures separated from a puzzle (problem), interests as icebergs (surface vs deep), multiple solution options fanning out, scales of justice (criteria), clean infographic business style
```

**Page 4:** "Cultural awareness in international negotiations."
```
A world map with different negotiation styles illustrated: Japanese businesspeople building relationship over tea, American professionals with efficiency charts, cultural symbols, sophisticated international business illustration
```

**Page 5:** "Preparation: elite negotiators spend 3x longer preparing."
```
A professional at a desk surrounded by research materials, notes, profiles of other party, strategy board, clock showing extended preparation time, chess pieces suggesting strategic thinking, detailed business illustration
```

---

### B017 - Echoes of Tomorrow

**Cover:**
```
A quantum machine glowing with blue-purple energy, streams of data flowing backward through a clock face, a female scientist silhouette, dark laboratory setting, cinematic sci-fi illustration, mysterious and thought-provoking
```

**Page 1:** "Dr. Sato built a device that could send messages to the past."
```
A female Japanese scientist in a lab coat standing before a large humming quantum machine with glowing blue particles, dark high-tech laboratory, screens showing quantum equations, cinematic sci-fi digital painting
```

**Page 2:** "The ethical committee debated. Could changing the past create paradoxes?"
```
A tense meeting room with scientists and ethicists debating, holographic displays showing branching timeline diagrams, concerned expressions, modern institutional setting, sci-fi editorial illustration
```

**Page 3:** "Her first message: a stock market prediction sent five years back."
```
Dr. Sato typing on the quantum machine interface, holographic calendar showing "5 YEARS AGO" with an arrow, stock chart visible on screen, her hands trembling, tense intimate moment, sci-fi thriller illustration
```

**Page 4:** "She pressed send. Nothing visible happened."
```
The machine humming quietly, no dramatic effect, Dr. Sato checking her phone/bank account showing no change, anticlimax visualized, quiet empty lab, existential uncertainty atmosphere, muted sci-fi illustration
```

**Page 5:** "A message from herself, thirty years in the future: Stop."
```
A warning message appearing on the machine screen in red text, Dr. Sato's face illuminated by the red glow, shock and fear in her eyes, cracks/fractures appearing in the air around the machine like shattered glass (reality fractures), dramatic sci-fi climax illustration
```

---

### B018 - Digital Minimalism

**Cover:**
```
A person sitting peacefully reading a physical book in nature, while a stream of digital notifications, apps, and screens flows away from them into the distance, contrast between calm analog and chaotic digital, modern editorial illustration
```

**Page 1:** "The average person checks their phone 96 times per day."
```
A person surrounded by floating notification bubbles, phone screen glowing, zombie-like scrolling posture, the number 96 prominent, urban setting with everyone on phones, critical modern editorial illustration, slightly dystopian
```

**Page 2:** "Digital minimalism: reduce your digital life to what supports your values."
```
A funnel or filter visualization: many apps and digital tools entering the top, only a few meaningful ones passing through to a calm person below, values written as labels on accepted tools, clean conceptual illustration
```

**Page 3:** "Limiting social media reduced loneliness and depression."
```
A before/after split: left shows a person scrolling alone in blue phone-light looking sad, right shows same person outside with friends laughing in warm sunlight, data visualization of 30-min limit, hopeful editorial illustration
```

**Page 4:** "The digital declutter: 30 days without optional technology."
```
A calendar showing 30 days, person progressively engaging in analog activities: reading books, walking in nature, cooking, having face-to-face conversations, rediscovery journey visualization, warm encouraging illustration
```

**Page 5:** "Critics say minimalism is a privilege. The counter: it's optimization."
```
A balanced scale: one side shows "deprivation" (crossed out), other shows "optimization" (highlighted), remote worker using minimal essential tools effectively, nuanced perspective illustration, modern editorial style
```

**Page 6:** "Attention is our scarcest resource. Focus deeply."
```
A person in deep focus at a desk, creating something beautiful (painting/writing), distractions fading away into the background, hourglass showing "attention" as sand, powerful closing image, inspirational editorial illustration, golden focused light
```

---

## DB Update SQL (Run after all images are uploaded)

```sql
-- Covers
UPDATE reading_books SET cover_url = 'https://nrkhfkxzfaycehaxfdek.supabase.co/storage/v1/object/public/reading/' || book_no || '/cover.png' WHERE cover_url IS NULL;

-- Page images (batch update)
UPDATE reading_pages SET image_url = 'https://nrkhfkxzfaycehaxfdek.supabase.co/storage/v1/object/public/reading/' || b.book_no || '/p' || reading_pages.page_no || '.png'
FROM reading_books b WHERE reading_pages.book_id = b.id AND reading_pages.image_url IS NULL;
```
