"""
MoWISE 全Layer音声生成スクリプト（Google Cloud TTS Neural2）

対象: P001〜P035 × Layer 0〜3
設計書: MoWISE_G_音声アセット計画_v1_0.md 準拠

使い方:
  1. Google Cloud API キーを設定:
     export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account.json"

  2. 依存インストール:
     pip install google-cloud-texttospeech supabase python-dotenv

  3. edge-tts フォールバック（Google Cloud なしでも動作）:
     pip install edge-tts

  4. 実行:
     python scripts/generate_all_audio.py

  オプション:
     --layer 0        # 特定Layerのみ
     --pattern P001   # 特定パターンのみ
     --provider edge  # edge-tts を強制使用
     --dry-run        # 生成せずに件数だけ表示
"""

import asyncio
import argparse
import os
import sys
from dataclasses import dataclass

from dotenv import load_dotenv

load_dotenv()

# ─────────────────────────────────────────────
# 設定
# ─────────────────────────────────────────────

OUTPUT_DIR = os.environ.get("MOWISE_AUDIO_DIR", "/tmp/mowise_audio")

# Google Cloud TTS Neural2 設定（設計書準拠）
VOICE_M = "en-US-Neural2-D"  # 男声: Layer 0, 3
VOICE_F = "en-US-Neural2-F"  # 女声: Layer 1, 2

# edge-tts フォールバック設定
EDGE_VOICE_M = "en-US-GuyNeural"
EDGE_VOICE_F = "en-US-JennyNeural"

# Layer別の音声仕様
LAYER_SPEC = {
    0: {
        "categories": [
            {"name": "slow", "speed": 0.75, "voice": "M", "field": "tts_text_a"},
            {"name": "natural", "speed": 1.0, "voice": "M", "field": "tts_text_b"},
        ],
    },
    1: {
        "categories": [
            {"name": "match", "speed": 1.0, "voice": "F", "field": "correct_answer"},
        ],
    },
    2: {
        "categories": [
            {"name": "answer", "speed": 1.0, "voice": "F", "field": "correct_answer"},
        ],
    },
    3: {
        "categories": [
            {"name": "answer", "speed": 1.0, "voice": "M", "field": "correct_answer"},
        ],
    },
}


@dataclass
class AudioTask:
    pattern_no: str
    layer: int
    category: str
    seq: int
    text: str
    speed: float
    voice_gender: str  # "M" or "F"

    @property
    def filename(self) -> str:
        return f"{self.pattern_no}_L{self.layer}_{self.category}_{self.seq}.mp3"

    @property
    def dir_path(self) -> str:
        return os.path.join(OUTPUT_DIR, self.pattern_no, f"L{self.layer}")

    @property
    def file_path(self) -> str:
        return os.path.join(self.dir_path, self.filename)


# ─────────────────────────────────────────────
# Supabase からデータ取得
# ─────────────────────────────────────────────

def fetch_content(layer_filter=None, pattern_filter=None):
    """pattern_content テーブルから音声生成に必要なデータを取得"""
    url = os.environ.get("VITE_SUPABASE_URL")
    key = os.environ.get("VITE_SUPABASE_SERVICE_ROLE_KEY")
    if not url or not key:
        print("⚠️  VITE_SUPABASE_URL / VITE_SUPABASE_SERVICE_ROLE_KEY が未設定")
        print("   .env に設定するか、環境変数で指定してください")
        sys.exit(1)

    from supabase import create_client
    sb = create_client(url, key)

    query = (
        sb.table("pattern_content")
        .select("pattern_no, layer, question_order, question_type, "
                "correct_answer, tts_text_a, tts_text_b, prompt_en, "
                "display_text, choices")
        .order("pattern_no")
        .order("layer")
        .order("question_order")
    )

    if layer_filter is not None:
        query = query.eq("layer", layer_filter)
    if pattern_filter:
        query = query.eq("pattern_no", pattern_filter)

    resp = query.execute()
    return resp.data


def _extract_full_sentence_l2(row) -> str:
    """Layer 2 slot_fill: display_text の ___ を最初の正解choiceで埋めて完全文を作る"""
    import json
    display = row.get("display_text") or ""
    choices_raw = row.get("choices")
    if not choices_raw or "___" not in display:
        return ""
    try:
        choices = json.loads(choices_raw) if isinstance(choices_raw, str) else choices_raw
        correct = next((c["text"] for c in choices if c.get("is_correct")), "")
        if correct:
            sentence = display.replace("___", correct)
            # ピリオドがなければ追加
            if not sentence.rstrip().endswith(('.', '!', '?')):
                sentence = sentence.rstrip() + '.'
            return sentence
    except Exception:
        pass
    return ""


