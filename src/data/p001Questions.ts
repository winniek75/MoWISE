/**
 * MoWISE P001 問題データ
 * [代名詞] + be動詞パターン
 *
 * Layer 2（Pattern Sense）・Layer 3（Flash Output タイル式）
 * 参照設計書：MoWISE_P001_コンテンツ設計_v2.md
 *
 * ⚠️ 品詞名はUI・フィードバックに一切出さない（AGENTS.md 禁止事項）
 */

// ─────────────────────────────────────────────
// 型定義
// ─────────────────────────────────────────────

export interface Layer2Choice {
  id: string
  text: string
  isCorrect: boolean
  wrongReason?: string  // 不正解時の解説（品詞名なし）
}

export interface Layer2Question {
  id: string
  slotPrefix: string    // '___ の前のテキスト'
  slotSuffix?: string   // '___ の後ろのテキスト'
  promptJa: string      // 日本語プロンプト
  fullSentence: string  // 完全な正解文（音声再生用）
  choices: Layer2Choice[]
  explanation: string   // 正解後の解説（任意表示）
  audio?: string        // 不正解時に再生する「変な音」（stub）
  correctAudio?: string // 正解文の音声ファイル名
}

export interface Layer3Tile {
  id: string
  word: string
  isDecoy: boolean
}

export interface Layer3Question {
  id: string
  promptJa: string       // 日本語プロンプト
  tiles: Layer3Tile[]    // タイルプール（正解 + ダミー混在）
  answer: string[]       // 正解ワード配列（順序通り）
  correctSentence: string
  hint?: string          // 3秒後に表示するヒント
  timeLimitSec: number   // 制限時間（秒）
  correctAudio?: string  // 正解音声ファイル名
}

// ─────────────────────────────────────────────
// P001 Layer 2：Pattern Sense（スロット穴埋め）
// 形式：4択シングルアンサー（設計書 L2-S1〜S6 より抽出・MVP用に単答化）
// ─────────────────────────────────────────────

