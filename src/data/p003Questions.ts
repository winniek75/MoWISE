/**
 * MoWISE P003 問題データ
 * Nice to meet you.（はじめまして — 固定表現）
 *
 * Layer 2（Pattern Sense）・Layer 3（Flash Output タイル式）
 * ⚠️ 品詞名はUI・フィードバックに一切出さない（AGENTS.md 禁止事項）
 */

import type { Layer2Question, Layer3Question } from './p001Questions'

// ─────────────────────────────────────────────
// P003 Layer 2：Pattern Sense（スロット穴埋め）
// 固定表現のためチャンク認識を重視
// ─────────────────────────────────────────────

export const p003Layer2Questions: Layer2Question[] = [
  {
    id: 'P003-L2-1',
    slotPrefix: 'Nice to',
    promptJa: '「はじめまして」',
    fullSentence: 'Nice to meet you.',
    correctAudio: 'P003_L2_answer_1.mp3',
    choices: [
      { id: 'a', text: 'meet you',  isCorrect: true },
      { id: 'b', text: 'see you',   isCorrect: false, wrongReason: '「Nice to see you.」は再会のとき。初対面は「meet you」！' },
      { id: 'c', text: 'know you',  isCorrect: false, wrongReason: '「Nice to know you.」は不自然。初対面なら「meet you」！' },
      { id: 'd', text: 'met you',   isCorrect: false, wrongReason: '「met」は過去形。ここでは「meet」が正解！' },
    ],
    explanation: '初対面の挨拶は「Nice to meet you.」がセット。丸ごと体に入れてしまおう！',
  },
  {
    id: 'P003-L2-2',
    slotPrefix: 'Nice to meet you',
    promptJa: '「こちらこそ、はじめまして」',
    fullSentence: 'Nice to meet you too.',
    correctAudio: 'P003_L2_answer_2.mp3',
    choices: [
      { id: 'a', text: 'too',    isCorrect: true },
      { id: 'b', text: 'also',   isCorrect: false, wrongReason: '「also」は文の途中で使う。返事には「too」が自然！' },
      { id: 'c', text: 'as well',isCorrect: false, wrongReason: '「as well」でも通じるけど、この場面では「too」が一番自然！' },
      { id: 'd', text: 'again',  isCorrect: false, wrongReason: '「again」は「また」の意味。初対面なのでNG！' },
    ],
    explanation: '相手に「Nice to meet you.」と言われたら「Nice to meet you too.」で返す。「too」をつけるだけ！',
  },
  {
    id: 'P003-L2-3',
    slotPrefix: "It's nice to",
    promptJa: '「お会いできてうれしいです、スミス先生」',
    fullSentence: "It's nice to meet you, Dr. Smith.",
    correctAudio: 'P003_L2_answer_3.mp3',
    choices: [
      { id: 'a', text: 'meet you, Dr. Smith', isCorrect: true },
      { id: 'b', text: 'see Dr. Smith',       isCorrect: false, wrongReason: '目の前の人に言うときは「meet you」。三人称の「Dr. Smith」だけだと不自然！' },
      { id: 'c', text: 'met you',             isCorrect: false, wrongReason: '「met」は過去形。ここでは「meet」を使うよ！' },
      { id: 'd', text: 'meeting you',         isCorrect: false, wrongReason: '「It\'s nice to」の後は原形の「meet」が来るよ！' },
    ],
    explanation: '丁寧に言うときは「It\'s nice to meet you.」。フォーマルな場面で使えるよ！',
  },
  {
    id: 'P003-L2-4',
    slotPrefix: 'Nice to meet you.',
    slotSuffix: 'Hana.',
    promptJa: '「はじめまして。私はハナです。」',
    fullSentence: "Nice to meet you. I'm Hana.",
    correctAudio: 'P003_L2_answer_4.mp3',
    choices: [
      { id: 'a', text: "I'm",     isCorrect: true },
      { id: 'b', text: 'My name', isCorrect: false, wrongReason: '「My name Hana.」だと動詞がない。「I\'m」なら一語で完成！' },
      { id: 'c', text: 'I am is', isCorrect: false, wrongReason: '「I am is」は動詞が多すぎ。「I\'m」だけでOK！' },
      { id: 'd', text: 'Me',      isCorrect: false, wrongReason: '「Me Hana.」は自然じゃない。「I\'m Hana.」が正解！' },
    ],
    explanation: '挨拶の後に自己紹介。「Nice to meet you. I\'m ○○.」これがセット！',
  },
  {
    id: 'P003-L2-5',
    slotPrefix: 'Hi! Nice to',
    promptJa: '「やあ！はじめまして！」',
    fullSentence: 'Hi! Nice to meet you!',
    correctAudio: 'P003_L2_answer_5.mp3',
    choices: [
      { id: 'a', text: 'meet you',  isCorrect: true },
      { id: 'b', text: 'meeting',   isCorrect: false, wrongReason: '「Nice to meeting」とは言わない。「meet you」が正解！' },
      { id: 'c', text: 'meets you', isCorrect: false, wrongReason: '「to」の後は原形。「meet」が正しいよ！' },
      { id: 'd', text: 'have met',  isCorrect: false, wrongReason: 'ここでは「meet you」がシンプルで自然！' },
    ],
    explanation: 'カジュアルでも「Nice to meet you!」はそのまま使える。「Hi!」をつければフレンドリー！',
  },
  {
    id: 'P003-L2-6',
    slotPrefix: "It's a",
    promptJa: '「お会いできて光栄です」',
    fullSentence: "It's a pleasure to meet you.",
    correctAudio: 'P003_L2_answer_6.mp3',
    choices: [
      { id: 'a', text: 'pleasure to meet you', isCorrect: true },
      { id: 'b', text: 'please to meet you',   isCorrect: false, wrongReason: '「please」ではなく「pleasure」。名詞の「pleasure（喜び）」が正解！' },
      { id: 'c', text: 'pleasant meet you',     isCorrect: false, wrongReason: '「pleasant」は近いけど、「a pleasure to meet you」が正しい形！' },
      { id: 'd', text: 'pleased meeting',       isCorrect: false, wrongReason: '「It\'s a pleasure to meet you.」が丁寧な定型表現。丸ごと覚えよう！' },
    ],
    explanation: '超丁寧な挨拶。「It\'s a pleasure to meet you.」ビジネスや大人の場面で使えるよ！',
  },
]

