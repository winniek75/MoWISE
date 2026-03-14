"""
P001〜P005 の Layer 2・Layer 3 データを pattern_content に INSERT
"""
import os
import json
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

sb = create_client(
    os.environ["VITE_SUPABASE_URL"],
    os.environ["VITE_SUPABASE_SERVICE_ROLE_KEY"]
)

SUPABASE_URL = os.environ["VITE_SUPABASE_URL"]
AUDIO_BASE = f"{SUPABASE_URL}/storage/v1/object/public/mowise-audio/patterns"

rows = []

# =====================================================================
# P001 Layer 2 — slot_fill (6問) + audio_predict (4問)
# =====================================================================

# slot_fill
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 1, "question_type": "slot_fill",
    "display_text": "I'm ___", "context_text": None,
    "choices": json.dumps([
        {"text": "tired", "is_correct": True},
        {"text": "from Japan", "is_correct": True},
        {"text": "sleep", "is_correct": False, "explanation": "「sleeping」にすれば入るよ！"},
        {"text": "go", "is_correct": False, "explanation": "「going」にすれば入るよ！"}
    ]),
    "explanation_ja": None,
    "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 2, "question_type": "slot_fill",
    "display_text": "She's ___", "context_text": None,
    "choices": json.dumps([
        {"text": "a teacher", "is_correct": True},
        {"text": "tall", "is_correct": True},
        {"text": "beautiful", "is_correct": True},
        {"text": "run", "is_correct": False, "explanation": "「She runs.」なら言えるよ！"}
    ]),
    "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 3, "question_type": "slot_fill",
    "display_text": "It's ___", "context_text": None,
    "choices": json.dumps([
        {"text": "hot today", "is_correct": True},
        {"text": "raining", "is_correct": True},
        {"text": "a great idea", "is_correct": True},
        {"text": "rain", "is_correct": False, "explanation": "「It's raining.」なら今雨が降ってるってこと！"}
    ]),
    "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 4, "question_type": "slot_fill",
    "display_text": "___ tired.", "context_text": None,
    "choices": json.dumps([
        {"text": "We're", "is_correct": True},
        {"text": "They're", "is_correct": True},
        {"text": "I'm", "is_correct": False, "explanation": "2人のことを話すとき We're か They're を使うよ！"},
        {"text": "She's", "is_correct": False}
    ]),
    "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 5, "question_type": "slot_fill",
    "display_text": "He's ___ ready.", "context_text": None,
    "choices": json.dumps([
        {"text": "not", "is_correct": True},
        {"text": "no", "is_correct": False, "explanation": "be動詞の否定は not だよ！"},
        {"text": "don't", "is_correct": False}
    ]),
    "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 6, "question_type": "slot_fill",
    "display_text": "You're ___", "context_text": None,
    "choices": json.dumps([
        {"text": "the best", "is_correct": True},
        {"text": "amazing", "is_correct": True},
        {"text": "a good friend", "is_correct": True},
        {"text": "know", "is_correct": False, "explanation": "「You know.」ならOKだけど！"}
    ]),
    "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})

# audio_predict
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 7, "question_type": "audio_predict",
    "display_text": "I'm...", "context_text": None,
    "choices": json.dumps([
        {"text": "tired", "is_correct": True},
        {"text": "Kenji", "is_correct": True},
        {"text": "a student", "is_correct": True},
        {"text": "run", "is_correct": False},
        {"text": "goes", "is_correct": False}
    ]),
    "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 8, "question_type": "audio_predict",
    "display_text": "She's...", "context_text": None,
    "choices": json.dumps([
        {"text": "happy", "is_correct": True},
        {"text": "a nurse", "is_correct": True},
        {"text": "from Canada", "is_correct": True},
        {"text": "cooks", "is_correct": False}
    ]),
    "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 9, "question_type": "audio_predict",
    "display_text": "They're...", "context_text": None,
    "choices": json.dumps([
        {"text": "friends", "is_correct": True},
        {"text": "late", "is_correct": True},
        {"text": "going to the park", "is_correct": True},
        {"text": "there", "is_correct": False, "explanation": "同音異義（「そこに」という意味）"}
    ]),
    "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P001", "layer": 2, "question_order": 10, "question_type": "audio_predict",
    "display_text": "It's...", "context_text": "状況：雲が多い",
    "choices": json.dumps([
        {"text": "cloudy", "is_correct": True},
        {"text": "raining", "is_correct": True},
        {"text": "rain", "is_correct": False},
        {"text": "a cloud", "is_correct": False}
    ]),
    "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})

