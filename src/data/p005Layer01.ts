/**
 * P005 Layer 0 / Layer 1 問題データ
 * "I have [noun]." パターン（私は〜を持っています）
 *
 * Layer 0: Sound Foundation — ゆっくり vs ナチュラルの聞き比べ
 * Layer 1: Echo Drill — 音声を聞いて正しいテキストを選ぶ
 */

import type { Layer0Question, Layer1Question } from './layerTypes'

// ─────────────────────────────────────────────
// P005 Layer 0: Sound Foundation
// ─────────────────────────────────────────────

export const p005Layer0Questions: Layer0Question[] = [
  {
    id: 'P005-L0-1',
    slowText: 'I have a dog.',
    naturalText: 'I have a dog.',
    meaningJa: '私は犬を飼っています',
    slowAudio: 'P005_L0_slow_1.mp3',
    naturalAudio: 'P005_L0_natural_1.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'I have a dog.', isNatural: true },
        { id: 'b', text: 'I had a dog.', isNatural: false },
      ],
      explanation: '"have"（持っている）と "had"（持っていた）は最後の音が違う。"v" と "d" を聞き分けよう！',
    },
  },
  {
    id: 'P005-L0-2',
    slowText: 'She has two cats.',
    naturalText: 'She has two cats.',
    meaningJa: '彼女は猫を2匹飼っています',
    slowAudio: 'P005_L0_slow_2.mp3',
    naturalAudio: 'P005_L0_natural_2.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'She has two cats.', isNatural: true },
        { id: 'b', text: 'She had two cats.', isNatural: false },
      ],
      explanation: '"has" は今のこと、"had" は前のこと。ナチュラルスピードでも "s" と "d" の違いに注目！',
    },
  },
  {
    id: 'P005-L0-3',
    slowText: 'I have a question.',
    naturalText: 'I have a question.',
    meaningJa: '質問があります',
    slowAudio: 'P005_L0_slow_3.mp3',
    naturalAudio: 'P005_L0_natural_3.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'I have a question.', isNatural: true },
        { id: 'b', text: 'I had a question.', isNatural: false },
      ],
      explanation: 'ナチュラルスピードだと "have a" がつながって「ハヴァ」と聞こえるよ。このリンキングに慣れよう！',
    },
  },
  {
    id: 'P005-L0-4',
    slowText: 'We have three kids.',
    naturalText: 'We have three kids.',
    meaningJa: '私たちは子供が3人います',
    slowAudio: 'P005_L0_slow_4.mp3',
    naturalAudio: 'P005_L0_natural_4.mp3',
    quiz: {
      options: [
        { id: 'a', text: "We've three kids.", isNatural: false },
        { id: 'b', text: 'We have three kids.', isNatural: true },
      ],
      explanation: 'この場合は "We have" をそのまま言うのが自然。"We\'ve" は会話ではあまり使わないよ。',
    },
  },
  {
    id: 'P005-L0-5',
    slowText: 'He has a new bike.',
    naturalText: 'He has a new bike.',
    meaningJa: '彼は新しい自転車を持っています',
    slowAudio: 'P005_L0_slow_5.mp3',
    naturalAudio: 'P005_L0_natural_5.mp3',
    quiz: {
      options: [
        { id: 'a', text: 'He has a new bike.', isNatural: true },
        { id: 'b', text: 'He had a new bike.', isNatural: false },
      ],
      explanation: '"has a" が速くなると「ハザ」みたいに聞こえる。リンキングのポイントだよ！',
    },
  },
]

// ─────────────────────────────────────────────
// P005 Layer 1: Echo Drill (Sound Match)
// ─────────────────────────────────────────────

export const p005Layer1Questions: Layer1Question[] = [
  {
    id: 'P005-L1-1',
    sentence: 'I have a dog.',
    hintJa: '「犬を飼っている」',
    audio: 'P005_L1_match_1.mp3',
    choices: [
      { id: 'a', text: 'I have a dog.', isCorrect: true },
      { id: 'b', text: 'I had a dog.', isCorrect: false },
      { id: 'c', text: "I've a dog.", isCorrect: false },
    ],
    explanation: '"have"（持っている）と "had"（持っていた）は最後の音が違う。"v" の振動を感じて！',
  },
  {
    id: 'P005-L1-2',
    sentence: 'She has two cats.',
    hintJa: '「猫が2匹」',
    audio: 'P005_L1_match_2.mp3',
    choices: [
      { id: 'a', text: 'She has two cats.', isCorrect: true },
      { id: 'b', text: 'She has two caps.', isCorrect: false },
      { id: 'c', text: 'She has two cabs.', isCorrect: false },
    ],
    explanation: '"cats"（猫）、"caps"（帽子）、"cabs"（タクシー）。最後の音が違うよ。聞き取れたかな？',
  },
  {
    id: 'P005-L1-3',
    sentence: 'I have a question.',
    hintJa: '「質問がある」',
    audio: 'P005_L1_match_3.mp3',
    choices: [
      { id: 'a', text: 'I have a cushion.', isCorrect: false },
      { id: 'b', text: 'I have a question.', isCorrect: true },
      { id: 'c', text: 'I have a session.', isCorrect: false },
    ],
    explanation: '"question"（質問）、"cushion"（クッション）、"session"（セッション）。似てるけど全部違う！',
  },
  {
    id: 'P005-L1-4',
    sentence: 'We have three kids.',
    hintJa: '「子供が3人」',
    audio: 'P005_L1_match_4.mp3',
    choices: [
      { id: 'a', text: 'We have three kits.', isCorrect: false },
      { id: 'b', text: 'We have free kids.', isCorrect: false },
      { id: 'c', text: 'We have three kids.', isCorrect: true },
    ],
    explanation: '"kids"（子供）と "kits"（セット）は最後の音が違う。"three" と "free" も似てるから注意！',
  },
  {
    id: 'P005-L1-5',
    sentence: 'He has a new bike.',
    hintJa: '「新しい自転車」',
    audio: 'P005_L1_match_5.mp3',
    choices: [
      { id: 'a', text: 'He has a new bike.', isCorrect: true },
      { id: 'b', text: 'He has a new bite.', isCorrect: false },
      { id: 'c', text: 'He has a new bake.', isCorrect: false },
    ],
    explanation: '"bike"（自転車）、"bite"（噛む）、"bake"（焼く）。最後の音と母音をよく聞いてみて！',
  },
]
