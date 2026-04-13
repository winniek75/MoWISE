/**
 * P003 Layer 0 / Layer 1 問題データ
 * "Nice to meet you." パターン（はじめまして — 挨拶の基本）
 *
 * Layer 0: Sound Foundation — ゆっくり vs ナチュラルの聞き比べ
 * Layer 1: Echo Drill — 音声を聞いて正しいテキストを選ぶ
 */

import type { Layer0Question, Layer1Question } from './layerTypes'

// ─────────────────────────────────────────────
// P003 Layer 0: Sound Foundation
// ─────────────────────────────────────────────

export const p003Layer0Questions: Layer0Question[] = [
  {
    id: 'P003-L0-1',
    slowText: 'It is nice to meet you.',
    naturalText: 'Nice to meet you.',
    meaningJa: 'はじめまして',
    slowAudio: 'P003_L0_slow_1.mp3',
    naturalAudio: 'P003_L0_natural_1.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'Nice to meet you.', isNatural: true },
        { id: 'b', text: 'It is nice to meet you.', isNatural: false },
      ],
      explanation: '実際の会話では "It is" を省略して "Nice to meet you." と言うのが普通だよ！',
    },
  },
  {
    id: 'P003-L0-2',
    slowText: 'Nice to meet you, too.',
    naturalText: 'Nice to meet you, too.',
    meaningJa: 'こちらこそ、はじめまして',
    slowAudio: 'P003_L0_slow_2.mp3',
    naturalAudio: 'P003_L0_natural_2.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'Nice to meet you, too.', isNatural: true },
        { id: 'b', text: 'Nice to meet you, two.', isNatural: false },
      ],
      explanation: '"too"（〜も）と "two"（2）は同じ発音だけど、意味が全然違う。ここでは「こちらこそ」の "too" だよ！',
    },
  },
  {
    id: 'P003-L0-3',
    slowText: 'It is good to see you.',
    naturalText: 'Good to see you.',
    meaningJa: '会えてうれしいです',
    slowAudio: 'P003_L0_slow_3.mp3',
    naturalAudio: 'P003_L0_natural_3.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'It is good to see you.', isNatural: false },
        { id: 'b', text: 'Good to see you.', isNatural: true },
      ],
      explanation: 'こちらも "It is" を省略するのが自然。友達同士だとカジュアルに "Good to see you!" でOK。',
    },
  },
  {
    id: 'P003-L0-4',
    slowText: 'How do you do?',
    naturalText: 'How do you do?',
    meaningJa: 'はじめまして（フォーマル）',
    slowAudio: 'P003_L0_slow_4.mp3',
    naturalAudio: 'P003_L0_natural_4.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'How do you do?', isNatural: true },
        { id: 'b', text: 'How do you dew?', isNatural: false },
      ],
      explanation: 'ナチュラルスピードだと "do" がすごく短くなって聞き取りにくいけど、ちゃんと "do" だよ！',
    },
  },
  {
    id: 'P003-L0-5',
    slowText: 'It is a pleasure to meet you.',
    naturalText: "It's a pleasure to meet you.",
    meaningJa: 'お会いできて光栄です',
    slowAudio: 'P003_L0_slow_5.mp3',
    naturalAudio: 'P003_L0_natural_5.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'It is a pleasure to meet you.', isNatural: false },
        { id: 'b', text: "It's a pleasure to meet you.", isNatural: true },
      ],
      explanation: '"It is" → "It\'s"。丁寧な表現でも短縮するのが自然だよ。',
    },
  },
]

// ─────────────────────────────────────────────
// P003 Layer 1: Echo Drill (Sound Match)
// ─────────────────────────────────────────────

export const p003Layer1Questions: Layer1Question[] = [
  {
    id: 'P003-L1-1',
    sentence: 'Nice to meet you.',
    hintJa: '「はじめまして」',
    audio: 'P003_L1_match_1.mp3',
    choices: [
      { id: 'a', text: 'Nice to meet you.', isCorrect: true },
      { id: 'b', text: 'Nice to eat you.', isCorrect: false },
      { id: 'c', text: 'Nice to need you.', isCorrect: false },
    ],
    explanation: '"meet"（会う）と "eat"（食べる）は似てるけど、最初の "m" を聞き逃さないで！',
  },
  {
    id: 'P003-L1-2',
    sentence: 'Nice to meet you, too.',
    hintJa: '「こちらこそ」',
    audio: 'P003_L1_match_2.mp3',
    choices: [
      { id: 'a', text: 'Nice to meet you, to.', isCorrect: false },
      { id: 'b', text: 'Nice to meet you, too.', isCorrect: true },
      { id: 'c', text: 'Nice to meet you, two.', isCorrect: false },
    ],
    explanation: '"too"（〜も）が正解。"to" や "two" と発音は同じだけど、ここでは「こちらこそ」の意味だよ。',
  },
  {
    id: 'P003-L1-3',
    sentence: 'Good to see you.',
    hintJa: '「会えてうれしい」',
    audio: 'P003_L1_match_3.mp3',
    choices: [
      { id: 'a', text: 'Good to see you.', isCorrect: true },
      { id: 'b', text: 'Good to be you.', isCorrect: false },
      { id: 'c', text: 'Could to see you.', isCorrect: false },
    ],
    explanation: '"Good" と "Could" は最初の音が違う。"G" の音をしっかり聞いてね！',
  },
  {
    id: 'P003-L1-4',
    sentence: 'How do you do?',
    hintJa: '「はじめまして（丁寧）」',
    audio: 'P003_L1_match_4.mp3',
    choices: [
      { id: 'a', text: 'How do you do?', isCorrect: true },
      { id: 'b', text: 'How do you too?', isCorrect: false },
      { id: 'c', text: 'How did you do?', isCorrect: false },
    ],
    explanation: '"do" が2回使われてるのがポイント。速く言うと聞き取りにくいけど、慣れれば大丈夫！',
  },
  {
    id: 'P003-L1-5',
    sentence: "It's a pleasure to meet you.",
    hintJa: '「お会いできて光栄です」',
    audio: 'P003_L1_match_5.mp3',
    choices: [
      { id: 'a', text: "It's a pressure to meet you.", isCorrect: false },
      { id: 'b', text: "It's a pleasure to meet you.", isCorrect: true },
      { id: 'c', text: "It's a treasure to meet you.", isCorrect: false },
    ],
    explanation: '"pleasure"（喜び）、"pressure"（圧力）、"treasure"（宝物）。似てるけど全部違う意味だよ！',
  },
]