# =====================================================================
# P001 Layer 3 — tile_select (7問)
# =====================================================================
p001_l3 = [
    (1, "私は疲れています。", "I'm tired.", [
        {"text": "I'm", "is_answer": True, "order": 1},
        {"text": "tired", "is_answer": True, "order": 2},
        {"text": ".", "is_answer": True, "order": 3},
        {"text": "tire", "is_answer": False}
    ]),
    (2, "あなたはすごいです。", "You're amazing.", [
        {"text": "You're", "is_answer": True, "order": 1},
        {"text": "amazing", "is_answer": True, "order": 2},
        {"text": ".", "is_answer": True, "order": 3},
        {"text": "I'm", "is_answer": False}
    ]),
    (3, "彼は私の友達です。", "He's my friend.", [
        {"text": "He's", "is_answer": True, "order": 1},
        {"text": "my", "is_answer": True, "order": 2},
        {"text": "friend", "is_answer": True, "order": 3},
        {"text": ".", "is_answer": True, "order": 4},
        {"text": "She's", "is_answer": False}
    ]),
    (4, "彼女は医者です。", "She's a doctor.", [
        {"text": "She's", "is_answer": True, "order": 1},
        {"text": "a", "is_answer": True, "order": 2},
        {"text": "doctor", "is_answer": True, "order": 3},
        {"text": ".", "is_answer": True, "order": 4},
        {"text": "He's", "is_answer": False}
    ]),
    (5, "今日は暑いです。", "It's hot today.", [
        {"text": "It's", "is_answer": True, "order": 1},
        {"text": "hot", "is_answer": True, "order": 2},
        {"text": "today", "is_answer": True, "order": 3},
        {"text": ".", "is_answer": True, "order": 4},
        {"text": "This's", "is_answer": False}
    ]),
    (6, "私たちは準備OKです。", "We're ready.", [
        {"text": "We're", "is_answer": True, "order": 1},
        {"text": "ready", "is_answer": True, "order": 2},
        {"text": ".", "is_answer": True, "order": 3},
        {"text": "They're", "is_answer": False}
    ]),
    (7, "彼らは遅刻しています。", "They're late.", [
        {"text": "They're", "is_answer": True, "order": 1},
        {"text": "late", "is_answer": True, "order": 2},
        {"text": ".", "is_answer": True, "order": 3},
        {"text": "There's", "is_answer": False}
    ]),
]

for order, prompt_ja, answer, choices in p001_l3:
    rows.append({
        "pattern_no": "P001", "layer": 3, "question_order": order, "question_type": "tile_select",
        "prompt_ja": prompt_ja, "correct_answer": answer,
        "choices": json.dumps(choices),
        "mowi_quote_correct": "でた。", "mowi_quote_wrong": "…なんか変。",
        "time_limit_sec": 8,
        "tts_text_a": answer, "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00,
        "audio_url_main": f"{AUDIO_BASE}/P001/L3/P001_L3_answer_{order}.mp3"
    })

