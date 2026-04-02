"""P006〜P035 Layer 3 音声生成（edge-tts）
Supabase DB の pattern_content から correct_answer を取得し、MP3を生成する。
"""
import asyncio
import os
import edge_tts
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ["VITE_SUPABASE_URL"]
key = os.environ["VITE_SUPABASE_SERVICE_ROLE_KEY"]
supabase = create_client(url, key)

VOICE = "en-US-GuyNeural"
OUTPUT_DIR = "/tmp/mowise_audio"


def fetch_l3_data():
    """pattern_content から P006〜P035 の Layer 3 tile_select を取得"""
    rows = []
    # Supabase のクエリは pattern_no の範囲フィルタ
    resp = (
        supabase.table("pattern_content")
        .select("pattern_no, question_order, correct_answer")
        .gte("pattern_no", "P006")
        .lte("pattern_no", "P035")
        .eq("layer", 3)
        .eq("question_type", "tile_select")
        .order("pattern_no")
        .order("question_order")
        .execute()
    )
    for r in resp.data:
        if r["correct_answer"]:
            rows.append((r["pattern_no"], r["question_order"], r["correct_answer"]))
    return rows


async def generate(pattern: str, seq: int, text: str):
    out_dir = os.path.join(OUTPUT_DIR, pattern, "L3")
    os.makedirs(out_dir, exist_ok=True)
    filename = f"{pattern}_L3_answer_{seq}.mp3"
    out_path = os.path.join(out_dir, filename)
    if os.path.exists(out_path):
        print(f"⏭️  {filename} (既存スキップ)")
        return False
    communicate = edge_tts.Communicate(text, VOICE)
    await communicate.save(out_path)
    print(f"✅ {filename}")
    return True


async def main():
    print("📥 DB から correct_answer を取得中...")
    audio_list = fetch_l3_data()
    print(f"   {len(audio_list)} 件取得\n")

    generated = 0
    for pattern, seq, text in audio_list:
        ok = await generate(pattern, seq, text)
        if ok:
            generated += 1

    print(f"\n🎉 完了：{generated} ファイル新規生成（全{len(audio_list)}件）")


asyncio.run(main())
