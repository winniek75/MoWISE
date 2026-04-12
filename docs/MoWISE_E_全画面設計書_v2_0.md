# MoWISE｜全画面設計書（画面遷移マップ + UI仕様）
**バージョン：v2.0**
**策定日：2026年3月10日**
**ステータス：設計確定・エンジニア実装引き渡し用マスタードキュメント**

> **v1.0 → v2.0 変更サマリー**
> | 変更箇所 | 内容 |
> |---------|------|
> | 画面インベントリ | `LAYER_2_SVO`・`LAYER_3_SPRINT` 2画面追加（#27・#28）|
> | SCREEN 10 補足 | Layer 2 → SVO Block モード遷移フロー追記 |
> | SCREEN 11 補足 | Layer 3 → Flash Sprint Mode 遷移フロー追記 |
> | **SCREEN 27（新規）** | SVOブロック画面（Layer 2 Pattern Sense ゲーム化）完全仕様 |
> | **SCREEN 28（新規）** | Flash Sprint Mode画面（Layer 3 ゲーム化）完全仕様 |
> | Vue Router | 2新画面のpath定義追加 |
> | 全画面遷移フロー | 2-4節「ゲーム化Layerフロー」追加 |
> | **Section 9（新規）** | Supabaseへの読み書きタイミング一覧 |

> **参照先設計書**
> - C2：`MoWISE_C2_チェックイン日記UX設計_v3_0.md`（チェックイン・ログ画面の詳細仕様）
> - H2：`MoWISE_H2_コアゲームループUI設計_v1_0.md`（問題・コンボ・セッション終了の詳細仕様）
> - F：`MoWISE_F_Supabaseスキーマ_v1_0.md`（テーブル定義・RLS）
> - ゲーム設計：`mowwise_game_integration.jsx`（ゲームメカニクス統合方針）

---

# 0. 設計の大前提

| ルール | 内容 |
|--------|------|
| **デバイス** | スマートフォン縦持ち専用（375px基準。タブレット対応は Phase 2）|
| **OS** | iOS / Android（Capacitor でネイティブビルド）|
| **フレームワーク** | Vue 3 + Composition API |
| **デザイントークン** | 本書末尾に記載（カラー・タイポ・スペーシング）|
| **Mowiエリア** | 全画面で上部1/4〜1/3に配置。常に画面内に存在すること |
| **スキップボタン** | チェックイン選択画面には表示しない（コアポリシー・例外なし）|
| **戻るボタン** | 問題画面中は「終了確認ダイアログ」を経由する |
| **ボトムナビ** | 5タブ常時表示（問題画面・ゲーム化Layer画面中のみ非表示）|

---

# 1. 全画面インベントリ

## 1-1. 画面一覧（MVP対象のみ）

| # | 画面ID | 画面名 | カテゴリ | 詳細設計書 |
|---|--------|--------|----------|-----------|
| 01 | `SPLASH` | スプラッシュ画面 | 起動 | 本書 |
| 02 | `ONBOARDING_*` | オンボーディング（5画面） | 初回 | C設計書 |
| 03 | `HOME` | ホーム画面 | メイン | H2 / 本書 |
| 04 | `CHECKIN_MORNING` | 朝チェックイン | チェックイン | C2 |
| 05 | `MOWI_REACTION` | Mowiリアクション（共通）| チェックイン | C2 |
| 06 | `CARD_TODAY` | 今日の一言カード | チェックイン | C2 |
| 07 | `SESSION_START` | パターン選択・セッション開始 | 練習 | H2 |
| 08 | `LAYER_0` | Layer 0 問題画面 | 練習 | H2 |
| 09 | `LAYER_1` | Layer 1 問題画面 | 練習 | H2 |
| 10 | `LAYER_2` | Layer 2 問題画面（標準）| 練習 | H2 |
| 11 | `LAYER_3` | Layer 3 問題画面（標準）| 練習 | H2 |
| 12 | `COMBO_BREAK` | コンボ切れダイアログ | 練習 | H2 |
| 13 | `SESSION_END` | セッション終了画面 | 練習 | H2 |
| 14 | `PATTERN_MASTER` | パターンマスター演出 | 練習 | H2 |
| 15 | `PATTERN_UNLOCK` | 新パターン解禁演出 | 練習 | H2 |
| 16 | `CHECKIN_NIGHT_PROMPT` | 夜チェックイン誘導 | チェックイン | C2 |
| 17 | `CHECKIN_NIGHT` | 夜チェックイン | チェックイン | C2 |
| 18 | `DIFF_FEEDBACK` | 朝×夜差分フィードバック | チェックイン | C2 |
| 19 | `CARD_SAVE` | 今日の記録保存カード | チェックイン | C2 |
| 20 | `ZUKAN` | パターン図鑑（一覧）| 図鑑 | 本書 |
| 21 | `ZUKAN_DETAIL` | パターン詳細 | 図鑑 | 本書 |
| 22 | `LOG_WEEKLY` | 週次ログビュー | 記録 | C2 |
| 23 | `LOG_MONTHLY` | 月次ログビュー | 記録 | C2 |
| 24 | `LOG_3MONTHS` | 3ヶ月振り返り | 記録 | C2 |
| 25 | `TEACHER_MSG` | 先生からのメッセージカード | 通知 | C2 |
| 26 | `SETTINGS` | 設定画面 | 設定 | 本書 |
| **27** | **`LAYER_2_SVO`** | **SVOブロック画面（Layer 2 ゲーム化）** | **練習** | **本書（v2.0新規）** |
| **28** | **`LAYER_3_SPRINT`** | **Flash Sprint Mode（Layer 3 ゲーム化）** | **練習** | **本書（v2.0新規）** |

---

# 2. 全画面遷移マップ

## 2-1. アプリ起動フロー

```
                    ┌─────────────┐
                    │  OS起動     │
                    └──────┬──────┘
                           ↓
                    ┌─────────────┐
                    │  SPLASH     │ ← 1.5秒表示。Mowiがふわっと登場
                    └──────┬──────┘
                           ↓
              ┌────────────┴────────────┐
              │  初回起動か？             │
              ├─ YES ───────────────────►  ONBOARDING_1〜5
              │                               ↓
              │                          HOME（初回）
              │
              └─ NO（2回目以降）─────────────────────────────┐
                                                             │
                    ┌──────────────────────────────────────┘
                    ↓
              ┌─────────────────────────────────────┐
              │ 先生メッセージ未読あり？              │
              ├─ YES ──────────► TEACHER_MSG ──────► HOME
              └─ NO ──────────────────────────────────┐
                                                       ↓
                    ┌──────────────────────────────────┐
                    │ 今日の朝チェックイン済みか？      │
                    ├─ NO ──► CHECKIN_MORNING
                    │              ↓
                    │         MOWI_REACTION（800ms）
                    │              ↓
                    │         CARD_TODAY（2秒）
                    │              ↓
                    │         HOME
                    │
                    └─ YES ──► HOME
```

## 2-2. メインループ（ホーム起点）