# =====================================================================
# P002 Layer 2 — slot_fill (6問) + audio_predict (4問)
# =====================================================================
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 1, "question_type": "slot_fill",
    "display_text": "This is ___", "choices": json.dumps([
        {"text": "my bag", "is_correct": True},
        {"text": "a pen", "is_correct": True},
        {"text": "am", "is_correct": False, "explanation": "「I am」はOKだけど「This am」とは言わないよ！"}
    ]),
    "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 2, "question_type": "slot_fill",
    "display_text": "This is ___", "choices": json.dumps([
        {"text": "great", "is_correct": True},
        {"text": "an apple", "is_correct": True},
        {"text": "are", "is_correct": False}
    ]),
    "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 3, "question_type": "slot_fill",
    "display_text": "___ is my school.", "choices": json.dumps([
        {"text": "That", "is_correct": True},
        {"text": "This", "is_correct": True},
        {"text": "It", "is_correct": False, "explanation": "指差すときは This/That を使うよ！"}
    ]),
    "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 4, "question_type": "slot_fill",
    "display_text": "This is ___ apple.", "choices": json.dumps([
        {"text": "an", "is_correct": True},
        {"text": "a", "is_correct": False, "explanation": "母音で始まる単語の前は an だよ！"}
    ]),
    "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 5, "question_type": "slot_fill",
    "display_text": "This is my friend, ___", "choices": json.dumps([
        {"text": "Yuki", "is_correct": True},
        {"text": "Taro", "is_correct": True},
        {"text": "a Yuki", "is_correct": False, "explanation": "人の名前の前に a はつけないよ！"}
    ]),
    "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 6, "question_type": "slot_fill",
    "display_text": "This is ___ amazing idea.", "choices": json.dumps([
        {"text": "an", "is_correct": True},
        {"text": "a", "is_correct": False, "explanation": "amazing は母音(a)で始まるから an だよ！"}
    ]),
    "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
# P002 audio_predict
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 7, "question_type": "audio_predict",
    "display_text": "This is...", "choices": json.dumps([
        {"text": "my bag", "is_correct": True},
        {"text": "great", "is_correct": True},
        {"text": "runs", "is_correct": False}
    ]),
    "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 8, "question_type": "audio_predict",
    "display_text": "This is a...", "choices": json.dumps([
        {"text": "pen", "is_correct": True},
        {"text": "book", "is_correct": True},
        {"text": "apple", "is_correct": False, "explanation": "apple の前は a ではなく an だよ！"}
    ]),
    "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 9, "question_type": "audio_predict",
    "display_text": "That is...", "choices": json.dumps([
        {"text": "my school", "is_correct": True},
        {"text": "his house", "is_correct": True},
        {"text": "go", "is_correct": False}
    ]),
    "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})
rows.append({
    "pattern_no": "P002", "layer": 2, "question_order": 10, "question_type": "audio_predict",
    "display_text": "This is an...", "choices": json.dumps([
        {"text": "amazing idea", "is_correct": True},
        {"text": "apple", "is_correct": True},
        {"text": "pen", "is_correct": False, "explanation": "pen は子音で始まるから a pen だよ！"}
    ]),
    "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。",
    "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00
})

