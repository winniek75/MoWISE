"""P006〜P035 Layer 3 の audio_url_main を一括更新"""
import os
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ["VITE_SUPABASE_URL"]
key = os.environ["VITE_SUPABASE_SERVICE_ROLE_KEY"]
supabase = create_client(url, key)

BUCKET = "mowise-audio"
BASE_URL = f"{url}/storage/v1/object/public/{BUCKET}"


def main():
    # P006〜P035 Layer 3 tile_select のレコードを取得
    resp = (
        supabase.table("pattern_content")
        .select("id, pattern_no, question_order")
        .gte("pattern_no", "P006")
        .lte("pattern_no", "P035")
        .eq("layer", 3)
        .eq("question_type", "tile_select")
        .order("pattern_no")
        .order("question_order")
        .execute()
    )

    updated = 0
    errors = 0
    for row in resp.data:
        pno = row["pattern_no"]
        seq = row["question_order"]
        audio_path = f"patterns/{pno}/L3/{pno}_L3_answer_{seq}.mp3"
        audio_url = f"{BASE_URL}/{audio_path}"

        try:
            supabase.table("pattern_content").update(
                {"audio_url_main": audio_url}
            ).eq("id", row["id"]).execute()
            print(f"✅ {pno} L3-Q{seq} → {audio_path}")
            updated += 1
        except Exception as e:
            print(f"❌ {pno} L3-Q{seq} : {e}")
            errors += 1

    print(f"\n🎉 URL更新完了：{updated} 件（エラー: {errors}）")


main()