export const p001Layer2Questions: Layer2Question[] = [
  {
    id: 'P001-L2-1',
    slotPrefix: "I'm",
    promptJa: '「私は疲れています」',
    fullSentence: "I'm tired.",
    correctAudio: 'P001_L2_answer_1.mp3',
    choices: [
      { id: 'a', text: 'tired',    isCorrect: true },
      { id: 'b', text: 'sleep',    isCorrect: false, wrongReason: '「sleep」はそのままだと入らない。「sleeping」にすれば入るよ！' },
      { id: 'c', text: 'go',       isCorrect: false, wrongReason: '「go」は入らない。「going」にすると入るよ！' },
      { id: 'd', text: 'runs',     isCorrect: false, wrongReason: '「runs」はここには来ない形。' },
    ],
    explanation: 'tired（疲れた）は I\'m の後ろにそのまま入る。状態を表す言葉はこのまま使えるよ！',
  },
  {
    id: 'P001-L2-2',
    slotPrefix: "She's",
    promptJa: '「彼女は先生です」',
    fullSentence: "She's a teacher.",
    correctAudio: 'P001_L2_answer_2.mp3',
    choices: [
      { id: 'a', text: 'a teacher',  isCorrect: true },
      { id: 'b', text: 'teach',      isCorrect: false, wrongReason: '「teach」はそのままだと入らない。She teaches. なら言えるよ！' },
      { id: 'c', text: 'teaching',   isCorrect: false, wrongReason: '「She\'s teaching.」なら「今まさに教えている」という意味になるよ。職業を言いたいなら「a teacher」！' },
      { id: 'd', text: 'run',        isCorrect: false, wrongReason: '「run」はここには入らない。She runs. という別の言い方になるよ。' },
    ],
    explanation: '職業を言うときは「a」をつけるのがポイント！「She\'s a teacher.」自然に出るようにしよう。',
  },
  {
    id: 'P001-L2-3',
    slotPrefix: "It's",
    promptJa: '「今日は暑いです」',
    fullSentence: "It's hot today.",
    correctAudio: 'P001_L2_answer_3.mp3',
    choices: [
      { id: 'a', text: 'hot',    isCorrect: true },
      { id: 'b', text: 'heat',   isCorrect: false, wrongReason: '「heat」は名詞・動詞として使う言葉。天気を言うときは「hot」を使うよ！' },
      { id: 'c', text: 'a hot',  isCorrect: false, wrongReason: '「a hot」という言い方はしない。「hot」だけでOK！' },
      { id: 'd', text: 'heats',  isCorrect: false, wrongReason: '「heats」はここには入らない。' },
    ],
    explanation: '天気を言うとき「It\'s + 状態の言葉」がセット。It\'s hot. / It\'s cold. / It\'s raining. …いくらでも応用できるよ！',
  },
  {
    id: 'P001-L2-4',
    slotPrefix: "He's",
    slotSuffix: 'ready.',
    promptJa: '「彼はまだ準備できていません」',
    fullSentence: "He's not ready.",
    correctAudio: 'P001_L2_answer_4.mp3',
    choices: [
      { id: 'a', text: 'not',    isCorrect: true },
      { id: 'b', text: 'no',     isCorrect: false, wrongReason: '「no」はここには入らない。be動詞の否定は「not」を使うよ！' },
      { id: 'c', text: "don't",  isCorrect: false, wrongReason: '「don\'t」は別のパターンの否定。be動詞があるときは「not」！' },
      { id: 'd', text: 'never',  isCorrect: false, wrongReason: '「never」だと「絶対に準備しない」という強い意味になってしまうよ。' },
    ],
    explanation: 'be動詞を「〜じゃない」にするときは「not」を間に入れるだけ。He\'s not ready. 自然に出るようにしよう！',
  },
  {
    id: 'P001-L2-5',
    slotPrefix: "We're",
    promptJa: '「私たちは準備OKです」',
    fullSentence: "We're ready.",
    correctAudio: 'P001_L2_answer_5.mp3',
    choices: [
      { id: 'a', text: 'ready',    isCorrect: true },
      { id: 'b', text: 'a ready',  isCorrect: false, wrongReason: '「a ready」という言い方はしない。「ready」だけでOK！' },
      { id: 'c', text: 'readying', isCorrect: false, wrongReason: '「We\'re readying.」は使わない形。「We\'re ready.」がシンプルで自然！' },
      { id: 'd', text: 'to ready', isCorrect: false, wrongReason: '「to ready」はここには入らない。' },
    ],
    explanation: 'We\'re の後ろも I\'m と同じ。状態・情報・評価が来る。We\'re ready. We\'re students. We\'re hungry. …全部使えるよ！',
  },
  {
    id: 'P001-L2-6',
    slotPrefix: "They're",
    promptJa: '「彼らはとても面白いです」',
    fullSentence: "They're very funny.",
    correctAudio: 'P001_L2_answer_6.mp3',
    choices: [
      { id: 'a', text: 'very funny',  isCorrect: true },
      { id: 'b', text: 'so funnily',  isCorrect: false, wrongReason: '「funnily」は少し別の使い方。「funny」のままの方が自然！' },
      { id: 'c', text: 'much funny',  isCorrect: false, wrongReason: '「much funny」という言い方はしない。「very funny」か「so funny」を使うよ。' },
      { id: 'd', text: 'have fun',    isCorrect: false, wrongReason: '「have fun」は「楽しむ」という意味。「面白い」を言うなら「funny」！' },
    ],
    explanation: 'They\'re の後ろも同じパターン。They\'re funny. / They\'re my friends. / They\'re late. 全部使えるよ！',
  },
]

// ─────────────────────────────────────────────
// P001 Layer 3：Flash Output（タイル選択式）
// 参照：MoWISE_P001_コンテンツ設計_v2.md FO1-Q1〜Q7
// ─────────────────────────────────────────────

