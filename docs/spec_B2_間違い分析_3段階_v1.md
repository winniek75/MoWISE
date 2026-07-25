# 開発spec: 生徒の間違い分析（B2・3段階ロールアウト）

**バージョン:** v1.0（2026-07-25）
**実装担当:** Claude Code（Cursor）
**対象:** MoWISE本体 + ゲームリポジトリ15本（beat-word-crush / eiken-sns-app / eiken-challenge の3本はリポジトリ未到達のため対象外・7月監査と同じ）

---

## 0. 全体像（なぜ3段階か）

「どの問題をよく間違えるか」を先生に見せるには、①データの標準形式 → ②各ゲームが送る → ③集計して表示、の3層が必要。
16リポジトリを一度に触るとレビュー不能になるため、**Phase 1で型と表示を完成させ、Phase 2以降はゲームを数本ずつ追加するだけ**の構造にする。各Phaseが独立して価値を出す（中断耐性）。

**SDK本体の改修は不要。** `GameScorePayload.metadata`（自由形式jsonb）が既に `game_scores.metadata` へ保存されているため、中身の標準形式を決めるだけでよい。

---

## 標準データ形式（全Phaseの共通契約・変更禁止）

各ゲームはスコア送信時、`metadata.wrongAnswers` に間違えた問題を入れる：

```json
{
  "wrongAnswers": [
    {
      "q": "She ___ to school every day.",   // 問題文または出題語（80文字まで）
      "correct": "goes",                      // 正答
      "chosen": "go",                         // 生徒の解答（無回答は null）
      "tag": "三単現"                          // 文法項目・音素などの分類タグ（任意）
    }
  ]
}
```

ルール:
- 1プレイ最大20件（超えたら新しい方を優先）
- 全問正解なら空配列 `[]`
- aredo-game の既存 `recentWrong` はこの形式に移行（Phase 1で対応）

---

## Phase 1: 基盤 + 表示 + 参照実装1本（小）

### 目的
標準形式を確定し、先生画面に「よく間違えた問題」が出る状態を1ゲームで完成させる。

### やる
1. **集計ビュー** `student_wrong_answers`（SQL view）を作成
   - `game_scores.metadata->'wrongAnswers'` を展開し、user_id / class_id / game_id / q / correct / chosen / tag / played_at で行化
   - RLS: 既存 `game_scores` の参照権限を継承（security_invoker）
2. **先生画面（生徒詳細 `TeacherStudentView.vue`）に「よく間違えた問題」セクション追加**
   - 直近30日の間違いを q ごとに集計し、回数順TOP10を表示（問題文 / 正答 / 生徒の答え / 回数 / ゲーム名）
   - tag があればタグ別の件数チップも表示（例: 三単現 ×7）
   - データが無い生徒は「まだ間違いデータがありません（対応ゲームのプレイ後に表示されます）」
3. **参照実装:** aredo-game を `wrongAnswers` 形式に更新（recentWrong→改名＋フィールド統一）
4. `docs/` に**ゲーム側実装ガイド1枚**（`wrongAnswers_実装ガイド_v1.md`）を作成 — Phase 2以降で各ゲームにそのまま渡す

### やらない
- クラス全体の横断集計画面（Phase 3後の候補）
- 過去データの遡及変換（recentWrongの過去分は少量のため捨てる）
- 3本の未到達リポジトリ

### 受け入れ条件
- [ ] aredo-game をプレイして間違えると、先生の生徒詳細に問題文・正答・生徒の答えが表示される
- [ ] 全問正解プレイでは何も増えない
- [ ] 未対応ゲームだけの生徒には案内文が表示される
- [ ] 既存のスコア・コイン・ミッション処理に影響がない（回帰確認）

---

## Phase 2: 文法系ゲーム5本を展開（中）

対象: verbform-battle / grammar-drill / grammar-app / eiken-grammar-game / wh-questiongame

- 各ゲームに実装ガイド通り `wrongAnswers` を追加（tag に文法項目を必ず入れる: 「be動詞」「to不定詞」「関係代名詞」等 — tag語彙は教育設計担当が確定したリストを使用）
- ゲームごとに1コミット・1デプロイ・1動作確認（5本まとめてレビューしない）

受け入れ条件: 5本すべてで、間違えた問題が先生画面に文法タグ付きで出る

## Phase 3: 残り9本を展開（中）

対象: phonics系4本 / eiken系3本（到達可能分）/ sentence-dash / wise-english-floor / instant-english-app / flashinput ほか
- フォニックス系は tag に音素（例: "th", "magic-e"）を入れる
- 3〜4本ずつのバッチで実施

---

## 技術メモ

- 触るファイル（本体）: `src/views/teacher/TeacherStudentView.vue`, 新規migration（view作成）, `src/stores/teacher.ts` 系
- jsonb展開は `jsonb_array_elements(metadata->'wrongAnswers')`。データ量が増えたら専用テーブル化を検討（今はビューで十分）
- ゲーム側は既に postMessage で metadata を送れる状態（7月のブリッジ実装済み）。**変更は「wrongAnswersを詰める」だけ**
- ⚠️ RLS注意: ビューは必ず security_invoker=true。classes↔class_members の再帰事故（7月）を繰り返さない

## 体調とレビュー可能時間

Winnie記入: ___ /10 ・ ___分（Phase着手ごとに確認）

## レビュー方法

各Phase完了時: preview URL + 「実際に間違えてみる→先生画面で見る」の手順書 + スクショ + 日本語サマリ

---

## 完了報告テンプレ（Phaseごとに記入）

- Phase:
- 変更点（日本語サマリ・非技術）:
- 確認方法:
- 触ったファイル/リポジトリ:
- 残課題:
- コミット/PR:
