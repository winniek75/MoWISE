# MoWISE ゲームコンテンツ ブラッシュアップ 引き継ぎ書

## ミッション
18個の英語学習ゲームを「教育カリキュラム戦略」の観点でリサーチし、英語力を本当に強化できるコンテンツに改良する。

---

## Phase 1: 教育カリキュラム戦略リサーチ（先にやること）

各ゲームの改良前に、以下をリサーチ・設計してください：

### 1-1. ターゲット学習者の定義
- 小学校高学年〜中学生（英検5級〜3級レベル）
- 英会話教室の補助教材としての使用を想定
- 先生がクラスに「宿題」として割り当てるユースケース

### 1-2. カテゴリ別の教育目標
| カテゴリ | 目標 | 参考フレームワーク |
|---------|------|-------------------|
| vocabulary | 英検級別語彙の定着（受容→産出） | Nation's vocabulary levels, 英検語彙リスト |
| grammar | 文法パターンの自動化（意識的→無意識的処理） | DeKeyser's skill acquisition theory |
| phonics | 音素認識→デコーディング→流暢性 | Ehri's phases of word reading |
| writing | 語順感覚→文構成→短文産出 | Pienemann's processability theory |

### 1-3. ゲーム改良の教育原則
- **Spaced repetition**: 間違えた問題の再出題間隔を最適化
- **Scaffolding**: 難易度の段階的上昇（ヒント→ノーヒント）
- **Immediate feedback**: 正解/不正解の即時フィードバック＋解説
- **Productive failure**: 間違いから学べる設計
- **Interleaving**: カテゴリ混合で長期記憶を促進

---

## Phase 2: 全18ゲームの現状と改良方針

### アーキテクチャ共通事項
- MoWISEプラットフォーム: /Users/winnie/Desktop/LEAPxWISE/MoWISE/
- ゲームリポジトリ: /Users/winnie/Desktop/LEAPxWISE/apps/{game-name}/
- Supabase (mowisse): yytxgxlhgotscwztlsqj
- スコア連携: wise-xp-sdk が postMessage で MoWISE親に自動転送（設定済み）
- Vercel team: team_TKGb96EGEQmtpfqNSUXhgZQE

### スコア連携の仕組み（重要）
各ゲームは `WiseXP.reportGame({score, correct, total, maxCombo, grade})` を呼ぶ。
wise-xp-sdk（CDN: cdn.jsdelivr.net/gh/winniek75/wise-xp-sdk@main/wise-xp.js）が
iframe内で自動検知し、postMessage で MoWISE 親に GAME_COMPLETE を送信。
MoWISE側で game_scores テーブルに記録 → バッジ trigger 発火。

### ゲーム別改良候補

---

#### 1. eiken-game（英検クイズ）★ Free
- **フレームワーク**: React (1,332行)
- **パス**: apps/eiken-game/eiken-game/src/App.jsx
- **現状**: 英検語彙4択クイズ。級別選択あり
- **データ**: JSONの問題バンクあり
- **改良案**:
  - [ ] 間違えた語彙のSpaced repetition（WiseXP.reportWrong連携）
  - [ ] 問題に例文を追加（コンテキスト学習）
  - [ ] 音声読み上げ（Web Speech API）
  - [ ] 英検級別の出題頻度データに基づく問題重み付け

#### 2. fallingwordbattle（落下ワードバトル）★ Free
- **フレームワーク**: React (3,988行)
- **パス**: apps/fallingwordbattle/
- **現状**: 落下する英単語の意味を素早く選択
- **改良案**:
  - [ ] 落下速度を正答率に応じて動的調整
  - [ ] 出題語彙を英検級別にフィルタリング
  - [ ] 間違えた単語のリトライモード追加
  - [ ] コンボシステムの視覚的強化

#### 3. verbform-battle（動詞活用バトル）★ Free
- **フレームワーク**: React (2,848行)
- **パス**: apps/verbform-battle/
- **データ**: 動詞データJSONあり
- **現状**: 動詞の活用形（過去形・過去分詞等）を回答
- **改良案**:
  - [ ] 不規則動詞のパターン分類（ABB, ABC, ABA型等）
  - [ ] 文脈付き出題（"Yesterday I ___ to school" → went）
  - [ ] 活用表の視覚化・パターンマップ
  - [ ] 間違いやすい動詞のフォーカスモード

