"""
MoWISE 音声ファイル一括アップロード + DB URL更新

生成済みの /tmp/mowise_audio/ 以下のファイルを
Supabase Storage (mowise-audio バケット) にアップロードし、
pattern_content テーブルの audio_url_a / audio_url_b / audio_url_main を更新する。

使い方:
  python scripts/upload_all_audio.py
  python scripts/upload_all_audio.py --dry-run   # アップロードせずに確認
  python scripts/upload_all_audio.py --pattern P001  # 特定パターンのみ
"""

import argparse
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

AUDIO_DIR = os.environ.get("MOWISE_AUDIO_DIR", "/tmp/mowise_audio")
BUCKET = "mowise-audio"

# ファイル名 → DB フィールドの対応
# P001_L0_slow_1.mp3   → audio_url_a (ゆっくり版)
# P001_L0_natural_1.mp3 → audio_url_b (ナチュラル版)
# P001_L1_match_1.mp3  → audio_url_main
# P001_L2_answer_1.mp3 → audio_url_main
# P001_L3_answer_1.mp3 → audio_url_main
CATEGORY_TO_FIELD = {
    "slow": "audio_url_a",
    "natural": "audio_url_b",
    "match": "audio_url_main",
    "answer": "audio_url_main",
    "predict": "audio_url_main",
    "feedback": "audio_url_main",
    "hint": "audio_url_main",
}


def get_supabase():
    url = os.environ.get("VITE_SUPABASE_URL")
    key = os.environ.get("VITE_SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        print("❌ VITE_SUPABASE_URL / VITE_SUPABASE_SERVICE_ROLE_KEY が未設定")
        sys.exit(1)
    from supabase import create_client
    return create_client(url, key), url


def scan_files(pattern_filter=None):
    """ローカルの音声ファイルをスキャンして (storage_path, local_path, meta) のリストを返す"""
    files = []
    root = Path(AUDIO_DIR)
    if not root.exists():
        print(f"❌ ディレクトリが見つかりません: {AUDIO_DIR}")
        sys.exit(1)

    for mp3 in sorted(root.rglob("*.mp3")):
        # /tmp/mowise_audio/P001/L3/P001_L3_answer_1.mp3
        name = mp3.name  # P001_L3_answer_1.mp3
        parts = name.replace(".mp3", "").split("_")
        if len(parts) < 4:
            continue

        pattern_no = parts[0]  # P001
        layer_str = parts[1]   # L3
        category = parts[2]    # answer
        seq_str = parts[3]     # 1

        if pattern_filter and pattern_no != pattern_filter:
            continue

        try:
            layer = int(layer_str[1])
            seq = int(seq_str)
        except (ValueError, IndexError):
            continue

        storage_path = f"patterns/{pattern_no}/{layer_str}/{name}"
        db_field = CATEGORY_TO_FIELD.get(category)

        files.append({
            "local_path": str(mp3),
            "storage_path": storage_path,
            "pattern_no": pattern_no,
            "layer": layer,
            "seq": seq,
            "category": category,
            "db_field": db_field,
            "filename": name,
        })

    return files


def upload_to_storage(sb, file_info, supabase_url):
    """Supabase Storage にアップロード"""
    with open(file_info["local_path"], "rb") as f:
        data = f.read()

    # upsert: 既存ファイルがあれば上書き
    sb.storage.from_(BUCKET).upload(
        file_info["storage_path"],
        data,
        file_options={"content-type": "audio/mpeg", "upsert": "true"},
    )

    # 公開 URL を返す
    return f"{supabase_url}/storage/v1/object/public/{BUCKET}/{file_info['storage_path']}"


def update_db_url(sb, pattern_no, layer, seq, field, url):
    """pattern_content テーブルの音声URLを更新"""
    sb.table("pattern_content").update(
        {field: url}
    ).eq(
        "pattern_no", pattern_no
    ).eq(
        "layer", layer
    ).eq(
        "question_order", seq
    ).execute()


def main():
    parser = argparse.ArgumentParser(description="MoWISE 音声ファイルアップロード")
    parser.add_argument("--pattern", type=str, help="特定パターンのみ (e.g. P001)")
    parser.add_argument("--dry-run", action="store_true", help="アップロードせずに確認")
    parser.add_argument("--skip-db", action="store_true", help="DB URL更新をスキップ")
    args = parser.parse_args()

    sb, supabase_url = get_supabase()

    print(f"📁 スキャン中: {AUDIO_DIR}")
    files = scan_files(pattern_filter=args.pattern)
    print(f"   {len(files)} ファイル検出\n")

    if not files:
        print("⚠️  アップロード対象のファイルがありません")
        return

    if args.dry_run:
        from collections import Counter
        counter = Counter(f"L{f['layer']} {f['category']}" for f in files)
        for key, count in sorted(counter.items()):
            print(f"   {key}: {count} ファイル")
        print(f"\n   合計: {len(files)} ファイル")
        return

    uploaded = 0
    db_updated = 0
    errors = 0

    for i, f in enumerate(files, 1):
        try:
            # Storage にアップロード
            public_url = upload_to_storage(sb, f, supabase_url)
            uploaded += 1

            # DB の URL を更新
            if not args.skip_db and f["db_field"]:
                update_db_url(sb, f["pattern_no"], f["layer"], f["seq"], f["db_field"], public_url)
                db_updated += 1

            if uploaded % 20 == 0 or uploaded == 1:
                print(f"   [{i}/{len(files)}] ✅ {f['filename']}")

        except Exception as e:
            errors += 1
            print(f"   [{i}/{len(files)}] ❌ {f['filename']}: {e}")

    print(f"\n🎉 完了:")
    print(f"   Storage: {uploaded} アップロード / {errors} エラー")
    print(f"   DB URL:  {db_updated} 更新")


if __name__ == "__main__":
    main()
