/**
 * MoWISE P005 問題データ
 * I want [名詞].（〜が欲しいです — 欲求の最基本）
 *
 * Layer 2（Pattern Sense）・Layer 3（Flash Output タイル式）
 * ⚠️ 品詞名はUI・フィードバックに一切出さない（AGENTS.md 禁止事項）
 */

import type { Layer2Question, Layer3Question } from './p001Questions'

// ─────────────────────────────────────────────
// P005 Layer 2：Pattern Sense（スロット穴埋め）
// ─────────────────────────────────────────────

export const p005Layer2Questions: Layer2Question[] = [
  {
    id: 'P005-L2-1',
    slotPrefix: 'I want',
    promptJa: '「お水がほしいです」',
    fullSentence: 'I want water.',
    correctAudio: 'P005_L2_answer_1.mp3',
    choices: [
      { id: 'a', text: 'water',     isCorrect: true },
      { id: 'b', text: 'a water',   isCorrect: false, wrongReason: '「water」には「a」をつけない。そのままでOK！' },
      { id: 'c', text: 'waters',    isCorrect: false, wrongReason: '「waters」は普通使わない。「water」だけで十分！' },
      { id: 'd', text: 'the water', isCorrect: false, wrongReason: 'お店で注文するときは「water」だけが自然！' },
    ],
    explanation: '「I want + 欲しいもの」でシンプルに伝えられる。I want water. / I want coffee. 即使える！',
  },
  {
    id: 'P005-L2-2',
    slotPrefix: 'I want to',
    promptJa: '「家に帰りたいです」',
    fullSentence: 'I want to go home.',
    correctAudio: 'P005_L2_answer_2.mp3',
    choices: [
      { id: 'a', text: 'go home',     isCorrect: true },
      { id: 'b', text: 'going home',  isCorrect: false, wrongReason: '「want to」の後は原形。「go home」が正解！' },
      { id: 'c', text: 'goes home',   isCorrect: false, wrongReason: '「to」の後は原形だから「go」。「goes」は使わないよ！' },
      { id: 'd', text: 'home go',     isCorrect: false, wrongReason: '順番が逆。「go home」が英語の自然な並び！' },
    ],
    explanation: '「〜したい」は「I want to + 動作」。I want to go. / I want to eat. / I want to sleep.',
  },
  {
    id: 'P005-L2-3',
    slotPrefix: 'I want',
    promptJa: '「新しい携帯がほしいです」',
    fullSentence: 'I want a new phone.',
    correctAudio: 'P005_L2_answer_3.mp3',
    choices: [
      { id: 'a', text: 'a new phone', isCorrect: true },
      { id: 'b', text: 'new phone',   isCorrect: false, wrongReason: '1台の携帯を言うときは「a」をつけるのが自然！' },
      { id: 'c', text: 'phone new',   isCorrect: false, wrongReason: '英語では「new phone」の順番。「新しい」が先！' },
      { id: 'd', text: 'new a phone', isCorrect: false, wrongReason: '「a」は「new」の前に置くよ。「a new phone」が正解！' },
    ],
    explanation: '物が欲しいときは「I want + a/an + 説明 + もの」。I want a new phone. / I want a cold drink.',
  },
  {
    id: 'P005-L2-4',
    slotPrefix: 'I want to',
    promptJa: '「食べたいです」',
    fullSentence: 'I want to eat.',
    correctAudio: 'P005_L2_answer_4.mp3',
    choices: [
      { id: 'a', text: 'eat',     isCorrect: true },
      { id: 'b', text: 'eating',  isCorrect: false, wrongReason: '「want to」の後は原形。「eat」が正しいよ！' },
      { id: 'c', text: 'eats',    isCorrect: false, wrongReason: '「to」の後は原形だから「eat」。「eats」は使わない！' },
      { id: 'd', text: 'ate',     isCorrect: false, wrongReason: '「ate」は過去形。「want to」の後は原形の「eat」！' },
    ],
    explanation: '「I want to eat.」シンプルだけど超使える。お腹が減ったらこのひと言！',
  },
  {
    id: 'P005-L2-5',
    slotPrefix: 'I want',
    promptJa: '「もっと時間がほしいです」',
    fullSentence: 'I want more time.',
    correctAudio: 'P005_L2_answer_5.mp3',
    choices: [
      { id: 'a', text: 'more time',  isCorrect: true },
      { id: 'b', text: 'many time',  isCorrect: false, wrongReason: '「time」は「many」ではなく「more」を使うよ！' },
      { id: 'c', text: 'time more',  isCorrect: false, wrongReason: '順番が逆。「more time」が自然な英語！' },
      { id: 'd', text: 'a more time',isCorrect: false, wrongReason: '「a more time」とは言わない。「more time」でOK！' },
    ],
    explanation: '「more + 名前」で「もっと〜」が言える。I want more time. / I want more sleep.',
  },
  {
    id: 'P005-L2-6',
    slotPrefix: 'I want to',
    promptJa: '「遊びたいです」',
    fullSentence: 'I want to play.',
    correctAudio: 'P005_L2_answer_6.mp3',
    choices: [
      { id: 'a', text: 'play',     isCorrect: true },
      { id: 'b', text: 'playing',  isCorrect: false, wrongReason: '「want to」の後は原形。「play」が正解！' },
      { id: 'c', text: 'plays',    isCorrect: false, wrongReason: '「to」の後は原形。「play」を使おう！' },
      { id: 'd', text: 'played',   isCorrect: false, wrongReason: '「played」は過去形。今したいことは「play」！' },
    ],
    explanation: '「I want to play.」で「遊びたい」。ゲームも外遊びも全部これでOK！',
  },
]

