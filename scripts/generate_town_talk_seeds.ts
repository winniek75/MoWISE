/**
 * Town Talk seed generator (C-1.3 / Phase 4)
 *
 * 仕様書 v1.3 §付録A の脚本（A-1〜A-9）を構造化 TypeScript で表現し、
 * payload_json として 9 件の JSON ファイルを scripts/town_talk_payloads/ に出力する。
 *
 * option_id 割当ルール（仕様書 §1-4）:
 *   - 脚本記載順を保持
 *   - option_id = (源データの index + 1)
 *   - Maria/Sam: [✅, ❌, ❌, ❌] → option_id = [1,2,3,4]
 *   - Lily       : [✅, △, ❌, ❌] → option_id = [1,2,3,4]
 *
 * 使い方:  npx -y tsx scripts/generate_town_talk_seeds.ts
 */

import { writeFileSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'

// ─── 型定義（src/types/townTalk.ts と同期）────────────
type Npc = 'maria' | 'sam' | 'lily'
type Difficulty = 'jh1' | 'jh2' | 'jh3'

interface Option {
  option_id: number
  text: string
  is_correct: boolean
  is_acceptable: boolean
  explanation: string | null
}

interface Turn {
  turn_no: number
  npc_audio: string
  required_keywords: string[]
  npc_reaction_correct: string
  options: Option[]
}

interface Scenario {
  scenario_id: string
  pattern_no: string
  npc_id: Npc
  place: string
  theme: string
  difficulty: Difficulty
  reward_coins: number
  reward_friendship: number
  mowi_message: string
  total_turns: number
  turns: Turn[]
  created_at: string
  version: number
}

// ─── ヘルパー：脚本記載順から Option[] 構築 ──────────────
type Verdict = 'correct' | 'acceptable' | 'wrong'
interface RawOption {
  text: string
  type: Verdict
  explanation: string | null
}

function opts(raw: RawOption[]): Option[] {
  return raw.map((r, i) => ({
    option_id: i + 1,
    text: r.text,
    is_correct: r.type === 'correct',
    is_acceptable: r.type === 'correct' || r.type === 'acceptable',
    explanation: r.type === 'correct' ? null : r.explanation,
  }))
}

// ─── 共通メタ ────────────────────────────────────────
const CREATED_AT = '2026-05-04T00:00:00Z'
const REWARD: Record<Npc, { coins: number; friendship: number; mowi: string }> = {
  maria: { coins: 50, friendship: 10, mowi: '届いたよ。' },
  sam:   { coins: 60, friendship: 10, mowi: '言えたな、次は？' },
  lily:  { coins: 75, friendship: 10, mowi: '届いたよ。少し遠くまでね。' },
}

// ─── A-1. maria_cafe_order_v1（ラテ注文）────────────
const A1: Scenario = {
  scenario_id: 'maria_cafe_order_v1',
  pattern_no: 'P021', npc_id: 'maria', place: 'MoWISE Café', theme: 'ラテ注文',
  difficulty: 'jh1',
  reward_coins: REWARD.maria.coins, reward_friendship: REWARD.maria.friendship, mowi_message: REWARD.maria.mowi,
  total_turns: 5, version: 1, created_at: CREATED_AT,
  turns: [
    {
      turn_no: 1,
      npc_audio: 'Welcome to MoWISE Café! What would you like?',
      required_keywords: ['latte'],
      npc_reaction_correct: 'Sure! One latte, coming up. ☕',
      options: opts([
        { type: 'correct', text: `I'd like a latte, please.`, explanation: null },
        { type: 'wrong',   text: `I want latte.`,             explanation: `「a」が抜けてる。"a latte" にしよう。` },
        { type: 'wrong',   text: `I'm a latte.`,              explanation: `"I'm" は「私は」だ。意味が変だね。` },
        { type: 'wrong',   text: `Please latte.`,             explanation: `文の形になってない。"I'd like" だね。` },
      ]),
    },
    {
      turn_no: 2,
      npc_audio: 'Anything else?',
      required_keywords: ['muffin'],
      npc_reaction_correct: 'Great choice! 🍪',
      options: opts([
        { type: 'correct', text: `I'd like a muffin, too.`,   explanation: null },
        { type: 'wrong',   text: `Yes, I'd like muffin.`,     explanation: `「a」が抜けてる。"a muffin" にしよう。` },
        { type: 'wrong',   text: `Muffin too.`,               explanation: `文になってない。"I'd like" を付けて。` },
        { type: 'wrong',   text: `I have a muffin.`,          explanation: `"have" は「持ってる」、注文と違う。` },
      ]),
    },
    {
      turn_no: 3,
      npc_audio: 'Hot or iced?',
      required_keywords: ['hot'],
      npc_reaction_correct: 'One hot latte. Got it. 🔥',
      options: opts([
        { type: 'correct', text: `I'd like it hot, please.`,  explanation: null },
        { type: 'wrong',   text: `I'd like hot.`,             explanation: `"it" を指して何が hot か必要だ。` },
        { type: 'wrong',   text: `Hot, give me.`,             explanation: `命令形すぎ。"I'd like" でお願いしよう。` },
        { type: 'wrong',   text: `I'd like a hot.`,           explanation: `"hot" は形容詞。後に名詞がいるよ。` },
      ]),
    },
    {
      turn_no: 4,
      npc_audio: 'For here or to go?',
      required_keywords: ['go'],
      npc_reaction_correct: `Perfect! I'll prepare it now. ⏱`,
      options: opts([
        { type: 'correct', text: `To go, please.`,            explanation: null },
        { type: 'wrong',   text: `I to go.`,                  explanation: `動詞がないよ。"To go, please" でOK。` },
        { type: 'wrong',   text: `Going, please.`,            explanation: `"going" は「行く」って意味、違う。` },
        { type: 'wrong',   text: `Yes, go.`,                  explanation: `Yes/Noじゃ答えにならないよ。` },
      ]),
    },
    {
      turn_no: 5,
      npc_audio: 'Have a great day!',
      required_keywords: ['thank'],
      npc_reaction_correct: 'See you next time! 👋✨',
      options: opts([
        { type: 'correct', text: `Thank you. You too!`,       explanation: null },
        { type: 'wrong',   text: `Yes, thank you.`,           explanation: `相手にも返そう、"You too!" を付けて。` },
        { type: 'wrong',   text: `Thank you. Me too.`,        explanation: `"Me too" は「私も」、ここは "You too"。` },
        { type: 'wrong',   text: `Thanks!`,                   explanation: `短すぎ。"You too!" を付けたい。` },
      ]),
    },
  ],
}

// ─── A-2. maria_cafe_morning_v2（朝のモーニング）───
const A2: Scenario = {
  scenario_id: 'maria_cafe_morning_v2',
  pattern_no: 'P021', npc_id: 'maria', place: 'MoWISE Café', theme: '朝のモーニング',
  difficulty: 'jh1',
  reward_coins: REWARD.maria.coins, reward_friendship: REWARD.maria.friendship, mowi_message: REWARD.maria.mowi,
  total_turns: 5, version: 1, created_at: CREATED_AT,
  turns: [
    {
      turn_no: 1,
      npc_audio: 'Good morning! What can I get for you?',
      required_keywords: ['morning', 'set'],
      npc_reaction_correct: 'Great choice! ☀️🍳',
      options: opts([
        { type: 'correct', text: `I'd like the morning set, please.`, explanation: null },
        { type: 'wrong',   text: `I want morning set.`,        explanation: `"the" が抜けてる。"the morning set"。` },
        { type: 'wrong',   text: `Morning set, give me.`,      explanation: `命令的。"I'd like" でお願いしよう。` },
        { type: 'wrong',   text: `Good morning set.`,          explanation: `挨拶と混ざってる。文を分けよう。` },
      ]),
    },
    {
      turn_no: 2,
      npc_audio: 'It comes with a drink. Coffee, tea, or juice?',
      required_keywords: ['juice'],
      npc_reaction_correct: 'Fresh juice, coming up. 🍊',
      options: opts([
        { type: 'correct', text: `I'd like orange juice, please.`, explanation: null },
        { type: 'wrong',   text: `Juice, please.`,            explanation: `短すぎ、"I'd like" を付けたい。` },
        { type: 'wrong',   text: `I'd like juice orange.`,    explanation: `語順が違う、"orange juice" の順。` },
        { type: 'wrong',   text: `I'm orange juice.`,         explanation: `"I'm" は「私は」、意味が変だ。` },
      ]),
    },
    {
      turn_no: 3,
      npc_audio: 'Would you like extra eggs with that?',
      required_keywords: ['eggs', 'two'],
      npc_reaction_correct: 'Sunny side up coming. 🍳',
      options: opts([
        { type: 'correct', text: `Yes, I'd like two eggs.`,   explanation: null },
        { type: 'wrong',   text: `Yes, two egg.`,             explanation: `複数形は "eggs"、s をつけよう。` },
        { type: 'wrong',   text: `Yes, I'd like egg two.`,    explanation: `語順が違う、"two eggs" の順で。` },
        { type: 'wrong',   text: `No, I'd like eggs.`,        explanation: `ほしいのに "No"、逆だね。` },
      ]),
    },
    {
      turn_no: 4,
      npc_audio: 'We have window seats. Where would you like to sit?',
      required_keywords: ['window', 'seat'],
      npc_reaction_correct: 'Right this way! 🪟',
      options: opts([
        { type: 'correct', text: `I'd like a window seat, please.`, explanation: null },
        { type: 'wrong',   text: `Window please.`,            explanation: `短すぎ、"I'd like" で頼もう。` },
        { type: 'wrong',   text: `I'd like a window.`,        explanation: `"seat" が抜けてる、"window seat"。` },
        { type: 'wrong',   text: `I'm window seat.`,          explanation: `"I'm" は「私は」、変だね。` },
      ]),
    },
    {
      turn_no: 5,
      npc_audio: 'Enjoy your morning!',
      required_keywords: ['thank'],
      npc_reaction_correct: 'Have a great day at school! 🎒✨',
      options: opts([
        { type: 'correct', text: `Thank you! You too.`,       explanation: null },
        { type: 'wrong',   text: `Thank you. Same.`,          explanation: `"Same" は不自然、"You too" にしよう。` },
        { type: 'wrong',   text: `Yes, I enjoy.`,             explanation: `返事になってない、"Thank you" で。` },
        { type: 'wrong',   text: `Enjoy you.`,                explanation: `"Enjoy" の使い方が変だね。` },
      ]),
    },
  ],
}

// ─── A-3. maria_cafe_takeout_v3（テイクアウト・複数注文）
const A3: Scenario = {
  scenario_id: 'maria_cafe_takeout_v3',
  pattern_no: 'P021', npc_id: 'maria', place: 'MoWISE Café', theme: 'テイクアウト',
  difficulty: 'jh1',
  reward_coins: REWARD.maria.coins, reward_friendship: REWARD.maria.friendship, mowi_message: REWARD.maria.mowi,
  total_turns: 5, version: 1, created_at: CREATED_AT,
  turns: [
    {
      turn_no: 1,
      npc_audio: 'Welcome! What can I get you today?',
      required_keywords: ['coffees', 'two'],
      npc_reaction_correct: 'Two coffees, got it. ☕☕',
      options: opts([
        { type: 'correct', text: `I'd like two coffees, please.`, explanation: null },
        { type: 'wrong',   text: `I'd like two coffee.`,      explanation: `複数形は "coffees"、s をつけよう。` },
        { type: 'wrong',   text: `I'd like coffee two.`,      explanation: `語順が違う、"two coffees" の順。` },
        { type: 'wrong',   text: `Two coffee me.`,            explanation: `文の形が変、"I'd like" がいる。` },
      ]),
    },
    {
      turn_no: 2,
      npc_audio: 'Sure! What kind would you like?',
      required_keywords: ['latte', 'cappuccino'],
      npc_reaction_correct: 'Great combo. 👍',
      options: opts([
        { type: 'correct', text: `One latte and one cappuccino.`, explanation: null },
        { type: 'wrong',   text: `One latte one cappuccino.`, explanation: `"and" でつないで、間に入れて。` },
        { type: 'wrong',   text: `A latte, a cappuccino.`,    explanation: `"and" が必要、リスト読みは変。` },
        { type: 'wrong',   text: `Latte cappuccino, please.`, explanation: `数を抜いてる、"One ... and one"で。` },
      ]),
    },
    {
      turn_no: 3,
      npc_audio: 'Anything else?',
      required_keywords: ['cookies'],
      npc_reaction_correct: 'Perfect for sharing. 🍪🍪',
      options: opts([
        { type: 'correct', text: `Yes, I'd like two cookies.`, explanation: null },
        { type: 'wrong',   text: `Yes, two cookie.`,          explanation: `複数形は "cookies"、s をつけよう。` },
        { type: 'wrong',   text: `Yes, cookie two.`,          explanation: `語順が違う、"two cookies"。` },
        { type: 'wrong',   text: `Yes, I'm cookies.`,         explanation: `"I'm" は「私は」、変だね。` },
      ]),
    },
    {
      turn_no: 4,
      npc_audio: 'Will you eat here?',
      required_keywords: ['go'],
      npc_reaction_correct: 'All to go. Coming up. 🛍',
      options: opts([
        { type: 'correct', text: `No, I'd like everything to go.`, explanation: null },
        { type: 'wrong',   text: `No, take out.`,             explanation: `文として弱い、"I'd like" を付けて。` },
        { type: 'wrong',   text: `Yes, to go.`,               explanation: `"Yes" だと店内、返事が逆だね。` },
        { type: 'wrong',   text: `No, I to go.`,              explanation: `動詞がない、"I'd like ... to go"。` },
      ]),
    },
    {
      turn_no: 5,
      npc_audio: 'Have a great day with your sister!',
      required_keywords: ['thank', 'will'],
      npc_reaction_correct: 'Take care! 👋✨',
      options: opts([
        { type: 'correct', text: `Thank you! We will.`,       explanation: null },
        { type: 'wrong',   text: `Thanks. I will.`,           explanation: `2人分だから "We will" にしよう。` },
        { type: 'wrong',   text: `Yes, with sister.`,         explanation: `返事が変、"Thank you" から。` },
        { type: 'wrong',   text: `Thank. Bye.`,               explanation: `"Thank you" が正しい形。` },
      ]),
    },
  ],
}

// ─── A-4. sam_shop_fitting_v1（試着）────────────
const A4: Scenario = {
  scenario_id: 'sam_shop_fitting_v1',
  pattern_no: 'P024', npc_id: 'sam', place: 'MoWISE Shop', theme: '試着',
  difficulty: 'jh2',
  reward_coins: REWARD.sam.coins, reward_friendship: REWARD.sam.friendship, mowi_message: REWARD.sam.mowi,
  total_turns: 5, version: 1, created_at: CREATED_AT,
  turns: [
    {
      turn_no: 1,
      npc_audio: 'Hey there! Looking for something?',
      required_keywords: ['try'],
      npc_reaction_correct: 'Sure! The fitting room is right over there. 🚪',
      options: opts([
        { type: 'correct', text: `Can I try this on?`,        explanation: null },
        { type: 'wrong',   text: `Can I try this?`,           explanation: `"on" が抜けてる、試着は "try on"。` },
        { type: 'wrong',   text: `Try this on me?`,           explanation: `語順が違う、"Can I" から始めよう。` },
        { type: 'wrong',   text: `I want try this.`,          explanation: `"to" が抜けてる、"want to" で覚えよう。` },
      ]),
    },
    {
      turn_no: 2,
      npc_audio: 'What size do you need?',
      required_keywords: ['medium'],
      npc_reaction_correct: 'Medium, got it. Here you go. 👕',
      options: opts([
        { type: 'correct', text: `Can I have a medium, please?`, explanation: null },
        { type: 'wrong',   text: `Medium one.`,               explanation: `文が足りない、"Can I have" を使おう。` },
        { type: 'wrong',   text: `I'm medium.`,               explanation: `これだと「私は中くらい」、変だね。` },
        { type: 'wrong',   text: `Give me medium.`,           explanation: `命令的。"Can I have" でお願いしよう。` },
      ]),
    },
    {
      turn_no: 3,
      npc_audio: 'We have blue and red. Which color?',
      required_keywords: ['blue'],
      npc_reaction_correct: 'Good choice! Blue is popular. 💙',
      options: opts([
        { type: 'correct', text: `Can I see the blue one?`,   explanation: null },
        { type: 'wrong',   text: `I want blue one.`,          explanation: `"the" が抜けてる、"the blue one"。` },
        { type: 'wrong',   text: `Show blue please.`,         explanation: `命令的、"Can I see" で頼もう。` },
        { type: 'wrong',   text: `Blue is mine.`,             explanation: `「青は私の」、意味が違うよ。` },
      ]),
    },
    {
      turn_no: 4,
      npc_audio: 'How does it look?',
      required_keywords: ['buy', 'like'],
      npc_reaction_correct: `Awesome! Let's go to the register. 💳`,
      options: opts([
        { type: 'correct', text: `I like it. Can I buy it?`,  explanation: null },
        { type: 'wrong',   text: `Yes, I like.`,              explanation: `"like" の後に "it" がいるよ。` },
        { type: 'wrong',   text: `It's me.`,                  explanation: `「これは私」感想になってない。` },
        { type: 'wrong',   text: `Buy this.`,                 explanation: `命令形すぎ、"Can I buy it?" に。` },
      ]),
    },
    {
      turn_no: 5,
      npc_audio: 'Come again soon!',
      required_keywords: ['thank', 'will'],
      npc_reaction_correct: 'Take care! 👋',
      options: opts([
        { type: 'correct', text: `Thank you. I will!`,        explanation: null },
        { type: 'wrong',   text: `Yes, I come.`,              explanation: `"I will" を使おう、また来るね。` },
        { type: 'wrong',   text: `OK, bye.`,                  explanation: `一言短すぎ、"Thank you" を付けて。` },
        { type: 'wrong',   text: `Sure, again.`,              explanation: `文になってない、"I will!" にしよう。` },
      ]),
    },
  ],
}

// ─── A-5. sam_shop_price_v2（値段確認）────────────
const A5: Scenario = {
  scenario_id: 'sam_shop_price_v2',
  pattern_no: 'P024', npc_id: 'sam', place: 'MoWISE Shop', theme: '値段確認',
  difficulty: 'jh2',
  reward_coins: REWARD.sam.coins, reward_friendship: REWARD.sam.friendship, mowi_message: REWARD.sam.mowi,
  total_turns: 5, version: 1, created_at: CREATED_AT,
  turns: [
    {
      turn_no: 1,
      npc_audio: 'Hi! Looking for something interesting?',
      required_keywords: ['notebook', 'see'],
      npc_reaction_correct: 'Sure, here you go. 📓',
      options: opts([
        { type: 'correct', text: `Can I see that notebook?`,  explanation: null },
        { type: 'wrong',   text: `Can I look notebook?`,      explanation: `"at" が抜けてる、"look at" で見るとき。` },
        { type: 'wrong',   text: `Show notebook me.`,         explanation: `命令的、"Can I see" でお願いしよう。` },
        { type: 'wrong',   text: `I want notebook see.`,      explanation: `語順が違う、"to see" の形で。` },
      ]),
    },
    {
      turn_no: 2,
      npc_audio: `It's a popular one. Anything you want to ask?`,
      required_keywords: ['price', 'ask'],
      npc_reaction_correct: `It's 800 yen. 💰`,
      options: opts([
        { type: 'correct', text: `Can I ask the price?`,      explanation: null },
        { type: 'wrong',   text: `Can I ask price?`,          explanation: `"the" が抜けてる、"the price"。` },
        { type: 'wrong',   text: `How much price?`,           explanation: `二重表現、"How much is it?" でOK。` },
        { type: 'wrong',   text: `Price me, please.`,         explanation: `文になってない、"Can I ask" から。` },
      ]),
    },
    {
      turn_no: 3,
      npc_audio: 'Nice, right? We have other colors too.',
      required_keywords: ['color', 'another'],
      npc_reaction_correct: 'We have red and green. ❤️💚',
      options: opts([
        { type: 'correct', text: `Can I see another color?`,  explanation: null },
        { type: 'wrong',   text: `Can I see other color?`,    explanation: `"another color" を使おう。` },
        { type: 'wrong',   text: `Other color show me.`,      explanation: `命令的、"Can I see" で頼もう。` },
        { type: 'wrong',   text: `I see another.`,            explanation: `"Can I" が必要、許可を求めよう。` },
      ]),
    },
    {
      turn_no: 4,
      npc_audio: 'Great choice! Cash or card?',
      required_keywords: ['pay', 'card'],
      npc_reaction_correct: 'Card works fine. 💳',
      options: opts([
        { type: 'correct', text: `Can I pay by card?`,        explanation: null },
        { type: 'wrong',   text: `Can I pay card?`,           explanation: `"by" が抜けてる、"pay by card"。` },
        { type: 'wrong',   text: `Card pay, please.`,         explanation: `文になってない、"Can I pay" から。` },
        { type: 'wrong',   text: `I pay card.`,               explanation: `"Can I" を使って許可を求めよう。` },
      ]),
    },
    {
      turn_no: 5,
      npc_audio: 'Thanks for shopping!',
      required_keywords: ['thank', 'good'],
      npc_reaction_correct: 'See you next time! 😊',
      options: opts([
        { type: 'correct', text: `Thank you. Have a good day!`, explanation: null },
        { type: 'wrong',   text: `Thanks. Good day.`,         explanation: `短すぎ、"Have a good day" で。` },
        { type: 'wrong',   text: `Yes, good day.`,            explanation: `返事が変、"Thank you" から始めよう。` },
        { type: 'wrong',   text: `You good day.`,             explanation: `文の形が変、"Have a" を入れて。` },
      ]),
    },
  ],
}

// ─── A-6. sam_shop_stock_v3（在庫確認）────────────
const A6: Scenario = {
  scenario_id: 'sam_shop_stock_v3',
  pattern_no: 'P020', npc_id: 'sam', place: 'MoWISE Shop', theme: '在庫確認',
  difficulty: 'jh2',
  reward_coins: REWARD.sam.coins, reward_friendship: REWARD.sam.friendship, mowi_message: REWARD.sam.mowi,
  total_turns: 5, version: 1, created_at: CREATED_AT,
  turns: [
    {
      turn_no: 1,
      npc_audio: 'Welcome! Looking for anything special?',
      required_keywords: ['backpack'],
      npc_reaction_correct: 'Yes, plenty of options. 🎒',
      options: opts([
        { type: 'correct', text: `Do you have a backpack?`,   explanation: null },
        { type: 'wrong',   text: `Do you have backpack?`,     explanation: `"a" が抜けてる、"a backpack"。` },
        { type: 'wrong',   text: `You have backpack?`,        explanation: `"Do" を付けたい、質問の形に。` },
        { type: 'wrong',   text: `Backpack, do you?`,         explanation: `語順が変、"Do you have ..." で。` },
      ]),
    },
    {
      turn_no: 2,
      npc_audio: 'What color do you like?',
      required_keywords: ['black', 'one'],
      npc_reaction_correct: 'Got several blacks. 🖤',
      options: opts([
        { type: 'correct', text: `Do you have a black one?`,  explanation: null },
        { type: 'wrong',   text: `Do you have black?`,        explanation: `"one" が抜けてる、"a black one"。` },
        { type: 'wrong',   text: `Black one is?`,             explanation: `文として変、"Do you have" から。` },
        { type: 'wrong',   text: `You black one?`,            explanation: `"Do" を付けたい、質問の形で。` },
      ]),
    },
    {
      turn_no: 3,
      npc_audio: 'We have small, medium, and large.',
      required_keywords: ['medium'],
      npc_reaction_correct: 'Medium is right here. 👍',
      options: opts([
        { type: 'correct', text: `Do you have it in medium?`, explanation: null },
        { type: 'wrong',   text: `Do you have medium?`,       explanation: `"it in" が抜けてる、"in medium"。` },
        { type: 'wrong',   text: `Medium, do you?`,           explanation: `語順が変、"Do you have" から。` },
        { type: 'wrong',   text: `I want medium.`,            explanation: `質問の形にしよう、"Do you have" で。` },
      ]),
    },
    {
      turn_no: 4,
      npc_audio: 'How many would you like?',
      required_keywords: ['two', 'stock'],
      npc_reaction_correct: 'Yes, two are available. ✓',
      options: opts([
        { type: 'correct', text: `Do you have two in stock?`, explanation: null },
        { type: 'wrong',   text: `Do you have two stock?`,    explanation: `"in" が抜けてる、"in stock"。` },
        { type: 'wrong',   text: `Two stocks, please.`,       explanation: `文として変、"Do you have" で聞こう。` },
        { type: 'wrong',   text: `You have two?`,             explanation: `"Do" を付けたい、質問の形に。` },
      ]),
    },
    {
      turn_no: 5,
      npc_audio: 'Thanks for shopping with us!',
      required_keywords: ['thank', 'back'],
      npc_reaction_correct: 'See you next time! 👋',
      options: opts([
        { type: 'correct', text: `Thank you. I'll be back.`,  explanation: null },
        { type: 'wrong',   text: `Thanks. I come back.`,      explanation: `"I'll come back" にしよう。` },
        { type: 'wrong',   text: `Yes, back.`,                explanation: `返事が短い、"Thank you" から。` },
        { type: 'wrong',   text: `Thank. See you.`,           explanation: `"Thank you" が正しい形。` },
      ]),
    },
  ],
}

// ─── A-7. lily_library_search_v1（本探し）─────────
// 仕様書 v1.3 §付録A の Turn 2/3/4 には npc_reaction_correct が明記されていないため、
// 司書ペルソナと文脈に沿った中立的な反応を補完（v1.3 §13 注意事項に従い暫定対応）。
const A7: Scenario = {
  scenario_id: 'lily_library_search_v1',
  pattern_no: 'P031', npc_id: 'lily', place: 'MoWISE Library', theme: '本探し',
  difficulty: 'jh3',
  reward_coins: REWARD.lily.coins, reward_friendship: REWARD.lily.friendship, mowi_message: REWARD.lily.mowi,
  total_turns: 5, version: 1, created_at: CREATED_AT,
  turns: [
    {
      turn_no: 1,
      npc_audio: 'Hello. May I help you?',
      required_keywords: ['help'],
      npc_reaction_correct: 'Of course. What kind of book? 📚',
      options: opts([
        { type: 'correct',    text: `Could you help me find a book?`, explanation: null },
        { type: 'acceptable', text: `Can you help me find a book?`,   explanation: `違わないけど "Could" の方が丁寧。` },
        { type: 'wrong',      text: `Please find me a book.`,         explanation: `命令的。"Could you" で頼もう。` },
        { type: 'wrong',      text: `I need book help.`,              explanation: `文として成立してないね。` },
      ]),
    },
    {
      turn_no: 2,
      npc_audio: 'What kind of book?',
      required_keywords: ['science'],
      npc_reaction_correct: 'Science section, this way. 📚',
      options: opts([
        { type: 'correct',    text: `I'm looking for a science book.`, explanation: null },
        { type: 'acceptable', text: `I want a science book.`,         explanation: `違わない、"looking for" がより自然。` },
        { type: 'wrong',      text: `Science book, please.`,          explanation: `短すぎ、文で答えたいね。` },
        { type: 'wrong',      text: `I need to a science book.`,      explanation: `"to" が余計、"a science book" が形。` },
      ]),
    },
    {
      turn_no: 3,
      npc_audio: 'Do you know where to go?',
      required_keywords: ['show', 'way', 'tell'],
      npc_reaction_correct: 'Let me show you. ➡️',
      options: opts([
        { type: 'correct',    text: `Could you show me the way?`,     explanation: null },
        { type: 'acceptable', text: `Where is it?`,                   explanation: `違わない、"Could you" の方が丁寧。` },
        { type: 'wrong',      text: `Tell me the way.`,               explanation: `命令的、"Could you tell me" にしよう。` },
        { type: 'wrong',      text: `I don't know.`,                  explanation: `これだと「知らない」、だから聞こう。` },
      ]),
    },
    {
      turn_no: 4,
      npc_audio: `Here it is. This is the one I'd recommend.`,
      required_keywords: ['borrow'],
      npc_reaction_correct: 'Of course, here it is. ✓',
      options: opts([
        { type: 'correct',    text: `Could I borrow this?`,           explanation: null },
        { type: 'acceptable', text: `Can I borrow this?`,             explanation: `違わない、"Could" がより大人っぽい。` },
        { type: 'wrong',      text: `I want borrow this.`,            explanation: `"to" が抜けてる、"want to borrow"。` },
        { type: 'wrong',      text: `Lend me this.`,                  explanation: `命令的、"Could I" で頼もう。` },
      ]),
    },
    {
      turn_no: 5,
      npc_audio: 'Enjoy reading!',
      required_keywords: ['thank'],
      npc_reaction_correct: `You're very welcome. 😊`,
      options: opts([
        { type: 'correct',    text: `Thank you so much for your help.`, explanation: null },
        { type: 'acceptable', text: `Thank you very much.`,           explanation: `OK、"for your help" まで言うと丁寧。` },
        { type: 'wrong',      text: `Thanks, bye.`,                   explanation: `砕けすぎ、図書館では丁寧めに。` },
        { type: 'wrong',      text: `Thank for help.`,                explanation: `"Thank you for the help" が形。` },
      ]),
    },
  ],
}

// ─── A-8. lily_library_extend_v2（貸出延長）───────
const A8: Scenario = {
  scenario_id: 'lily_library_extend_v2',
  pattern_no: 'P031', npc_id: 'lily', place: 'MoWISE Library', theme: '貸出延長',
  difficulty: 'jh3',
  reward_coins: REWARD.lily.coins, reward_friendship: REWARD.lily.friendship, mowi_message: REWARD.lily.mowi,
  total_turns: 5, version: 1, created_at: CREATED_AT,
  turns: [
    {
      turn_no: 1,
      npc_audio: 'Hello again. May I help you?',
      required_keywords: ['extend'],
      npc_reaction_correct: 'Of course. Let me check. 📅',
      options: opts([
        { type: 'correct',    text: `Could you extend the loan, please?`, explanation: null },
        { type: 'acceptable', text: `Can you extend the loan?`,       explanation: `違わない、"Could" の方が丁寧だよ。` },
        { type: 'wrong',      text: `Extend, please.`,                explanation: `短すぎ、"Could you" で頼もう。` },
        { type: 'wrong',      text: `I want extend.`,                 explanation: `"to" が抜けてる、"want to extend"。` },
      ]),
    },
    {
      turn_no: 2,
      npc_audio: 'How many more days do you need?',
      required_keywords: ['week'],
      npc_reaction_correct: `Sure, that's possible. 👍`,
      options: opts([
        { type: 'correct',    text: `Could I have one more week?`,    explanation: null },
        { type: 'acceptable', text: `Can I have one more week?`,      explanation: `違わない、"Could" の方が大人っぽいよ。` },
        { type: 'wrong',      text: `One week more.`,                 explanation: `文として弱い、"Could I have" で。` },
        { type: 'wrong',      text: `I need week.`,                   explanation: `"a" が抜けてる、"a week" にしよう。` },
      ]),
    },
    {
      turn_no: 3,
      npc_audio: 'May I ask why?',
      required_keywords: ['finish', 'read'],
      npc_reaction_correct: 'I understand. Take your time. 📖',
      options: opts([
        { type: 'correct',    text: `I haven't finished reading it yet.`, explanation: null },
        { type: 'acceptable', text: `I didn't finish it.`,            explanation: `違わない、"haven't finished" がより自然。` },
        { type: 'wrong',      text: `No finish reading.`,             explanation: `文が壊れてる、"I haven't" から始めよう。` },
        { type: 'wrong',      text: `I'm reading still.`,             explanation: `語順が変、"I'm still reading" で。` },
      ]),
    },
    {
      turn_no: 4,
      npc_audio: 'Your new due date is next Friday.',
      required_keywords: ['write'],
      npc_reaction_correct: `Here's a note for you. 📝`,
      options: opts([
        { type: 'correct',    text: `Could you write it down for me?`, explanation: null },
        { type: 'acceptable', text: `Can you write it down?`,         explanation: `違わない、"Could" でより丁寧に。` },
        { type: 'wrong',      text: `Write it.`,                      explanation: `命令的、"Could you" を付けて頼もう。` },
        { type: 'wrong',      text: `Could you write down?`,          explanation: `"it" が抜けてる、"write it down"。` },
      ]),
    },
    {
      turn_no: 5,
      npc_audio: 'Anything else?',
      required_keywords: ['thank'],
      npc_reaction_correct: `You're very welcome. 😊`,
      options: opts([
        { type: 'correct',    text: `Thank you for being so kind.`,   explanation: null },
        { type: 'acceptable', text: `Thanks a lot.`,                  explanation: `"for being so kind" を足すと丁寧。` },
        { type: 'wrong',      text: `Thanks, see you.`,               explanation: `砕けすぎ、図書館では丁寧めに。` },
        { type: 'wrong',      text: `Thank for kind.`,                explanation: `"for your kindness" の形にしよう。` },
      ]),
    },
  ],
}

// ─── A-9. lily_library_reserve_v3（本の予約）──────
const A9: Scenario = {
  scenario_id: 'lily_library_reserve_v3',
  pattern_no: 'P031', npc_id: 'lily', place: 'MoWISE Library', theme: '本の予約',
  difficulty: 'jh3',
  reward_coins: REWARD.lily.coins, reward_friendship: REWARD.lily.friendship, mowi_message: REWARD.lily.mowi,
  total_turns: 5, version: 1, created_at: CREATED_AT,
  turns: [
    {
      turn_no: 1,
      npc_audio: 'Hello. How can I help you today?',
      required_keywords: ['reserve'],
      npc_reaction_correct: 'Of course. Let me check. 📕',
      options: opts([
        { type: 'correct',    text: `Could I reserve this book, please?`, explanation: null },
        { type: 'acceptable', text: `Can I reserve this book?`,       explanation: `違わない、"Could" の方が丁寧だよ。` },
        { type: 'wrong',      text: `Reserve this for me.`,           explanation: `命令的、"Could I" で頼もう。` },
        { type: 'wrong',      text: `I want reserve this.`,           explanation: `"to" が抜けてる、"want to reserve"。` },
      ]),
    },
    {
      turn_no: 2,
      npc_audio: `I'm sorry, it's currently checked out.`,
      required_keywords: ['when', 'available'],
      npc_reaction_correct: 'Probably next Monday. 📅',
      options: opts([
        { type: 'correct',    text: `When will it be available again?`, explanation: null },
        { type: 'acceptable', text: `When does it come back?`,        explanation: `違わない、"available" の方が大人っぽい。` },
        { type: 'wrong',      text: `When return book?`,              explanation: `主語が抜けてる、文を整えよう。` },
        { type: 'wrong',      text: `It comes when?`,                 explanation: `語順が変、"When does it" で。` },
      ]),
    },
    {
      turn_no: 3,
      npc_audio: 'Shall I contact you when it returns?',
      required_keywords: ['call'],
      npc_reaction_correct: `I'll call you. 📞`,
      options: opts([
        { type: 'correct',    text: `Could you call me when it's ready?`, explanation: null },
        { type: 'acceptable', text: `Can you call me?`,               explanation: `違わない、"when it's ready" まで丁寧。` },
        { type: 'wrong',      text: `Call me ready.`,                 explanation: `文が壊れてる、"when it's" で。` },
        { type: 'wrong',      text: `I want call.`,                   explanation: `"you to" が抜けてる、形を整えよう。` },
      ]),
    },
    {
      turn_no: 4,
      npc_audio: 'Where would you like to pick it up?',
      required_keywords: ['pick', 'up'],
      npc_reaction_correct: 'This counter, then. ✓',
      options: opts([
        { type: 'correct',    text: `Could I pick it up at this counter?`, explanation: null },
        { type: 'acceptable', text: `Can I pick up here?`,            explanation: `"pick it up" の "it" を忘れずに。` },
        { type: 'wrong',      text: `Pick up here.`,                  explanation: `命令的、"Could I" で頼もう。` },
        { type: 'wrong',      text: `I pick up.`,                     explanation: `"it" が入れたい、"pick it up" で。` },
      ]),
    },
    {
      turn_no: 5,
      npc_audio: `All set. We'll let you know.`,
      required_keywords: ['thank'],
      npc_reaction_correct: `You're very welcome. 😊`,
      options: opts([
        { type: 'correct',    text: `Thank you for your help.`,       explanation: null },
        { type: 'acceptable', text: `Thank you so much.`,             explanation: `OK、"for your help" を付けると丁寧。` },
        { type: 'wrong',      text: `Thanks, OK.`,                    explanation: `砕けすぎ、図書館では丁寧めに。` },
        { type: 'wrong',      text: `Thank for help.`,                explanation: `"Thank you for the help" が形。` },
      ]),
    },
  ],
}

// ─── 出力 ──────────────────────────────────────────
const SCENARIOS: Scenario[] = [A1, A2, A3, A4, A5, A6, A7, A8, A9]

const OUT_DIR = 'scripts/town_talk_payloads'
mkdirSync(OUT_DIR, { recursive: true })

let totalBytes = 0
console.log(`Writing ${SCENARIOS.length} scenarios to ${OUT_DIR}/`)
for (const s of SCENARIOS) {
  const path = join(OUT_DIR, `${s.scenario_id}.json`)
  const json = JSON.stringify(s, null, 2)
  writeFileSync(path, json + '\n', 'utf-8')
  totalBytes += json.length
  console.log(`  ✓ ${s.scenario_id}.json (${json.length} bytes)`)
}
console.log(`Done. Total: ${totalBytes} bytes (avg ${Math.round(totalBytes / SCENARIOS.length)} bytes/scenario).`)