```
                         ┌────────────┐
                         │   HOME     │
                         └─────┬──────┘
                               │
          ┌────────────────────┼────────────────────┐
          ↓                    ↓                    ↓
   [練習を始める]         [図鑑を見る]          [記録を見る]
          │                    │                    │
          ↓                    ↓                    ↓
   SESSION_START            ZUKAN              LOG_WEEKLY
          │                    │                    │
          │              ZUKAN_DETAIL         LOG_MONTHLY
          ↓                                         │
   LAYER_0/1                               LOG_3MONTHS
   ↓
   LAYER_2（標準）──[ゲーム化解禁]──► LAYER_2_SVO
   ↓
   LAYER_3（標準）──[ゲーム化解禁]──► LAYER_3_SPRINT
          │
          ├── 正解 → 継続
          ├── 不正解 → COMBO_BREAK（コンボ3+の場合）
          │
          ↓
   SESSION_END
          │
          ├── PATTERN_MASTER（★5達成時）
          ├── PATTERN_UNLOCK（新解禁時）
          │
          ↓
   CHECKIN_NIGHT_PROMPT
          │
          ├─[答える] ─► CHECKIN_NIGHT
          │                   ↓
          │              MOWI_REACTION（800ms）
          │                   ↓
          │              DIFF_FEEDBACK
          │                   ↓
          │              CARD_SAVE
          │                   ↓
          │              HOME
          │
          └─[あとで] ─► HOME（夜未記録フラグ保持）
```

## 2-3. ボトムナビゲーション遷移

```
┌──────────────────────────────────────────┐
│  🏠 ホーム  ▶ 練習  📖 図鑑  📊 記録  ⚙ 設定 │
└──────────────────────────────────────────┘

タブ選択時の遷移：
  🏠 ホーム  → HOME
  ▶ 練習    → SESSION_START
  📖 図鑑   → ZUKAN
  📊 記録   → LOG_WEEKLY（デフォルト）
  ⚙ 設定   → SETTINGS
```

## 2-4. ゲーム化 Layer フロー（v2.0 新規）

```
  ┌──────────────────────────────────────────────────────────────────┐
  │                  Layer 2 Pattern Sense フロー                     │
  └──────────────────────────────────────────────────────────────────┘

  SESSION_START（P×××選択）
         ↓
  LAYER_2（標準：スロット穴埋め）
         │
         ├─ [ゲーム化モード有効かつパターン★2以上] ──────────────────┐
         │   ※ セッション開始時に自動判定                              │
         │   ※ ゲーム化ON/OFFはSETTINGSで変更可                       │
         ↓                                                            ↓
  標準モード継続                                           LAYER_2_SVO
  （スロット穴埋め）                                  （SVOブロック選択）
         │                                                            │
         └──────────────────────┬─────────────────────────────────────┘
                                ↓
                        Layer 3 へ進む（★3解禁）

  ┌──────────────────────────────────────────────────────────────────┐
  │                  Layer 3 Flash Output フロー                      │
  └──────────────────────────────────────────────────────────────────┘

  LAYER_3（標準：タイル選択 / キーボード入力）
         │
         ├─ [ゲーム化モード有効かつパターン★3以上] ──────────────────┐
         ↓                                                            ↓
  標準モード継続                                        LAYER_3_SPRINT
  （タイル選択）                                    （Flash Sprint Mode）
         │                                                            │
         └──────────────────────┬─────────────────────────────────────┘
                                ↓
                        SESSION_END（通常フローへ戻る）

  ┌──────────────────────────────────────────────────────────────────┐
  │              LAYER_2_SVO / LAYER_3_SPRINT 共通フロー              │
  └──────────────────────────────────────────────────────────────────┘

  ゲーム化Layer画面
         │
         ├── [× 終了] タップ ─────► 終了確認ダイアログ ────► SESSION_END
         │
         ├── ゲームクリア（全問完了）──► 完了アニメーション ──► SESSION_END
         │
         └── ゲームオーバー（タイムアップ連続3回）──► COMBO_BREAK ──► SESSION_END
```

---

# 3. 各画面の設計仕様

> **記載方針：** C2・H2に詳細仕様がある画面は「→ 参照先を明示 + 追加補足のみ」。本書オリジナルの画面は完全仕様を記載。

---

## SCREEN 01：スプラッシュ画面（`SPLASH`）

```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│                                         │
│                                         │
│         [Mowi・登場アニメーション]        │
│          （下からふわっと浮上）           │
│                                         │
│              MoWISE                     │
│         もっと賢く、英語と生きる          │
│                                         │
│                                         │
│                                         │
│         WISE English Club               │
│                                         │
└─────────────────────────────────────────┘
```

| 項目 | 仕様 |
|------|------|
| **表示時間** | 1.5秒。その間にログイン状態・チェックイン状態を非同期チェック |
| **背景** | 深夜グラデーション（#0d0d1a → #1a1040）|
| **Mowiアニメ** | 画面中央下から浮上（500ms）→ Idle浮遊へ移行 |
| **ロゴ** | MoWISEロゴ（brand_system.jsxのデザイン準拠）|
| **遷移** | 1.5秒後に自動でONBOARDING or HOME へ |

---

## SCREEN 03：ホーム画面（`HOME`）

**→ 詳細仕様：H2設計書「② ホーム画面」**

```
┌─────────────────────────────────────────┐
│  ステータスバー（OS標準）                 │
│─────────────────────────────────────────│
│  🔥 N日連続         Lv.3 ████░░ 62%    │
│─────────────────────────────────────────│
│                                         │
│         [Mowi エリア]                    │
│     今日の朝状態 × コンボ履歴で輝度決定   │
│         「今日も、ここにいる。」          │
│                                         │
│─────────────────────────────────────────│
│  ── 今日の練習 ──                        │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  ▶ デイリー練習を始める [未完了]  │    │
│  │    P007〜P010 ｜ 推定8分         │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌──────────────┐  ┌──────────────────┐  │
│  │  📖 パターン図鑑│  │  📊 記録・ログ  │  │
│  └──────────────┘  └──────────────────┘  │
│─────────────────────────────────────────│
│  🏠    ▶    📖    📊    ⚙              │  ← ボトムナビ
└─────────────────────────────────────────┘
```

**本書追加補足（H2に未記載事項）**

| 項目 | 仕様 |
|------|------|
| **夜未記録バナー** | 前日夜チェックイン未記録 + 朝13:59以前の場合：ホーム上部に「昨日の夜を記録する」バナー表示。タップで `CHECKIN_NIGHT`（後追いモード）へ |
| **完了後のホーム** | デイリー練習完了後：練習ボタンが「✅ 今日の練習、完了」に変わる。グレー化するが非活性ではない（復習として再挑戦可）|
| **プッシュ通知バッジ** | 先生メッセージ未読時：ボトムナビ「🏠」にバッジ表示 |

---

## SCREEN 04：朝チェックイン画面（`CHECKIN_MORNING`）

**→ 詳細仕様：C2設計書「② 2-1. 朝チェックイン画面」**

**本書追加補足**

| 項目 | 仕様 |
|------|------|
| **ルーティング** | アプリ起動時に条件分岐で自動遷移。ユーザーが意図してナビゲートする画面ではない |
| **アニメーション遷移** | SPLASH/HOME から `slide-up` でモーダル的に登場 |
| **バックジェスチャー** | iOS/Android の戻るジェスチャーは無効化（選択を完了させる）|

---

## SCREEN 05：Mowiリアクション画面（`MOWI_REACTION`）

**→ 詳細仕様：C2設計書「② 2-3. Mowiリアクション画面」**

**本書追加補足**

| 項目 | 仕様 |
|------|------|
| **Vue コンポーネント名** | `<MowiReactionOverlay>` として実装。モーダルオーバーレイ形式 |
| **遷移アニメ** | `fade-in` 200ms → 800ms表示 → `fade-out` 200ms → 次画面へ |
| **タップ領域** | 画面全体。どこをタップしても即スキップ |

