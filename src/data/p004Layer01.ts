/**
 * P004 Layer 0 / Layer 1 問題データ
 * "I like [noun]." パターン（私は〜が好きです）
 *
 * Layer 0: Sound Foundation — ゆっくり vs ナチュラルの聞き比べ
 * Layer 1: Echo Drill — 音声を聞いて正しいテキストを選ぶ
 */

import type { Layer0Question, Layer1Question } from './layerTypes'

// ─────────────────────────────────────────────
// P004 Layer 0: Sound Foundation
// ─────────────────────────────────────────────

export const p004Layer0Questions: Layer0Question[] = [
  {
    id: 'P004-L0-1',
    slowText: 'I like cats.',
    naturalText: 'I like cats.',
    meaningJa: '私は猫が好きです',
    slowAudio: 'P004_L0_slow_1.mp3',
    naturalAudio: 'P004_L0_natural_1.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'I like cats.', isNatural: true },
        { id: 'b', text: 'I like cats.', isNatural: false },
      ],
      explanation: 'ナチュラルスピードだと "I like" がつながって「アイライク」と聞こえるよ。リンキングに慣れよう！',
    },
  },
  {
    id: 'P004-L0-2',
    slowText: 'She likes music.',
    naturalText: 'She likes music.',
    meaningJa: '彼女は音楽が好きです',
    slowAudio: 'P004_L0_slow_2.mp3',
    naturalAudio: 'P004_L0_natural_2.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'She likes music.', isNatural: true },
        { id: 'b', text: 'She like music.', isNatural: false },
      ],
      explanation: '"She" のときは "likes" と "s" がつくよ。速く言っても "s" の音はちゃんと聞こえる！',
    },
  },
  {
    id: 'P004-L0-3',
    slowText: 'I like coffee.',
    naturalText: 'I like coffee.',
    meaningJa: '私はコーヒーが好きです',
    slowAudio: 'P004_L0_slow_3.mp3',
    naturalAudio: 'P004_L0_natural_3.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'I like coffee.', isNatural: true },
        { id: 'b', text: 'I liked coffee.', isNatural: false },
      ],
      explanation: '"like" と "liked" では意味が変わる。"like" は今好きなこと、"liked" は前に好きだったこと。音の違いを聞いてみて！',
    },
  },
  {
    id: 'P004-L0-4',
    slowText: 'We like pizza.',
    naturalText: 'We like pizza.',
    meaningJa: '私たちはピザが好きです',
    slowAudio: 'P004_L0_slow_4.mp3',
    naturalAudio: 'P004_L0_natural_4.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'We like pizza.', isNatural: true },
        { id: 'b', text: 'We liked pizza.', isNatural: false },
      ],
      explanation: 'ナチュラルスピードでも "like" の最後に "d" の音がないのを聞き取れたかな？',
    },
  },
  {
    id: 'P004-L0-5',
    slowText: 'He likes soccer.',
    naturalText: 'He likes soccer.',
    meaningJa: '彼はサッカーが好きです',
    slowAudio: 'P004_L0_slow_5.mp3',
    naturalAudio: 'P004_L0_natural_5.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'He likes soccer.', isNatural: true },
        { id: 'b', text: 'He like soccer.', isNatural: false },
      ],
      explanation: '"He" のときも "likes" と "s" がつく。速い英語でもこの "s" はしっかり聞こえるよ！',
    },
  },
]

// ─────────────────────────────────────────────
// P004 Layer 1: Echo Drill (Sound Match)
// ─────────────────────────────────────────────

export const p004Layer1Questions: Layer1Question[] = [
  {
    id: 'P004-L1-1',
    sentence: 'I like cats.',
    hintJa: '「猫が好き」',
    audio: 'P004_L1_match_1.mp3',
    choices: [
      { id: 'a', text: 'I like cats.', isCorrect: true },
      { id: 'b', text: "I'd like cats.", isCorrect: false },
      { id: 'c', text: 'I lied cats.', isCorrect: false },
    ],
    explanation: '"I like"（好き）と "I\'d like"（欲しい）は似てるけど、"d" の音があるかないかがポイント！',
  },
  {
    id: 'P004-L1-2',
    sentence: 'She likes music.',
    hintJa: '「音楽が好き」',
    audio: 'P004_L1_match_2.mp3',
    choices: [
      { id: 'a', text: 'She licks music.', isCorrect: false },
      { id: 'b', text: 'She likes music.', isCorrect: true },
      { id: 'c', text: 'She lies music.', isCorrect: false },
    ],
    explanation: '"likes"（好き）と "licks"（なめる）は超似てる！でも真ん中の音が少し違うよ。',
  },
  {
    id: 'P004-L1-3',
    sentence: 'I like coffee.',
    hintJa: '「コーヒーが好き」',
    audio: 'P004_L1_match_3.mp3',
    choices: [
      { id: 'a', text: "I'd like coffee.", isCorrect: false },
      { id: 'b', text: 'I liked coffee.', isCorrect: false },
      { id: 'c', text: 'I like coffee.', isCorrect: true },
    ],
    explanation: '"I like"（好き）、"I\'d like"（欲しい）、"I liked"（好きだった）。全部違う意味だから聞き分けが大事！',
  },
  {
    id: 'P004-L1-4',
    sentence: 'We like pizza.',
    hintJa: '「ピザが好き」',
    audio: 'P004_L1_match_4.mp3',
    choices: [
      { id: 'a', text: 'We like pizza.', isCorrect: true },
      { id: 'b', text: 'We liked pizza.', isCorrect: false },
      { id: 'c', text: 'We light pizza.', isCorrect: false },
    ],
    explanation: '"like"（好き）と "light"（火をつける）は音が似てるけど、最後の音が違うよ！',
  },
  {
    id: 'P004-L1-5',
    sentence: 'He likes soccer.',
    hintJa: '「サッカーが好き」',
    audio: 'P004_L1_match_5.mp3',
    choices: [
      { id: 'a', text: 'He likes sucker.', isCorrect: false },
      { id: 'b', text: 'He likes soccer.', isCorrect: true },
      { id: 'c', text: 'He likes soaker.', isCorrect: false },
    ],
    explanation: '"soccer"（サッカー）と "sucker" は母音が違う。"ソッカー" の音をよく聞いてね！',
  },
]
