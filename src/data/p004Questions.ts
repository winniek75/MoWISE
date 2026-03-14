/**
 * MoWISE P004 問題データ
 * I like [名詞/動名詞].（〜が好きです — 会話の鉄板パターン）
 *
 * Layer 2（Pattern Sense）・Layer 3（Flash Output タイル式）
 * ⚠️ 品詞名はUI・フィードバックに一切出さない（AGENTS.md 禁止事項）
 */

import type { Layer2Question, Layer3Question } from './p001Questions'

// ─────────────────────────────────────────────
// P004 Layer 2：Pattern Sense（スロット穴埋め）
// ─────────────────────────────────────────────

export const p004Layer2Questions: Layer2Question[] = [
  {
    id: 'P004-L2-1',
    slotPrefix: 'I like',
    promptJa: '「私はサッカーが好きです」',
    fullSentence: 'I like soccer.',
    correctAudio: 'P004_L2_answer_1.mp3',
    choices: [
      { id: 'a', text: 'soccer',     isCorrect: true },
      { id: 'b', text: 'a soccer',   isCorrect: false, wrongReason: 'スポーツ名には「a」をつけない。「soccer」だけでOK！' },
      { id: 'c', text: 'soccers',    isCorrect: false, wrongReason: 'スポーツ名は複数形にしない。「soccer」が正解！' },
      { id: 'd', text: 'the soccer', isCorrect: false, wrongReason: '好きなものを言うときは「the」なしが自然。「soccer」だけでOK！' },
    ],
    explanation: '「I like + 好きなもの」で自分の好みを伝えられる。I like soccer. / I like music. シンプル！',
  },
  {
    id: 'P004-L2-2',
    slotPrefix: 'I like',
    promptJa: '「寿司を食べるのが好きです」',
    fullSentence: 'I like eating sushi.',
    correctAudio: 'P004_L2_answer_2.mp3',
    choices: [
      { id: 'a', text: 'eating sushi', isCorrect: true },
      { id: 'b', text: 'eat sushi',    isCorrect: false, wrongReason: '「like」の後は「eating」の形にすると自然。「〜すること」という意味になるよ！' },
      { id: 'c', text: 'to eating',    isCorrect: false, wrongReason: '「to eating」とは言わない。「eating sushi」か「to eat sushi」！' },
      { id: 'd', text: 'sushi eating', isCorrect: false, wrongReason: '順番が逆。「eating sushi」が正しい！' },
    ],
    explanation: '「〜することが好き」は「I like + ○○ing」。I like eating. / I like running. / I like reading.',
  },
  {
    id: 'P004-L2-3',
    slotPrefix: 'I like',
    promptJa: '「あなたの靴いいね」',
    fullSentence: 'I like your shoes.',
    correctAudio: 'P004_L2_answer_3.mp3',
    choices: [
      { id: 'a', text: 'your shoes', isCorrect: true },
      { id: 'b', text: 'you shoes',  isCorrect: false, wrongReason: '「you shoes」ではなく「your shoes」。「あなたの」は「your」！' },
      { id: 'c', text: 'your shoe',  isCorrect: false, wrongReason: '靴は普通2つで1セット。「shoes」と複数で言うのが自然！' },
      { id: 'd', text: 'the shoes',  isCorrect: false, wrongReason: '相手の靴を褒めるなら「your shoes」の方が自然！' },
    ],
    explanation: '「I like + your ○○」で褒め言葉にもなる。I like your shoes. / I like your hair. 使える！',
  },
  {
    id: 'P004-L2-4',
    slotPrefix: 'I like',
    promptJa: '「音楽が好きです」',
    fullSentence: 'I like music.',
    correctAudio: 'P004_L2_answer_4.mp3',
    choices: [
      { id: 'a', text: 'music',     isCorrect: true },
      { id: 'b', text: 'a music',   isCorrect: false, wrongReason: '「music」には「a」をつけない。そのままでOK！' },
      { id: 'c', text: 'musics',    isCorrect: false, wrongReason: '「music」は複数形にしない。そのままで使うよ！' },
      { id: 'd', text: 'the musics',isCorrect: false, wrongReason: '好きなジャンルを言うときは「music」だけが自然！' },
    ],
    explanation: '数えられないもの（music, water, food…）もそのまま「I like ○○」で使える！',
  },
  {
    id: 'P004-L2-5',
    slotPrefix: 'I like',
    promptJa: '「犬が好きです」',
    fullSentence: 'I like dogs.',
    correctAudio: 'P004_L2_answer_5.mp3',
    choices: [
      { id: 'a', text: 'dogs',   isCorrect: true },
      { id: 'b', text: 'dog',    isCorrect: false, wrongReason: '「犬が好き」を一般的に言うときは「dogs」と複数形が自然！' },
      { id: 'c', text: 'a dog',  isCorrect: false, wrongReason: '「a dog」だと特定の1匹。犬全般が好きなら「dogs」！' },
      { id: 'd', text: 'the dog',isCorrect: false, wrongReason: '「the dog」は特定の犬のこと。犬が全般的に好きなら「dogs」！' },
    ],
    explanation: '動物や食べ物など「〜が好き」全般は複数形が自然。I like dogs. / I like cats. / I like apples.',
  },
  {
    id: 'P004-L2-6',
    slotPrefix: 'I like',
    promptJa: '「泳ぐのが好きです」',
    fullSentence: 'I like swimming.',
    correctAudio: 'P004_L2_answer_6.mp3',
    choices: [
      { id: 'a', text: 'swimming', isCorrect: true },
      { id: 'b', text: 'swim',     isCorrect: false, wrongReason: '「〜するのが好き」は「I like ○○ing」の形。「swimming」が正解！' },
      { id: 'c', text: 'swims',    isCorrect: false, wrongReason: '「swims」はここには入らない。「swimming」が正しい形！' },
      { id: 'd', text: 'to swimming', isCorrect: false, wrongReason: '「to swimming」とは言わない。「swimming」だけで入るよ！' },
    ],
    explanation: '「I like swimming.」「I like dancing.」…何でも ○○ing をつけるだけ！',
  },
]