---

## SCREEN 06：今日の一言カード（`CARD_TODAY`）

**→ 詳細仕様：C2設計書「② 2-4. 今日の一言カード」**

---

## SCREEN 07：パターン選択・セッション開始（`SESSION_START`）

**→ 詳細仕様：H2設計書「③ パターン選択 / セッション開始画面」**

**本書追加補足**

| 項目 | 仕様 |
|------|------|
| **空状態** | 全パターン完了・弱点なしの場合：「今日の練習、全部終わった。」Mowiが特別セリフ |
| **弱点パターンの自動選択ロジック** | `pattern_progress.next_review_at <= now()` のパターンを優先。最大4件 |

---

## SCREEN 08〜11：Layer 0〜3 問題画面（`LAYER_0`〜`LAYER_3`）

**→ 詳細仕様：H2設計書「④ Layer別 問題画面 UI仕様」「⑤ コンボゲージ & Mowi輝き連動システム」「⑥ 正解・不正解時のUI挙動」**

**本書追加補足：問題画面の共通ヘッダー仕様**

```
┌─────────────────────────────────────────┐
│  [× 終了]   P007｜Layer 3   [3/5問]     │
│─────────────────────────────────────────│
```

| 要素 | 仕様 |
|------|------|
| **「× 終了」ボタン** | タップで終了確認ダイアログ表示（後述）|
| **パターン表示** | `P007` ＋ `Layer 3` を表示。タップでパターン詳細ポップアップ（任意）|
| **問題カウント** | `3/5問` 形式。セッション総問数はセッション開始時に決定 |

**終了確認ダイアログ**
```
┌────────────────────────────────────────┐
│                                        │
│  練習を終了しますか？                   │
│  今回の記録は保存されます              │
│                                        │
│  [やめる]          [続ける]            │
│                                        │
└────────────────────────────────────────┘
```

**Layer 2・Layer 3 ゲーム化モードへの切り替えルール（v2.0 追記）**

| 条件 | 挙動 |
|------|------|
| `pattern_progress.stars >= 2` かつゲーム化ON | Layer 2 開始時に `LAYER_2_SVO` へ自動ルーティング |
| `pattern_progress.stars >= 3` かつゲーム化ON | Layer 3 開始時に `LAYER_3_SPRINT` へ自動ルーティング |
| ゲーム化OFF（設定）| 標準の `LAYER_2` / `LAYER_3` 画面を使用 |
| 初回学習（★0→★）| 常に標準画面（慣れを優先）|

---

## SCREEN 12：コンボ切れダイアログ（`COMBO_BREAK`）

**→ 詳細仕様：H2設計書「⑥ 正解・不正解時のUI挙動 / もう一回ダイアログ」**

---

## SCREEN 13：セッション終了画面（`SESSION_END`）

**→ 詳細仕様：H2設計書「⑦ セッション終了画面」**

---

## SCREEN 14：パターンマスター演出（`PATTERN_MASTER`）

**→ 詳細仕様：H2設計書「⑧ ★UP / パターン完了演出」**

---

## SCREEN 15：新パターン解禁演出（`PATTERN_UNLOCK`）

**→ 詳細仕様：H2設計書「⑨ 新パターン解禁演出」**

---

## SCREEN 16：夜チェックイン誘導（`CHECKIN_NIGHT_PROMPT`）

```
┌─────────────────────────────────────────┐
│                                         │
│         🌙                              │
│                                         │
│     [Mowi・Growアニメーション]            │
│       （セッション終了後の状態）          │
│                                         │
│         今日の練習、どうだった？          │
│         How did practice go today?     │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │     答える（夜チェックインへ）    │    │  ← 主CTA
│  └─────────────────────────────────┘    │
│                                         │
│         あとで記録する                   │  ← 控えめリンク
│                                         │
└─────────────────────────────────────────┘
```

| 項目 | 仕様 |
|------|------|
| **表示タイミング** | SESSION_END から3秒後に自動遷移 |
| **「あとで記録する」** | タップでHOMEへ。夜チェックイン未実施フラグを `checkins` テーブルに保持 |
| **Mowiセリフ** | `TRIGGER_SESSION_END` セリフを継続表示（SESSION_ENDから引き継ぎ）|
| **背景** | 夜グラデーション（#0d0d1a → #4a0e8f）|

---

## SCREEN 17：夜チェックイン画面（`CHECKIN_NIGHT`）

**→ 詳細仕様：C2設計書「② 2-2. 夜チェックイン画面」**

---

## SCREEN 18：朝×夜差分フィードバック（`DIFF_FEEDBACK`）

**→ 詳細仕様：C2設計書「② 2-5. 朝×夜差分フィードバック画面」**

---

## SCREEN 19：今日の記録保存カード（`CARD_SAVE`）

**→ 詳細仕様：C2設計書「② 2-4. 今日の一言カード（夜版）」**

**朝版との差分**

| 項目 | 朝版（`CARD_TODAY`）| 夜版（`CARD_SAVE`）|
|------|--------------------|--------------------|
| **表示内容** | 朝の選択 + Mowiセリフ | 朝＋夜の両選択 + 差分セリフ |
| **ストリーク** | 表示 | 表示（夜まで完了したので確定値）|
| **保存ボタン** | あり | あり |
| **シェアボタン** | あり | あり（より充実した内容）|
| **次のアクション** | 2秒後HOME | [ホームへ戻る] ボタン（自動遷移なし）|

---

## SCREEN 20：パターン図鑑（一覧）（`ZUKAN`）

```
┌─────────────────────────────────────────┐
│  パターン図鑑                      [検索]│
│─────────────────────────────────────────│
│                                         │
│  ── エリア1：はじまりの村 ──            │
│  P001〜P020                             │
│                                         │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │  P001    │ │  P002    │ │  P003    │  │
│  │ I'm [~]. │ │This is ~ │ │Nice to  │  │
│  │ ★★★★☆  │ │  ★★☆☆☆ │ │ ★☆☆☆☆  │  │
│  └──────────┘ └──────────┘ └──────────┘  │
│                                         │
│  ── エリア2：街の市場 ──               │
│  P021〜P045 🔒（P020まで★3で解禁）     │
│                                         │
│─────────────────────────────────────────│
│  🏠    ▶    📖    📊    ⚙              │
└─────────────────────────────────────────┘
```

| 項目 | 仕様 |
|------|------|
| **レイアウト** | 3列グリッド。各カード：正方形・角丸12px |
| **カード表示** | パターン番号・パターン冒頭（省略）・★レベル（0〜5）|
| **未習得パターン** | グレーアウト。タップで詳細は見られる |
| **ロックエリア** | 未解禁エリアは 🔒 マーク＋解禁条件を表示 |
| **エリア区切り** | セクションヘッダーでエリア名を表示 |

---

## SCREEN 21：パターン詳細（`ZUKAN_DETAIL`）

```
┌─────────────────────────────────────────┐
│  ← 戻る          P007                   │
│─────────────────────────────────────────│
│                                         │
│  I'd like [名詞].                        │
│  〜をお願いします                        │
│                                         │
│  ★★★☆☆  Layer 3 まで完了              │
│  ─────────────────────────────          │
│  ── 例文 ──                             │
│  🔊 "I'd like a coffee, please."        │
│     コーヒーをお願いします              │
│  ─────────────────────────────          │
│  ── 進化形 ──                           │
│  P011：I'd love to [動詞].（★5で解禁）  │
│                                         │
│  [この パターンを練習する]               │
│                                         │
│─────────────────────────────────────────│
│  🏠    ▶    📖    📊    ⚙              │
└─────────────────────────────────────────┘
```

