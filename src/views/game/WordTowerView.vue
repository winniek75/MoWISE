<template>
  <div class="min-h-screen bg-[#0a0a1a] text-white flex flex-col overflow-hidden select-none">

    <!-- Header -->
    <header class="flex items-center justify-between px-4 pt-safe pt-3 pb-2 z-10">
      <button @click="confirmExit" class="text-white/40 text-sm active:text-white/60">
        &times; やめる
      </button>
      <div class="flex items-center gap-3">
        <span class="text-xs text-white/50">{{ questionIndex + 1 }}/8</span>
        <div class="flex gap-1">
          <span v-for="i in 2" :key="i" class="w-2.5 h-2.5 rounded-full transition-all duration-300"
            :class="i <= missesLeft ? 'bg-red-400 shadow-[0_0_6px_rgba(248,113,113,0.6)]' : 'bg-white/10'" />
        </div>
      </div>
    </header>

    <!-- Tower visualization -->
    <div class="relative flex-shrink-0 h-28 mx-4 mb-2 flex items-end justify-center gap-[2px]">
      <transition-group name="block-pop">
        <div
          v-for="i in towerHeight"
          :key="'block-' + i"
          class="w-8 rounded-sm transition-all duration-300"
          :class="towerShaking ? 'animate-shake' : ''"
          :style="{
            height: '12px',
            background: blockGradient(i),
            boxShadow: `0 0 ${6 + i}px ${blockGlow(i)}`,
            opacity: 0.7 + (i / 8) * 0.3,
          }"
        />
      </transition-group>
      <!-- Tower height label -->
      <span v-if="towerHeight > 0" class="absolute -right-1 bottom-0 text-[10px] text-white/30 font-mono">
        {{ towerHeight }}
      </span>
    </div>

    <!-- Image area -->
    <div class="flex-shrink-0 mx-4 mb-4">
      <div class="relative aspect-square max-w-[240px] mx-auto rounded-2xl overflow-hidden shadow-2xl"
        :class="{ 'ring-2 ring-green-400/50': lastResult === 'correct', 'ring-2 ring-red-400/50': lastResult === 'wrong' }">
        <img
          v-if="currentWord"
          :src="currentWord.image"
          :alt="currentWord.en"
          class="w-full h-full object-cover transition-transform duration-200"
          :class="{ 'scale-105': showingResult }"
          loading="eager"
        />
        <div class="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
        <!-- Japanese meaning overlay -->
        <div class="absolute bottom-0 left-0 right-0 p-3 text-center">
          <p class="text-2xl font-black tracking-wide drop-shadow-lg">{{ currentWord?.ja }}</p>
        </div>
      </div>
    </div>

    <!-- Slot machine area -->
    <div class="flex-1 flex flex-col items-center justify-center px-4 mb-4">

      <!-- Speed indicator -->
      <div class="flex items-center gap-2 mb-3">
        <div class="flex gap-0.5">
          <span v-for="i in 3" :key="'spd'+i" class="w-1.5 h-3 rounded-full transition-all duration-500"
            :class="i <= speedLevel ? 'bg-yellow-400' : 'bg-white/10'" />
        </div>
        <span class="text-[10px] text-white/30 uppercase tracking-widest">
          {{ ['SLOW', 'NORMAL', 'FAST'][speedLevel - 1] }}
        </span>
      </div>

      <!-- Slot window -->
      <div class="relative w-full max-w-xs h-14 rounded-2xl bg-white/[0.04] border border-white/10 overflow-hidden backdrop-blur-sm">
        <!-- Scrolling words -->
        <div
          ref="slotTrack"
          class="absolute top-0 left-0 h-full flex items-center whitespace-nowrap"
          :style="{ transform: `translateX(${slotOffset}px)`, transition: isPaused ? 'none' : 'none' }"
        >
          <span
            v-for="(word, i) in slotWords"
            :key="i"
            class="inline-flex items-center justify-center h-full px-6 text-lg font-bold tracking-wide"
            :class="word.id === currentWord?.id ? 'text-white' : 'text-white/50'"
          >
            {{ word.en }}
          </span>
        </div>
        <!-- Center indicator -->
        <div class="absolute top-0 bottom-0 left-1/2 -translate-x-1/2 w-[2px] bg-yellow-400/60 z-10" />
        <!-- Gradient edges -->
        <div class="absolute inset-y-0 left-0 w-12 bg-gradient-to-r from-[#0a0a1a] to-transparent z-[5]" />
        <div class="absolute inset-y-0 right-0 w-12 bg-gradient-to-l from-[#0a0a1a] to-transparent z-[5]" />
      </div>

      <!-- Result flash -->
      <transition name="result-pop">
        <div v-if="showingResult" class="mt-3 text-center">
          <p v-if="lastResult === 'correct'" class="text-green-400 font-bold text-sm">
            {{ currentWord?.en }}
          </p>
          <p v-else-if="lastResult === 'wrong'" class="text-red-400 font-bold text-sm">
            {{ stoppedWord }} &times;
            <span class="text-white/50 ml-1">→ {{ currentWord?.en }}</span>
          </p>
        </div>
      </transition>
    </div>

    <!-- STOP button -->
    <div class="flex-shrink-0 px-6 pb-8 pb-safe">
      <button
        @click="handleStop"
        :disabled="showingResult || gameOver"
        class="w-full py-4 rounded-2xl text-xl font-black uppercase tracking-[0.2em] transition-all duration-150 active:scale-[0.96]"
        :class="showingResult || gameOver
          ? 'bg-white/5 text-white/20'
          : 'bg-gradient-to-r from-yellow-500 to-orange-500 text-black shadow-[0_4px_24px_rgba(245,158,11,0.4)]'"
      >
        STOP!
      </button>
    </div>

    <!-- Game Over overlay -->
    <transition name="fade">
      <div v-if="gameOver" class="fixed inset-0 bg-black/80 backdrop-blur-sm flex items-center justify-center z-50 p-6">
        <div class="w-full max-w-sm text-center">
          <!-- Tower collapse animation -->
          <div class="text-5xl mb-4" :class="isPerfect ? 'animate-bounce' : ''">
            {{ isPerfect ? '&#127775;' : '&#128165;' }}
          </div>

          <h2 class="text-2xl font-black mb-1">
            {{ isPerfect ? 'タワー完成！' : 'タワー崩壊！' }}
          </h2>
          <p class="text-white/50 text-sm mb-6">
            {{ isPerfect ? 'パーフェクト！全問正解' : `${towerHeight}段まで積めた` }}
          </p>

          <!-- Stats -->
          <div class="grid grid-cols-3 gap-3 mb-6">
            <div class="bg-white/5 rounded-xl p-3">
              <p class="text-2xl font-black text-yellow-400">{{ towerHeight }}</p>
              <p class="text-[10px] text-white/40 mt-0.5">段</p>
            </div>
            <div class="bg-white/5 rounded-xl p-3">
              <p class="text-2xl font-black text-green-400">+{{ xpEarned }}</p>
              <p class="text-[10px] text-white/40 mt-0.5">XP</p>
            </div>
            <div class="bg-white/5 rounded-xl p-3">
              <p class="text-2xl font-black text-blue-400">{{ correctCount }}</p>
              <p class="text-[10px] text-white/40 mt-0.5">正解</p>
            </div>
          </div>

          <!-- Missed words -->
          <div v-if="missedWords.length > 0" class="mb-6">
            <p class="text-xs text-white/30 mb-2">まだMowiに届いていない単語</p>
            <div class="flex flex-wrap justify-center gap-2">
              <span v-for="w in missedWords" :key="w.id"
                class="px-3 py-1 bg-red-500/10 border border-red-500/20 rounded-full text-xs text-red-300">
                {{ w.en }} = {{ w.ja }}
              </span>
            </div>
          </div>

          <!-- Near miss text -->
          <p v-if="!isPerfect && towerHeight >= 6" class="text-yellow-400/80 text-sm mb-4 font-medium">
            惜しい！あと{{ 8 - towerHeight }}問だった
          </p>

          <!-- Mowi line -->
          <p class="text-white/50 text-sm italic mb-6">
            {{ mowiEndLine }}
          </p>

          <!-- Buttons -->
          <button
            @click="restartGame"
            class="w-full py-3.5 rounded-2xl text-base font-bold bg-gradient-to-r from-yellow-500 to-orange-500 text-black mb-3 active:scale-[0.97] transition-transform shadow-[0_4px_20px_rgba(245,158,11,0.3)]"
          >
            もう1ラウンド
          </button>
          <button
            @click="goHome"
            class="text-white/30 text-sm hover:text-white/50 transition-colors"
          >
            ホームに戻る
          </button>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { pickRoundWords, pickDecoys, type WordTowerWord } from '@/data/wordTowerWords'

