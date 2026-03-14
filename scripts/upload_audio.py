import os
import glob
from supabase import create_client
from dotenv import load_dotenv

load_dotenv()

url  = os.environ["VITE_SUPABASE_URL"]
key  = os.environ["VITE_SUPABASE_SERVICE_ROLE_KEY"]
supabase = create_client(url, key)

BUCKET    = "mowise-audio"
LOCAL_DIR = "/tmp/mowise_audio"

try:
    supabase.storage.create_bucket(BUCKET, options={"public": True})
    print(f"✅ バケット '{BUCKET}' を作成しました")
except Exception:
    print(f"ℹ️  バケット '{BUCKET}' は既に存在します")

files = sorted(glob.glob(f"{LOCAL_DIR}/**/*.mp3", recursive=True))
for local_path in files:
    rel  = os.path.relpath(local_path, LOCAL_DIR)
    dest = f"patterns/{rel}"
    with open(local_path, "rb") as f:
        try:
            supabase.storage.from_(BUCKET).upload(
                dest, f,
                file_options={"content-type": "audio/mpeg", "upsert": "true"}
            )
            print(f"⬆️  {dest}")
        except Exception as e:
            print(f"❌ {dest} : {e}")

print(f"\n🎉 アップロード完了：{len(files)}ファイル")
