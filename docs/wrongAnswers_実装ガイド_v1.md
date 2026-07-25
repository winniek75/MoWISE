# wrongAnswers 実装ガイド v1（ゲーム側）

**対象:** MoWISE連携ゲーム全般
**目的:** 生徒の間違いデータを標準形式で送信し、先生画面で分析できるようにする

---

## やること（3ステップ）

### 1. セッション中の間違いを蓄積する変数を用意

```javascript
let sessionWrongAnswers = [];
```

ゲーム開始時にリセット:
```javascript
sessionWrongAnswers = [];
```

### 2. 不正解時に追加

```javascript
// 不正解が発生したら:
sessionWrongAnswers.push({
  q: "She ___ to school every day.",  // 問題文（80文字まで）
  correct: "goes",                     // 正答
  chosen: "go",                        // 生徒の解答（無回答はnull）
  tag: "third_person_s"                // タグID（下記リスト参照）
});

// 最大20件（超えたら古いものを捨てる）
if (sessionWrongAnswers.length > 20) {
  sessionWrongAnswers = sessionWrongAnswers.slice(-20);
}
```

### 3. スコア送信時の metadata に含める

```javascript
window.WiseGame.reportComplete({
  score: ...,
  maxScore: ...,
  accuracy: ...,
  timeSpent: ...,
  metadata: {
    // 既存のメタデータはそのまま維持
    ...,
    // これを追加:
    wrongAnswers: sessionWrongAnswers
  }
});
```

全問正解の場合は空配列 `[]` が送られる（変数を空のまま送信するだけ）。

---

## タグIDリスト

タグは英数字IDで送信する。日本語表示名はMoWISE本体が変換する。

### 文法タグ（Phase 1-2）

| tag ID | 意味 |
|---|---|
| `be_verb` | be動詞 |
| `general_verb` | 一般動詞 |
| `third_person_s` | 三単現のs |
| `plural_s` | 複数形 |
| `pronoun` | 代名詞 |
| `article` | 冠詞 |
| `preposition` | 前置詞 |
| `past_regular` | 過去形（規則） |
| `past_irregular` | 過去形（不規則） |
| `progressive` | 進行形 |
| `future` | 未来表現 |
| `present_perfect` | 現在完了 |
| `passive` | 受動態 |
| `auxiliary` | 助動詞 |
| `to_infinitive` | to不定詞 |
| `gerund` | 動名詞 |
| `relative_pronoun` | 関係代名詞 |
| `participle` | 分詞 |
| `comparative` | 比較 |
| `other_grammar` | その他（文法）- 迷ったらこれ |

### フォニックス・語彙タグ（Phase 3用、後日確定）

| tag ID | 意味 |
|---|---|
| `short_vowel` | 短母音 |
| `long_vowel` | 長母音・マジックe |
| `digraph` | 二重字 (sh/ch/th) |
| `blend` | 子音ブレンド |
| `sight_word` | サイトワード |

---

## 判断基準の例

- 正答が am/is/are → `be_verb`
- 正答が do/does の判断問題で主語が三人称単数 → `third_person_s`
- 正答が一般動詞の形 → `general_verb`
- 迷ったら `other_grammar` で送信（月次でリスト更新）

## 注意事項

- tag IDの改名・削除は禁止（過去データが壊れる）
- 1問につきタグ1つ
- 既存のスコア送信ロジックは変更しない（metadataにwrongAnswersを追加するだけ）