---

## SCREEN 22〜24：記録ログ（`LOG_WEEKLY`/`LOG_MONTHLY`/`LOG_3MONTHS`）

**→ 詳細仕様：C2設計書「③ 過去ログの見せ方」**

---

## SCREEN 25：先生からのメッセージカード（`TEACHER_MSG`）

**→ 詳細仕様：C2設計書「④ 4-3. 先生→生徒へのフィードバックフロー」**

割り込み表示の優先順位：
1. TEACHER_MSG（最優先）
2. LOG_3MONTHS モーダル（3ヶ月目日曜日のみ）
3. CHECKIN_MORNING（朝未記録の場合）
4. HOME

---

## SCREEN 26：設定画面（`SETTINGS`）

```
┌─────────────────────────────────────────┐
│  設定                                    │
│─────────────────────────────────────────│
│  ── アカウント ──                        │
│  名前：田中 花子                         │
│  クラス：中学2年A組                      │
│                                         │
│  ── 通知 ──                             │
│  朝チェックイン通知   [ON / OFF]         │
│  夜チェックイン通知   [ON / OFF]         │
│  練習リマインダー     [ON / OFF]         │
│  通知時刻（朝）      [07:30 ▼]          │
│  通知時刻（夜）      [20:00 ▼]          │
│                                         │
│  ── 練習モード ──                        │
│  ゲーム化Layer      [ON / OFF]          │  ← v2.0 追加
│  （Layer2 SVO・Layer3 Sprint有効化）     │
│                                         │
│  ── 表示 ──                             │
│  表示言語           [日本語 ▼]           │
│  英語表示           [ON / OFF]          │
│                                         │
│  ── その他 ──                           │
│  プライバシーポリシー               [>]  │
│  利用規約                           [>]  │
│  ログアウト                              │
│                                         │
│─────────────────────────────────────────│
│  🏠    ▶    📖    📊    ⚙              │
└─────────────────────────────────────────┘
```

---

## ★ SCREEN 27：SVOブロック画面（`LAYER_2_SVO`）【v2.0 新規】

### 概要

**Layer 2 Pattern Sense のゲーム化版。** Word Block Quest 型（Tetris クローン）のメカニクスを使い、SVO色分けブロックを正しい語順でスロットにはめ込む。品詞名を一切使わず「並びの感覚」だけで語順を体得する。

> **設計哲学（v3.1準拠）：** 「動詞・名詞・形容詞」という言葉を使わない。色だけで語順の感覚を脳に入れる。

### ワイヤーフレーム

```
┌─────────────────────────────────────────┐
│  [× 終了]   P007 Layer 2 SVO   [2/4問] │  ← ヘッダー（共通形式）
│─────────────────────────────────────────│
│  ████████████████░░░░░░░░  コンボ: 3   │  ← コンボゲージ
│─────────────────────────────────────────│
│                                         │
│  [Mowi エリア]                           │
│  「この並び、体に聞いてみて。」           │
│                                         │
│─────────────────────────────────────────│
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  🇯🇵  コーヒーをお願いします。       │  │  ← 日本語提示
│  └───────────────────────────────────┘  │
│                                         │
│  ── 文を作ってみよう ──                  │
│                                         │
│  ┌──────────┬──────────┬──────────┐    │
│  │  🔵      │  🔴      │  🟡      │    │  ← SVO スロット（空）
│  │ [    ]   │ [    ]   │ [    ]   │    │
│  └──────────┴──────────┴──────────┘    │
│                                         │
│  ── 単語ブロック（タップで選択）──        │
│                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐     │
│  │🔵 I'd  │ │🔴 like │ │🟡 a    │     │
│  └────────┘ └────────┘ └────────┘     │
│                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐     │
│  │🟡coffee│ │🟡please│ │🔴 want │     │  ← ダミーブロック含む
│  └────────┘ └────────┘ └────────┘     │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │           ✅ 送信                │    │  ← 全スロット埋まりで活性化
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### SVOカラーコード

| 色 | 役割 | 対象 | CSS変数 |
|---|------|------|---------|
| 🔵 **ブルー** | 主語ブロック（Subject）| I / You / She / We など | `--svo-subject: #4A7AFF` |
| 🔴 **レッド** | 動詞ブロック（Verb）| like / want / have / go など | `--svo-verb: #F44336` |
| 🟡 **イエロー** | 目的語・補語ブロック（Object/Complement）| a coffee / tired / from Japan など | `--svo-object: #FFD700` |
| ⬜ **ホワイト** | 固定語（変更不可）| I'd / please / . など | `--svo-fixed: #E0E0E0` |

### UI仕様詳細

| 項目 | 仕様 |
|------|------|
| **出題数** | 1パターンにつき4〜6問 |
| **スロット数** | パターン構造に合わせて2〜5スロット |
| **ブロック選択** | タップで選択 → スロットに自動充填（左から順）。誤配置はスロットをタップしてリセット |
| **固定語** | I'd・please・. などはグレーで表示済み・タップ不可 |
| **送信ボタン** | 全スロット埋まりで活性化。タップで判定 |
| **正解時** | スロット全体が緑色フラッシュ（200ms）→ 音声自動再生 → 次問へ（300ms後）|
| **不正解時** | ブロックが赤く震える → 不自然な文を音声再生 → Mowiが「…なんか変」→ リセット |
| **タイムアップ** | 制限なし（SVOは考える時間を保証）。ただしコンボゲージは時間で減衰 |
| **SM-2連動** | 7日前に間違えたブロック問題が「おじゃまブロック」として最初3問に混入 |

### 状況イラスト表示

```
┌─────────────────────────────────────────┐
│  ┌──────────────────────────────────┐   │
│  │  [状況イラスト：カフェのカウンター] │   │  ← 問題エリア上部に表示
│  │      🧑‍💻 ☕ 📋                   │   │    （二重符号化・視覚記憶強化）
│  └──────────────────────────────────┘   │
```

| 項目 | 仕様 |
|------|------|
| **イラストサイズ** | 横幅100% × 高さ80px（アスペクト比維持）|
| **格納先** | Supabase Storage。`pattern_content.illustration_url` から取得 |
| **なし時の代替** | 🇯🇵 日本語のみ表示（Phase 1 はイラストなしでもOK）|

### Mowiセリフ（SVO専用）

| タイミング | セリフ例 |
|-----------|---------|
| 問題開始時 | 「この並び、体に聞いてみて。」|
| 正解時 | 「その感じ。」「ちゃんと並んでる。」|
| 不正解時 | 「…なんか変。」「その並び、しっくりこない。」|
| コンボ3+ | 「感覚が開いてきた。」|
| 全問クリア | 「並びが、見えてきた。」|

### Supabase 読み書き（`LAYER_2_SVO`）

| タイミング | テーブル | 操作 | フィールド |
|-----------|---------|------|-----------|
| 画面マウント時 | `pattern_content` | READ | `layer_2_questions`（SVO問題セット）|
| 画面マウント時 | `pattern_progress` | READ | `stars`, `ease_factor`（難易度調整用）|
| 1問正解時 | `flash_output_logs` | INSERT | `pattern_id`, `is_correct=true`, `response_ms`, `layer=2` |
| 1問不正解時 | `flash_output_logs` | INSERT | `pattern_id`, `is_correct=false`, `response_ms`, `layer=2` |
| 全問完了時 | `pattern_progress` | UPDATE | `stars`（+0.5相当）, `next_review_at`（SM-2計算）|
| 全問完了時 | `mowi_state` | UPDATE | `combo_count`, `glow_level` |

---

## ★ SCREEN 28：Flash Sprint Mode（`LAYER_3_SPRINT`）【v2.0 新規】

### 概要

**Layer 3 Flash Output のゲーム化版。** Sentence Dash 型（Subway Surfers本体インスパイア）のメカニクスを使い、流れてくる単語・フレーズを正しい語順でタップし続ける。コンボで加速感・Mowi輝き連動。**MVP最重要画面。**

> **実装方針：** 既存の Flash Output（タイル選択）にレーン演出を追加するだけ。最小工数で最大ゲーム効果。

### ワイヤーフレーム

```
┌─────────────────────────────────────────┐
│  [× 終了]  P007 Flash Sprint  [3/5問]  │  ← ヘッダー
│─────────────────────────────────────────│
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  ⚡ I'd like [名詞].             │    │  ← 今日のパターン（常時表示）
│  │  〜をお願いします                 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ████████████████░░░░░░░  コンボ: 5 🔥 │  ← コンボゲージ（太め・派手）
│                                         │
│─────────────────────────────────────────│
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  🇯🇵  コーヒーをお願いします       │  │  ← 問題（日本語）
│  └───────────────────────────────────┘  │
│                                         │
│  ⏱  ░░░░░░░░░░░░░░░░  残り 6秒        │  ← タイマーバー（緊張感演出）
│                                         │
│─────────────────────────────────────────│
│                                         │
│  ── 回答組み立てエリア ──                │
│  ┌─────────────────────────────────┐    │
│  │  I'd  like  ___  ___  ___       │    │  ← 固定語 + 空スロット
│  └─────────────────────────────────┘    │
│                                         │
│  ── タイル（タップで選択）──             │
│                                         │
│  ┌────────┐ ┌────────┐ ┌────────┐      │
│  │  a     │ │ coffee │ │ please │      │  ← 正解タイル
│  └────────┘ └────────┘ └────────┘      │
│  ┌────────┐ ┌────────┐                  │
│  │  want  │ │  the   │                  │  ← ダミータイル
│  └────────┘ └────────┘                  │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │           ✅ 送信                │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  [Mowi エリア]                   │    │
│  │  コンボ5→光り輝いている          │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
```

### 難易度レベル

| レベル | 形式 | 発動条件 | タイム制限 |
|--------|------|---------|----------|
| **Lv.1 初級** | タイル選択式（バラバラ単語を並べる）| 初回・コンボ0〜2 | 8秒 |
| **Lv.2 中級** | タイル選択式（ダミー多め）| コンボ3〜4継続 | 6秒 |
| **Lv.3 上級** | ノーヒント瞬間英作文（タイルなし・キーボード入力）| **コンボ5連続** で自動解禁 | 10秒 |

### Sprint特有のゲームメカニクス

| 要素 | 仕様 |
|------|------|
| **パターン常時表示** | 画面上部に `⚡ I'd like [名詞].` を常時表示。問題ごとに消えない（刷り込み設計）|
| **初回特別演出** | スプリント1問目は必ず新パターン。特殊BGM（♪）+ Mowi発光演出（primacy effect）|
| **加速コンボ** | コンボ3+：タイマーバーが青く点灯。コンボ5+：タイマーバーが虹色に点灯 |
| **タイムアップ時** | 時間切れ：「惜しい！」演出 → 正解を0.5秒表示 → 次問へ（コンボリセット）|
| **障害物問題（SM-2）** | 過去のミス問題が「スペシャルブロック（⚠マーク）」として後のセッションで再登場 |
| **My Sentence** | セッション中に自分が作った文の中から1文をセッション終了後に自動ピックアップ → `SESSION_END` 画面に「Today's My Sentence」として表示 |

### コンボゲージ演出（Sprint専用強化）

```
コンボ 0〜2：━━━━━━━━━━░░░░░░  グレー
コンボ 3〜4：━━━━━━━━━━━━░░░░  ブルー（青く発光）
コンボ 5〜6：━━━━━━━━━━━━━━░░  オレンジ（熱い！演出）
コンボ 7+  ：━━━━━━━━━━━━━━━━  レインボー（Mowi最大輝度）
```

### 正解・不正解時のUI挙動（全Layer共通ルール適用）

```
ユーザーが間違えた文を選ぶ
         ↓
【Step 1】間違えた文をそのまま音声再生（例：「I'd want a coffee」）
          テキスト表示なし。音だけ。
         ↓
【Step 2】Mowiが反応
          アニメーション：首をかしげる / 光がわずかに揺れる
          セリフ：「…なんか変」「この並び、しっくりこない」
         ↓
【Step 3】2択ボタン表示
          [もう一回聞く]  [理由を見る]
         ↓
「理由を見る」選択時のみ解説テキスト表示
          例：「"want" より "I'd like" のほうが自然！」
         ↓
正しい文を音声再生して終わる → 次問へ
```

### Mowiセリフ（Sprint専用）

| タイミング | セリフ例 |
|-----------|---------|
| スプリント開始時 | 「行こう。」「始まる。」|
| 正解 + 高速 | 「はやい。」「そう。」|
| コンボ5達成 | 「走ってる。」「止まらない。」|
| タイムアップ | 「惜しかった。」「もう少し。」|
| コンボ切れ | 「…転んだ。」「また走れる。」|
| 全問クリア | 「体が覚えた。」「出た。ちゃんと出た。」|

### Supabase 読み書き（`LAYER_3_SPRINT`）

| タイミング | テーブル | 操作 | フィールド |
|-----------|---------|------|-----------|
| 画面マウント時 | `pattern_content` | READ | `layer_3_questions`（Flash問題セット）|
| 画面マウント時 | `pattern_progress` | READ | `stars`, `ease_factor`, `last_reviewed_at` |
| 画面マウント時 | `flash_output_logs` | READ | 過去ミス問題の取得（SM-2障害物挿入用）|
| 1問回答時（正・不正解とも）| `flash_output_logs` | INSERT | `pattern_id`, `is_correct`, `response_ms`, `combo_at_time`, `layer=3`, `difficulty_level` |
| コンボ5連続達成時 | `mowi_state` | UPDATE | `glow_level=max`, `combo_count` |
| 全問完了時 | `pattern_progress` | UPDATE | `stars`（+1）, `next_review_at`（SM-2計算）, `ease_factor` |
| 全問完了時 | `mowi_state` | UPDATE | `glow_level`, `combo_count` |
| My Sentence確定時 | `flash_output_logs` | UPDATE | `is_my_sentence=true`（ユーザーが最も速く正解した文）|

---

# 4. ナビゲーション構造

## 4-1. ボトムナビゲーション

| タブ | アイコン | ラベル | デフォルト遷移先 |
|------|---------|--------|----------------|
| タブ1 | 🏠 | ホーム | HOME |
| タブ2 | ▶ | 練習 | SESSION_START |
| タブ3 | 📖 | 図鑑 | ZUKAN |
| タブ4 | 📊 | 記録 | LOG_WEEKLY |
| タブ5 | ⚙ | 設定 | SETTINGS |

**ボトムナビの非表示条件**
- LAYER_0〜3（問題画面）
- **LAYER_2_SVO・LAYER_3_SPRINT（ゲーム化Layer画面）← v2.0追加**
- MOWI_REACTION
- PATTERN_MASTER / PATTERN_UNLOCK