# P002 Layer 3
p002_l3 = [
    (1, "これは私のカバンです。", "This is my bag.", [
        {"text": "This", "is_answer": True, "order": 1}, {"text": "is", "is_answer": True, "order": 2},
        {"text": "my", "is_answer": True, "order": 3}, {"text": "bag", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "are", "is_answer": False}
    ]),
    (2, "これはすごい！", "This is great!", [
        {"text": "This", "is_answer": True, "order": 1}, {"text": "is", "is_answer": True, "order": 2},
        {"text": "great", "is_answer": True, "order": 3}, {"text": "!", "is_answer": True, "order": 4},
        {"text": "That", "is_answer": False}
    ]),
    (3, "これはペンです。", "This is a pen.", [
        {"text": "This", "is_answer": True, "order": 1}, {"text": "is", "is_answer": True, "order": 2},
        {"text": "a", "is_answer": True, "order": 3}, {"text": "pen", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "an", "is_answer": False}
    ]),
    (4, "これはリンゴです。", "This is an apple.", [
        {"text": "This", "is_answer": True, "order": 1}, {"text": "is", "is_answer": True, "order": 2},
        {"text": "an", "is_answer": True, "order": 3}, {"text": "apple", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "a", "is_answer": False}
    ]),
    (5, "こちらは私の友達のユキです。", "This is my friend, Yuki.", [
        {"text": "This", "is_answer": True, "order": 1}, {"text": "is", "is_answer": True, "order": 2},
        {"text": "my", "is_answer": True, "order": 3}, {"text": "friend,", "is_answer": True, "order": 4},
        {"text": "Yuki", "is_answer": True, "order": 5}, {"text": ".", "is_answer": True, "order": 6},
        {"text": "your", "is_answer": False}
    ]),
    (6, "あれは私の学校です。", "That is my school.", [
        {"text": "That", "is_answer": True, "order": 1}, {"text": "is", "is_answer": True, "order": 2},
        {"text": "my", "is_answer": True, "order": 3}, {"text": "school", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "This", "is_answer": False}
    ]),
    (7, "これはすばらしいアイデアです。", "This is an amazing idea.", [
        {"text": "This", "is_answer": True, "order": 1}, {"text": "is", "is_answer": True, "order": 2},
        {"text": "an", "is_answer": True, "order": 3}, {"text": "amazing", "is_answer": True, "order": 4},
        {"text": "idea", "is_answer": True, "order": 5}, {"text": ".", "is_answer": True, "order": 6},
        {"text": "a", "is_answer": False}
    ]),
]
for order, prompt_ja, answer, choices in p002_l3:
    rows.append({
        "pattern_no": "P002", "layer": 3, "question_order": order, "question_type": "tile_select",
        "prompt_ja": prompt_ja, "correct_answer": answer,
        "choices": json.dumps(choices),
        "mowi_quote_correct": "でた。", "mowi_quote_wrong": "…なんか変。",
        "time_limit_sec": 8, "tts_text_a": answer,
        "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00,
        "audio_url_main": f"{AUDIO_BASE}/P002/L3/P002_L3_answer_{order}.mp3"
    })

# =====================================================================
# P003 Layer 2 — slot_fill (6問) + audio_predict (4問)
# =====================================================================
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 1, "question_type": "slot_fill",
    "display_text": "I like ___", "choices": json.dumps([
        {"text": "soccer", "is_correct": True}, {"text": "music", "is_correct": True},
        {"text": "liking", "is_correct": False, "explanation": "like の後にもう一度 liking は不要！"}
    ]), "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 2, "question_type": "slot_fill",
    "display_text": "I like ___ sushi.", "choices": json.dumps([
        {"text": "eating", "is_correct": True}, {"text": "eat", "is_correct": False, "explanation": "like の後の動詞は -ing 形にするよ！"}
    ]), "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 3, "question_type": "slot_fill",
    "display_text": "I like watching ___", "choices": json.dumps([
        {"text": "movies", "is_correct": True}, {"text": "anime", "is_correct": True},
        {"text": "watch", "is_correct": False}
    ]), "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 4, "question_type": "slot_fill",
    "display_text": "I ___ like spicy food.", "choices": json.dumps([
        {"text": "don't", "is_correct": True}, {"text": "not", "is_correct": False, "explanation": "一般動詞の否定は don't を使うよ！"}
    ]), "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 5, "question_type": "slot_fill",
    "display_text": "___ you like music?", "choices": json.dumps([
        {"text": "Do", "is_correct": True}, {"text": "Are", "is_correct": False, "explanation": "like は一般動詞だから Do を使うよ！"}
    ]), "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 6, "question_type": "slot_fill",
    "display_text": "I don't like ___ up early.", "choices": json.dumps([
        {"text": "waking", "is_correct": True}, {"text": "wake", "is_correct": False, "explanation": "like の後は -ing 形！"}
    ]), "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
# P003 audio_predict
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 7, "question_type": "audio_predict",
    "display_text": "I like...", "choices": json.dumps([
        {"text": "soccer", "is_correct": True}, {"text": "your idea", "is_correct": True}, {"text": "likes", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 8, "question_type": "audio_predict",
    "display_text": "I like eating...", "choices": json.dumps([
        {"text": "sushi", "is_correct": True}, {"text": "pizza", "is_correct": True}, {"text": "eat", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 9, "question_type": "audio_predict",
    "display_text": "I don't like...", "choices": json.dumps([
        {"text": "spicy food", "is_correct": True}, {"text": "waking up early", "is_correct": True}, {"text": "don't", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P003", "layer": 2, "question_order": 10, "question_type": "audio_predict",
    "display_text": "Do you like...?", "choices": json.dumps([
        {"text": "music", "is_correct": True}, {"text": "reading", "is_correct": True}, {"text": "likes", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})

# P003 Layer 3
p003_l3 = [
    (1, "私はサッカーが好きです。", "I like soccer.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "like", "is_answer": True, "order": 2},
        {"text": "soccer", "is_answer": True, "order": 3}, {"text": ".", "is_answer": True, "order": 4},
        {"text": "likes", "is_answer": False}
    ]),
    (2, "私はお寿司を食べるのが好きです。", "I like eating sushi.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "like", "is_answer": True, "order": 2},
        {"text": "eating", "is_answer": True, "order": 3}, {"text": "sushi", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "eat", "is_answer": False}
    ]),
    (3, "私は映画を見るのが好きです。", "I like watching movies.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "like", "is_answer": True, "order": 2},
        {"text": "watching", "is_answer": True, "order": 3}, {"text": "movies", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "watch", "is_answer": False}
    ]),
    (4, "あなたのアイデアが好きです。", "I like your idea.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "like", "is_answer": True, "order": 2},
        {"text": "your", "is_answer": True, "order": 3}, {"text": "idea", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "my", "is_answer": False}
    ]),
    (5, "辛い食べ物が好きではありません。", "I don't like spicy food.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "don't", "is_answer": True, "order": 2},
        {"text": "like", "is_answer": True, "order": 3}, {"text": "spicy", "is_answer": True, "order": 4},
        {"text": "food", "is_answer": True, "order": 5}, {"text": ".", "is_answer": True, "order": 6},
        {"text": "not", "is_answer": False}
    ]),
    (6, "音楽は好きですか？", "Do you like music?", [
        {"text": "Do", "is_answer": True, "order": 1}, {"text": "you", "is_answer": True, "order": 2},
        {"text": "like", "is_answer": True, "order": 3}, {"text": "music", "is_answer": True, "order": 4},
        {"text": "?", "is_answer": True, "order": 5}, {"text": "Are", "is_answer": False}
    ]),
    (7, "早起きが好きではありません。", "I don't like waking up early.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "don't", "is_answer": True, "order": 2},
        {"text": "like", "is_answer": True, "order": 3}, {"text": "waking", "is_answer": True, "order": 4},
        {"text": "up", "is_answer": True, "order": 5}, {"text": "early", "is_answer": True, "order": 6},
        {"text": ".", "is_answer": True, "order": 7}, {"text": "wake", "is_answer": False}
    ]),
]
for order, prompt_ja, answer, choices in p003_l3:
    rows.append({
        "pattern_no": "P003", "layer": 3, "question_order": order, "question_type": "tile_select",
        "prompt_ja": prompt_ja, "correct_answer": answer, "choices": json.dumps(choices),
        "mowi_quote_correct": "でた。", "mowi_quote_wrong": "…なんか変。",
        "time_limit_sec": 8, "tts_text_a": answer, "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00,
        "audio_url_main": f"{AUDIO_BASE}/P003/L3/P003_L3_answer_{order}.mp3"
    })

# =====================================================================
# P004 Layer 2 + Layer 3
# =====================================================================
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 1, "question_type": "slot_fill",
    "display_text": "I want ___", "choices": json.dumps([
        {"text": "water", "is_correct": True}, {"text": "a new bag", "is_correct": True},
        {"text": "wanting", "is_correct": False}
    ]), "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 2, "question_type": "slot_fill",
    "display_text": "I want to ___", "choices": json.dumps([
        {"text": "go home", "is_correct": True}, {"text": "eat ramen", "is_correct": True},
        {"text": "going", "is_correct": False, "explanation": "want to の後は原形だよ！"}
    ]), "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 3, "question_type": "slot_fill",
    "display_text": "I ___ want it.", "choices": json.dumps([
        {"text": "don't", "is_correct": True}, {"text": "not", "is_correct": False, "explanation": "一般動詞の否定は don't！"}
    ]), "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 4, "question_type": "slot_fill",
    "display_text": "I don't want to ___ late.", "choices": json.dumps([
        {"text": "be", "is_correct": True}, {"text": "being", "is_correct": False, "explanation": "want to の後は原形！"}
    ]), "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 5, "question_type": "slot_fill",
    "display_text": "___ you want to eat something?", "choices": json.dumps([
        {"text": "Do", "is_correct": True}, {"text": "Are", "is_correct": False}
    ]), "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 6, "question_type": "slot_fill",
    "display_text": "I want ___ new bag.", "choices": json.dumps([
        {"text": "a", "is_correct": True}, {"text": "the", "is_correct": False, "explanation": "初めて話題に出すものには a を使うよ！"}
    ]), "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
# P004 audio_predict
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 7, "question_type": "audio_predict",
    "display_text": "I want...", "choices": json.dumps([
        {"text": "water", "is_correct": True}, {"text": "a new bag", "is_correct": True}, {"text": "wants", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 8, "question_type": "audio_predict",
    "display_text": "I want to...", "choices": json.dumps([
        {"text": "go home", "is_correct": True}, {"text": "eat ramen", "is_correct": True}, {"text": "going", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 9, "question_type": "audio_predict",
    "display_text": "I don't want...", "choices": json.dumps([
        {"text": "it", "is_correct": True}, {"text": "to be late", "is_correct": True}, {"text": "don't", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P004", "layer": 2, "question_order": 10, "question_type": "audio_predict",
    "display_text": "Do you want to...?", "choices": json.dumps([
        {"text": "eat something", "is_correct": True}, {"text": "go out", "is_correct": True}, {"text": "wanting", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})

# P004 Layer 3
p004_l3 = [
    (1, "水がほしいです。", "I want water.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "want", "is_answer": True, "order": 2},
        {"text": "water", "is_answer": True, "order": 3}, {"text": ".", "is_answer": True, "order": 4},
        {"text": "wants", "is_answer": False}
    ]),
    (2, "家に帰りたいです。", "I want to go home.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "want", "is_answer": True, "order": 2},
        {"text": "to", "is_answer": True, "order": 3}, {"text": "go", "is_answer": True, "order": 4},
        {"text": "home", "is_answer": True, "order": 5}, {"text": ".", "is_answer": True, "order": 6},
        {"text": "going", "is_answer": False}
    ]),
    (3, "新しいカバンがほしいです。", "I want a new bag.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "want", "is_answer": True, "order": 2},
        {"text": "a", "is_answer": True, "order": 3}, {"text": "new", "is_answer": True, "order": 4},
        {"text": "bag", "is_answer": True, "order": 5}, {"text": ".", "is_answer": True, "order": 6},
        {"text": "the", "is_answer": False}
    ]),
    (4, "ラーメンが食べたいです。", "I want to eat ramen.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "want", "is_answer": True, "order": 2},
        {"text": "to", "is_answer": True, "order": 3}, {"text": "eat", "is_answer": True, "order": 4},
        {"text": "ramen", "is_answer": True, "order": 5}, {"text": ".", "is_answer": True, "order": 6},
        {"text": "eating", "is_answer": False}
    ]),
    (5, "いりません。", "I don't want it.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "don't", "is_answer": True, "order": 2},
        {"text": "want", "is_answer": True, "order": 3}, {"text": "it", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "not", "is_answer": False}
    ]),
    (6, "遅刻したくないです。", "I don't want to be late.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "don't", "is_answer": True, "order": 2},
        {"text": "want", "is_answer": True, "order": 3}, {"text": "to", "is_answer": True, "order": 4},
        {"text": "be", "is_answer": True, "order": 5}, {"text": "late", "is_answer": True, "order": 6},
        {"text": ".", "is_answer": True, "order": 7}, {"text": "being", "is_answer": False}
    ]),
    (7, "何か食べたいですか？", "Do you want to eat something?", [
        {"text": "Do", "is_answer": True, "order": 1}, {"text": "you", "is_answer": True, "order": 2},
        {"text": "want", "is_answer": True, "order": 3}, {"text": "to", "is_answer": True, "order": 4},
        {"text": "eat", "is_answer": True, "order": 5}, {"text": "something", "is_answer": True, "order": 6},
        {"text": "?", "is_answer": True, "order": 7}, {"text": "Are", "is_answer": False}
    ]),
]
for order, prompt_ja, answer, choices in p004_l3:
    rows.append({
        "pattern_no": "P004", "layer": 3, "question_order": order, "question_type": "tile_select",
        "prompt_ja": prompt_ja, "correct_answer": answer, "choices": json.dumps(choices),
        "mowi_quote_correct": "でた。", "mowi_quote_wrong": "…なんか変。",
        "time_limit_sec": 8, "tts_text_a": answer, "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00,
        "audio_url_main": f"{AUDIO_BASE}/P004/L3/P004_L3_answer_{order}.mp3"
    })

# =====================================================================
# P005 Layer 2 + Layer 3
# =====================================================================
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 1, "question_type": "slot_fill",
    "display_text": "I have ___", "choices": json.dumps([
        {"text": "a question", "is_correct": True}, {"text": "two brothers", "is_correct": True},
        {"text": "having", "is_correct": False}
    ]), "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 2, "question_type": "slot_fill",
    "display_text": "I have ___ headache.", "choices": json.dumps([
        {"text": "a", "is_correct": True}, {"text": "the", "is_correct": False, "explanation": "初めて話すときは a だよ！"}
    ]), "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 3, "question_type": "slot_fill",
    "display_text": "I have ___ reservation.", "choices": json.dumps([
        {"text": "a", "is_correct": True}, {"text": "an", "is_correct": False, "explanation": "reservation は子音で始まるよ！"}
    ]), "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 4, "question_type": "slot_fill",
    "display_text": "I ___ have any money.", "choices": json.dumps([
        {"text": "don't", "is_correct": True}, {"text": "not", "is_correct": False, "explanation": "一般動詞の否定は don't！"}
    ]), "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 5, "question_type": "slot_fill",
    "display_text": "___ you have time?", "choices": json.dumps([
        {"text": "Do", "is_correct": True}, {"text": "Are", "is_correct": False}
    ]), "mowi_quote_correct": "並びが見えてきた", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 6, "question_type": "slot_fill",
    "display_text": "I have a good ___", "choices": json.dumps([
        {"text": "idea", "is_correct": True}, {"text": "friend", "is_correct": True},
        {"text": "an idea", "is_correct": False, "explanation": "a good の後に直接名詞が来るよ！"}
    ]), "mowi_quote_correct": "その感じ。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
# P005 audio_predict
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 7, "question_type": "audio_predict",
    "display_text": "I have...", "choices": json.dumps([
        {"text": "a question", "is_correct": True}, {"text": "two brothers", "is_correct": True}, {"text": "has", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 8, "question_type": "audio_predict",
    "display_text": "I have a...", "choices": json.dumps([
        {"text": "headache", "is_correct": True}, {"text": "reservation", "is_correct": True}, {"text": "an idea", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 9, "question_type": "audio_predict",
    "display_text": "I don't have...", "choices": json.dumps([
        {"text": "any money", "is_correct": True}, {"text": "time", "is_correct": True}, {"text": "don't", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})
rows.append({"pattern_no": "P005", "layer": 2, "question_order": 10, "question_type": "audio_predict",
    "display_text": "Do you have...?", "choices": json.dumps([
        {"text": "time", "is_correct": True}, {"text": "a pen", "is_correct": True}, {"text": "having", "is_correct": False}
    ]), "mowi_quote_correct": "感覚が通ってきた。", "mowi_quote_wrong": "…なんか変。", "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00})

# P005 Layer 3
p005_l3 = [
    (1, "質問があります。", "I have a question.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "have", "is_answer": True, "order": 2},
        {"text": "a", "is_answer": True, "order": 3}, {"text": "question", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "has", "is_answer": False}
    ]),
    (2, "兄弟が二人います。", "I have two brothers.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "have", "is_answer": True, "order": 2},
        {"text": "two", "is_answer": True, "order": 3}, {"text": "brothers", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "brother", "is_answer": False}
    ]),
    (3, "頭痛がします。", "I have a headache.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "have", "is_answer": True, "order": 2},
        {"text": "a", "is_answer": True, "order": 3}, {"text": "headache", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "head", "is_answer": False}
    ]),
    (4, "予約があります。", "I have a reservation.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "have", "is_answer": True, "order": 2},
        {"text": "a", "is_answer": True, "order": 3}, {"text": "reservation", "is_answer": True, "order": 4},
        {"text": ".", "is_answer": True, "order": 5}, {"text": "an", "is_answer": False}
    ]),
    (5, "お金がありません。", "I don't have any money.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "don't", "is_answer": True, "order": 2},
        {"text": "have", "is_answer": True, "order": 3}, {"text": "any", "is_answer": True, "order": 4},
        {"text": "money", "is_answer": True, "order": 5}, {"text": ".", "is_answer": True, "order": 6},
        {"text": "not", "is_answer": False}
    ]),
    (6, "時間ありますか？", "Do you have time?", [
        {"text": "Do", "is_answer": True, "order": 1}, {"text": "you", "is_answer": True, "order": 2},
        {"text": "have", "is_answer": True, "order": 3}, {"text": "time", "is_answer": True, "order": 4},
        {"text": "?", "is_answer": True, "order": 5}, {"text": "Are", "is_answer": False}
    ]),
    (7, "良いアイデアがあります。", "I have a good idea.", [
        {"text": "I", "is_answer": True, "order": 1}, {"text": "have", "is_answer": True, "order": 2},
        {"text": "a", "is_answer": True, "order": 3}, {"text": "good", "is_answer": True, "order": 4},
        {"text": "idea", "is_answer": True, "order": 5}, {"text": ".", "is_answer": True, "order": 6},
        {"text": "an", "is_answer": False}
    ]),
]
for order, prompt_ja, answer, choices in p005_l3:
    rows.append({
        "pattern_no": "P005", "layer": 3, "question_order": order, "question_type": "tile_select",
        "prompt_ja": prompt_ja, "correct_answer": answer, "choices": json.dumps(choices),
        "mowi_quote_correct": "でた。", "mowi_quote_wrong": "…なんか変。",
        "time_limit_sec": 8, "tts_text_a": answer, "tts_voice": "en-US-Neural2-D", "tts_speed_b": 1.00,
        "audio_url_main": f"{AUDIO_BASE}/P005/L3/P005_L3_answer_{order}.mp3"
    })

# =====================================================================
# INSERT
# =====================================================================
print(f"Inserting {len(rows)} rows...")

# Insert in batches of 20
batch_size = 20
for i in range(0, len(rows), batch_size):
    batch = rows[i:i+batch_size]
    result = sb.table("pattern_content").insert(batch).execute()
    print(f"  Batch {i//batch_size + 1}: {len(batch)} rows inserted")

print(f"\n🎉 挿入完了：合計 {len(rows)} 件")

# Summary
from collections import Counter
summary = Counter((r["pattern_no"], r["layer"], r.get("question_type","")) for r in rows)
print("\n| パターン | Layer | 問題タイプ | 件数 |")
print("|---------|-------|----------|------|")
for (pno, layer, qtype), count in sorted(summary.items()):
    print(f"| {pno}    | {layer}     | {qtype:15s} | {count} |")
