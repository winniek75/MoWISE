<template>
  <div class="min-h-screen bg-gradient-to-b from-[#0d0d1a] to-[#1a1040] text-white flex flex-col">

    <!-- ヘッダー -->
    <header class="flex items-center justify-between px-4 pt-safe pt-4 pb-2">
      <button @click="confirmExit" class="text-white/60 text-sm px-2 py-1">
        × 終了
      </button>
      <div class="text-sm font-bold text-white/80">
        {{ currentPatternId }} Flash Sprint
      </div>
      <div class="text-sm text-white/60">
        {{ currentIndex + 1 }}/{{ questions.length }}問
      </div>
    </header>

    <!-- パターン常時表示（刷り込み設計） -->
    <div class="mx-4 mb-2 bg-white/10 rounded-xl px-4 py-2 flex items-center gap-2">
      <span class="text-yellow-400 font-bold">⚡</span>
      <span class="text-sm font-bold text-white">{{ patternText }}</span>
      <span class="text-xs text-white/50 ml-1">{{ patternJp }}</span>
    </div>

    <!-- コンボゲージ -->
    <div class="px-4 mb-3">
      <div class="flex items-center justify-between mb-1">
        <span class="text-xs text-white/50">COMBO</span>
        <span class="text-sm font-bold" :class="comboTextClass">
          {{ combo }}{{ combo >= 5 ? ' 🔥' : '' }}
        </span>
      </div>
      <div class="h-3 bg-white/10 rounded-full overflow-hidden">
        <div
          class="h-full rounded-full transition-all duration-200"
          :class="comboGaugeClass"
          :style="{ width: `${Math.min(combo * 10, 100)}%` }"
        ></div>
      </div>
    </div>

    <!-- 問題エリア -->
    <div class="mx-4 mb-3">
      <!-- 日本語問題文 -->
      <div class="bg-white/10 rounded-xl px-4 py-3 text-center mb-3">
        <span class="text-lg font-bold">🇯🇵 {{ currentQuestion?.japanese }}</span>
      </div>

      <!-- タイマーバー -->
      <div class="flex items-center gap-2 mb-3">
        <span class="text-xs text-white/50">⏱</span>
        <div class="flex-1 h-2 bg-white/10 rounded-full overflow-hidden">
          <div
            class="h-full rounded-full transition-none"
            :class="timerBarClass"
            :style="{ width: `${timerPercent}%` }"
          ></div>
        </div>
        <span class="text-xs font-bold" :class="timerPercent < 30 ? 'text-red-400 animate-pulse' : 'text-white/60'">
          {{ Math.ceil(timeLeft) }}秒
        </span>
      </div>

      <!-- 回答組み立てエリア -->
      <div class="bg-white/5 rounded-xl px-4 py-3 mb-3 min-h-[52px] flex flex-wrap gap-2 items-center">
        <span
          v-for="(part, i) in answerSlots"
          :key="i"
          class="px-3 py-1.5 rounded-lg text-sm font-bold"
          :class="part.filled
            ? 'bg-indigo-500 text-white cursor-pointer'
            : 'bg-white/10 text-white/30 border border-white/20'"
          @click="part.filled ? removeFromSlot(i) : null"
        >
          {{ part.filled ? part.word : '_____' }}
        </span>
      </div>

      <!-- タイルエリア -->
      <div class="flex flex-wrap gap-2 mb-4">
        <button
          v-for="(tile, i) in availableTiles"
          :key="i"
          @click="selectTile(tile, i)"
          :disabled="tile.used"
          class="px-4 py-2 rounded-xl text-sm font-bold transition-all duration-150 active:scale-95"
          :class="tile.used
            ? 'bg-white/5 text-white/20 cursor-not-allowed'
            : 'bg-white/20 hover:bg-white/30 text-white'"
        >
          {{ tile.word }}
        </button>
      </div>

      <!-- 送信ボタン -->
      <button
        @click="submitAnswer"
        :disabled="!allSlotsFilled"
        class="w-full py-3.5 rounded-2xl font-bold text-base transition-all duration-200"
        :class="allSlotsFilled
          ? 'bg-indigo-500 hover:bg-indigo-400 text-white active:scale-[0.98]'
          : 'bg-white/10 text-white/30 cursor-not-allowed'"
      >
        ✓ 送信
      </button>
    </div>

    <!-- Mowiエリア -->
    <div class="flex-1 flex flex-col items-center justify-center pb-8">
      <MowiOrb
        :brightness="mowiGlow"
        :emotion="mowiEmotion"
        class="w-24 h-24"
      />
      <p v-if="mowiLine" class="mt-2 text-sm text-white/70 text-center px-8 transition-opacity duration-500">
        {{ mowiLine }}
      </p>
    </div>

    <!-- 正解フィードバックオーバーレイ -->
    <Transition name="feedback">
      <div
        v-if="feedback"
        class="fixed inset-0 flex items-center justify-center pointer-events-none"
      >
        <div
          class="text-6xl animate-bounce"
          :class="feedback === 'correct' ? 'text-green-400' : 'text-red-400'"
        >
          {{ feedback === 'correct' ? '⭐' : '✕' }}
        </div>
      </div>
    </Transition>

    <!-- 終了確認ダイアログ -->
    <div
      v-if="showExitDialog"
      class="fixed inset-0 bg-black/60 flex items-center justify-center z-50"
    >
      <div class="bg-[#1a1040] border border-white/20 rounded-2xl p-6 mx-8 text-center">
        <p class="font-bold text-lg mb-1">練習を終了しますか？</p>
        <p class="text-sm text-white/50 mb-6">今回の記録は保存されます</p>
        <div class="flex gap-3">
          <button @click="showExitDialog = false" class="flex-1 py-2.5 rounded-xl border border-white/20 text-sm">
            続ける
          </button>
          <button @click="exitSession" class="flex-1 py-2.5 rounded-xl bg-indigo-500 text-sm font-bold">
            はい
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '@/stores/session'
import { useMowiStore } from '@/stores/mowi'
import { supabase } from '@/lib/supabase'
import MowiOrb from '@/components/mowi/MowiOrb.vue'

