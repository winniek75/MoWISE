/**
 * MoWISE P002 問題データ
 * This is [名詞].（これは〜です — 紹介の基本）
 *
 * Layer 2（Pattern Sense）・Layer 3（Flash Output タイル式）
 * ⚠️ 品詞名はUI・フィードバックに一切出さない（AGENTS.md 禁止事項）
 */

import type { Layer2Question, Layer3Question } from './p001Questions'

// ─────────────────────────────────────────────
// P002 Layer 2：Pattern Sense（スロット穴埋め）
// ─────────────────────────────────────────────

export const p002Layer2Questions: Layer2Question[] = [
  {
    id: 'P002-L2-1',
    slotPrefix: 'This is',
    promptJa: '「これは私のカバンです」',
    fullSentence: 'This is my bag.',
    correctAudio: 'P002_L2_answer_1.mp3',
    choices: [
      { id: 'a', text: 'my bag',    isCorrect: true },
      { id: 'b', text: 'bag my',    isCorrect: false, wrongReason: '順番が逆だよ。「my bag」が自然な並び！' },
      { id: 'c', text: 'a my bag',  isCorrect: false, wrongReason: '「a」と「my」は一緒に使わない。「my bag」だけでOK！' },
      { id: 'd', text: 'bags',      isCorrect: false, wrongReason: '「bags」だと複数になる。一つなら「my bag」！' },
    ],
    explanation: '「This is + 名前のついたもの」で紹介できる。my bag, my friend, my school …何でも入るよ！',
  },
  {
    id: 'P002-L2-2',
    slotPrefix: 'This is',
    promptJa: '「こちらは私の友だちのユキです」',
    fullSentence: 'This is my friend, Yuki.',
    correctAudio: 'P002_L2_answer_2.mp3',
    choices: [
      { id: 'a', text: 'my friend, Yuki', isCorrect: true },
      { id: 'b', text: 'Yuki my friend',  isCorrect: false, wrongReason: '英語では「my friend, Yuki」の順番が自然！' },
      { id: 'c', text: 'friend my',       isCorrect: false, wrongReason: '順番が逆。「my friend」が正しい並び！' },
      { id: 'd', text: 'a Yuki',          isCorrect: false, wrongReason: '人の名前に「a」はつけないよ！' },
    ],
    explanation: '人を紹介するときも「This is + 関係, 名前」のパターン。This is my friend, Yuki. 自然に言えるようにしよう！',
  },
  {
    id: 'P002-L2-3',
    slotPrefix: 'This is',
    promptJa: '「これ、いいね！」',
    fullSentence: 'This is great!',
    correctAudio: 'P002_L2_answer_3.mp3',
    choices: [
      { id: 'a', text: 'great',    isCorrect: true },
      { id: 'b', text: 'a great',  isCorrect: false, wrongReason: '「a great」だけでは文にならない。「great!」だけでOK！' },
      { id: 'c', text: 'greatly',  isCorrect: false, wrongReason: '「greatly」は別の使い方。感動は「great」でストレート！' },
      { id: 'd', text: 'greats',   isCorrect: false, wrongReason: '「greats」はここでは使わない形。' },
    ],
    explanation: '「This is + 感想」で感動も伝えられる！This is great! / This is amazing! / This is fun!',
  },
  {
    id: 'P002-L2-4',
    slotPrefix: 'This is',
    promptJa: '「これは私の学校です」',
    fullSentence: 'This is my school.',
    correctAudio: 'P002_L2_answer_4.mp3',
    choices: [
      { id: 'a', text: 'my school',   isCorrect: true },
      { id: 'b', text: 'school',      isCorrect: false, wrongReason: '「school」だけだと「誰の？」が分からない。「my school」で伝わるよ！' },
      { id: 'c', text: 'the my school',isCorrect: false, wrongReason: '「the」と「my」は一緒に使わない。「my school」だけで十分！' },
      { id: 'd', text: 'schools my',  isCorrect: false, wrongReason: '順番が逆だよ。「my school」が正しい並び！' },
    ],
    explanation: '場所を紹介するときも同じ。This is my school. / This is my room. パターンは同じ！',
  },
  {
    id: 'P002-L2-5',
    slotPrefix: 'This is',
    promptJa: '「これは新しいゲームです」',
    fullSentence: 'This is a new game.',
    correctAudio: 'P002_L2_answer_5.mp3',
    choices: [
      { id: 'a', text: 'a new game', isCorrect: true },
      { id: 'b', text: 'new game',   isCorrect: false, wrongReason: '初めて紹介するものには「a」をつけると自然！' },
      { id: 'c', text: 'new a game', isCorrect: false, wrongReason: '「a」は「new」の前に置くよ。「a new game」が正解！' },
      { id: 'd', text: 'games new',  isCorrect: false, wrongReason: '順番が違う。英語では「a new game」の順！' },
    ],
    explanation: '初めて紹介するものには「a」をつける。This is a new game. / This is a cool place.',
  },
  {
    id: 'P002-L2-6',
    slotPrefix: 'This is',
    promptJa: '「これは難しいです」',
    fullSentence: 'This is difficult.',
    correctAudio: 'P002_L2_answer_6.mp3',
    choices: [
      { id: 'a', text: 'difficult',    isCorrect: true },
      { id: 'b', text: 'a difficult',  isCorrect: false, wrongReason: '「a difficult」だけでは文にならない。「difficult」だけでOK！' },
      { id: 'c', text: 'difficulty',   isCorrect: false, wrongReason: '「difficulty」は名詞。ここでは「difficult」が自然！' },
      { id: 'd', text: 'very much difficult', isCorrect: false, wrongReason: 'この言い方はしない。「very difficult」なら使えるよ！' },
    ],
    explanation: 'P001と同じで、This is の後ろに状態を表す言葉もそのまま入る。This is difficult. / This is easy.',
  },
]

