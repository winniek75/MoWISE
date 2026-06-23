<template>
  <div class="min-h-screen bg-gradient-to-b from-[#0d0d1a] to-[#1a1040] text-white flex flex-col">

    <!-- Header -->
    <header class="flex items-center justify-between px-4 pt-safe pt-4 pb-2">
      <button @click="goBack" class="text-white/60 text-sm px-2 py-1">
        &larr; 戻る
      </button>
      <div class="text-sm font-bold text-white/80">
        {{ patternId }} 自分の言葉で
      </div>
      <div class="w-12"></div>
    </header>

    <!-- Mowi area -->
    <div class="flex flex-col items-center mt-4 mb-6">
      <div
        class="w-20 h-20 rounded-full transition-all duration-500"
        :class="mowiClass"
        :style="orbStyle"
      />
      <p class="mt-3 text-sm text-white/70 text-center px-8 min-h-[2em] transition-opacity duration-500">
        {{ mowiLine }}
      </p>
    </div>

    <!-- Instruction -->
    <div class="mx-4 mb-4">
      <div class="bg-white/10 rounded-xl px-4 py-3 text-center">
        <p class="text-xs text-white/50 mb-1">この型を使って、自分だけの文を作ろう</p>
        <p class="text-xl font-bold text-yellow-300">{{ templateDisplay }}</p>
      </div>
    </div>

    <!-- Example (what NOT to write) -->
    <div class="mx-4 mb-4">
      <p class="text-xs text-white/40 mb-1 px-1">例文（これとは違う文を書こう）</p>
      <div class="bg-white/5 rounded-lg px-3 py-2">
        <p v-for="(ex, i) in examples" :key="i" class="text-sm text-white/40">
          {{ ex }}
        </p>
      </div>
    </div>

    <!-- Input area -->
    <div class="mx-4 mb-4 flex-1">
      <div class="relative">
        <textarea
          ref="inputRef"
          v-model="userSentence"
          :disabled="isJudging || hasPassed"
          placeholder="自分の文を書いてみよう..."
          class="w-full h-24 bg-white/10 border border-white/20 rounded-xl px-4 py-3 text-white text-lg placeholder-white/30 resize-none focus:outline-none focus:border-indigo-400 transition-colors"
          :class="{ 'border-green-400': hasPassed, 'border-red-400/50': hasRetried && !hasPassed }"
          @keydown.enter.prevent="submitSentence"
        />
      </div>
    </div>

    <!-- Feedback area -->
    <Transition name="slide-up">
      <div v-if="feedbackText" class="mx-4 mb-4">
        <div
          class="rounded-xl px-4 py-3 text-sm text-center"
          :class="hasPassed ? 'bg-green-500/20 text-green-300' : 'bg-orange-500/15 text-orange-300'"
        >
          {{ feedbackText }}
        </div>
      </div>
    </Transition>

    <!-- Action buttons -->
    <div class="mx-4 mb-8 pb-safe">
      <button
        v-if="!hasPassed"
        @click="submitSentence"
        :disabled="!canSubmit"
        class="w-full py-3.5 rounded-2xl font-bold text-base transition-all duration-200"
        :class="canSubmit
          ? 'bg-indigo-500 hover:bg-indigo-400 text-white active:scale-[0.98]'
          : 'bg-white/10 text-white/30 cursor-not-allowed'"
      >
        {{ isJudging ? '判定中...' : '送信' }}
      </button>

      <button
        v-else
        @click="proceedAfterPass"
        class="w-full py-3.5 rounded-2xl font-bold text-base bg-green-500 hover:bg-green-400 text-white active:scale-[0.98] transition-all duration-200"
      >
        次へ進む
      </button>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '@/stores/session'
import { useAuthStore } from '@/stores/auth'
import { supabase, isOfflineMode } from '@/lib/supabase'

const router = useRouter()
const sessionStore = useSessionStore()
const authStore = useAuthStore()