const router = useRouter()
const sessionStore = useSessionStore()
const mowiStore = useMowiStore()

// ─── 状態 ──────────────────────────────────────────────────────
const questions        = ref<any[]>([])
const currentIndex     = ref(0)
const combo            = ref(0)
const feedback         = ref<'correct' | 'wrong' | null>(null)
const showExitDialog   = ref(false)
const mowiLine         = ref('行くよ。')
const mowiEmotion      = ref<'idle' | 'joy' | 'sad' | 'cheer'>('cheer')
const sessionLogs      = ref<any[]>([])

// タイマー
const timeLeft    = ref(8)
const timerMax    = ref(8)
const timerActive = ref(false)
let   timerHandle: ReturnType<typeof setInterval> | null = null

// タイル・スロット状態
const availableTiles = ref<{ word: string; used: boolean }[]>([])
const answerSlots    = ref<{ word: string; filled: boolean }[]>([])

// ─── パターン情報（sessionStoreから受け取り） ───────────────────
const currentPatternId = computed(() => sessionStore.currentPattern?.patternId ?? 'P001')
const patternText      = computed(() => sessionStore.currentPattern?.patternLabel ?? '')
const patternJp        = computed(() => sessionStore.currentPattern?.patternJa ?? '')
const currentQuestion  = computed(() => questions.value[currentIndex.value])

// ─── 算出プロパティ ───────────────────────────────────────────
const allSlotsFilled = computed(() => answerSlots.value.every(s => s.filled))
const timerPercent   = computed(() => (timeLeft.value / timerMax.value) * 100)

const mowiGlow = computed(() => {
  if (combo.value >= 10) return 10
  if (combo.value >= 7)  return 9
  if (combo.value >= 5)  return 7
  if (combo.value >= 3)  return 5
  return 3
})

const comboTextClass = computed(() => {
  if (combo.value >= 7) return 'text-yellow-400'
  if (combo.value >= 5) return 'text-orange-400'
  if (combo.value >= 3) return 'text-blue-400'
  return 'text-white/50'
})

const comboGaugeClass = computed(() => {
  if (combo.value >= 7) return 'bg-gradient-to-r from-yellow-400 via-orange-400 to-red-400'
  if (combo.value >= 5) return 'bg-orange-400'
  if (combo.value >= 3) return 'bg-blue-400'
  return 'bg-gray-400'
})

const timerBarClass = computed(() => {
  if (timerPercent.value < 30) return 'bg-red-500'
  if (combo.value >= 5)         return 'bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400'
  if (combo.value >= 3)         return 'bg-blue-400'
  return 'bg-white/50'
})

// ─── ライフサイクル ───────────────────────────────────────────
onMounted(async () => {
  await loadQuestions()
  setupQuestion()
})

onUnmounted(() => {
  stopTimer()
})

// ─── データ取得 ───────────────────────────────────────────────
async function loadQuestions() {
  const { data } = await supabase
    .from('pattern_content')
    .select('layer_3_questions')
    .eq('pattern_id', currentPatternId.value)
    .single()
  questions.value = data?.layer_3_questions ?? []
}

// ─── 問題セットアップ ─────────────────────────────────────────
function setupQuestion() {
  const q = currentQuestion.value
  if (!q) return

  // 難易度によるタイム変更
  const difficulty = getDifficulty()
  timerMax.value  = difficulty === 'hard' ? 6 : 8
  timeLeft.value  = timerMax.value

  // スロット初期化
  answerSlots.value = q.answer_words.map(() => ({ word: '', filled: false }))

  // タイル生成（正解 + ダミー シャッフル）
  const all = [...q.answer_words, ...(q.dummy_words ?? [])].sort(() => Math.random() - 0.5)
  availableTiles.value = all.map((w: string) => ({ word: w, used: false }))

  startTimer()
}