**ボトムナビの高さ**：OSのセーフエリア込みで 80px（iPhoneのホームインジケーター分を含む）

## 4-2. 画面遷移アニメーション

| 遷移パターン | アニメーション | 時間 |
|-------------|-------------|------|
| タブ切り替え | fade（クロスフェード）| 150ms |
| 前進（深く潜る）| slide-left | 300ms |
| 戻る | slide-right | 250ms |
| モーダル（下から）| slide-up | 350ms |
| モーダル（閉じる）| slide-down | 250ms |
| MOWI_REACTION | fade-in/out | 200ms |
| PATTERN_MASTER | zoom-in | 400ms |
| **LAYER_2_SVO 開始** | **slide-up（ゲーム化演出）** | **400ms** |
| **LAYER_3_SPRINT 開始** | **zoom-in（スプリント開始演出）** | **350ms** |

---

# 5. コンポーネント共通仕様

## 5-1. Mowiエリア（全画面共通）

| 項目 | 仕様 |
|------|------|
| **Mowiのサイズ** | 基本：120px × 120px。コンボ10+時：+10% |
| **セリフの表示** | Mowiエリア内、Mowiの下に表示。フォントサイズ16sp |
| **セリフの表示時間** | 3秒表示後にフェードアウト。次のトリガーまで非表示 |
| **輝き演出** | CSS `filter: drop-shadow()` で実装。輝度レベルに応じてblur半径・色を変更 |

## 5-2. 選択肢ボタン（チェックイン・問題共通）

| 状態 | スタイル |
|------|---------|
| **通常** | 背景：白（透明度80%）・ボーダー：#E0E0E0・角丸16px |
| **タップ中** | 背景：#F5F5FF・スケール: 0.97 |
| **正解ハイライト** | 背景：#E8F5E9・ボーダー：#4CAF50・チェックマーク表示 |
| **不正解ハイライト** | 背景：#FFEBEE・ボーダー：#F44336・✕マーク表示 |

## 5-3. SVOブロック専用コンポーネント（v2.0 新規）

```
<SVOBlock color="blue|red|yellow|white" word="..." selected="true|false" />
```

| 状態 | スタイル |
|------|---------|
| **通常** | 各色の背景（透明度70%）・角丸12px・テキスト白 |
| **選択済み** | スケール1.05 + 影強調 + スロットへ移動アニメ（200ms bounce）|
| **スロット配置済み** | スロット内で色背景維持 + 枠線なし |
| **震え（不正解）** | `keyframe: shake` 300ms・左右5px揺れ |

## 5-4. タイマーバー（Sprint専用コンポーネント）（v2.0 新規）

```
<SprintTimer :seconds="8" :combo="currentCombo" @timeout="handleTimeout" />
```

| 項目 | 仕様 |
|------|------|
| **高さ** | 12px（コンボゲージより細め）|
| **色** | コンボ0〜2：#9E9E9E / コンボ3〜4：#4A7AFF / コンボ5+：rainbow |
| **アニメーション** | 問題開始時：右端から左端へ線形に縮小 |
| **残り40%** | 点滅開始（500ms interval）|
| **タイムアップ** | 赤色フラッシュ（200ms）→ タイムアップ音 |

## 5-5. コンボゲージ

| 項目 | 仕様 |
|------|------|
| **高さ** | 10px |
| **角丸** | 5px |
| **コンボ数テキスト** | 右端・12sp・Bold |
| **アニメーション** | 正解時：左から右に伸びる（200ms ease-out）。不正解時：右から左に縮む（400ms ease-in）|

## 5-6. ★（スター）表示

| 状態 | スタイル |
|------|---------|
| **達成★** | 金色（#FFD700）塗りつぶし |
| **未達成★** | グレー（#E0E0E0）アウトラインのみ |
| **UP演出** | scale 0→1.3→1.0（300ms bounce）|

---

# 6. デザイントークン

## 6-1. カラーパレット

```css
/* Primary */
--color-brand-primary: #4A7AFF;
--color-brand-secondary: #9B5CF6;

/* Background */
--color-bg-light: #FFFFFF;
--color-bg-dark: #0d0d1a;
--color-bg-morning-top: #1a1a2e;
--color-bg-morning-bottom: #f4a261;
--color-bg-night-top: #0d0d1a;
--color-bg-night-bottom: #4a0e8f;

/* Text */
--color-text-primary: #1A2E4A;
--color-text-secondary: #6B7C93;
--color-text-on-dark: #FFFFFF;

/* Mowi Combo Colors */
--color-combo-none: #9E9E9E;
--color-combo-low: #64B5F6;   /* 3〜4 */
--color-combo-mid: #9C27B0;   /* 5〜6 */
--color-combo-high: #FF9800;  /* 7〜9 */
--color-combo-max: rainbow;   /* 10+  */

/* SVO Block Colors（v2.0 追加）*/
--svo-subject: #4A7AFF;        /* 🔵 主語 */
--svo-verb: #F44336;           /* 🔴 動詞 */
--svo-object: #FFD700;         /* 🟡 目的語・補語 */
--svo-fixed: #E0E0E0;          /* ⬜ 固定語 */
--svo-subject-bg: rgba(74,122,255,0.15);
--svo-verb-bg: rgba(244,67,54,0.15);
--svo-object-bg: rgba(255,215,0,0.15);

/* Feedback */
--color-correct: #4CAF50;
--color-wrong: #F44336;
--color-warning: #FF9800;
--color-streak: #FF6D00;

/* Stars */
--color-star-active: #FFD700;
--color-star-inactive: #E0E0E0;
```

## 6-2. タイポグラフィ

```css
--font-primary: 'Hiragino Sans', 'Noto Sans JP', sans-serif;
--font-display: 'Hiragino Maru Gothic ProN', 'Noto Sans JP', sans-serif;

--text-xs:   11sp;
--text-sm:   13sp;
--text-base: 16sp;
--text-lg:   18sp;
--text-xl:   22sp;
--text-2xl:  28sp;
--text-3xl:  36sp;

--text-pattern:     22sp / Bold    /* パターン本体表示 */
--text-question:    18sp / Regular  /* 問題文 */
--text-option:      16sp / Medium   /* 選択肢ラベル */
--text-mowi-serif:  16sp / Regular  /* Mowiセリフ */
--text-svo-block:   15sp / Bold     /* SVOブロック文字 */
--text-sprint-timer: 13sp / Bold    /* Sprintタイマー残り秒数 */
--text-label:       13sp / Regular  /* ラベル類 */
--text-badge:       11sp / Bold     /* バッジ内テキスト */
```

## 6-3. スペーシング

```css
--space-1: 4px;   --space-2: 8px;   --space-3: 12px;
--space-4: 16px;  --space-5: 20px;  --space-6: 24px;
--space-8: 32px;  --space-10: 40px; --space-12: 48px;

--screen-padding-h: 16px;
--screen-padding-top: 16px;
--safe-area-bottom: env(safe-area-inset-bottom);

/* SVO Block グリッド */
--svo-block-min-width: 72px;
--svo-block-height: 44px;
--svo-slot-height: 52px;
--svo-slot-gap: 8px;
```

## 6-4. 角丸

```css
--radius-sm: 8px;   --radius-md: 12px;
--radius-lg: 16px;  --radius-xl: 24px;
--radius-full: 9999px;

--radius-card: 24px;
--radius-button: 16px;
--radius-badge: 9999px;
--radius-svo-block: 10px;    /* SVOブロック */
--radius-svo-slot: 8px;      /* SVOスロット */
```

