"""
P001 Layer 2 音声生成スクリプト
edge-tts で P001 の Layer 2 正解文を音声化
"""
import asyncio
import os
import edge_tts

VOICE = "en-US-GuyNeural"
OUT_DIR = "/tmp/mowise_audio"

# P001 Layer 2 の正解文（fullSentence）
L2_SENTENCES = [
    ("P001", 2, 1, "I'm tired."),
    ("P001", 2, 2, "She's a teacher."),
    ("P001", 2, 3, "It's hot today."),
    ("P001", 2, 4, "He's not ready."),
    ("P001", 2, 5, "We're ready."),
    ("P001", 2, 6, "They're very funny."),
]

async def generate():
    for pattern, layer, seq, text in L2_SENTENCES:
        folder = os.path.join(OUT_DIR, pattern, f"L{layer}")
        os.makedirs(folder, exist_ok=True)
        filename = f"{pattern}_L{layer}_answer_{seq}.mp3"
        filepath = os.path.join(folder, filename)
        comm = edge_tts.Communicate(text, VOICE)
        await comm.save(filepath)
        print(f"✅ {filepath}")

asyncio.run(generate())
print("\n🎉 L2 音声生成完了")