def build_tasks(rows, layer_filter=None) -> list[AudioTask]:
    """DBの行から AudioTask リストを生成"""
    tasks = []
    for r in rows:
        layer = r["layer"]
        if layer_filter is not None and layer != layer_filter:
            continue
        if layer not in LAYER_SPEC:
            continue

        spec = LAYER_SPEC[layer]
        for cat in spec["categories"]:
            # テキスト取得
            if layer == 2:
                # Layer 2: display_text + choices から完全文を組み立てる
                text = _extract_full_sentence_l2(r)
            else:
                text = r.get(cat["field"]) or r.get("correct_answer") or ""

            if not text.strip():
                continue

            tasks.append(AudioTask(
                pattern_no=r["pattern_no"],
                layer=layer,
                category=cat["name"],
                seq=r["question_order"],
                text=text.strip(),
                speed=cat["speed"],
                voice_gender=cat["voice"],
            ))

    return tasks


# ─────────────────────────────────────────────
# ローカルデータから Layer 0/1 タスク生成
# ─────────────────────────────────────────────

# P001〜P005 のローカルデータ（DB未投入分）
LOCAL_LAYER0_DATA = {
    "P001": [
        ("I am tired.", "I'm tired."),
        ("She is a teacher.", "She's a teacher."),
        ("It is hot today.", "It's hot today."),
        ("We are ready.", "We're ready."),
        ("They are late.", "They're late."),
    ],
    "P002": [
        ("That is my car.", "That's my car."),
        ("This is my bag.", "This is my bag."),
        ("That is a good idea.", "That's a good idea."),
        ("This is our school.", "This is our school."),
        ("That is her book.", "That's her book."),
    ],
    "P003": [
        ("It is nice to meet you.", "Nice to meet you."),
        ("It is nice to meet you too.", "Nice to meet you too."),
        ("It is good to see you.", "Good to see you."),
        ("It is great to meet you.", "Great to meet you."),
        ("It is nice to see you again.", "Nice to see you again."),
    ],
    "P004": [
        ("I like cats.", "I like cats."),
        ("She likes music.", "She likes music."),
        ("I like playing soccer.", "I like playing soccer."),
        ("He likes reading books.", "He likes reading books."),
        ("We like this restaurant.", "We like this restaurant."),
    ],
    "P005": [
        ("I have a dog.", "I have a dog."),
        ("She has two cats.", "She has two cats."),
        ("I have a question.", "I have a question."),
        ("He has a big house.", "He has a big house."),
        ("We have three classes today.", "We have three classes today."),
    ],
}

LOCAL_LAYER1_DATA = {
    "P001": ["I'm tired.", "She's a teacher.", "It's hot today.", "He's my friend.", "We're ready.", "They're late."],
    "P002": ["This is my bag.", "That's my car.", "This is our school.", "That's a good idea.", "This is her book."],
    "P003": ["Nice to meet you.", "Nice to meet you too.", "Good to see you.", "Great to meet you.", "Nice to see you again."],
    "P004": ["I like cats.", "She likes music.", "I like playing soccer.", "He likes reading books.", "We like this restaurant."],
    "P005": ["I have a dog.", "She has two cats.", "I have a question.", "He has a big house.", "We have three classes today."],
}


def build_local_layer01_tasks(layer_filter=None, pattern_filter=None) -> list[AudioTask]:
    """ローカルデータから Layer 0/1 の AudioTask を生成"""
    tasks = []

    # Layer 0
    if layer_filter is None or layer_filter == 0:
        for pno, sentences in LOCAL_LAYER0_DATA.items():
            if pattern_filter and pno != pattern_filter:
                continue
            for seq, (slow, natural) in enumerate(sentences, 1):
                tasks.append(AudioTask(pno, 0, "slow", seq, slow, 0.75, "M"))
                tasks.append(AudioTask(pno, 0, "natural", seq, natural, 1.0, "M"))

    # Layer 1
    if layer_filter is None or layer_filter == 1:
        for pno, sentences in LOCAL_LAYER1_DATA.items():
            if pattern_filter and pno != pattern_filter:
                continue
            for seq, sentence in enumerate(sentences, 1):
                tasks.append(AudioTask(pno, 1, "match", seq, sentence, 1.0, "F"))

    return tasks


# ─────────────────────────────────────────────
# 音声生成: Google Cloud TTS
# ─────────────────────────────────────────────

def generate_google(task: AudioTask) -> bool:
    """Google Cloud TTS Neural2 で生成"""
    try:
        from google.cloud import texttospeech
    except ImportError:
        return False

    client = texttospeech.TextToSpeechClient()
    voice_name = VOICE_M if task.voice_gender == "M" else VOICE_F

    input_text = texttospeech.SynthesisInput(text=task.text)
    voice = texttospeech.VoiceSelectionParams(
        language_code="en-US",
        name=voice_name,
    )
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3,
        speaking_rate=task.speed,
        sample_rate_hertz=24000,
        effects_profile_id=["headphone-class-device"],
    )

    response = client.synthesize_speech(
        input=input_text, voice=voice, audio_config=audio_config,
    )

    os.makedirs(task.dir_path, exist_ok=True)
    with open(task.file_path, "wb") as f:
        f.write(response.audio_content)
    return True