function getDifficulty(): 'normal' | 'hard' {
  return combo.value >= 3 ? 'hard' : 'normal'
}

// ─── タイマー ─────────────────────────────────────────────────
function startTimer() {
  timerActive.value = true
  timerHandle = setInterval(() => {
    timeLeft.value -= 0.1
    if (timeLeft.value <= 0) {
      clearInterval(timerHandle!)
      handleTimeout()
    }
  }, 100)
}

function stopTimer() {
  if (timerHandle) clearInterval(timerHandle)
  timerActive.value = false
}

function handleTimeout() {
  logAnswer(false, timerMax.value * 1000)
  combo.value = 0
  mowiEmotion.value = 'sad'
  mowiLine.value = '間にあわなかった。'
  feedback.value = 'wrong'
  setTimeout(() => {
    feedback.value = null
    nextQuestion()
  }, 1500)
}

// ─── タイル操作 ───────────────────────────────────────────────
function selectTile(tile: { word: string; used: boolean }, _index: number) {
  if (tile.used) return
  const slotIndex = answerSlots.value.findIndex(s => !s.filled)
  if (slotIndex === -1) return

  tile.used = true
  answerSlots.value[slotIndex] = { word: tile.word, filled: true }
}

function removeFromSlot(slotIndex: number) {
  const word = answerSlots.value[slotIndex].word
  answerSlots.value[slotIndex] = { word: '', filled: false }
  const tile = availableTiles.value.find(t => t.word === word && t.used)
  if (tile) tile.used = false
}

// ─── 送信・判定 ───────────────────────────────────────────────
function submitAnswer() {
  if (!allSlotsFilled.value) return
  stopTimer()

  const responseMs = Math.round((timerMax.value - timeLeft.value) * 1000)
  const userAnswer = answerSlots.value.map(s => s.word).join(' ')
  const correct    = userAnswer === currentQuestion.value?.answer

  logAnswer(correct, responseMs)

  if (correct) {
    combo.value++
    mowiEmotion.value = combo.value >= 5 ? 'joy' : 'cheer'
    mowiLine.value = combo.value >= 5
      ? ['走ってる。', '止まれない。', 'はやい。'][Math.floor(Math.random() * 3)]
      : ['でた。', 'ちゃんと出てる。', 'その感じ。'][Math.floor(Math.random() * 3)]
    feedback.value = 'correct'
    mowiStore.updateAfterSession({ combo: combo.value })
    setTimeout(() => {
      feedback.value = null
      nextQuestion()
    }, 800)
  } else {
    combo.value = 0
    mowiEmotion.value = 'sad'
    mowiLine.value = '…なんか変。'
    feedback.value = 'wrong'
    setTimeout(() => {
      feedback.value = null
      nextQuestion()
    }, 1800)
  }
}

// ─── 次問 / 終了 ──────────────────────────────────────────────
function nextQuestion() {
  if (currentIndex.value < questions.value.length - 1) {
    currentIndex.value++
    setupQuestion()
  } else {
    finishSession()
  }
}

async function finishSession() {
  stopTimer()
  // ログINSERT
  if (sessionLogs.value.length > 0) {
    await supabase.from('flash_output_logs').insert(sessionLogs.value)
  }
  // pattern_progress 更新
  await supabase.from('pattern_progress')
    .upsert({
      user_id: (await supabase.auth.getUser()).data.user!.id,
      pattern_id: currentPatternId.value,
      star_level: 4, // Layer3完了で★4
      layer_3_cleared: true,
      last_attempted_at: new Date().toISOString(),
    }, { onConflict: 'user_id,pattern_id' })
  router.push('/session/end')
}

function logAnswer(isCorrect: boolean, responseMs: number) {
  sessionLogs.value.push({
    pattern_id:     currentPatternId.value,
    is_correct:     isCorrect,
    response_ms:    responseMs,
    combo_at_time:  combo.value,
    layer:          3,
    difficulty_level: getDifficulty(),
    answered_at:    new Date().toISOString(),
  })
}

// ─── ナビゲーション ───────────────────────────────────────────
function confirmExit() {
  stopTimer()
  showExitDialog.value = true
}

async function exitSession() {
  if (sessionLogs.value.length > 0) {
    await supabase.from('flash_output_logs').insert(sessionLogs.value)
  }
  router.push('/session/end')
}
</script>

<style scoped>
.feedback-enter-active, .feedback-leave-active { transition: opacity 200ms; }
.feedback-enter-from, .feedback-leave-to       { opacity: 0; }
</style>