// ─────────────────────────────────────────────
// P002 Layer 3：Flash Output（タイル選択式）
// ─────────────────────────────────────────────

export const p002Layer3Questions: Layer3Question[] = [
  {
    id: 'P002-L3-1',
    promptJa: '「これは私のカバンです。」',
    tiles: [
      { id: 't1', word: 'This',  isDecoy: false },
      { id: 't2', word: 'is',    isDecoy: false },
      { id: 't3', word: 'my',    isDecoy: false },
      { id: 't4', word: 'bag',   isDecoy: false },
      { id: 't5', word: '.',     isDecoy: false },
      { id: 't6', word: 'That',  isDecoy: true },
    ],
    answer: ['This', 'is', 'my', 'bag', '.'],
    correctSentence: 'This is my bag.',
    hint: 'This is ___',
    timeLimitSec: 8,
    correctAudio: 'P002_L3_correct_1.mp3',
  },
  {
    id: 'P002-L3-2',
    promptJa: '「こちらは私の友だちのユキです。」',
    tiles: [
      { id: 't1', word: 'This',   isDecoy: false },
      { id: 't2', word: 'is',     isDecoy: false },
      { id: 't3', word: 'my',     isDecoy: false },
      { id: 't4', word: 'friend', isDecoy: false },
      { id: 't5', word: ',',      isDecoy: false },
      { id: 't6', word: 'Yuki',   isDecoy: false },
      { id: 't7', word: '.',      isDecoy: false },
      { id: 't8', word: 'a',      isDecoy: true },
    ],
    answer: ['This', 'is', 'my', 'friend', ',', 'Yuki', '.'],
    correctSentence: 'This is my friend, Yuki.',
    hint: 'This is my ___',
    timeLimitSec: 10,
    correctAudio: 'P002_L3_correct_2.mp3',
  },
  {
    id: 'P002-L3-3',
    promptJa: '「これ、いいね！」',
    tiles: [
      { id: 't1', word: 'This',  isDecoy: false },
      { id: 't2', word: 'is',    isDecoy: false },
      { id: 't3', word: 'great', isDecoy: false },
      { id: 't4', word: '!',     isDecoy: false },
      { id: 't5', word: 'good',  isDecoy: true },
    ],
    answer: ['This', 'is', 'great', '!'],
    correctSentence: 'This is great!',
    hint: 'This is ___',
    timeLimitSec: 8,
    correctAudio: 'P002_L3_correct_3.mp3',
  },
  {
    id: 'P002-L3-4',
    promptJa: '「これは私の学校です。」',
    tiles: [
      { id: 't1', word: 'This',   isDecoy: false },
      { id: 't2', word: 'is',     isDecoy: false },
      { id: 't3', word: 'my',     isDecoy: false },
      { id: 't4', word: 'school', isDecoy: false },
      { id: 't5', word: '.',      isDecoy: false },
      { id: 't6', word: 'your',   isDecoy: true },
    ],
    answer: ['This', 'is', 'my', 'school', '.'],
    correctSentence: 'This is my school.',
    hint: 'This is ___',
    timeLimitSec: 8,
    correctAudio: 'P002_L3_correct_4.mp3',
  },
  {
    id: 'P002-L3-5',
    promptJa: '「これは新しいゲームです。」',
    tiles: [
      { id: 't1', word: 'This', isDecoy: false },
      { id: 't2', word: 'is',   isDecoy: false },
      { id: 't3', word: 'a',    isDecoy: false },
      { id: 't4', word: 'new',  isDecoy: false },
      { id: 't5', word: 'game', isDecoy: false },
      { id: 't6', word: '.',    isDecoy: false },
      { id: 't7', word: 'old',  isDecoy: true },
    ],
    answer: ['This', 'is', 'a', 'new', 'game', '.'],
    correctSentence: 'This is a new game.',
    hint: 'This is a ___',
    timeLimitSec: 10,
    correctAudio: 'P002_L3_correct_5.mp3',
  },
  {
    id: 'P002-L3-6',
    promptJa: '「これは難しいです。」',
    tiles: [
      { id: 't1', word: 'This',      isDecoy: false },
      { id: 't2', word: 'is',        isDecoy: false },
      { id: 't3', word: 'difficult', isDecoy: false },
      { id: 't4', word: '.',         isDecoy: false },
      { id: 't5', word: 'easy',      isDecoy: true },
    ],
    answer: ['This', 'is', 'difficult', '.'],
    correctSentence: 'This is difficult.',
    hint: 'This is ___',
    timeLimitSec: 8,
    correctAudio: 'P002_L3_correct_6.mp3',
  },
  {
    id: 'P002-L3-7',
    promptJa: '「これは楽しいです。」',
    tiles: [
      { id: 't1', word: 'This',  isDecoy: false },
      { id: 't2', word: 'is',    isDecoy: false },
      { id: 't3', word: 'fun',   isDecoy: false },
      { id: 't4', word: '.',     isDecoy: false },
      { id: 't5', word: 'funny', isDecoy: true },
    ],
    answer: ['This', 'is', 'fun', '.'],
    correctSentence: 'This is fun.',
    hint: 'This is ___',
    timeLimitSec: 8,
    correctAudio: 'P002_L3_correct_7.mp3',
  },
]

// ─────────────────────────────────────────────
// P002 パターン基本情報
// ─────────────────────────────────────────────

export const p002PatternInfo = {
  id: 'P002',
  label: 'This is [名詞].',
  labelJa: 'これは〜です',
  rarity: 1,
  area: 'area1',
  layer2QuestionCount: p002Layer2Questions.length,
  layer3QuestionCount: p002Layer3Questions.length,
  layer2PassThreshold: 5,
  layer3PassThreshold: 5,
}