const router = useRouter()

// Game state
const questionIndex = ref(0)
const towerHeight = ref(0)
const missesLeft = ref(2)
const correctCount = ref(0)
const xpEarned = ref(0)
const gameOver = ref(false)
const showingResult = ref(false)
const lastResult = ref<'correct' | 'wrong' | null>(null)
const towerShaking = ref(false)
const stoppedWord = ref('')
const missedWords = ref<WordTowerWord[]>([])

// Round words (8 per round)
const roundWords = ref<WordTowerWord[]>([])
const currentWord = computed(() => roundWords.value[questionIndex.value] ?? null)

// Slot machine state
const slotWords = ref<WordTowerWord[]>([])
const slotOffset = ref(0)
const isPaused = ref(false)
let animFrame: number | null = null
let slotSpeed = 2 // pixels per frame

// Speed level (1-3)
const speedLevel = computed(() => {
  const q = questionIndex.value
  if (q < 3) return 1
  if (q < 6) return 2
  return 3
})

const isPerfect = computed(() => towerHeight.value === 8 && missedWords.value.length === 0)

const mowiEndLine = computed(() => {
  if (isPerfect.value) return '全部、積み上がった。'
  if (towerHeight.value >= 6) return 'もう少しで見えた景色があった。'
  if (towerHeight.value >= 3) return '崩れた。でも、土台は残ってる。'
  return 'まだ体になじんでない。もう一回。'
})

