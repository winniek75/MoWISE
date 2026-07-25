# wrongAnswers タグ語彙リスト v1.0（教育設計・確定版）

**日付:** 2026-07-25
**用途:** spec B2「間違い分析」の `metadata.wrongAnswers[].tag` に入れる値の正本
**適用:** Phase 1（aredo-game 参照実装）から使用。Phase 2・3 で対象ゲームを拡大

---

## 運用ルール（変更禁止の契約）

1. **ゲームは英数字IDを送る**（下表の `tag ID`）。日本語表示名はMoWISE本体の変換マップだけが持つ
2. **1問につきタグ1つ。** 複数該当する場合は「その問題で試されている操作」を選ぶ
   - 例: "___ she play tennis?"（Does を選ぶ問題）→ 疑問文の作り方が試されている → `question_form` ではなく `third_person_s`（三単現のdoes/doesの判断が核心）※各ゲームの判断基準は下の対応表に固定
3. **IDの改名・削除は禁止**（過去データが壊れる）。追加はこのドキュメントを更新してから
4. リストにない項目に出会ったら `other_grammar` で送り、月次でこのリストに昇格させる

---

## 文法タグ（Phase 1–2 で使用）

| tag ID | 先生画面の表示名 | 主な使用ゲーム |
|---|---|---|
| `be_verb` | be動詞 | aredo-game |
| `general_verb` | 一般動詞 | aredo-game |
| `third_person_s` | 三単現のs | aredo-game, grammar-app |
| `plural_s` | 複数形 | grammar-app |
| `pronoun` | 代名詞 | grammar-app |
| `article` | 冠詞 (a/an/the) | grammar-app |
| `preposition` | 前置詞 | grammar-app |
| `past_regular` | 過去形（規則） | eiken-grammar-game |
| `past_irregular` | 過去形（不規則） | eiken-grammar-game |
| `progressive` | 進行形 | eiken-grammar-game |
| `future` | 未来表現 (will / be going to) | eiken-grammar-game |
| `present_perfect` | 現在完了 | eiken-grammar-game |
| `passive` | 受動態 | eiken-grammar-game |
| `auxiliary` | 助動詞 (can/must/should…) | grammar-app |
| `to_infinitive` | to不定詞 | grammar-drill |
| `gerund` | 動名詞 (〜ing) | grammar-drill |
| `relative_pronoun` | 関係代名詞 | verbform-battle |
| `participle` | 分詞 | verbform-battle |
| `comparative` | 比較 | grammar-app |
| `imperative` | 命令文 | grammar-app |
| `there_is` | There is / are | grammar-app |
| `word_order` | 語順 | sentence-dash（Phase 3） |
| `wh_what` | What の疑問文 | wh-questiongame |
| `wh_who` | Who の疑問文 | wh-questiongame |
| `wh_where` | Where の疑問文 | wh-questiongame |
| `wh_when` | When の疑問文 | wh-questiongame |
| `wh_why` | Why の疑問文 | wh-questiongame |
| `wh_how` | How の疑問文 | wh-questiongame |
| `other_grammar` | その他（文法） | 全ゲーム（受け皿） |

### ゲーム別の判断基準（迷い防止・Phase 2実装時にそのまま使う）

- **aredo-game:** 問題の正答が am/is/are → `be_verb`。do/does/一般動詞の形 → 主語が三人称単数なら `third_person_s`、それ以外は `general_verb`
- **grammar-drill:** 正答が to+動詞 → `to_infinitive`、〜ing → `gerund`（判別ゲームなので2択で完結）
- **verbform-battle:** 関係詞の選択問題 → `relative_pronoun`、現在分詞/過去分詞の選択 → `participle`
- **eiken-grammar-game:** 時制の問題は正答の形で判定（規則過去 / 不規則過去 / 進行 / 未来 / 完了）。受動態の語形が核心なら `passive`
- **wh-questiongame:** 出題のWH語そのままタグ化（間違いの偏りが疑問詞ごとに見えることがこのゲームの分析価値）
- **grammar-app:** 単元IDからタグへの対応表をゲーム内に定義（実装時に単元一覧→タグの表を作りcommitに含める）

---

## フォニックス・語彙タグ（Phase 3 用・v0ドラフト）

Phase 3 着手前に `教育設計:` で確定させる。現時点の骨子のみ：

| tag ID | 表示名 | 想定ゲーム |
|---|---|---|
| `short_vowel` | 短母音 (a,e,i,o,u) | phonics系 |
| `long_vowel` | 長母音・マジックe | phonics系 |
| `digraph` | 二重字 (sh/ch/th/ph) | phonics系 |
| `blend` | 子音ブレンド (bl/st/tr…) | phonics系 |
| `r_controlled` | rのつく母音 (ar/er/or) | phonics系 |
| `sight_word` | サイトワード | sight-words-memory |
| `vocab_eiken5` / `vocab_eiken4` / `vocab_eiken3` | 英検5級/4級/3級 語彙 | eiken系, flashinput |

※ 音素単位（"th", "magic-e" など）まで細分化するかは、Phase 3 前に実データ（どの粒度なら先生が動けるか）を見て判断

---

## 教育設計としての意図（なぜこの粒度か）

- 粒度の基準は「**先生が次の一手を打てるか**」。例：「三単現のs ×7回」→ aredo-game か grammar-app の該当単元を課題に出す、という行動に直結する
- 「時制」で丸めず規則/不規則を分けたのは、**つまずきの原因が違う**ため（規則=ルール未定着、不規則=個別暗記不足）で処方箋が変わる
- WH疑問文を疑問詞ごとに分けたのは、Why/How が意味理解、What/Where が語順の課題として現れやすく、偏りに診断価値があるため
- タグ集計は将来のルーブリック（★1–★5 の背骨）の「土台レイヤーの弱点検知」入力としてそのまま使える設計

---

## 更新履歴

| 日付 | バージョン | 内容 |
|---|---|---|
| 2026-07-25 | v1.0 | 初版確定（文法29タグ）。フォニックスはv0ドラフト |