## 6-5. アニメーションパラメータ

```css
--ease-standard: cubic-bezier(0.4, 0, 0.2, 1);
--ease-decelerate: cubic-bezier(0, 0, 0.2, 1);
--ease-bounce: cubic-bezier(0.34, 1.56, 0.64, 1);

--duration-fast: 150ms;
--duration-normal: 300ms;
--duration-slow: 500ms;
--duration-mowi-reaction: 800ms;    /* 固定値・変更禁止 */
--duration-svo-block-place: 200ms;  /* ブロック配置アニメ */
--duration-sprint-start: 350ms;     /* Sprint開幕ズームイン */
```

---

# 7. Vue Router 構成（完全版）

```javascript
// router/index.js  （v2.0 更新：LAYER_2_SVO・LAYER_3_SPRINT 追加）
const routes = [
  // ──── 起動 ────
  { path: '/',
    name: 'Splash',
    component: () => import('@/views/SplashView.vue') },

  // ──── オンボーディング ────
  { path: '/onboarding',
    name: 'Onboarding',
    component: () => import('@/views/OnboardingView.vue') },

  // ──── ホーム ────
  { path: '/home',
    name: 'Home',
    component: () => import('@/views/HomeView.vue') },

  // ──── チェックイン ────
  { path: '/checkin/morning',
    name: 'CheckinMorning',
    component: () => import('@/views/checkin/CheckinMorningView.vue') },
  { path: '/checkin/reaction',
    name: 'MowiReaction',
    component: () => import('@/views/checkin/MowiReactionView.vue') },
  { path: '/checkin/card',
    name: 'CardToday',
    component: () => import('@/views/checkin/CardTodayView.vue') },
  { path: '/checkin/night-prompt',
    name: 'NightPrompt',
    component: () => import('@/views/checkin/NightPromptView.vue') },
  { path: '/checkin/night',
    name: 'CheckinNight',
    component: () => import('@/views/checkin/CheckinNightView.vue') },
  { path: '/checkin/diff',
    name: 'DiffFeedback',
    component: () => import('@/views/checkin/DiffFeedbackView.vue') },
  { path: '/checkin/save',
    name: 'CardSave',
    component: () => import('@/views/checkin/CardSaveView.vue') },

  // ──── 練習（標準Layer）────
  { path: '/session/start',
    name: 'SessionStart',
    component: () => import('@/views/session/SessionStartView.vue') },
  { path: '/session/layer/:n',         // n = 0 / 1 / 2 / 3
    name: 'LayerQuestion',
    component: () => import('@/views/session/LayerQuestionView.vue'),
    props: true },
  { path: '/session/end',
    name: 'SessionEnd',
    component: () => import('@/views/session/SessionEndView.vue') },
  { path: '/session/master',
    name: 'PatternMaster',
    component: () => import('@/views/session/PatternMasterView.vue') },
  { path: '/session/unlock',
    name: 'PatternUnlock',
    component: () => import('@/views/session/PatternUnlockView.vue') },

  // ──── ゲーム化 Layer（v2.0 新規）────
  {
    path: '/session/layer/2/svo',
    name: 'Layer2SVO',
    component: () => import('@/views/session/Layer2SVOView.vue'),
    meta: {
      gameMode: true,
      layer: 2,
      title: 'SVO Block',
      hideBottomNav: true,
    }
  },
  {
    path: '/session/layer/3/sprint',
    name: 'Layer3Sprint',
    component: () => import('@/views/session/Layer3SprintView.vue'),
    meta: {
      gameMode: true,
      layer: 3,
      title: 'Flash Sprint',
      hideBottomNav: true,
    }
  },

  // ──── 図鑑 ────
  { path: '/zukan',
    name: 'Zukan',
    component: () => import('@/views/zukan/ZukanView.vue') },
  { path: '/zukan/:id',
    name: 'ZukanDetail',
    component: () => import('@/views/zukan/ZukanDetailView.vue'),
    props: true },

  // ──── 記録 ────
  { path: '/log/weekly',
    name: 'LogWeekly',
    component: () => import('@/views/log/LogWeeklyView.vue') },
  { path: '/log/monthly',
    name: 'LogMonthly',
    component: () => import('@/views/log/LogMonthlyView.vue') },
  { path: '/log/3months',
    name: 'Log3Months',
    component: () => import('@/views/log/Log3MonthsView.vue') },

  // ──── 通知・設定 ────
  { path: '/message',
    name: 'TeacherMsg',
    component: () => import('@/views/TeacherMsgView.vue') },
  { path: '/settings',
    name: 'Settings',
    component: () => import('@/views/SettingsView.vue') },
]

// ──── ゲーム化モード ルーティングガード（v2.0 追加）────
router.beforeEach(async (to, from, next) => {
  // Layer 2・3 への遷移時にゲーム化条件を判定
  if (to.name === 'LayerQuestion' && to.params.n === '2') {
    const canGameify = await checkGameMode(2)  // ★2以上 + ゲーム化ON
    if (canGameify) return next({ name: 'Layer2SVO' })
  }
  if (to.name === 'LayerQuestion' && to.params.n === '3') {
    const canGameify = await checkGameMode(3)  // ★3以上 + ゲーム化ON
    if (canGameify) return next({ name: 'Layer3Sprint' })
  }
  next()
})
```

---

# 8. 実装フェーズ別 画面スコープ

## MVP（フェーズ1）

| 画面 | 必須 | 備考 |
|------|------|------|
| SPLASH | ✅ | |
| HOME | ✅ | |
| CHECKIN_MORNING / NIGHT | ✅ | |
| MOWI_REACTION | ✅ | |
| CARD_TODAY / CARD_SAVE | ✅ | |
| SESSION_START | ✅ | |
| LAYER_2（標準）| ✅ | スロット穴埋め |
| **LAYER_2_SVO** | **✅** | **★2以上で自動切り替え** |
| LAYER_3（標準）| ✅ | タイル選択 |
| **LAYER_3_SPRINT** | **✅** | **MVP最重要・★3以上で自動切り替え** |
| COMBO_BREAK | ✅ | |
| SESSION_END | ✅ | |
| CHECKIN_NIGHT_PROMPT | ✅ | |
| DIFF_FEEDBACK | ✅ | |
| ZUKAN（一覧・詳細）| ✅ | 簡易版でOK |
| LOG_WEEKLY | ✅ | |
| SETTINGS | ✅ | ゲーム化ON/OFF含む |

## フェーズ2

| 画面 | 内容 |
|------|------|
| ONBOARDING_* | 初回体験フロー |
| LAYER_0 / LAYER_1 | 音声系Layer |
| PATTERN_MASTER / UNLOCK | 演出強化版 |
| LOG_MONTHLY / LOG_3MONTHS | 長期ログ |
| TEACHER_MSG | 先生メッセージ |
| LAYER_2_SVO 状況イラスト | Supabase Storageイラスト連動 |
| LAYER_3_SPRINT Lv.3 | キーボード自由入力版 |

---

# 9. Supabaseへの読み書きタイミング一覧（v2.0 新規）

## 9-1. アプリ起動時フロー

```
OS起動
  ↓
SPLASH（1.5秒）
  ↓ 非同期並列実行
  ┌─────────────────────────────────────────────────────────┐
  │ READ: auth.users（ログイン状態確認）                      │
  │ READ: users（role, display_name, streak）                │
  │ READ: checkins（今日の朝チェックイン済みか）               │
  │ READ: teacher_messages（未読メッセージあるか）             │
  │ READ: mowi_state（Mowiの感情・輝き状態）                  │
  └─────────────────────────────────────────────────────────┘
  ↓
条件分岐 → 各画面へ
```

## 9-2. 全画面 × Supabase読み書きタイミング一覧表

| 画面ID | 読み込み（READ）| 書き込み（WRITE）| タイミング |
|--------|---------------|----------------|-----------|
| `SPLASH` | `auth.users`, `users`, `checkins`, `teacher_messages`, `mowi_state` | なし | 起動時（並列）|
| `CHECKIN_MORNING` | `checkins`（過去ログ参照）| `checkins`（morning_feeling, morning_checked_at）| 選択肢タップ後 |
| `MOWI_REACTION` | `mowi_state`（セリフ取得）| `mowi_state`（last_reaction_at 更新）| 表示開始時 |
| `CARD_TODAY` | `checkins`（今朝のデータ）| なし | 画面マウント時 |
| `HOME` | `users`（streak, level）, `pattern_progress`（今日のおすすめ）, `mowi_state` | なし | タブ表示時 |
| `SESSION_START` | `pattern_progress`（next_review_at順）, `patterns`（パターン名）| なし | 画面マウント時 |
| `LAYER_0` | `pattern_content`（Layer 0問題）| `flash_output_logs`（各回答）, `pattern_progress`（完了後）| 回答時 / 完了時 |
| `LAYER_1` | `pattern_content`（Layer 1問題）| `flash_output_logs`, `pattern_progress` | 同上 |
| `LAYER_2` | `pattern_content`（Layer 2問題）| `flash_output_logs`, `pattern_progress` | 同上 |
| **`LAYER_2_SVO`** | **`pattern_content`（SVO問題）**, **`pattern_progress`** | **`flash_output_logs`（layer=2）**, **`pattern_progress`**, **`mowi_state`** | **回答時 / 完了時** |
| `LAYER_3` | `pattern_content`（Layer 3問題）| `flash_output_logs`, `pattern_progress` | 同上 |
| **`LAYER_3_SPRINT`** | **`pattern_content`（Sprint問題）**, **`pattern_progress`**, **`flash_output_logs`（過去ミス取得）** | **`flash_output_logs`（layer=3）**, **`pattern_progress`**, **`mowi_state`** | **回答時 / 完了時** |
| `SESSION_END` | `pattern_progress`（★表示用）, `mowi_state` | `pattern_progress`（セッション全体サマリー）, `mowi_state`（セッション終了後感情）| 画面表示時 / 集計完了後 |
| `PATTERN_MASTER` | `pattern_progress`（★5確定）| `pattern_progress`（status='mastered'）| 演出中 |
| `PATTERN_UNLOCK` | `patterns`（次パターン情報）| `pattern_progress`（新パターン初期化：stars=0）| 演出中 |
| `CHECKIN_NIGHT_PROMPT` | `checkins`（今日の朝データ）| なし | 画面マウント時 |
| `CHECKIN_NIGHT` | `checkins`（朝データ参照）| `checkins`（evening_feeling, evening_checked_at）| 選択肢タップ後 |
| `DIFF_FEEDBACK` | `checkins`（朝夜両方）, `mowi_state` | `mowi_state`（今日のセリフ確定）| 画面マウント時 |
| `CARD_SAVE` | `checkins`（今日の完全データ）| なし | 画面マウント時 |
| `ZUKAN` | `patterns`（全一覧）, `pattern_progress`（ユーザー別★）| なし | 画面マウント時 |
| `ZUKAN_DETAIL` | `patterns`（1件詳細）, `pattern_content`（例文）, `pattern_progress` | なし | 画面マウント時 |
| `LOG_WEEKLY` | `checkins`（直近7日）, `flash_output_logs`（直近7日）| なし | 画面マウント時 |
| `LOG_MONTHLY` | `checkins`（直近30日）, `pattern_progress`（月間サマリー）| なし | 画面マウント時 |
| `LOG_3MONTHS` | `checkins`（直近90日）, `gym_badges` | なし | 画面マウント時 |
| `TEACHER_MSG` | `teacher_messages`（未読1件）| `teacher_messages`（is_read=true）| メッセージ表示後 |
| `SETTINGS` | `users`（設定値）| `users`（通知設定, ゲーム化設定）| 変更即時 |

## 9-3. Supabase Realtime 使用箇所

| 画面 | チャンネル | 用途 |
|------|-----------|------|
| `HOME` | `mowi_state:user_id=*` | Mowi輝度のリアルタイム反映 |
| `LAYER_3_SPRINT` | ─（Realtimeなし）| ローカルステートで管理。完了時にバッチ書き込み |
| `TEACHER_MSG` | `teacher_messages:user_id=*` | 先生メッセージのプッシュ受信 |

## 9-4. オフライン挙動

| 状況 | 挙動 |
|------|------|
| **問題画面中（オフライン）** | `flash_output_logs` の書き込みを `Capacitor Preferences` にキャッシュ → 次回オンライン時に自動 UPSERT |
| **チェックイン（オフライン）** | 朝・夜のチェックイン選択データをローカル保存 → オンライン復帰時に同期 |
| **Mowi状態（オフライン）** | 前回取得のキャッシュを表示。書き込みはキュー管理 |

---

# 10. 実装上の注意事項（v2.0 追記）

## 10-1. ゲーム化Layer切り替えロジック

```javascript
// composables/useGameMode.js
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export async function checkGameMode(layer) {
  // ① ユーザー設定チェック
  const { data: user } = await supabase
    .from('users')
    .select('game_mode_enabled')
    .single()
  if (!user.game_mode_enabled) return false

  // ② 現在セッションのパターン★チェック
  const { data: progress } = await supabase
    .from('pattern_progress')
    .select('stars')
    .eq('pattern_id', currentPatternId)
    .single()

  // Layer 2 SVO：★2以上で解禁
  if (layer === 2) return progress.stars >= 2
  // Layer 3 Sprint：★3以上で解禁
  if (layer === 3) return progress.stars >= 3

  return false
}
```

## 10-2. SM-2 アルゴリズムの実装箇所

`pattern_progress` テーブルの更新は **Supabase Edge Function** で実行。
フロントエンドは `completed: true` を送信するだけで、SM-2計算（`ease_factor`・`next_review_at`）はサーバー側で処理。

```
フロントエンド（Vue）         Supabase Edge Function
─────────────────────────    ──────────────────────────────────
POST /api/complete-layer  →  SM-2計算
  { pattern_id,               ease_factor更新
    layer,                     next_review_at更新
    is_correct,                stars更新
    response_ms }             → pattern_progress UPDATE
```

## 10-3. `flash_output_logs` のバッチ書き込み

Layer 3 Sprint では1セッションに5〜10問回答するため、1問ごとの個別INSERTではなく**セッション終了時にまとめてバッチINSERT**する。

```javascript
// セッション中はローカル配列に追記
const sessionLogs = []
function onAnswer(result) {
  sessionLogs.push({ pattern_id, is_correct, response_ms, combo_at_time, layer: 3 })
}

// 完了時にまとめてINSERT（Supabase bulk insert）
async function onSessionEnd() {
  await supabase.from('flash_output_logs').insert(sessionLogs)
}
```

---

*MoWISE 全画面設計書 v2.0*
*策定日：2026年3月10日*
*前バージョン：v1.0（2026年2月23日）*
*次回更新：MVP実装開始時点で画面追加・変更を反映*