// ─────────────────────────────────────────────
// P003 Layer 3：Flash Output（タイル選択式）
// ─────────────────────────────────────────────

export const p003Layer3Questions: Layer3Question[] = [
  {
    id: 'P003-L3-1',
    promptJa: '「はじめまして。」',
    tiles: [
      { id: 't1', word: 'Nice',  isDecoy: false },
      { id: 't2', word: 'to',    isDecoy: false },
      { id: 't3', word: 'meet',  isDecoy: false },
      { id: 't4', word: 'you',   isDecoy: false },
      { id: 't5', word: '.',     isDecoy: false },
      { id: 't6', word: 'see',   isDecoy: true },
    ],
    answer: ['Nice', 'to', 'meet', 'you', '.'],
    correctSentence: 'Nice to meet you.',
    hint: 'Nice to ___',
    timeLimitSec: 8,
    correctAudio: 'P003_L3_correct_1.mp3',
  },
  {
    id: 'P003-L3-2',
    promptJa: '「こちらこそ、はじめまして。」',
    tiles: [
      { id: 't1', word: 'Nice',  isDecoy: false },
      { id: 't2', word: 'to',    isDecoy: false },
      { id: 't3', word: 'meet',  isDecoy: false },
      { id: 't4', word: 'you',   isDecoy: false },
      { id: 't5', word: 'too',   isDecoy: false },
      { id: 't6', word: '.',     isDecoy: false },
      { id: 't7', word: 'also',  isDecoy: true },
    ],
    answer: ['Nice', 'to', 'meet', 'you', 'too', '.'],
    correctSentence: 'Nice to meet you too.',
    hint: 'Nice to meet you ___',
    timeLimitSec: 10,
    correctAudio: 'P003_L3_correct_2.mp3',
  },
  {
    id: 'P003-L3-3',
    promptJa: '「はじめまして。私はケンです。」',
    tiles: [
      { id: 't1', word: 'Nice',  isDecoy: false },
      { id: 't2', word: 'to',    isDecoy: false },
      { id: 't3', word: 'meet',  isDecoy: false },
      { id: 't4', word: 'you',   isDecoy: false },
      { id: 't5', word: '.',     isDecoy: false },
      { id: 't6', word: "I'm",   isDecoy: false },
      { id: 't7', word: 'Ken',   isDecoy: false },
      { id: 't8', word: 'My',    isDecoy: true },
    ],
    answer: ['Nice', 'to', 'meet', 'you', '.', "I'm", 'Ken', '.'],
    correctSentence: "Nice to meet you. I'm Ken.",
    hint: 'Nice to meet you. ___',
    timeLimitSec: 12,
    correctAudio: 'P003_L3_correct_3.mp3',
    // Note: 2つ目のピリオドはtiles内に追加が必要
  },
  {
    id: 'P003-L3-4',
    promptJa: '「お会いできてうれしいです。」',
    tiles: [
      { id: 't1', word: "It's",  isDecoy: false },
      { id: 't2', word: 'nice',  isDecoy: false },
      { id: 't3', word: 'to',    isDecoy: false },
      { id: 't4', word: 'meet',  isDecoy: false },
      { id: 't5', word: 'you',   isDecoy: false },
      { id: 't6', word: '.',     isDecoy: false },
      { id: 't7', word: 'see',   isDecoy: true },
    ],
    answer: ["It's", 'nice', 'to', 'meet', 'you', '.'],
    correctSentence: "It's nice to meet you.",
    hint: "It's nice to ___",
    timeLimitSec: 10,
    correctAudio: 'P003_L3_correct_4.mp3',
  },
  {
    id: 'P003-L3-5',
    promptJa: '「やあ！はじめまして！」',
    tiles: [
      { id: 't1', word: 'Hi',    isDecoy: false },
      { id: 't2', word: '!',     isDecoy: false },
      { id: 't3', word: 'Nice',  isDecoy: false },
      { id: 't4', word: 'to',    isDecoy: false },
      { id: 't5', word: 'meet',  isDecoy: false },
      { id: 't6', word: 'you',   isDecoy: false },
      { id: 't7', word: 'Hello', isDecoy: true },
    ],
    answer: ['Hi', '!', 'Nice', 'to', 'meet', 'you', '!'],
    correctSentence: 'Hi! Nice to meet you!',
    hint: 'Hi! ___',
    timeLimitSec: 10,
    correctAudio: 'P003_L3_correct_5.mp3',
  },
  {
    id: 'P003-L3-6',
    promptJa: '「お会いできて光栄です。」',
    tiles: [
      { id: 't1', word: "It's",     isDecoy: false },
      { id: 't2', word: 'a',        isDecoy: false },
      { id: 't3', word: 'pleasure', isDecoy: false },
      { id: 't4', word: 'to',       isDecoy: false },
      { id: 't5', word: 'meet',     isDecoy: false },
      { id: 't6', word: 'you',      isDecoy: false },
      { id: 't7', word: '.',        isDecoy: false },
      { id: 't8', word: 'please',   isDecoy: true },
    ],
    answer: ["It's", 'a', 'pleasure', 'to', 'meet', 'you', '.'],
    correctSentence: "It's a pleasure to meet you.",
    hint: "It's a pleasure ___",
    timeLimitSec: 12,
    correctAudio: 'P003_L3_correct_6.mp3',
  },
  {
    id: 'P003-L3-7',
    promptJa: '「はじめまして、田中先生。」',
    tiles: [
      { id: 't1', word: 'Nice',   isDecoy: false },
      { id: 't2', word: 'to',     isDecoy: false },
      { id: 't3', word: 'meet',   isDecoy: false },
      { id: 't4', word: 'you',    isDecoy: false },
      { id: 't5', word: ',',      isDecoy: false },
      { id: 't6', word: 'Mr.',    isDecoy: false },
      { id: 't7', word: 'Tanaka', isDecoy: false },
      { id: 't8', word: '.',      isDecoy: false },
      { id: 't9', word: 'Mrs.',   isDecoy: true },
    ],
    answer: ['Nice', 'to', 'meet', 'you', ',', 'Mr.', 'Tanaka', '.'],
    correctSentence: 'Nice to meet you, Mr. Tanaka.',
    hint: 'Nice to meet you, ___',
    timeLimitSec: 12,
    correctAudio: 'P003_L3_correct_7.mp3',
  },
]

// ─────────────────────────────────────────────
// P003 パターン基本情報
// ─────────────────────────────────────────────

export const p003PatternInfo = {
  id: 'P003',
  label: 'Nice to meet you.',
  labelJa: 'はじめまして',
  rarity: 1,
  area: 'area1',
  layer2QuestionCount: p003Layer2Questions.length,
  layer3QuestionCount: p003Layer3Questions.length,
  layer2PassThreshold: 5,
  layer3PassThreshold: 5,
}
