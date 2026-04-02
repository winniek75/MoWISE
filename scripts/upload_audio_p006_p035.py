"""P006〜P035 Layer 3 音声をSupabase Storageにアップロード"""
import os
import glob
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url = os.environ["VITE_SUPABASE_URL"]
key = os.environ["VITE_SUPABASE_SERVICE_ROLE_KEY"]
supabase = create_client(url, key)

BUCKET = "mowise-audio"
LOCAL_DIR = "/tmp/mowise_audio"

# バケット存在確認
try:
    supabase.storage.create_bucket(BUCKET, options={"public": True})
    print(f"✅ バケット '{BUCKET}' を作成しました")
except Exception:
    print(f"ℹ️  バケット '{BUCKET}' は既に存在します")

# P006〜P035 のファイルのみ対象
target_patterns = [f"P{i:03d}" for i in range(6, 36)]
files = []
for p in target_patterns:
    pattern_files = sorted(glob.glob(f"{LOCAL_DIR}/{p}/L3/*.mp3"))
    files.extend(pattern_files)

uploaded = 0
errors = 0
for local_path in files:
    rel = os.path.relpath(local_path, LOCAL_DIR)
    dest = f"patterns/{rel}"
    with open(local_path, "rb") as f:
        try:
            supabase.storage.from_(BUCKET).upload(
                dest, f,
                file_options={"content-type": "audio/mpeg", "upsert": "true"}
            )
            print(f"⬆️  {dest}")
            uploaded += 1
        except Exception as e:
            print(f"❌ {dest} : {e}")
            errors += 1

print(f"\n🎉 アップロード完了：{uploaded} ファイル（エラー: {errors}）")
