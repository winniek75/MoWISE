/**
 * production-gate-judge
 *
 * Star 3->4 self-production gate.
 * Judges whether a user-produced sentence:
 *   1. Contains the target pattern
 *   2. Makes sense (lenient, Newcomer level)
 *   3. Is not a copy of the example sentences
 *
 * Auth: Bearer token (anon key) + Supabase auth JWT
 * Method: POST
 *
 * Request:
 * {
 *   user_id:    string,
 *   pattern_id: string,   // 'P001'
 *   sentence:   string    // user's free-form sentence
 * }
 *
 * Response:
 * {
 *   pass:     boolean,
 *   feedback: string      // short positive/guiding message
 * }
 */

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, apikey',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}
const JSON_HEADERS = { ...CORS_HEADERS, 'Content-Type': 'application/json' }

function jsonResponse(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: JSON_HEADERS })
}

// Pattern templates: the core structure the user must use
// In production this would come from DB; for MVP we hardcode the essentials
const PATTERN_TEMPLATES: Record<string, { template: string; examples: string[] }> = {
  P001: { template: "I'm", examples: ["I'm tired.", "I'm happy.", "I'm a student."] },
  P002: { template: 'This is', examples: ['This is my dog.', 'This is a pen.'] },
  P003: { template: 'Nice to meet you', examples: ['Nice to meet you.'] },
  P004: { template: 'I like', examples: ['I like soccer.', 'I like cats.', 'I like playing games.'] },
  P005: { template: 'I want', examples: ['I want water.', 'I want a new bag.'] },
  P006: { template: 'I have', examples: ['I have a dog.', 'I have two brothers.'] },
  P007: { template: 'I can', examples: ['I can swim.', 'I can play piano.'] },
  P008: { template: "I'm from", examples: ["I'm from Japan.", "I'm from Tokyo."] },
  P009: { template: "It's", examples: ["It's cold.", "It's a nice day."] },
  P010: { template: 'Thank you for', examples: ['Thank you for helping me.', 'Thank you for the gift.'] },
  P011: { template: "I'm sorry for", examples: ["I'm sorry for being late."] },
  P012: { template: 'See you', examples: ['See you tomorrow.', 'See you later.'] },
  P013: { template: 'How are you', examples: ['How are you?'] },
  P014: { template: "I don't understand", examples: ["I don't understand English."] },
  P015: { template: 'Can you', examples: ['Can you help me?', 'Can you speak English?'] },
  P016: { template: 'Where is', examples: ['Where is the station?', 'Where is my bag?'] },
  P017: { template: 'How much is', examples: ['How much is this?'] },
  P018: { template: "I'm looking for", examples: ["I'm looking for my keys."] },
  P019: { template: "Let's", examples: ["Let's go.", "Let's play together."] },
  P020: { template: 'I feel', examples: ['I feel happy.', 'I feel tired.'] },
  // P021-P035 can be extended later
}

/**
 * Local rule-based judgment (no external AI needed for MVP).
 * Returns { pass, feedback }.
 */
function judgeLocally(
  patternId: string,
  sentence: string,
): { pass: boolean; feedback: string } {
  const trimmed = sentence.trim()
  const lower = trimmed.toLowerCase()

  // Basic length check
  if (trimmed.length < 3) {
    return { pass: false, feedback: 'もう少し書いてみよう。短すぎるかも。' }
  }

  const patternInfo = PATTERN_TEMPLATES[patternId]
  if (!patternInfo) {
    // Unknown pattern: pass if sentence is reasonable length
    return trimmed.length >= 5
      ? { pass: true, feedback: '書けたね。' }
      : { pass: false, feedback: 'もう少し書いてみよう。' }
  }

  // 1. Check target pattern is used
  const templateLower = patternInfo.template.toLowerCase()
  if (!lower.includes(templateLower)) {
    return {
      pass: false,
      feedback: `「${patternInfo.template}」を使って文を作ってみよう。`,
    }
  }

  // 2. Check it's not a copy of example sentences
  const isExactCopy = patternInfo.examples.some(
    (ex) => ex.toLowerCase().replace(/[.!?]/g, '').trim() === lower.replace(/[.!?]/g, '').trim()
  )
  if (isExactCopy) {
    return {
      pass: false,
      feedback: '例文とは違う、自分だけの文を作ってみよう。',
    }
  }

  // 3. Check the sentence has content after the pattern (not just the pattern alone)
  const afterPattern = lower.slice(lower.indexOf(templateLower) + templateLower.length).trim()
  // Remove punctuation for length check
  const afterClean = afterPattern.replace(/[.!?,]/g, '').trim()
  if (afterClean.length < 1) {
    return {
      pass: false,
      feedback: `「${patternInfo.template}」の後に続きを書いてみよう。`,
    }
  }

  // All checks passed
  const feedbacks = [
    '自分の言葉で書けたね。通じてるよ。',
    'ちゃんと伝わる文になってる。',
    '自分の文が作れた。これが本物の力。',
    'いい文。Mowiが少し大きくなった。',
  ]
  const feedback = feedbacks[Math.floor(Math.random() * feedbacks.length)]

  return { pass: true, feedback }
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response(null, { headers: CORS_HEADERS })
  }
  if (req.method !== 'POST') {
    return jsonResponse({ error: 'method_not_allowed' }, 405)
  }

  // Parse body
  let body: { user_id?: string; pattern_id?: string; sentence?: string }
  try {
    body = await req.json()
  } catch {
    return jsonResponse({ error: 'invalid_json' }, 400)
  }

  const { user_id, pattern_id, sentence } = body
  if (!user_id || !pattern_id || !sentence) {
    return jsonResponse({ error: 'missing_required_fields' }, 400)
  }

  // Judge
  const result = judgeLocally(pattern_id, sentence)

  // Save to production_log
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  const serviceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (supabaseUrl && serviceKey) {
    try {
      const supabase = createClient(supabaseUrl, serviceKey)
      await supabase.from('production_log').insert({
        user_id,
        pattern_id,
        sentence: sentence.trim(),
        passed: result.pass,
        ai_feedback: result.feedback,
      })
    } catch (e) {
      console.warn('[production-gate-judge] log insert failed:', e)
    }
  }

  return jsonResponse({
    pass: result.pass,
    feedback: result.feedback,
  })
})