// ─────────────────────────────────────────────
// P004 Layer 3：Flash Output（タイル選択式）
// ─────────────────────────────────────────────

export const p004Layer3Questions: Layer3Question[] = [
  {
    id: 'P004-L3-1',
    promptJa: '「私はサッカーが好きです。」',
    tiles: [
      { id: 't1', word: 'I',      isDecoy: false },
      { id: 't2', word: 'like',   isDecoy: false },
      { id: 't3', word: 'soccer', isDecoy: false },
      { id: 't4', word: '.',      isDecoy: false },
      { id: 't5', word: 'want',   isDecoy: true },
    ],
    answer: ['I', 'like', 'soccer', '.'],
    correctSentence: 'I like soccer.',
    hint: 'I like ___',
    timeLimitSec: 8,
    correctAudio: 'P004_L3_correct_1.mp3',
  },
  {
    id: 'P004-L3-2',
    promptJa: '「寿司を食べるのが好きです。」',
    tiles: [
      { id: 't1', word: 'I',      isDecoy: false },
      { id: 't2', word: 'like',   isDecoy: false },
      { id: 't3', word: 'eating', isDecoy: false },
      { id: 't4', word: 'sushi',  isDecoy: false },
      { id: 't5', word: '.',      isDecoy: false },
      { id: 't6', word: 'eat',    isDecoy: true },
    ],
    answer: ['I', 'like', 'eating', 'sushi', '.'],
    correctSentence: 'I like eating sushi.',
    hint: 'I like ___ing',
    timeLimitSec: 10,
    correctAudio: 'P004_L3_correct_2.mp3',
  },
  {
    id: 'P004-L3-3',
    promptJa: '「あなたの靴いいね。」',
    tiles: [
      { id: 't1', word: 'I',     isDecoy: false },
      { id: 't2', word: 'like',  isDecoy: false },
      { id: 't3', word: 'your',  isDecoy: false },
      { id: 't4', word: 'shoes', isDecoy: false },
      { id: 't5', word: '.',     isDecoy: false },
      { id: 't6', word: 'my',    isDecoy: true },
    ],
    answer: ['I', 'like', 'your', 'shoes', '.'],
    correctSentence: 'I like your shoes.',
    hint: 'I like your ___',
    timeLimitSec: 8,
    correctAudio: 'P004_L3_correct_3.mp3',
  },
  {
    id: 'P004-L3-4',
    promptJa: '「音楽が好きです。」',
    tiles: [
      { id: 't1', word: 'I',     isDecoy: false },
      { id: 't2', word: 'like',  isDecoy: false },
      { id: 't3', word: 'music', isDecoy: false },
      { id: 't4', word: '.',     isDecoy: false },
      { id: 't5', word: 'song',  isDecoy: true },
    ],
    answer: ['I', 'like', 'music', '.'],
    correctSentence: 'I like music.',
    hint: 'I like ___',
    timeLimitSec: 8,
    correctAudio: 'P004_L3_correct_4.mp3',
  },
  {
    id: 'P004-L3-5',
    promptJa: '「犬が好きです。」',
    tiles: [
      { id: 't1', word: 'I',    isDecoy: false },
      { id: 't2', word: 'like', isDecoy: false },
      { id: 't3', word: 'dogs', isDecoy: false },
      { id: 't4', word: '.',    isDecoy: false },
      { id: 't5', word: 'cats', isDecoy: true },
    ],
    answer: ['I', 'like', 'dogs', '.'],
    correctSentence: 'I like dogs.',
    hint: 'I like ___',
    timeLimitSec: 8,
    correctAudio: 'P004_L3_correct_5.mp3',
  },
  {
    id: 'P004-L3-6',
    promptJa: '「泳ぐのが好きです。」',
    tiles: [
      { id: 't1', word: 'I',        isDecoy: false },
      { id: 't2', word: 'like',     isDecoy: false },
      { id: 't3', word: 'swimming', isDecoy: false },
      { id: 't4', word: '.',        isDecoy: false },
      { id: 't5', word: 'running',  isDecoy: true },
    ],
    answer: ['I', 'like', 'swimming', '.'],
    correctSentence: 'I like swimming.',
    hint: 'I like ___',
    timeLimitSec: 8,
    correctAudio: 'P004_L3_correct_6.mp3',
  },
  {
    id: 'P004-L3-7',
    promptJa: '「野球が好きです。」',
    tiles: [
      { id: 't1', word: 'I',        isDecoy: false },
      { id: 't2', word: 'like',     isDecoy: false },
      { id: 't3', word: 'baseball', isDecoy: false },
      { id: 't4', word: '.',        isDecoy: false },
      { id: 't5', word: 'basket',   isDecoy: true },
    ],
    answer: ['I', 'like', 'baseball', '.'],
    correctSentence: 'I like baseball.',
    hint: 'I like ___',
    timeLimitSec: 8,
    correctAudio: 'P004_L3_correct_7.mp3',
  },
]

// ─────────────────────────────────────────────
// P004 パターン基本情報
// ─────────────────────────────────────────────

export const p004PatternInfo = {
  id: 'P004',
  label: 'I like [名詞/動名詞].',
  labelJa: '〜が好きです',
  rarity: 1,
  area: 'area1',
  layer2QuestionCount: p004Layer2Questions.length,
  layer3QuestionCount: p004Layer3Questions.length,
  layer2PassThreshold: 5,
  layer3PassThreshold: 5,
}