// Block visuals
function blockGradient(i: number) {
  const hue = 220 + (i * 15) // blue to purple
  return `linear-gradient(135deg, hsl(${hue}, 80%, 55%), hsl(${hue + 20}, 70%, 40%))`
}
function blockGlow(i: number) {
  const hue = 220 + (i * 15)
  return `hsla(${hue}, 80%, 55%, 0.4)`
}

// Initialize
onMounted(() => {
  startGame()
})

onUnmounted(() => {
  stopSlot()
})

function startGame() {
  roundWords.value = pickRoundWords()
  questionIndex.value = 0
  towerHeight.value = 0
  missesLeft.value = 2
  correctCount.value = 0
  xpEarned.value = 0
  gameOver.value = false
  missedWords.value = []
  setupQuestion()
}

function setupQuestion() {
  if (!currentWord.value) return

  showingResult.value = false
  lastResult.value = null
  towerShaking.value = false

  // Build slot word list: correct + 5 decoys, repeated for seamless loop
  const decoys = pickDecoys(currentWord.value, 5)
  const oneSet = [currentWord.value, ...decoys].sort(() => Math.random() - 0.5)
  // Repeat 4x for smooth looping
  slotWords.value = [...oneSet, ...oneSet, ...oneSet, ...oneSet]

  // Set speed based on question number
  const q = questionIndex.value
  slotSpeed = q < 3 ? 1.5 : q < 6 ? 2.5 : 4

  slotOffset.value = 0
  isPaused.value = false
  startSlot()
}

function startSlot() {
  stopSlot()
  function tick() {
    if (isPaused.value) return
    slotOffset.value -= slotSpeed
    // Loop: when we've scrolled past one set, reset
    const wordWidth = 120 // approx px per word
    const setWidth = wordWidth * 6
    if (Math.abs(slotOffset.value) > setWidth) {
      slotOffset.value += setWidth
    }
    animFrame = requestAnimationFrame(tick)
  }
  animFrame = requestAnimationFrame(tick)
}

function stopSlot() {
  if (animFrame) {
    cancelAnimationFrame(animFrame)
    animFrame = null
  }
}

function handleStop() {
  if (showingResult.value || gameOver.value || !currentWord.value) return

  isPaused.value = true
  stopSlot()

  // Determine which word is at center
  const wordWidth = 120
  const centerOffset = 160 // approx half container width
  const adjustedOffset = Math.abs(slotOffset.value) + centerOffset
  const wordIndex = Math.floor(adjustedOffset / wordWidth) % slotWords.value.length
  const selectedWord = slotWords.value[wordIndex]

  stoppedWord.value = selectedWord?.en ?? ''
  const isCorrect = selectedWord?.id === currentWord.value.id

  showingResult.value = true

  if (isCorrect) {
    lastResult.value = 'correct'
    towerHeight.value++
    correctCount.value++
    // XP: base 3, fast bonus 5, perfect bonus will be added at end
    const baseXp = speedLevel.value >= 3 ? 5 : 3
    xpEarned.value += baseXp
  } else {
    lastResult.value = 'wrong'
    missesLeft.value--
    missedWords.value.push(currentWord.value)
    towerShaking.value = true
    setTimeout(() => { towerShaking.value = false }, 500)
  }

  // Check game over or next question
  setTimeout(() => {
    if (missesLeft.value <= 0) {
      // Game over - tower collapse
      gameOver.value = true
      return
    }
    if (questionIndex.value >= 7) {
      // Round complete!
      xpEarned.value += 15 // completion bonus
      if (isPerfect.value) xpEarned.value += 10 // perfect bonus
      gameOver.value = true
      return
    }
    questionIndex.value++
    setupQuestion()
  }, isCorrect ? 600 : 1000)
}

function restartGame() {
  startGame()
}

function goHome() {
  router.push({ name: 'Home' })
}

function confirmExit() {
  if (towerHeight.value > 0 && !gameOver.value) {
    if (!confirm('ゲームを終了しますか？')) return
  }
  goHome()
}
</script>

<style scoped>
/* Block pop animation */
.block-pop-enter-active {
  animation: blockPop 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}
@keyframes blockPop {
  0% { transform: scaleY(0); opacity: 0; }
  100% { transform: scaleY(1); opacity: 1; }
}

/* Tower shake */
@keyframes shake {
  0%, 100% { transform: translateX(0); }
  20% { transform: translateX(-4px) rotate(-1deg); }
  40% { transform: translateX(4px) rotate(1deg); }
  60% { transform: translateX(-3px) rotate(-0.5deg); }
  80% { transform: translateX(3px) rotate(0.5deg); }
}
.animate-shake {
  animation: shake 0.4s ease-in-out;
}

/* Result pop */
.result-pop-enter-active {
  animation: popIn 0.2s ease-out;
}
.result-pop-leave-active {
  animation: popIn 0.15s ease-in reverse;
}
@keyframes popIn {
  0% { transform: scale(0.8); opacity: 0; }
  100% { transform: scale(1); opacity: 1; }
}

/* Fade */
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>