// Pattern info
const patternId = computed(() => sessionStore.currentPattern?.patternId ?? 'P001')
const patternLabel = computed(() => sessionStore.currentPattern?.patternLabel ?? '')

// Pattern templates for display
const TEMPLATES: Record<string, { display: string; examples: string[] }> = {
  P001: { display: "I'm ___.", examples: ["I'm tired.", "I'm happy."] },
  P002: { display: 'This is ___.', examples: ['This is my dog.'] },
  P003: { display: 'Nice to meet you.', examples: ['Nice to meet you.'] },
  P004: { display: 'I like ___.', examples: ['I like soccer.', 'I like cats.'] },
  P005: { display: 'I want ___.', examples: ['I want water.'] },
  P006: { display: 'I have ___.', examples: ['I have a dog.'] },
  P007: { display: 'I can ___.', examples: ['I can swim.'] },
  P008: { display: "I'm from ___.", examples: ["I'm from Japan."] },
  P009: { display: "It's ___.", examples: ["It's cold."] },
  P010: { display: 'Thank you for ___.', examples: ['Thank you for helping me.'] },
  P011: { display: "I'm sorry for ___.", examples: ["I'm sorry for being late."] },
  P012: { display: 'See you ___.', examples: ['See you tomorrow.'] },
  P013: { display: 'How are you?', examples: ['How are you?'] },
  P014: { display: "I don't understand ___.", examples: ["I don't understand English."] },
  P015: { display: 'Can you ___?', examples: ['Can you help me?'] },
  P016: { display: 'Where is ___?', examples: ['Where is the station?'] },
  P017: { display: 'How much is ___?', examples: ['How much is this?'] },
  P018: { display: "I'm looking for ___.", examples: ["I'm looking for my keys."] },
  P019: { display: "Let's ___.", examples: ["Let's go."] },
  P020: { display: 'I feel ___.', examples: ['I feel happy.'] },
}

const templateDisplay = computed(() => TEMPLATES[patternId.value]?.display ?? `${patternLabel.value} ___`)
const examples = computed(() => TEMPLATES[patternId.value]?.examples ?? [])

// State
const inputRef = ref<HTMLTextAreaElement | null>(null)
const userSentence = ref('')
const isJudging = ref(false)
const hasPassed = ref(false)
const hasRetried = ref(false)
const feedbackText = ref('')
const mowiLine = ref('自分の言葉で、書いてみて。')
const mowiEmotion = ref<'idle' | 'cheer' | 'joy' | 'grow'>('cheer')

const canSubmit = computed(() => userSentence.value.trim().length >= 3 && !isJudging.value && !hasPassed.value)

const mowiClass = computed(() => ({
  'animate-pulse': mowiEmotion.value === 'cheer',
  'animate-bounce': mowiEmotion.value === 'joy' || mowiEmotion.value === 'grow',
}))

const orbStyle = computed(() => {
  const isGrow = mowiEmotion.value === 'grow'
  const brightness = isGrow ? 10 : hasPassed.value ? 8 : 5
  const size = 80
  return {
    width: `${size}px`,
    height: `${size}px`,
    background: `radial-gradient(circle at 35% 35%, rgba(200,220,255,0.9), #4A7AFF 60%, #2a3a8f)`,
    boxShadow: `0 0 ${20 + brightness * 4}px rgba(74,122,255,0.7), 0 0 ${40 + brightness * 6}px rgba(155,92,246,0.3)`,
  }
})

onMounted(() => {
  nextTick(() => inputRef.value?.focus())
})

