# MoWISE｜G 音声アセット制作計画書
**タスクG：音声アセット制作計画**  
**バージョン：v1.0**  
**策定日：2026年3月10日**  
**ステータス：設計確定・実装準備用**  
**対応要件定義：v3.1（2026年2月23日）**

---

## 📋 ドキュメント概要

このファイルは、MoWISE アプリケーションにおける英語音声アセットの制作・管理計画書です。  
Google Cloud TTS Neural2 を使用して、P001〜P035 × Layer 0〜3 に必要な全音声ファイルを  
計画的に生成・管理・配信するための仕様を定めます。

> **音声プロバイダー変更履歴：**  
> v3.0 以前：ElevenLabs TTS → v3.1 以降：**Google Cloud TTS（Neural2）**に変更確定

---

## 目次

1. [Google Cloud TTS Neural2 モデル・声質・パラメータ仕様](#1-google-cloud-tts-neural2-モデル声質パラメータ仕様)
2. [音声ファイル試算（P001〜P035 × Layer 0〜3）](#2-音声ファイル試算p001p035--layer-03)
3. [ファイル命名規則](#3-ファイル命名規則)
4. [Supabase Storage バケット構成](#4-supabase-storage-バケット構成)
5. [生成バッチスクリプト設計方針（Node.js）](#5-生成バッチスクリプト設計方針nodejs)
6. [優先生成順（MVP最小セット）](#6-優先生成順mvp最小セット)
7. [コスト試算](#7-コスト試算)
8. [今後の拡張方針](#8-今後の拡張方針)

---

## 1. Google Cloud TTS Neural2 モデル・声質・パラメータ仕様

### 1.1 使用モデル一覧

MoWISE では Layer の用途・目的に応じて 2 種類のモデルを使い分ける。  
**バリエーションを持たせること**で、ユーザーが「1つの声」に慣れすぎず、  
多様なネイティブ音声に耳を慣らす学習効果を意図した設計。

| ID | モデル名 | 性別 | 特徴 | 主な使用Layer |
|----|---------|------|------|-------------|
| Voice-M | `en-US-Neural2-D` | 男性 | 落ち着き・明瞭・信頼感 | Layer 0, Layer 3（正解フィードバック） |
| Voice-F | `en-US-Neural2-F` | 女性 | 明るい・自然・親しみやすい | Layer 1（Sound Match）、Layer 2 |

> **将来の拡張（Phase 2以降）：**  
> Echo Drill（録音比較）実装時は `en-US-Neural2-J`（男性・若め）の追加を検討。  
> 発音評価（Azure Speech連携）との整合性のため、主要モデルは上記 2 種で固定する。

---

### 1.2 Layer別パラメータ定義

各 Layer の学習目的に合わせて、速度（speaking_rate）・ピッチ・ボリュームを制御する。

```
凡例
  speaking_rate : 1.0 = 標準速度。0.75 = 75%速度（ゆっくり明瞭）
  pitch         : 0.0 = 変更なし（デフォルト）
  volume_gain_db: 0 = 変更なし（デフォルト）
```

#### Layer 0：Sound Foundation（聞き比べ）

| 種別 | モデル | speaking_rate | pitch | volume_gain_db | 用途 |
|------|--------|---------------|-------|----------------|------|
| `normal`（通常版） | Voice-M | `0.75` | `0.0` | `0` | ゆっくり・明瞭。短縮前の形 |
| `native`（ネイティブ版） | Voice-M | `1.0` | `0.0` | `0` | 自然速度。短縮形・リンキング表現 |

> **設計意図：** L0 の「同じ意味？YES/NO」比較問題は、ゆっくり版とネイティブ版の  
> 2音声が学習の核心。speaking_rate の差を明確にすることで  
> 「聞こえ方の違い」を耳で体験させる。

#### Layer 1：Echo Drill（Sound Match）

| 種別 | モデル | speaking_rate | pitch | volume_gain_db | 用途 |
|------|--------|---------------|-------|----------------|------|
| `match`（問題音声） | Voice-F | `1.0` | `0.0` | `0` | 3択テキスト選択のための問題音声 |

> **Voice-F 採用理由：** Layer 0 で Voice-M を使用するため、Layer 1 では  
> 声のバリエーション（女性声）を導入してリスニング耐性を向上させる。

#### Layer 2：Pattern Sense（スロット穴埋め ＋ 音声予測）

| 種別 | モデル | speaking_rate | pitch | volume_gain_db | 用途 |
|------|--------|---------------|-------|----------------|------|
| `predict`（予測用部分音声） | Voice-F | `1.0` | `0.0` | `0` | 「I'm...」で止まる途中音声 |
| `feedback`（正解フィードバック） | Voice-F | `1.0` | `0.0` | `0` | スロット穴埋め正解後の完成文 |
| `wrong`（不正解時・不自然音声） | Voice-M | `1.0` | `-2.0` | `-3` | 不自然さを耳で体験させる誤答文 |

> **wrong ボイスの設計意図：** v3.1 の「不正解時UX原則」に基づき、  
> まず「不自然な音」を聞かせてMowiが反応する設計。ピッチを僅かに下げることで  
> 「何か変」という違和感を聴覚的に演出する。

#### Layer 3：Flash Output（瞬間英作文）

| 種別 | モデル | speaking_rate | pitch | volume_gain_db | 用途 |
|------|--------|---------------|-------|----------------|------|
| `answer`（正解後再生） | Voice-M | `1.0` | `0.0` | `0` | タイル・キーボード正解後の確認音声 |
| `hint`（ヒント音声） | Voice-M | `0.85` | `0.0` | `0` | 3秒経過ヒント用（少しゆっくり） |

---

### 1.3 Google Cloud TTS API 呼び出し仕様

```json
{
  "input": {
    "text": "I'm tired."
  },
  "voice": {
    "languageCode": "en-US",
    "name": "en-US-Neural2-D"
  },
  "audioConfig": {
    "audioEncoding": "MP3",
    "speakingRate": 1.0,
    "pitch": 0.0,
    "volumeGainDb": 0,
    "sampleRateHertz": 24000,
    "effectsProfileId": ["headphone-class-device"]
  }
}
```

**共通設定方針：**
- フォーマット：**MP3**（iOS/Android/Web 全対応・サイズ効率優秀）
- サンプルレート：**24,000 Hz**（Neural2 の推奨値）
- エフェクト：`headphone-class-device`（スマートフォン視聴に最適化）
- ビットレート：デフォルト（128kbps）

---

## 2. 音声ファイル試算（P001〜P035 × Layer 0〜3）

### 2.1 Layer別・1パターンあたりのファイル数

P001 の実装設計を基に、各パターンの典型的なファイル数を試算する。

| Layer | 用途 | 1問あたりのファイル数 | 標準問題数 | 1パターンあたりの小計 |
|-------|------|---------------------|-----------|-------------------|
| **L0** | normal（ゆっくり版） | 1 | 3〜4 問 | **3〜4 ファイル** |
| **L0** | native（ネイティブ版） | 1 | 3〜4 問 | **3〜4 ファイル** |
| **L0** | A/B比較（NO問題） | 2（A・B各1） | 1 問 | **2 ファイル** |
| **L1** | match（Sound Match問題） | 1 | 5〜8 問 | **6〜8 ファイル** |
| **L2** | predict（音声予測・途中停止） | 1 | 4 問 | **4 ファイル** |
| **L2** | feedback（スロット正解文） | 1 | 4〜6 問 | **4〜6 ファイル** |
| **L3** | answer（正解確認） | 1 | 7〜10 問 | **7〜10 ファイル** |

**1パターンあたりの合計：約 25〜38 ファイル（平均：約 30 ファイル）**

> **P001 の実績値：約 25 ファイル**  
> P001 は代名詞7種という特殊構造のため、Layer 1 が 7問と多い一方、  
> Layer 0 は4問セット（3ペア＋1比較）と比較的コンパクト。  
> P002 以降の一般的なパターンでは Layer 1 が 5〜6 問に収まることが多く、  
> **平均 25〜28 ファイル**と見積もる。

---

### 2.2 P001〜P035 全体ファイル数試算

パターンの複雑度を3段階に分類して試算する。

| 分類 | 対象パターン | 複雑度の根拠 | 推定ファイル数/パターン | パターン数 | 小計 |
|------|------------|------------|----------------------|-----------|------|
| **複雑** | P001〜P010 | 代名詞変化・時制変化・前置詞など多様な形を含む | 28 ファイル | 10 | **280 ファイル** |
| **標準** | P011〜P025 | 典型的な構文。バリエーションは限定的 | 25 ファイル | 15 | **375 ファイル** |
| **シンプル** | P026〜P035 | 単一構文・短い例文が中心 | 20 ファイル | 10 | **200 ファイル** |
| | | | | **合計** | **🔴 855 ファイル** |

---

### 2.3 Layer別の内訳試算

| Layer | 役割 | 35パターン × 平均ファイル数 | 推定ファイル数 |
|-------|------|--------------------------|-------------|
| Layer 0 | Sound Foundation（normal + native + AB比較） | 35 × 9 | **315 ファイル** |
| Layer 1 | Echo Drill（Sound Match） | 35 × 7 | **245 ファイル** |
| Layer 2 | Pattern Sense（predict + feedback） | 35 × 8 | **280 ファイル** |
| Layer 3 | Flash Output（answer） | 35 × 9 | **315 ファイル** |
| **合計** | | | **🔴 約 855 ファイル（MVP）** |

> **補足：**  
> - Layer 4（Scene Challenge）は Phase 2 対応のため今回の試算に含まない  
> - P036〜P100 は Phase 2・3 対応（追加試算は別途）  
> - wrong 音声（不正解UX用）はパターンコンテンツ詳細設計 完成後に精査・追加する

---

### 2.4 ストレージ容量見積もり

| 条件 | 値 |
|------|-----|
| 1ファイルの平均サイズ | 約 30 KB（短文 MP3・128kbps） |
| 総ファイル数 | 855 ファイル |
| **推定総容量** | **約 25〜30 MB** |

> Neural2 の MP3 出力は非常に軽量。Supabase Storage の無料枠（1 GB）の範囲内に  
> 十分収まる。Phase 2・3 を含んでも 100 MB 以内の見込み。

---

## 3. ファイル命名規則

### 3.1 基本フォーマット

```
P{NNN}_L{n}_{category}_{seq}.mp3
```

| 変数 | 説明 | 例 |
|------|------|-----|
| `{NNN}` | パターン番号（3桁ゼロ埋め） | `001`, `035` |
| `{n}` | レイヤー番号（0〜3） | `0`, `1`, `2`, `3` |
| `{category}` | 音声の種類（下表参照） | `normal`, `native`, `match` |
| `{seq}` | 問題内の連番（1始まり） | `1`, `2`, `7` |

---

### 3.2 カテゴリ一覧

| Layer | category値 | 内容 | モデル | speed |
|-------|-----------|------|--------|-------|
| L0 | `normal` | ゆっくり・明瞭版（short縮前） | Voice-M | 0.75 |
| L0 | `native` | 自然速度・短縮形・リンキングあり | Voice-M | 1.0 |
| L1 | `match` | Sound Match 問題音声 | Voice-F | 1.0 |
| L2 | `predict` | 途中で止まる予測用音声 | Voice-F | 1.0 |
| L2 | `feedback` | スロット穴埋め正解文 | Voice-F | 1.0 |
| L2 | `wrong` | 不正解UX用の不自然音声 | Voice-M | 1.0 |
| L3 | `answer` | 正解後の確認音声 | Voice-M | 1.0 |
| L3 | `hint` | 3秒経過ヒント音声 | Voice-M | 0.85 |

---

### 3.3 命名例

```
# Layer 0 — 聞き比べペア（Q1：ゆっくり・ネイティブ）
P001_L0_normal_1.mp3     → "I am tired."（0.75速度）
P001_L0_native_1.mp3     → "I'm tired."（1.0速度）

# Layer 0 — AB比較問題（Q4：意味が違う2文）
P001_L0_native_4a.mp3    → "She's happy."
P001_L0_native_4b.mp3    → "She's hungry."

# Layer 1 — Sound Match問題（Q1〜Q7）
P001_L1_match_1.mp3      → "I'm hungry."
P001_L1_match_7.mp3      → "They're so funny."

# Layer 2 — 音声予測（途中停止）
P001_L2_predict_1.mp3    → "I'm..."（フェードアウト）
P001_L2_predict_4.mp3    → "It's..."（フェードアウト）

# Layer 2 — スロット正解フィードバック
P001_L2_feedback_1.mp3   → "I'm tired."（正解文完成）
P001_L2_wrong_1.mp3      → "I'm go."（不自然音・不正解UX用）

# Layer 3 — 正解確認音声
P001_L3_answer_1.mp3     → "I'm tired."
P001_L3_answer_7.mp3     → "They're late."

# Layer 3 — ヒント音声
P001_L3_hint_5.mp3       → "It's ___"（3秒後提示）
```

---

### 3.4 命名規則のルール補足

- **ゼロ埋め必須：** パターン番号は 3桁で統一（`P001` ～ `P035`）
- **小文字統一：** category・拡張子はすべて小文字
- **スペース禁止：** アンダースコア `_` のみで区切る
- **AB比較の場合：** `_4a` / `_4b` のように末尾に `a` / `b` を追加
- **拡張子：** `.mp3` 固定（フォーマット統一）

---

## 4. Supabase Storage バケット構成

### 4.1 バケット設計方針

| 設計項目 | 決定事項 | 理由 |
|---------|---------|------|
| バケット名 | `mowise-audio` | 単一バケット集約。将来拡張しやすい |
| 公開設定 | **Public（読み取り専用）** | アプリから直接 URL 参照が必要。CDN 経由が前提 |
| ファイル上書き | **禁止**（バージョン管理） | 誤上書きを防ぎ、再生成時は上書き確認フラグを使用 |
| フォルダ構造 | 階層型（下記参照） | パターン・レイヤー別の管理・デプロイが容易 |

---

### 4.2 フォルダ構造

```
mowise-audio/                         ← バケットルート
│
├── patterns/                         ← 全パターン音声の格納先
│   ├── P001/
│   │   ├── L0/
│   │   │   ├── P001_L0_normal_1.mp3
│   │   │   ├── P001_L0_native_1.mp3
│   │   │   ├── P001_L0_normal_2.mp3
│   │   │   ├── P001_L0_native_2.mp3
│   │   │   ├── P001_L0_normal_3.mp3
│   │   │   ├── P001_L0_native_3.mp3
│   │   │   ├── P001_L0_native_4a.mp3
│   │   │   └── P001_L0_native_4b.mp3
│   │   ├── L1/
│   │   │   ├── P001_L1_match_1.mp3
│   │   │   ├── ...
│   │   │   └── P001_L1_match_7.mp3
│   │   ├── L2/
│   │   │   ├── P001_L2_predict_1.mp3
│   │   │   ├── P001_L2_predict_2.mp3
│   │   │   ├── P001_L2_predict_3.mp3
│   │   │   ├── P001_L2_predict_4.mp3
│   │   │   ├── P001_L2_feedback_1.mp3
│   │   │   ├── ...
│   │   │   └── P001_L2_wrong_1.mp3
│   │   └── L3/
│   │       ├── P001_L3_answer_1.mp3
│   │       ├── ...
│   │       └── P001_L3_hint_5.mp3
│   ├── P002/
│   │   ├── L0/
│   │   ├── L1/
│   │   ├── L2/
│   │   └── L3/
│   ├── ...
│   └── P035/
│
└── mowi/                             ← Mowi SE（効果音）将来用
    └── README.md                     ← Phase 2 以降に追加予定
```

---

### 4.3 Public URL フォーマット

```
https://{project-ref}.supabase.co/storage/v1/object/public/mowise-audio/patterns/{PNNN}/L{n}/{filename}.mp3
```

**例：**
```
https://xxxx.supabase.co/storage/v1/object/public/mowise-audio/patterns/P001/L0/P001_L0_native_1.mp3
```

---

### 4.4 DB連携：`pattern_content` テーブルへの格納

`pattern_content` テーブルの `audio_urls` カラム（JSONB）に  
各 Layer の音声ファイル URL をマニフェストとして格納する。

```json
// pattern_content.audio_urls の例（P001_L0）
{
  "L0": {
    "q1": {
      "normal": "patterns/P001/L0/P001_L0_normal_1.mp3",
      "native": "patterns/P001/L0/P001_L0_native_1.mp3"
    },
    "q2": {
      "normal": "patterns/P001/L0/P001_L0_normal_2.mp3",
      "native": "patterns/P001/L0/P001_L0_native_2.mp3"
    },
    "q4": {
      "a": "patterns/P001/L0/P001_L0_native_4a.mp3",
      "b": "patterns/P001/L0/P001_L0_native_4b.mp3"
    }
  },
  "L1": {
    "q1": "patterns/P001/L1/P001_L1_match_1.mp3",
    "q2": "patterns/P001/L1/P001_L1_match_2.mp3"
  },
  "L2": {
    "predict_1": "patterns/P001/L2/P001_L2_predict_1.mp3",
    "feedback_1": "patterns/P001/L2/P001_L2_feedback_1.mp3",
    "wrong_1":    "patterns/P001/L2/P001_L2_wrong_1.mp3"
  },
  "L3": {
    "answer_1": "patterns/P001/L3/P001_L3_answer_1.mp3",
    "hint_5":   "patterns/P001/L3/P001_L3_hint_5.mp3"
  }
}
```

> **URL管理の方針：** フルURLではなく **パス（path）のみをDBに格納**する。  
> Supabase の base URL は環境変数から取得することで、ステージング／本番の切り替えを容易にする。

---

## 5. 生成バッチスクリプト設計方針（Node.js）

### 5.1 スクリプト全体アーキテクチャ

```
scripts/
├── audio/
│   ├── manifest/
│   │   ├── P001_manifest.json     ← 各パターンの音声生成定義
│   │   ├── P002_manifest.json
│   │   └── ...
│   ├── generate.js                ← メイン生成スクリプト
│   ├── upload.js                  ← Supabase Storage アップロード
│   ├── validate.js                ← 生成済みチェック・欠損検出
│   └── index.js                   ← エントリポイント（CLI）
```

---

### 5.2 マニフェスト JSON フォーマット

各パターンの音声生成仕様を JSON で管理する。  
コンテンツ設計書（P001〜P035）の完成に合わせて、各 `manifest.json` を作成する。

```json
// P001_manifest.json の例（一部）
{
  "pattern_id": "P001",
  "created_at": "2026-03-10",
  "files": [
    {
      "filename": "P001_L0_normal_1.mp3",
      "layer": 0,
      "category": "normal",
      "seq": 1,
      "text": "I am tired.",
      "voice": "en-US-Neural2-D",
      "speaking_rate": 0.75,
      "pitch": 0.0,
      "volume_gain_db": 0
    },
    {
      "filename": "P001_L0_native_1.mp3",
      "layer": 0,
      "category": "native",
      "seq": 1,
      "text": "I'm tired.",
      "voice": "en-US-Neural2-D",
      "speaking_rate": 1.0,
      "pitch": 0.0,
      "volume_gain_db": 0
    },
    {
      "filename": "P001_L2_predict_1.mp3",
      "layer": 2,
      "category": "predict",
      "seq": 1,
      "text": "I'm",
      "voice": "en-US-Neural2-F",
      "speaking_rate": 1.0,
      "pitch": 0.0,
      "volume_gain_db": 0,
      "note": "文末でフェードアウト処理。実装側で対応"
    }
  ]
}
```

---

### 5.3 generate.js の設計方針

```javascript
// 疑似コード（設計イメージ）

const { TextToSpeechClient } = require('@google-cloud/text-to-speech');
const fs = require('fs/promises');
const path = require('path');

const client = new TextToSpeechClient();

/**
 * メイン生成関数
 * @param {string} patternId - 例: 'P001'
 * @param {object} options
 * @param {boolean} options.dryRun    - 生成せず一覧のみ出力
 * @param {boolean} options.overwrite - 既存ファイルを上書きするか
 * @param {number[]} options.layers   - 対象レイヤーを絞る [0,1,2,3]
 */
async function generateAudioForPattern(patternId, options = {}) {
  const manifest = await loadManifest(patternId);
  const results = { success: [], skipped: [], failed: [] };

  for (const fileSpec of manifest.files) {
    // レイヤーフィルタ
    if (options.layers && !options.layers.includes(fileSpec.layer)) {
      continue;
    }

    const outputPath = `./audio_cache/${patternId}/L${fileSpec.layer}/${fileSpec.filename}`;

    // 既存チェック（overwrite=false の場合はスキップ）
    if (!options.overwrite && await fileExists(outputPath)) {
      results.skipped.push(fileSpec.filename);
      continue;
    }

    if (options.dryRun) {
      console.log(`[DRY RUN] ${fileSpec.filename}: "${fileSpec.text}"`);
      continue;
    }

    try {
      // Google Cloud TTS API 呼び出し
      const [response] = await client.synthesizeSpeech({
        input: { text: fileSpec.text },
        voice: {
          languageCode: 'en-US',
          name: fileSpec.voice,
        },
        audioConfig: {
          audioEncoding: 'MP3',
          speakingRate: fileSpec.speaking_rate,
          pitch: fileSpec.pitch,
          volumeGainDb: fileSpec.volume_gain_db,
          sampleRateHertz: 24000,
          effectsProfileId: ['headphone-class-device'],
        },
      });

      // ローカルキャッシュに保存
      await fs.mkdir(path.dirname(outputPath), { recursive: true });
      await fs.writeFile(outputPath, response.audioContent, 'binary');

      results.success.push(fileSpec.filename);
      console.log(`✅ Generated: ${fileSpec.filename}`);

      // レートリミット対策（1秒あたり最大10リクエスト）
      await sleep(120); // 120ms待機
    } catch (err) {
      results.failed.push({ file: fileSpec.filename, error: err.message });
      console.error(`❌ Failed: ${fileSpec.filename} - ${err.message}`);
    }
  }

  return results;
}
```

---

### 5.4 upload.js の設計方針

```javascript
// Supabase Storage へのアップロード

const { createClient } = require('@supabase/supabase-js');

/**
 * ローカルキャッシュから Supabase Storage にアップロード
 * @param {string} patternId
 * @param {object} options
 * @param {number[]} options.layers
 */
async function uploadAudioForPattern(patternId, options = {}) {
  const supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY  // Storage書き込みにはServiceRoleKeyが必要
  );

  const manifest = await loadManifest(patternId);

  for (const fileSpec of manifest.files) {
    if (options.layers && !options.layers.includes(fileSpec.layer)) continue;

    const localPath = `./audio_cache/${patternId}/L${fileSpec.layer}/${fileSpec.filename}`;
    const storagePath = `patterns/${patternId}/L${fileSpec.layer}/${fileSpec.filename}`;

    const fileBuffer = await fs.readFile(localPath);

    const { error } = await supabase.storage
      .from('mowise-audio')
      .upload(storagePath, fileBuffer, {
        contentType: 'audio/mpeg',
        upsert: true,  // 上書き許可（本番では false 推奨）
      });

    if (error) {
      console.error(`❌ Upload failed: ${fileSpec.filename}`, error);
    } else {
      console.log(`☁️  Uploaded: ${storagePath}`);
    }
  }
}
```

---

### 5.5 CLI インターフェース（index.js）

```bash
# 使用例

# P001 の全レイヤーを生成（ドライラン確認）
node scripts/audio/index.js generate --pattern P001 --dry-run

# P001〜P010 の Layer 0 のみ生成
node scripts/audio/index.js generate --pattern P001-P010 --layers 0

# P001 の全ファイルを生成 → Supabase にアップロード
node scripts/audio/index.js generate --pattern P001 && \
node scripts/audio/index.js upload --pattern P001

# 欠損ファイルチェック（全パターン）
node scripts/audio/index.js validate --pattern all

# MVP 最小セット（P001〜P010 全レイヤー）を一括処理
node scripts/audio/index.js generate --pattern P001-P010 --layers 0,1,3
node scripts/audio/index.js upload --pattern P001-P010 --layers 0,1,3
```

---

### 5.6 スクリプト設計の重要方針

| 方針 | 詳細 |
|------|------|
| **冪等性の確保** | 既存ファイルはスキップ。`--overwrite` フラグを明示しない限り再生成しない |
| **レートリミット対策** | Google TTS API は 1,500,000 文字/分が上限。120ms 間隔で呼び出し |
| **ローカルキャッシュ** | `audio_cache/` にまず保存。Upload は別コマンドで分離 |
| **エラー継続** | 1ファイルの失敗で全体を止めない。`failed.json` にエラーログを書き出す |
| **マニフェスト駆動** | テキストの変更は `manifest.json` のみを修正して再生成可能 |
| **環境変数管理** | APIキーは `.env` で管理。コードに直書き禁止 |

---

## 6. 優先生成順（MVP最小セット）

### 6.1 優先度の考え方

```
学習の起点はLayer 0。
正解体験の快感はLayer 3。
この2つがあれば最小限のゲームループが回る。

Layer 1 は Layer 0 の延長で「聞いた音を選ぶ」。
Layer 2 は Layer 1 の次に続く「感じる」フェーズ。

→ 優先順：L0 → L3 → L1 → L2
```

---

### 6.2 Phase別生成計画

#### 🔴 Phase G-1（最優先）：コアループ成立セット
**対象：P001〜P010 × Layer 0 ＋ Layer 3**  
**必要ファイル数：約 170 ファイル**  
**目標：開発環境でのゲームループ動作確認に必要な最小セット**

| 優先順 | 対象 | ファイル数 | 完了条件 |
|--------|------|-----------|---------|
| 1位 | P001 × L0（normal + native） | 8 ファイル | オンボーディング音声テスト可能 |
| 2位 | P001 × L3（answer） | 10 ファイル | Flash Output 正解フィードバック動作確認 |
| 3位 | P002〜P005 × L0 | 32 ファイル | エリア1前半のSound Foundation完成 |
| 4位 | P002〜P005 × L3 | 40 ファイル | エリア1前半のFlash Output完成 |
| 5位 | P006〜P010 × L0 ＋ L3 | 80 ファイル | エリア1後半・エリア2前半カバー |

---

#### 🟡 Phase G-2（次優先）：Layer 1 追加
**対象：P001〜P010 × Layer 1**  
**必要ファイル数：約 70 ファイル**  
**目標：Echo Drill（Sound Match）の動作確認**

| 優先順 | 対象 | ファイル数 |
|--------|------|-----------|
| 1位 | P001〜P005 × L1 | 35 ファイル |
| 2位 | P006〜P010 × L1 | 35 ファイル |

---

#### 🟢 Phase G-3（標準優先）：Layer 2 + 残りパターン
**対象：P001〜P010 × Layer 2 ＋ P011〜P035 × Layer 0〜3**  
**必要ファイル数：約 615 ファイル**  
**目標：MVP 全スコープ完成**

| 優先順 | 対象 | ファイル数 | タイミング |
|--------|------|-----------|---------|
| 1位 | P001〜P010 × L2 | 80 ファイル | Pattern Sense 実装完了後 |
| 2位 | P011〜P020 × L0 + L3 | 250 ファイル | コンテンツ設計書完成次第 |
| 3位 | P011〜P020 × L1 + L2 | 150 ファイル | 上記完了後 |
| 4位 | P021〜P035 × 全レイヤー | 375 ファイル | β版リリース前 |

---

### 6.3 MVP最小セット サマリー

| フェーズ | 対象 | ファイル数 | 完了で達成できること |
|---------|------|-----------|-------------------|
| G-1 | P001〜P010 × L0 + L3 | **170 ファイル** | ゲームループ動作確認・開発テスト |
| G-2 | P001〜P010 × L1 追加 | **240 ファイル** | Echo Drill 動作確認 |
| G-3 | P001〜P010 × L2 追加 | **320 ファイル** | P001〜P010 全Layer完成 |
| G-4 | P011〜P035 × 全Layer | **855 ファイル** | MVP全スコープ音声完成 |

---

## 7. コスト試算

### 7.1 Google Cloud TTS Neural2 料金

| 条件 | 値 |
|------|-----|
| Neural2 料金 | $16.00 / 100万文字 |
| 平均文字数/ファイル | 約 30 文字（短文 TTS が中心） |
| MVP 総文字数（855 ファイル） | 855 × 30 = **25,650 文字** |
| **推定コスト（MVP全体）** | **約 $0.41（約 60円）** |

> Google Cloud TTS の**無料枠は月間 100 万文字**（Neural2 は除外、100万文字は WaveNet 含む標準音声）。  
> Neural2 の無料枠は **月間 100 万文字**（2024年現在の料金体系を確認すること）。  
> MVP の総文字数は約 25,650 文字であり、**実質無料枠内に収まる可能性が高い**。  
> 
> ⚠️ 最新料金は必ず [Google Cloud TTS 料金ページ](https://cloud.google.com/text-to-speech/pricing) で確認すること。

---

## 8. 今後の拡張方針

### Phase 2 以降の追加音声

| 追加項目 | Layer | 概要 | 追加ファイル数目安 |
|---------|-------|------|-----------------|
| Layer 4 Scene Challenge | L4 | 状況音声・シーン説明ナレーション | P001〜P035 × 5〜8 ファイル |
| Echo Drill 録音比較 | L1 拡張 | 比較用「お手本音声」（Phase 2） | P001〜P065 × 3 ファイル |
| P036〜P065 音声 | L0〜L3 | Phase 2 パターン追加分 | +約 750 ファイル |
| P066〜P100 音声 | L0〜L3 | Phase 3 パターン追加分 | +約 875 ファイル |
| Mowi SE（効果音） | - | Mowi 反応音（非言語。Phase 2〜） | 20〜30 ファイル |
| 多言語ナレーション | - | 日本語 UI 読み上げ（Phase 3） | 別途試算 |

---

### 音声バリエーション戦略（Phase 2 以降の検討事項）

| 検討項目 | 内容 |
|---------|------|
| アクセント追加 | イギリス英語（`en-GB-Neural2-A` など）で一部問題にバリエーション付与 |
| 年齢感バリエーション | 子ども向け問題には若め声（`en-US-Neural2-J`）を追加 |
| 速度バリエーション | Layer 3 上級者向けに `1.15` 速度版を追加（スピードドリル強化） |

---

*MoWISE 音声アセット制作計画書 v1.0*  
*策定日：2026年3月10日*  
*次回更新：P001〜P010 コンテンツ設計完成後（マニフェスト JSON 作成時）*