export const p001Layer3Questions: Layer3Question[] = [
  {
    id: 'P001-L3-1',
    promptJa: '「私は疲れています。」',
    tiles: [
      { id: 't1', word: "I'm",   isDecoy: false },
      { id: 't2', word: 'tired', isDecoy: false },
      { id: 't3', word: '.',     isDecoy: false },
      { id: 't4', word: 'tire',  isDecoy: true  },  // ダミー
    ],
    answer: ["I'm", 'tired', '.'],
    correctSentence: "I'm tired.",
    hint: "I'm ___",
    timeLimitSec: 8,
    correctAudio: 'P001_L3_correct_1.mp3',
  },
  {
    id: 'P001-L3-2',
    promptJa: '「あなたはすごいです。」',
    tiles: [
      { id: 't1', word: "You're",  isDecoy: false },
      { id: 't2', word: 'amazing', isDecoy: false },
      { id: 't3', word: '.',       isDecoy: false },
      { id: 't4', word: "I'm",     isDecoy: true  },  // ダミー
    ],
    answer: ["You're", 'amazing', '.'],
    correctSentence: "You're amazing.",
    hint: "You're ___",
    timeLimitSec: 8,
    correctAudio: 'P001_L3_correct_2.mp3',
  },
  {
    id: 'P001-L3-3',
    promptJa: '「彼は私の友達です。」',
    tiles: [
      { id: 't1', word: "He's",   isDecoy: false },
      { id: 't2', word: 'my',     isDecoy: false },
      { id: 't3', word: 'friend', isDecoy: false },
      { id: 't4', word: '.',      isDecoy: false },
      { id: 't5', word: "She's",  isDecoy: true  },  // ダミー
    ],
    answer: ["He's", 'my', 'friend', '.'],
    correctSentence: "He's my friend.",
    hint: "He's ___",
    timeLimitSec: 8,
    correctAudio: 'P001_L3_correct_3.mp3',
  },
  {
    id: 'P001-L3-4',
    promptJa: '「彼女は医者です。」',
    tiles: [
      { id: 't1', word: "She's",  isDecoy: false },
      { id: 't2', word: 'a',      isDecoy: false },
      { id: 't3', word: 'doctor', isDecoy: false },
      { id: 't4', word: '.',      isDecoy: false },
      { id: 't5', word: "He's",   isDecoy: true  },  // ダミー
    ],
    answer: ["She's", 'a', 'doctor', '.'],
    correctSentence: "She's a doctor.",
    hint: "She's ___",
    timeLimitSec: 8,
    correctAudio: 'P001_L3_correct_4.mp3',
  },
  {
    id: 'P001-L3-5',
    promptJa: '「今日は暑いです。」',
    tiles: [
      { id: 't1', word: "It's",   isDecoy: false },
      { id: 't2', word: 'hot',    isDecoy: false },
      { id: 't3', word: 'today',  isDecoy: false },
      { id: 't4', word: '.',      isDecoy: false },
      { id: 't5', word: "This's", isDecoy: true  },  // ダミー（存在しない形）
    ],
    answer: ["It's", 'hot', 'today', '.'],
    correctSentence: "It's hot today.",
    hint: "It's ___",
    timeLimitSec: 8,
    correctAudio: 'P001_L3_correct_5.mp3',
  },
  {
    id: 'P001-L3-6',
    promptJa: '「私たちは準備OKです。」',
    tiles: [
      { id: 't1', word: "We're",  isDecoy: false },
      { id: 't2', word: 'ready',  isDecoy: false },
      { id: 't3', word: '.',      isDecoy: false },
      { id: 't4', word: "They're",isDecoy: true  },  // ダミー
    ],
    answer: ["We're", 'ready', '.'],
    correctSentence: "We're ready.",
    hint: "We're ___",
    timeLimitSec: 8,
    correctAudio: 'P001_L3_correct_6.mp3',
  },
  {
    id: 'P001-L3-7',
    promptJa: '「彼らは遅刻しています。」',
    tiles: [
      { id: 't1', word: "They're", isDecoy: false },
      { id: 't2', word: 'late',    isDecoy: false },
      { id: 't3', word: '.',       isDecoy: false },
      { id: 't4', word: "There's", isDecoy: true  },  // ダミー（They're / There's 混同対策）
    ],
    answer: ["They're", 'late', '.'],
    correctSentence: "They're late.",
    hint: "They're ___",
    timeLimitSec: 8,
    correctAudio: 'P001_L3_correct_7.mp3',
  },
]

// ─────────────────────────────────────────────
// P001 パターン基本情報
// ─────────────────────────────────────────────

export const p001PatternInfo = {
  id: 'P001',
  label: '[代名詞] + be動詞 + [状態/情報]',
  labelJa: '〜は…です',
  rarity: 1,
  area: 'area1',
  layer2QuestionCount: p001Layer2Questions.length,
  layer3QuestionCount: p001Layer3Questions.length,
  layer2PassThreshold: 5,   // 6問中5問
  layer3PassThreshold: 5,   // 7問中5問
}
