import asyncio
import os
import edge_tts

VOICE = "en-US-GuyNeural"
OUTPUT_DIR = "/tmp/mowise_audio"

AUDIO_LIST = [
    ("P001", 1, "I'm tired."),
    ("P001", 2, "You're amazing."),
    ("P001", 3, "He's my friend."),
    ("P001", 4, "She's a doctor."),
    ("P001", 5, "It's hot today."),
    ("P001", 6, "We're ready."),
    ("P001", 7, "They're late."),
    ("P002", 1, "This is my bag."),
    ("P002", 2, "This is great!"),
    ("P002", 3, "This is a pen."),
    ("P002", 4, "This is an apple."),
    ("P002", 5, "This is my friend, Yuki."),
    ("P002", 6, "That is my school."),
    ("P002", 7, "This is an amazing idea."),
    ("P003", 1, "I like soccer."),
    ("P003", 2, "I like eating sushi."),
    ("P003", 3, "I like watching movies."),
    ("P003", 4, "I like your idea."),
    ("P003", 5, "I don't like spicy food."),
    ("P003", 6, "Do you like music?"),
    ("P003", 7, "I don't like waking up early."),
    ("P004", 1, "I want water."),
    ("P004", 2, "I want to go home."),
    ("P004", 3, "I want a new bag."),
    ("P004", 4, "I want to eat ramen."),
    ("P004", 5, "I don't want it."),
    ("P004", 6, "I don't want to be late."),
    ("P004", 7, "Do you want to eat something?"),
    ("P005", 1, "I have a question."),
    ("P005", 2, "I have two brothers."),
    ("P005", 3, "I have a headache."),
    ("P005", 4, "I have a reservation."),
    ("P005", 5, "I don't have any money."),
    ("P005", 6, "Do you have time?"),
    ("P005", 7, "I have a good idea."),
]

async def generate(pattern: str, seq: int, text: str):
    out_dir  = os.path.join(OUTPUT_DIR, pattern, "L3")
    os.makedirs(out_dir, exist_ok=True)
    filename = f"{pattern}_L3_answer_{seq}.mp3"
    out_path = os.path.join(out_dir, filename)
    communicate = edge_tts.Communicate(text, VOICE)
    await communicate.save(out_path)
    print(f"✅ {filename}")

async def main():
    for pattern, seq, text in AUDIO_LIST:
        await generate(pattern, seq, text)
    print(f"\n🎉 完了：{len(AUDIO_LIST)}ファイル生成")

asyncio.run(main())