# ─────────────────────────────────────────────
# 音声生成: edge-tts フォールバック
# ─────────────────────────────────────────────

async def generate_edge(task: AudioTask) -> bool:
    """edge-tts（無料）で生成"""
    try:
        import edge_tts
    except ImportError:
        print("❌ edge-tts がインストールされていません: pip install edge-tts")
        return False

    voice = EDGE_VOICE_M if task.voice_gender == "M" else EDGE_VOICE_F
    # edge-tts は rate を "+0%" 形式で指定
    rate_pct = round((task.speed - 1.0) * 100)
    rate_str = f"{rate_pct:+d}%"

    os.makedirs(task.dir_path, exist_ok=True)
    communicate = edge_tts.Communicate(task.text, voice, rate=rate_str)
    await communicate.save(task.file_path)
    return True


# ─────────────────────────────────────────────
# メイン
# ─────────────────────────────────────────────

async def main():
    parser = argparse.ArgumentParser(description="MoWISE 全Layer音声生成")
    parser.add_argument("--layer", type=int, choices=[0, 1, 2, 3], help="特定Layerのみ生成")
    parser.add_argument("--pattern", type=str, help="特定パターンのみ (e.g. P001)")
    parser.add_argument("--provider", choices=["google", "edge", "auto"], default="auto",
                        help="TTS プロバイダー (default: auto)")
    parser.add_argument("--dry-run", action="store_true", help="生成せずに件数のみ表示")
    args = parser.parse_args()

    # Google Cloud TTS が使えるか確認
    use_google = False
    if args.provider in ("google", "auto"):
        try:
            from google.cloud import texttospeech  # noqa: F401
            if os.environ.get("GOOGLE_APPLICATION_CREDENTIALS"):
                use_google = True
                print("🟢 Google Cloud TTS Neural2 を使用")
            elif args.provider == "google":
                print("❌ GOOGLE_APPLICATION_CREDENTIALS が未設定")
                sys.exit(1)
        except ImportError:
            if args.provider == "google":
                print("❌ google-cloud-texttospeech がインストールされていません")
                sys.exit(1)

    if not use_google:
        print("🟡 edge-tts（フォールバック）を使用")

    # DB からデータ取得
    print("\n📥 Supabase から問題データを取得中...")
    rows = fetch_content(layer_filter=args.layer, pattern_filter=args.pattern)
    print(f"   {len(rows)} 行取得")

    # タスク生成
    tasks = build_tasks(rows, layer_filter=args.layer)

    # Layer 0/1 が DB にない場合、ローカルデータから補完
    layers_in_db = set(r["layer"] for r in rows)
    if 0 not in layers_in_db or 1 not in layers_in_db:
        local_tasks = build_local_layer01_tasks(
            layer_filter=args.layer, pattern_filter=args.pattern
        )
        if local_tasks:
            tasks.extend(local_tasks)
            print(f"   + ローカルデータから {len(local_tasks)} 件追加（Layer 0/1）")

    print(f"   {len(tasks)} 件の音声タスクを生成\n")

    if args.dry_run:
        # Layer別サマリー
        from collections import Counter
        counter = Counter(f"L{t.layer} {t.category}" for t in tasks)
        for key, count in sorted(counter.items()):
            print(f"   {key}: {count} ファイル")
        print(f"\n   合計: {len(tasks)} ファイル")
        return

    # 生成実行
    generated = 0
    skipped = 0
    errors = 0

    for i, task in enumerate(tasks, 1):
        # 既存ファイルスキップ
        if os.path.exists(task.file_path):
            skipped += 1
            continue

        try:
            if use_google:
                ok = generate_google(task)
            else:
                ok = await generate_edge(task)

            if ok:
                generated += 1
                if generated % 10 == 0 or generated == 1:
                    print(f"   [{i}/{len(tasks)}] ✅ {task.filename}")
            else:
                errors += 1
                print(f"   [{i}/{len(tasks)}] ❌ {task.filename}")
        except Exception as e:
            errors += 1
            print(f"   [{i}/{len(tasks)}] ❌ {task.filename}: {e}")

    print(f"\n🎉 完了: 生成 {generated} / スキップ {skipped} / エラー {errors} （全{len(tasks)}件）")
    print(f"📁 出力先: {OUTPUT_DIR}")


if __name__ == "__main__":
    asyncio.run(main())