async function submitSentence() {
  if (!canSubmit.value) return

  isJudging.value = true
  feedbackText.value = ''
  mowiLine.value = '…読んでる。'
  mowiEmotion.value = 'idle'

  try {
    let result: { pass: boolean; feedback: string }

    if (isOfflineMode) {
      // Offline: simple local check
      result = localJudge(patternId.value, userSentence.value)
    } else {
      // Call Edge Function
      const { data, error } = await supabase.functions.invoke('production-gate-judge', {
        body: {
          user_id: authStore.userId,
          pattern_id: patternId.value,
          sentence: userSentence.value.trim(),
        },
      })

      if (error || !data) {
        // Fallback to local
        console.warn('[ProductionGate] Edge Function failed, using local judge:', error)
        result = localJudge(patternId.value, userSentence.value)
      } else {
        result = data as { pass: boolean; feedback: string }
      }
    }

    feedbackText.value = result.feedback

    if (result.pass) {
      hasPassed.value = true
      mowiEmotion.value = 'grow'
      mowiLine.value = '自分の言葉で書けた。これが本物。'

      // Update star to 4
      await updateStarTo4()
    } else {
      hasRetried.value = true
      mowiEmotion.value = 'cheer'
      mowiLine.value = 'もう一回。自分の言葉で。'
    }
  } catch (e) {
    console.warn('[ProductionGate] submit error:', e)
    feedbackText.value = 'エラーが発生しました。もう一度試してみてください。'
    mowiEmotion.value = 'cheer'
  } finally {
    isJudging.value = false
  }
}

async function updateStarTo4() {
  if (isOfflineMode || !authStore.userId) return

  try {
    await supabase.from('pattern_progress')
      .upsert({
        user_id: authStore.userId,
        pattern_no: patternId.value,
        mastery_level: 4,
        layer_3_cleared: true,
        updated_at: new Date().toISOString(),
      }, { onConflict: 'user_id,pattern_no' })
  } catch (e) {
    console.warn('[ProductionGate] star update failed:', e)
  }
}

/**
 * Offline/fallback local judge (same logic as Edge Function)
 */
function localJudge(pId: string, sentence: string): { pass: boolean; feedback: string } {
  const trimmed = sentence.trim()
  const lower = trimmed.toLowerCase()

  if (trimmed.length < 3) {
    return { pass: false, feedback: 'もう少し書いてみよう。短すぎるかも。' }
  }

  const tmpl = TEMPLATES[pId]
  if (!tmpl) {
    return trimmed.length >= 5
      ? { pass: true, feedback: '書けたね。' }
      : { pass: false, feedback: 'もう少し書いてみよう。' }
  }

  // Extract the pattern core (before ___)
  const templateCore = tmpl.display.replace(/\s*___.*/, '').toLowerCase().trim()

  if (!lower.includes(templateCore)) {
    return { pass: false, feedback: `「${templateCore}」を使って文を作ってみよう。` }
  }

  // Check not exact copy
  const isExactCopy = tmpl.examples.some(
    (ex) => ex.toLowerCase().replace(/[.!?]/g, '').trim() === lower.replace(/[.!?]/g, '').trim()
  )
  if (isExactCopy) {
    return { pass: false, feedback: '例文とは違う、自分だけの文を作ってみよう。' }
  }

  // Check content after pattern
  const afterPattern = lower.slice(lower.indexOf(templateCore) + templateCore.length).trim()
  const afterClean = afterPattern.replace(/[.!?,]/g, '').trim()
  if (afterClean.length < 1) {
    return { pass: false, feedback: `「${templateCore}」の後に続きを書いてみよう。` }
  }

  const feedbacks = [
    '自分の言葉で書けたね。通じてるよ。',
    'ちゃんと伝わる文になってる。',
    '自分の文が作れた。これが本物の力。',
  ]
  return { pass: true, feedback: feedbacks[Math.floor(Math.random() * feedbacks.length)] }
}

function proceedAfterPass() {
  // Update session store
  sessionStore.completeLayer3()
  sessionStore.productionGatePassed = true
  router.push({ name: 'session-end' })
}

function goBack() {
  if (hasPassed.value) {
    proceedAfterPass()
  } else {
    router.push({ name: 'session-end' })
  }
}
</script>

<style scoped>
.slide-up-enter-active,
.slide-up-leave-active {
  transition: all 0.3s ease;
}
.slide-up-enter-from {
  opacity: 0;
  transform: translateY(12px);
}
.slide-up-leave-to {
  opacity: 0;
  transform: translateY(-12px);
}
</style>