// ─────────────────────────────────────────────
// P005 Layer 3：Flash Output（タイル選択式）
// ─────────────────────────────────────────────

export const p005Layer3Questions: Layer3Question[] = [
  {
    id: 'P005-L3-1',
    promptJa: '「お水がほしいです。」',
    tiles: [
      { id: 't1', word: 'I',     isDecoy: false },
      { id: 't2', word: 'want',  isDecoy: false },
      { id: 't3', word: 'water', isDecoy: false },
      { id: 't4', word: '.',     isDecoy: false },
      { id: 't5', word: 'like',  isDecoy: true },
    ],
    answer: ['I', 'want', 'water', '.'],
    correctSentence: 'I want water.',
    hint: 'I want ___',
    timeLimitSec: 8,
    correctAudio: 'P005_L3_correct_1.mp3',
  },
  {
    id: 'P005-L3-2',
    promptJa: '「家に帰りたいです。」',
    tiles: [
      { id: 't1', word: 'I',    isDecoy: false },
      { id: 't2', word: 'want', isDecoy: false },
      { id: 't3', word: 'to',   isDecoy: false },
      { id: 't4', word: 'go',   isDecoy: false },
      { id: 't5', word: 'home', isDecoy: false },
      { id: 't6', word: '.',    isDecoy: false },
      { id: 't7', word: 'come', isDecoy: true },
    ],
    answer: ['I', 'want', 'to', 'go', 'home', '.'],
    correctSentence: 'I want to go home.',
    hint: 'I want to ___',
    timeLimitSec: 10,
    correctAudio: 'P005_L3_correct_2.mp3',
  },
  {
    id: 'P005-L3-3',
    promptJa: '「新しい携帯がほしいです。」',
    tiles: [
      { id: 't1', word: 'I',     isDecoy: false },
      { id: 't2', word: 'want',  isDecoy: false },
      { id: 't3', word: 'a',     isDecoy: false },
      { id: 't4', word: 'new',   isDecoy: false },
      { id: 't5', word: 'phone', isDecoy: false },
      { id: 't6', word: '.',     isDecoy: false },
      { id: 't7', word: 'old',   isDecoy: true },
    ],
    answer: ['I', 'want', 'a', 'new', 'phone', '.'],
    correctSentence: 'I want a new phone.',
    hint: 'I want a ___',
    timeLimitSec: 10,
    correctAudio: 'P005_L3_correct_3.mp3',
  },
  {
    id: 'P005-L3-4',
    promptJa: '「食べたいです。」',
    tiles: [
      { id: 't1', word: 'I',    isDecoy: false },
      { id: 't2', word: 'want', isDecoy: false },
      { id: 't3', word: 'to',   isDecoy: false },
      { id: 't4', word: 'eat',  isDecoy: false },
      { id: 't5', word: '.',    isDecoy: false },
      { id: 't6', word: 'have', isDecoy: true },
    ],
    answer: ['I', 'want', 'to', 'eat', '.'],
    correctSentence: 'I want to eat.',
    hint: 'I want to ___',
    timeLimitSec: 8,
    correctAudio: 'P005_L3_correct_4.mp3',
  },
  {
    id: 'P005-L3-5',
    promptJa: '「もっと時間がほしいです。」',
    tiles: [
      { id: 't1', word: 'I',    isDecoy: false },
      { id: 't2', word: 'want', isDecoy: false },
      { id: 't3', word: 'more', isDecoy: false },
      { id: 't4', word: 'time', isDecoy: false },
      { id: 't5', word: '.',    isDecoy: false },
      { id: 't6', word: 'much', isDecoy: true },
    ],
    answer: ['I', 'want', 'more', 'time', '.'],
    correctSentence: 'I want more time.',
    hint: 'I want more ___',
    timeLimitSec: 8,
    correctAudio: 'P005_L3_correct_5.mp3',
  },
  {
    id: 'P005-L3-6',
    promptJa: '「遊びたいです。」',
    tiles: [
      { id: 't1', word: 'I',    isDecoy: false },
      { id: 't2', word: 'want', isDecoy: false },
      { id: 't3', word: 'to',   isDecoy: false },
      { id: 't4', word: 'play', isDecoy: false },
      { id: 't5', word: '.',    isDecoy: false },
      { id: 't6', word: 'run',  isDecoy: true },
    ],
    answer: ['I', 'want', 'to', 'play', '.'],
    correctSentence: 'I want to play.',
    hint: 'I want to ___',
    timeLimitSec: 8,
    correctAudio: 'P005_L3_correct_6.mp3',
  },
  {
    id: 'P005-L3-7',
    promptJa: '「寝たいです。」',
    tiles: [
      { id: 't1', word: 'I',     isDecoy: false },
      { id: 't2', word: 'want',  isDecoy: false },
      { id: 't3', word: 'to',    isDecoy: false },
      { id: 't4', word: 'sleep', isDecoy: false },
      { id: 't5', word: '.',     isDecoy: false },
      { id: 't6', word: 'rest',  isDecoy: true },
    ],
    answer: ['I', 'want', 'to', 'sleep', '.'],
    correctSentence: 'I want to sleep.',
    hint: 'I want to ___',
    timeLimitSec: 8,
    correctAudio: 'P005_L3_correct_7.mp3',
  },
]

// ─────────────────────────────────────────────
// P005 パターン基本情報
// ─────────────────────────────────────────────

export const p005PatternInfo = {
  id: 'P005',
  label: 'I want [名詞].',
  labelJa: '〜が欲しいです',
  rarity: 1,
  area: 'area1',
  layer2QuestionCount: p005Layer2Questions.length,
  layer3QuestionCount: p005Layer3Questions.length,
  layer2PassThreshold: 5,
  layer3PassThreshold: 5,
}
