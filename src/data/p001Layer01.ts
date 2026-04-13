/**
 * P001 Layer 0 / Layer 1 問題データ
 * [代名詞] + be動詞パターン
 *
 * Layer 0: Sound Foundation — ゆっくり vs ナチュラルの聞き比べ
 * Layer 1: Echo Drill — 音声を聞いて正しいテキストを選ぶ
 */

import type { Layer0Question, Layer1Question } from './layerTypes'

// ─────────────────────────────────────────────
// P001 Layer 0: Sound Foundation
// ─────────────────────────────────────────────

export const p001Layer0Questions: Layer0Question[] = [
  {
    id: 'P001-L0-1',
    slowText: 'I am tired.',
    naturalText: "I'm tired.",
    meaningJa: '私は疲れています',
    slowAudio: 'P001_L0_slow_1.mp3',
    naturalAudio: 'P001_L0_natural_1.mp3',
    quiz: {
      options: [
        { id: 'a', text: "I'm tired.", isNatural: true },
        { id: 'b', text: 'I am tired.', isNatural: false },
      ],
      explanation: '普段の会話では "I am" を "I\'m" と縮めて言うよ。こっちの方がずっと自然！',
    },
  },
  {
    id: 'P001-L0-2',
    slowText: 'She is a teacher.',
    naturalText: "She's a teacher.",
    meaningJa: '彼女は先生です',
    slowAudio: 'P001_L0_slow_2.mp3',
    naturalAudio: 'P001_L0_natural_2.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'She is a teacher.', isNatural: false },
        { id: 'b', text: "She's a teacher.", isNatural: true },
      ],
      explanation: '"She is" → "She\'s"。会話ではほぼいつも短縮するよ。',
    },
  },
  {
    id: 'P001-L0-3',
    slowText: 'It is hot today.',
    naturalText: "It's hot today.",
    meaningJa: '今日は暑いです',
    slowAudio: 'P001_L0_slow_3.mp3',
    naturalAudio: 'P001_L0_natural_3.mp3',
    quiz: {
      options: [
        { id: 'a', text: "It's hot today.", isNatural: true },
        { id: 'b', text: 'It is hot today.', isNatural: false },
      ],
      explanation: '"It is" → "It\'s"。天気の話をするときも短縮が自然。',
    },
  },
  {
    id: 'P001-L0-4',
    slowText: 'We are ready.',
    naturalText: "We're ready.",
    meaningJa: '私たちは準備OKです',
    slowAudio: 'P001_L0_slow_4.mp3',
    naturalAudio: 'P001_L0_natural_4.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'We are ready.', isNatural: false },
        { id: 'b', text: "We're ready.", isNatural: true },
      ],
      explanation: '"We are" → "We\'re"。短い方が、英語っぽく聞こえるよ。',
    },
  },
  {
    id: 'P001-L0-5',
    slowText: 'They are late.',
    naturalText: "They're late.",
    meaningJa: '彼らは遅刻しています',
    slowAudio: 'P001_L0_slow_5.mp3',
    naturalAudio: 'P001_L0_natural_5.mp3',
    quiz: {
      options: [
        { id: 'a', text: "They're late.", isNatural: true },
        { id: 'b', text: 'They are late.', isNatural: false },
      ],
      explanation: '"They are" → "They\'re"。最初は難しく感じるけど、耳で慣れればすぐ聞き取れるようになる。',
    },
  },
]

// ─────────────────────────────────────────────
// P001 Layer 1: Echo Drill (Sound Match)
// ─────────────────────────────────────────────

export const p001Layer1Questions: Layer1Question[] = [
  {
    id: 'P001-L1-1',
    sentence: "I'm tired.",
    hintJa: '「疲れている」',
    audio: 'P001_L1_match_1.mp3',
    choices: [
      { id: 'a', text: "I'm tired.", isCorrect: true },
      { id: 'b', text: "I'm tried.", isCorrect: false },
      { id: 'c', text: "I'm tied.", isCorrect: false },
    ],
    explanation: '"tired"（疲れた）と "tried"（試した）は似てるけど音が違う。聞き分けられたかな？',
  },
  {
    id: 'P001-L1-2',
    sentence: "She's a teacher.",
    hintJa: '「先生」',
    audio: 'P001_L1_match_2.mp3',
    choices: [
      { id: 'a', text: "She's a teacher.", isCorrect: true },
      { id: 'b', text: "She's a cheater.", isCorrect: false },
      { id: 'c', text: "She's a feature.", isCorrect: false },
    ],
    explanation: '"teacher" と "cheater" は似てるけど最初の音が違うよ。',
  },
  {
    id: 'P001-L1-3',
    sentence: "It's hot today.",
    hintJa: '「暑い」',
    audio: 'P001_L1_match_3.mp3',
    choices: [
      { id: 'a', text: "It's hat today.", isCorrect: false },
      { id: 'b', text: "It's hot today.", isCorrect: true },
      { id: 'c', text: "It's hut today.", isCorrect: false },
    ],
    explanation: '"hot"（暑い）は "hat"（帽子）や "hut"（小屋）と母音が違う。口を大きく開けて「ホット」！',
  },
  {
    id: 'P001-L1-4',
    sentence: "He's my friend.",
    hintJa: '「友達」',
    audio: 'P001_L1_match_4.mp3',
    choices: [
      { id: 'a', text: "He's my front.", isCorrect: false },
      { id: 'b', text: "He's my fried.", isCorrect: false },
      { id: 'c', text: "He's my friend.", isCorrect: true },
    ],
    explanation: '"friend" の最後に "d" がある。"fried"（揚げた）とは違うよ！',
  },
  {
    id: 'P001-L1-5',
    sentence: "We're ready.",
    hintJa: '「準備OK」',
    audio: 'P001_L1_match_5.mp3',
    choices: [
      { id: 'a', text: "We're really.", isCorrect: false },
      { id: 'b', text: "We're ready.", isCorrect: true },
      { id: 'c', text: "Were ready.", isCorrect: false },
    ],
    explanation: '"We\'re"（ウィアー）と "Were"（ワー）は発音が違う。短縮形をしっかり聞き取ろう。',
  },
  {
    id: 'P001-L1-6',
    sentence: "They're late.",
    hintJa: '「遅刻」',
    audio: 'P001_L1_match_6.mp3',
    choices: [
      { id: 'a', text: "There late.", isCorrect: false },
      { id: 'b', text: "Their late.", isCorrect: false },
      { id: 'c', text: "They're late.", isCorrect: true },
    ],
    explanation: '"They\'re"（彼らは）、"There"（そこ）、"Their"（彼らの）。音は似てるけど意味が全然違う！',
  },
]
