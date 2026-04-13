/**
 * P002 Layer 0 / Layer 1 問題データ
 * "This is [noun]." パターン（これは〜です — 紹介の基本）
 *
 * Layer 0: Sound Foundation — ゆっくり vs ナチュラルの聞き比べ
 * Layer 1: Echo Drill — 音声を聞いて正しいテキストを選ぶ
 */

import type { Layer0Question, Layer1Question } from './layerTypes'

// ─────────────────────────────────────────────
// P002 Layer 0: Sound Foundation
// ─────────────────────────────────────────────

export const p002Layer0Questions: Layer0Question[] = [
  {
    id: 'P002-L0-1',
    slowText: 'This is my bag.',
    naturalText: 'This is my bag.',
    meaningJa: 'これは私のカバンです',
    slowAudio: 'P002_L0_slow_1.mp3',
    naturalAudio: 'P002_L0_natural_1.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'This is my bag.', isNatural: true },
        { id: 'b', text: 'This is my back.', isNatural: false },
      ],
      explanation: 'ナチュラルスピードだと "bag" の最後の音が聞き取りにくいけど、"g" の音をしっかり聞いてみて！',
    },
  },
  {
    id: 'P002-L0-2',
    slowText: 'That is my car.',
    naturalText: "That's my car.",
    meaningJa: 'あれは私の車です',
    slowAudio: 'P002_L0_slow_2.mp3',
    naturalAudio: 'P002_L0_natural_2.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'That is my car.', isNatural: false },
        { id: 'b', text: "That's my car.", isNatural: true },
      ],
      explanation: '"That is" → "That\'s"。会話ではこっちの方がずっと自然だよ！',
    },
  },
  {
    id: 'P002-L0-3',
    slowText: 'This is a pen.',
    naturalText: 'This is a pen.',
    meaningJa: 'これはペンです',
    slowAudio: 'P002_L0_slow_3.mp3',
    naturalAudio: 'P002_L0_natural_3.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'This is a pen.', isNatural: true },
        { id: 'b', text: 'This is a pan.', isNatural: false },
      ],
      explanation: 'ナチュラルスピードだと "pen" と "pan" が似て聞こえるけど、口の開き方が違うよ。',
    },
  },
  {
    id: 'P002-L0-4',
    slowText: 'That is her book.',
    naturalText: "That's her book.",
    meaningJa: 'あれは彼女の本です',
    slowAudio: 'P002_L0_slow_4.mp3',
    naturalAudio: 'P002_L0_natural_4.mp3',
    quiz: {
      options: [
        { id: 'a', text: "That's her book.", isNatural: true },
        { id: 'b', text: 'That is her book.', isNatural: false },
      ],
      explanation: '"That is" → "That\'s"。短縮すると英語らしいリズムになるよ。',
    },
  },
  {
    id: 'P002-L0-5',
    slowText: 'This is his phone.',
    naturalText: 'This is his phone.',
    meaningJa: 'これは彼の電話です',
    slowAudio: 'P002_L0_slow_5.mp3',
    naturalAudio: 'P002_L0_natural_5.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'This is his phone.', isNatural: true },
        { id: 'b', text: 'This is his foam.', isNatural: false },
      ],
      explanation: 'ナチュラルスピードだと "phone" と "foam" が似て聞こえることがあるけど、最後の "n" をよく聞いて！',
    },
  },
]

// ─────────────────────────────────────────────
// P002 Layer 1: Echo Drill (Sound Match)
// ─────────────────────────────────────────────

export const p002Layer1Questions: Layer1Question[] = [
  {
    id: 'P002-L1-1',
    sentence: 'This is my bag.',
    hintJa: '「カバン」',
    audio: 'P002_L1_match_1.mp3',
    choices: [
      { id: 'a', text: 'This is my bag.', isCorrect: true },
      { id: 'b', text: 'This is my back.', isCorrect: false },
      { id: 'c', text: 'This is my bad.', isCorrect: false },
    ],
    explanation: '"bag"（カバン）、"back"（背中）、"bad"（悪い）。最後の音の違いを聞き取れたかな？',
  },
  {
    id: 'P002-L1-2',
    sentence: "That's my car.",
    hintJa: '「車」',
    audio: 'P002_L1_match_2.mp3',
    choices: [
      { id: 'a', text: "That's my card.", isCorrect: false },
      { id: 'b', text: "That's my car.", isCorrect: true },
      { id: 'c', text: "That's my cart.", isCorrect: false },
    ],
    explanation: '"car" は最後に "d" や "t" がつかない。シンプルに「カー」でOK！',
  },
  {
    id: 'P002-L1-3',
    sentence: 'This is a pen.',
    hintJa: '「ペン」',
    audio: 'P002_L1_match_3.mp3',
    choices: [
      { id: 'a', text: 'This is a pan.', isCorrect: false },
      { id: 'b', text: 'This is a pin.', isCorrect: false },
      { id: 'c', text: 'This is a pen.', isCorrect: true },
    ],
    explanation: '"pen"（ペン）、"pan"（フライパン）、"pin"（ピン）。真ん中の母音が全部違うよ！',
  },
  {
    id: 'P002-L1-4',
    sentence: "That's her book.",
    hintJa: '「本」',
    audio: 'P002_L1_match_4.mp3',
    choices: [
      { id: 'a', text: "That's her book.", isCorrect: true },
      { id: 'b', text: "That's her look.", isCorrect: false },
      { id: 'c', text: "That's her cook.", isCorrect: false },
    ],
    explanation: '"book"、"look"、"cook" は母音は同じだけど、最初の音が違う。"b" の音を聞き取ろう！',
  },
  {
    id: 'P002-L1-5',
    sentence: 'This is his phone.',
    hintJa: '「電話」',
    audio: 'P002_L1_match_5.mp3',
    choices: [
      { id: 'a', text: 'This is his foam.', isCorrect: false },
      { id: 'b', text: 'This is his phone.', isCorrect: true },
      { id: 'c', text: 'This is his tone.', isCorrect: false },
    ],
    explanation: '"phone"（電話）は "ph" で「フ」の音。"foam"（泡）や "tone"（音色）とは違うよ！',
  },
]