#### 4. flashinput（フラッシュ入力）
- **フレームワーク**: React (1,449行)
- **パス**: apps/flashinput/flushinput/
- **データ**: 2つのJSONデータファイル
- **現状**: 英単語を素早くタイピング
- **改良案**:
  - [ ] 日本語→英語、英語→日本語の双方向
  - [ ] タイピング速度に基づく WPM 計測
  - [ ] よく間違えるスペリングパターンの強化出題

#### 5. grammar-drill（文法ドリル）
- **フレームワーク**: React (1,110行)
- **パス**: apps/grammar-drill/
- **データ**: 問題JSONあり
- **改良案**:
  - [ ] 文法項目別（時制・助動詞・関係代名詞等）の体系的出題
  - [ ] 誤答分析→弱点文法の自動検出
  - [ ] 解説画面（なぜその答えか）の追加

#### 6. grammar-app（文法クラスルーム）
- **フレームワーク**: Next.js (8,560行) ← 最大規模
- **パス**: apps/grammar-app/
- **現状**: 文法レッスン＋練習問題
- **改良案**:
  - [ ] レッスン→練習→テストの3段階フロー
  - [ ] 英検級別の文法シラバス対応
  - [ ] 図解（時制タイムライン等）の追加

#### 7. eiken-grammar-game（英検文法）
- **フレームワーク**: バニラJS (index.html 1,448行の単一ファイル)
- **パス**: apps/eiken-grammar-game/index.html
- **改良案**:
  - [ ] React/Vue への移行検討（メンテナビリティ）
  - [ ] 英検過去問データの拡充
  - [ ] 選択肢の質向上（紛らわしい誤答 = distractors の改善）

#### 8. aredo-game（アレドクイズ）
- **フレームワーク**: バニラJS (index.html 1,414行)
- **パス**: apps/aredo-game/index.html
- **データ**: JSONデータ1件
- **改良案**:
  - [ ] 問題データの品質・量の拡充
  - [ ] ゲーム性の強化（タイムアタック、ランキング等）

#### 9. phonics（フォニックスゲーム）
- **フレームワーク**: Next.js (6,193行)
- **パス**: apps/phonics/
- **データ**: JSONデータ1件
- **現状**: フォニックスルール学習
- **改良案**:
  - [ ] 音素認識ドリル（minimal pairs: bat/bet, ship/sheep等）
  - [ ] ブレンディング練習（c-a-t → cat）
  - [ ] デコーディング段階の可視化
  - [ ] 音声認識による発音チェック（Web Speech API）

#### 10. phonics-battle（フォニックスバトル）
- **フレームワーク**: Next.js (1,236行)
- **パス**: apps/phonics-battle/
- **改良案**:
  - [ ] 対戦要素の強化（クラス内リアルタイムバトル）
  - [ ] 音声付き出題

#### 11. Phonics-sounds（フォニックスサウンド）
- **フレームワーク**: バニラJS (index.html 1,168行 + 62行JS)
- **パス**: apps/Phonics-sounds/
- **データ**: JSONデータ1件
- **改良案**:
  - [ ] 44英語音素の体系的カバー
  - [ ] IPA記号との対応表示
  - [ ] 録音→比較機能

#### 12. sight-words-memory（サイトワード記憶）
- **フレームワーク**: React (1,316行)
- **パス**: apps/sight-words-memory/
- **現状**: 頻出単語の記憶ゲーム（神経衰弱系？）
- **改良案**:
  - [ ] Dolch/Fry sight word リストに基づく段階的学習
  - [ ] 読み上げ→単語選択のリスニングモード
  - [ ] フラッシュカードモードの追加

#### 13. instant-english-app（インスタント英語）
- **フレームワーク**: React (3,247行)
- **パス**: apps/instant-english-app/
- **データ**: JSONデータ1件
- **改良案**:
  - [ ] 瞬間英作文メソッド（日→英変換）の体系化
  - [ ] 難易度段階: 単語→句→文→複文
  - [ ] 音声入力での回答オプション

#### 14. sentence-dash（センテンスダッシュ）
- **フレームワーク**: バニラJS (index.html 173行 + 2,136行JS)
- **パス**: apps/sentence-dash/
- **データ**: JSONデータ1件
- **改良案**:
  - [ ] 語順並べ替え問題の質向上
  - [ ] SVO/SVOCなど文型パターン別の出題
  - [ ] 制限時間内のスコアアタック

#### 15. wh-questiongame（WH質問ゲーム）
- **フレームワーク**: バニラJS (index.html 993行)
- **パス**: apps/wh-questiongame/
- **データ**: JSONデータ1件
- **改良案**:
  - [ ] What/Where/When/Who/Why/How の体系的カバー
  - [ ] 質問生成練習（答えから質問を作る逆方向）
  - [ ] 会話シミュレーション形式

#### 16. wise-english-floor（ザ・フロア）
- **フレームワーク**: React (2,854行)
- **パス**: apps/wise-english-floor/
- **データ**: JSONデータ1件
- **改良案**:
  - [ ] ゲーム性の詳細調査後に判断
  - [ ] 複合スキル（語彙+文法+リスニング）の統合テスト化

#### 17. eiken-sns-app（英検SNS）
- **フレームワーク**: React (2,340行)
- **パス**: apps/eiken-sns-app/
- **現状**: SNS形式で英検学習
- **改良案**:
  - [ ] SNS投稿風の英作文練習
  - [ ] 模擬会話（チャット形式）での文法・語彙練習

#### 18. eiken-challenge（英検チャレンジ）
- **フレームワーク**: React (922行)
- **パス**: apps/eiken-challenge/
- **現状**: 英検総合チャレンジ
- **改良案**:
  - [ ] 英検模擬テスト形式（リーディング+リスニング+ライティング）
  - [ ] 級別の合格予測スコア表示

---

## Phase 3: 改良の優先順位（推奨）

### Tier 1: Free ゲーム（最優先 — 全ユーザーが触る）
1. **eiken-game** — 語彙の定着率向上（SR + 音声 + 例文）
2. **fallingwordbattle** — 級別フィルタ + 動的難易度
3. **verbform-battle** — 文脈付き出題 + パターン分類

### Tier 2: カテゴリ代表（各カテゴリ1本ずつ磨く）
4. **grammar-drill** — 解説画面 + 弱点検出
5. **phonics** — 音素認識ドリル + 音声
6. **instant-english-app** — 瞬間英作文の体系化

### Tier 3: 残り（Tier 1-2完了後）
7-18: 上記で得たパターンを横展開

---

## 技術的な注意事項

### スコア連携（必須）
各ゲームのゲーム終了時に以下を呼ぶこと：
```js
// wise-xp-sdk が自動でMoWISEに転送する
WiseXP.reportGame({
  score: 1500,        // スコア
  correct: 8,         // 正答数
  total: 10,          // 総問題数
  maxCombo: 5,        // 最大コンボ
  grade: '5',         // 英検級 等
  durationSeconds: 120 // プレイ時間
});
```

### 間違い記録（推奨）
```js
WiseXP.reportWrong({
  question: '"apple" means?',
  correct: 'りんご',
  playerAnswer: 'みかん'
});
```

### フレームワーク別の対応
- **React系** (eiken-game, fallingwordbattle, etc.): src/App.jsx を編集
- **Next.js系** (grammar-app, phonics, phonics-battle): pages/ or app/ を編集
- **バニラJS** (aredo-game, eiken-grammar-game, wh-questiongame, Phonics-sounds): index.html を直接編集
- **注意**: バニラJS系は1ファイルに全ロジック。大規模改修ならReact化も検討

### デプロイ
各ゲームはVercel連携済み。`git push origin main` でデプロイされる。
Vercel team: team_TKGb96EGEQmtpfqNSUXhgZQE

---

## 進め方の指示

1. **このファイルを新しいチャットの最初に読み込ませる**
2. 「Phase 1 の教育カリキュラムリサーチから始めて」と指示
3. リサーチ結果に基づいて Tier 1 の3本から着手
4. 1ゲームずつ完了 → テスト → 次のゲームへ

新チャットでの最初のプロンプト例：
```
/Users/winnie/Desktop/LEAPxWISE/MoWISE/GAME_BRUSHUP_HANDOFF.md を読んで。
MoWISEプラットフォームの18個の英語学習ゲームのブラッシュアップ。
Phase 1 の教育カリキュラム戦略リサーチから始めて、
Tier 1（eiken-game, fallingwordbattle, verbform-battle）の改良計画を策定して。
```
