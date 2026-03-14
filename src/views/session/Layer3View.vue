<template>
  <div class="layer3-screen">

    <!-- ヘッダー -->
    <header class="l3-header">
      <button class="btn-exit" @click="confirmExit">← 終了</button>
      <span class="l3-header__title">{{ gameMode.patternId.value }} &nbsp; Layer 3</span>
      <span class="l3-header__progress">{{ currentIndex + 1 }} / {{ questions.length }}問</span>
    </header>

    <!-- コンボゲージ -->
    <div class="combo-gauge-wrap">
      <div class="combo-gauge">
        <div
          class="combo-gauge__fill"
          :class="{
            'is-rainbow': sessionStore.combo >= 10,
            'is-pulsing': sessionStore.combo >= 5,
            'is-dimming': isDimming,
          }"
          :style="gaugeStyle"
        />
        <!-- タイマー残り40%で右端からグレー化 -->
        <div v-if="isDimming" class="gauge-dim-overlay" :style="dimOverlayStyle" />
      </div>
      <span v-if="sessionStore.combo >= 3" class="combo-text" :style="{ color: sessionStore.comboColor }">
        {{ sessionStore.combo }}
      </span>
    </div>

    <!-- Mowi エリア -->
    <div class="mowi-area" :class="{ 'mowi-area--dimming': isDimming }">
      <div class="mowi-orb-wrap" :class="mowiStateClass">
        <div class="orb-core" :style="orbStyle" :class="{ 'orb--trembling': isTrembling }" />
        <div class="orb-glow"  :style="glowStyle" />
        <!-- 実装時: <MowiOrb :state="sessionStore.mowiEmotionState" :brightness="orbBrightness" size="md" /> -->
      </div>
      <transition name="fade-text">
        <p v-if="mowiDialogue" class="mowi-dialogue">{{ mowiDialogue }}</p>
      </transition>
    </div>

    <!-- 問題エリア -->
    <div v-if="currentQ" class="question-area">
      <!-- 日本語プロンプト -->
      <p class="prompt-ja">{{ currentQ.promptJa }}</p>

      <!-- タイマーバー -->
      <div class="timer-wrap">
        <span class="timer-icon">⏱</span>
        <div class="timer-bar">
          <div
            class="timer-fill"
            :class="{ 'timer--warning': timerPercent <= 40, 'timer--critical': timerPercent <= 15 }"
            :style="{ width: `${timerPercent}%` }"
          />
        </div>
        <span class="timer-sec" :class="{ 'text--warning': timerPercent <= 40 }">
          {{ timerSecondsLeft }}秒
        </span>
      </div>
    </div>

    <!-- 組み立てエリア（置かれたタイル） -->
    <div class="build-area">
      <div class="build-slots">
        <transition-group name="tile-move" tag="div" class="placed-tiles">
          <button
            v-for="tile in placedTiles"
            :key="tile.id + '-placed'"
            class="tile tile--placed"
            :class="{
              'tile--correct': isAnswered && isCorrectAnswer,
              'tile--wrong':   isAnswered && !isCorrectAnswer,
            }"
            :disabled="isAnswered"
            @click="removeTile(tile)"
          >
            {{ tile.word }}
          </button>
        </transition-group>
        <!-- 空のとき -->
        <p v-if="placedTiles.length === 0 && !isAnswered" class="build-placeholder">
          下のタイルをタップ
        </p>
        <!-- 正解文表示（答え合わせ後） -->
        <p v-if="isAnswered && !isCorrectAnswer" class="correct-sentence-label">
          正解：{{ currentQ.correctSentence }}
        </p>
      </div>

      <!-- 確認ボタン -->
      <button
        v-if="!isAnswered && placedTiles.length > 0"
        class="btn-check"
        :class="{ 'btn-check--ready': placedTiles.length >= currentQ.answer.length }"
        @click="checkAnswer"
      >
        確認する
      </button>
    </div>

    <!-- タイルプール -->
    <div class="tile-pool" :class="{ 'pool--disabled': isAnswered }">
      <transition-group name="tile-move" tag="div" class="tile-grid">
        <button
          v-for="tile in availableTiles"
          :key="tile.id + '-pool'"
          class="tile tile--pool"
          :disabled="isAnswered"
          @click="placeTile(tile)"
        >
          {{ tile.word }}
        </button>
      </transition-group>
    </div>

    <!-- 正解後・不正解後のアクションボタン -->
    <transition name="slide-up">
      <div v-if="isAnswered" class="answer-result-bar">
        <div class="result-indicator" :class="isCorrectAnswer ? 'result--correct' : 'result--wrong'">
          <span class="result-icon">{{ isCorrectAnswer ? '✓' : '✗' }}</span>
          <span class="result-text">{{ isCorrectAnswer ? '正解！' : 'もう一回' }}</span>
        </div>
        <button class="btn-next" @click="nextQuestion">
          {{ currentIndex + 1 < questions.length ? '次へ →' : '終了 →' }}
        </button>
      </div>
    </transition>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '@/stores/session'
import { useGameMode } from '@/composables/useGameMode'
import type { Layer3Tile } from '@/data/p001Questions'

const router = useRouter()
const sessionStore = useSessionStore()
const gameMode = useGameMode()

// ─────────────────────────────────────────────
// State
// ─────────────────────────────────────────────

const questions = gameMode.layer3Questions
const currentIndex = ref(0)

// タイル状態（pool/placed）
const availableTiles = ref<Layer3Tile[]>([])
const placedTiles    = ref<Layer3Tile[]>([])

// 回答状態
const isAnswered     = ref(false)
const isCorrectAnswer = ref(false)

// タイマー
const timerSecondsLeft = ref(0)
const totalTimeSec = computed(() => currentQ.value.timeLimitSec)
let timerInterval: ReturnType<typeof setInterval> | null = null

// Mowi演出
const mowiDialogue = ref('')
let mowiClearTimer: ReturnType<typeof setTimeout> | null = null

// ヒント（3秒後表示）
let hintTimer: ReturnType<typeof setTimeout> | null = null

// コンボ減衰演出（タイマー残り40%から）
const isDimming   = ref(false)
const isTrembling = ref(false)

// 正解数追跡
const correctInLayer3 = ref(0)

// ─────────────────────────────────────────────
// Computed
// ─────────────────────────────────────────────

const currentQ = computed(() => questions.value[currentIndex.value])

const timerPercent = computed(() =>
  Math.round((timerSecondsLeft.value / totalTimeSec.value) * 100)
)

const gaugeWidth = computed(() => {
  const c = sessionStore.combo
  if (c === 0)  return 0
  if (c >= 10)  return 100
  return Math.min(100, c * 10)
})

const gaugeStyle = computed(() => ({
  width: `${gaugeWidth.value}%`,
  background: sessionStore.combo >= 10
    ? 'linear-gradient(90deg, #ff6b6b, #ffd700, #4CAF50, #4A7AFF, #9B5CF6, #ff6b6b)'
    : sessionStore.comboColor,
  backgroundSize: sessionStore.combo >= 10 ? '200% 100%' : 'auto',
  // コンボ切れかけ：右端からグレーに（H2設計書 減衰演出）
  opacity: isDimming.value ? 0.7 : 1,
  transition: 'width 0.3s, opacity 0.8s',
}))

// タイマー残り40%でゲージ右端をグレーに
const dimOverlayStyle = computed(() => {
  const dimStart = 0.4  // 残り40%から減衰開始
  const progress = timerPercent.value / 100
  if (progress > dimStart) return { width: '0%' }
  const dimWidth = ((dimStart - progress) / dimStart) * 100
  return {
    width: `${Math.min(dimWidth, 60)}%`,
    right: '0',
    background: 'linear-gradient(to right, transparent, #333)',
  }
})

// Mowiオーブの輝度（コンボ連動 + タイマー減衰）
const orbBrightness = computed(() => {
  let br = sessionStore.brightness
  if (isDimming.value) {
    const dimFactor = timerPercent.value / 40  // 40%→0%に向かって暗くなる
    br = Math.max(1, Math.round(br * dimFactor))
  }
  return br
})

const orbStyle = computed(() => {
  const br = orbBrightness.value
  const alpha = 0.3 + (br / 10) * 0.7
  const size  = 48 + (br / 10) * 16
  return {
    width:    `${size}px`,
    height:   `${size}px`,
    background: `radial-gradient(circle at 35% 35%, rgba(160,188,255,${alpha}), #4A7AFF 60%, #2a3a8f)`,
    boxShadow:  `0 0 ${10 + br * 3}px rgba(74,122,255,${0.3 + br * 0.07})`,
    transition: 'width 0.3s, height 0.3s, box-shadow 0.3s, filter 0.8s',
    filter: isDimming.value ? `brightness(${0.5 + timerPercent.value / 80})` : 'brightness(1)',
  }
})

const glowStyle = computed(() => {
  const br = orbBrightness.value
  return {
    background: `radial-gradient(circle, rgba(74,122,255,${0.05 + br * 0.015}), transparent 70%)`,
    transition: 'background 0.3s',
  }
})

const mowiStateClass = computed(() => ({
  'mowi--joy':  sessionStore.mowiEmotionState === 'joy',
  'mowi--sad':  sessionStore.mowiEmotionState === 'sad',
  'mowi--grow': sessionStore.mowiEmotionState === 'grow',
}))

// ─────────────────────────────────────────────
// Lifecycle
// ─────────────────────────────────────────────

onMounted(async () => {
  // Layer2View で既にロード済みの場合はスキップ
  if (!gameMode.patternId.value) {
    const patternId = sessionStore.currentPattern?.patternId ?? 'P001'
    await gameMode.loadPattern(patternId)
  }
  initQuestion()
})

onUnmounted(() => {
  stopTimer()
  clearAllTimers()
})

// ─────────────────────────────────────────────
// 問題初期化
// ─────────────────────────────────────────────

function initQuestion() {
  const q = currentQ.value

  // タイルをシャッフルして pool にセット
  availableTiles.value = shuffleTiles([...q.tiles])
  placedTiles.value = []
  isAnswered.value = false
  isCorrectAnswer.value = false
  isDimming.value = false
  isTrembling.value = false
  mowiDialogue.value = ''

  sessionStore.mowiEmotionState = 'cheer'
  showMowiDialogue('体に聞いてみて。')

  // タイマー開始
  timerSecondsLeft.value = q.timeLimitSec
  startTimer()

  // ヒント（3秒後）
  hintTimer = setTimeout(() => {
    if (!isAnswered.value && q.hint) {
      showMowiDialogue(`ヒント: ${q.hint}`)
      sessionStore.mowiEmotionState = 'think'
    }
  }, 3000)
}

// ─────────────────────────────────────────────
// タイマー
// ─────────────────────────────────────────────

function startTimer() {
  stopTimer()
  timerInterval = setInterval(() => {
    if (isAnswered.value) { stopTimer(); return }

    timerSecondsLeft.value--

    // 残り40%で減衰演出開始（H2設計書準拠）
    const percent = timerPercent.value
    if (percent <= 40 && !isDimming.value) {
      isDimming.value = true
      // コンボが高い場合のみ震え演出
      if (sessionStore.combo >= 3) {
        showMowiDialogue('…消えそう。')
      }
    }

    // 残り2秒で震え
    if (timerSecondsLeft.value <= 2 && sessionStore.combo >= 3) {
      isTrembling.value = true
    }

    // タイムアウト
    if (timerSecondsLeft.value <= 0) {
      stopTimer()
      handleTimeout()
    }
  }, 1000)
}

function stopTimer() {
  if (timerInterval) {
    clearInterval(timerInterval)
    timerInterval = null
  }
}

// ─────────────────────────────────────────────
// タイル操作
// ─────────────────────────────────────────────

function placeTile(tile: Layer3Tile) {
  if (isAnswered.value) return
  const idx = availableTiles.value.findIndex(t => t.id === tile.id)
  if (idx !== -1) {
    availableTiles.value.splice(idx, 1)
    placedTiles.value.push(tile)
  }

  // placed が answer と同じ長さになったら自動チェック（任意）
  // if (placedTiles.value.length === currentQ.value.answer.length) checkAnswer()
}

function removeTile(tile: Layer3Tile) {
  if (isAnswered.value) return
  const idx = placedTiles.value.findIndex(t => t.id === tile.id)
  if (idx !== -1) {
    placedTiles.value.splice(idx, 1)
    availableTiles.value.push(tile)
  }
}

// ─────────────────────────────────────────────
// 正誤判定
// ─────────────────────────────────────────────

function checkAnswer() {
  if (isAnswered.value) return
  stopTimer()
  isDimming.value = false
  isTrembling.value = false

  const placed = placedTiles.value.map(t => t.word)
  const answer = currentQ.value.answer
  const correct = placed.length === answer.length
    && placed.every((w, i) => w === answer[i])

  isAnswered.value = true
  isCorrectAnswer.value = correct

  if (correct) {
    correctInLayer3.value++
    handleCorrect()
  } else {
    handleWrong()
  }
}

/**
 * 正解フロー（H2設計書 ⑥ 準拠）
 */
function handleCorrect() {
  sessionStore.recordAnswer(true)
  playAudio(currentQ.value.correctAudio)
  showMowiDialogue(sessionStore.mowiDialogue)
}

/**
 * 不正解フロー（H2設計書 ⑥ 不正解フロー準拠）
 */
function handleWrong() {
  sessionStore.recordAnswer(false)
  playAudio(currentQ.value.correctAudio)  // 正しい音を聞かせる
  showMowiDialogue('…なんか変。')
}

/**
 * タイムアウト
 */
function handleTimeout() {
  isAnswered.value = true
  isCorrectAnswer.value = false
  sessionStore.recordAnswer(false)
  showMowiDialogue(sessionStore.combo >= 3 ? '止まった。また積む。' : 'まだ、体になじんでない。')
}

// ─────────────────────────────────────────────
// 次の問題
// ─────────────────────────────────────────────

function nextQuestion() {
  clearAllTimers()

  if (currentIndex.value + 1 >= questions.value.length) {
    finishLayer3()
    return
  }

  currentIndex.value++
  initQuestion()
}

/**
 * Layer 3 終了 → SessionEnd へ
 */
function finishLayer3() {
  sessionStore.completeLayer3()
  router.push({ name: 'session-end' })
}

// ─────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────

function shuffleTiles<T>(arr: T[]): T[] {
  return arr
    .map(v => ({ v, r: Math.random() }))
    .sort((a, b) => a.r - b.r)
    .map(x => x.v)
}

function showMowiDialogue(text: string) {
  mowiDialogue.value = ''
  if (mowiClearTimer) clearTimeout(mowiClearTimer)
  setTimeout(() => {
    mowiDialogue.value = text
  }, 30)
  mowiClearTimer = setTimeout(() => {
    mowiDialogue.value = ''
  }, 3500)
}

function playAudio(filename?: string) {
  if (!filename) return
  const baseUrl = import.meta.env.VITE_SUPABASE_URL
  const match = filename.match(/^(P\d+)_L(\d)_(?:correct|answer)_(\d+)\.mp3$/)
  if (match) {
    const [, patternNo, layer, seq] = match
    const url = `${baseUrl}/storage/v1/object/public/mowise-audio/patterns/${patternNo}/L${layer}/${patternNo}_L${layer}_answer_${seq}.mp3`
    const audio = new Audio(url)
    audio.play().catch((e) => console.warn('[Audio] play failed:', e))
  }
}

function clearAllTimers() {
  stopTimer()
  if (mowiClearTimer) clearTimeout(mowiClearTimer)
  if (hintTimer)      clearTimeout(hintTimer)
}

function confirmExit() {
  stopTimer()
  router.push({ name: 'Home' })
}
</script>

<style scoped>
/* ─────────────────────────────────────────────
   ベース
───────────────────────────────────────────── */
.layer3-screen {
  min-height: 100vh;
  background: #0d0d1a;
  color: #f0f0ff;
  display: flex;
  flex-direction: column;
  font-family: 'Noto Sans JP', sans-serif;
  overflow: hidden;
  user-select: none;
}

/* ─────────────────────────────────────────────
   ヘッダー
───────────────────────────────────────────── */
.l3-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.9rem 1.25rem;
  border-bottom: 1px solid rgba(255,255,255,0.07);
  flex-shrink: 0;
}

.btn-exit {
  background: none;
  border: none;
  color: rgba(255,255,255,0.45);
  font-size: 0.85rem;
  cursor: pointer;
  transition: color 0.2s;
}
.btn-exit:hover { color: #fff; }

.l3-header__title {
  font-size: 0.9rem;
  color: rgba(255,255,255,0.6);
  letter-spacing: 0.1em;
}

.l3-header__progress {
  font-size: 0.85rem;
  color: #4A7AFF;
  font-weight: 700;
}

/* ─────────────────────────────────────────────
   コンボゲージ
───────────────────────────────────────────── */
.combo-gauge-wrap {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.6rem 1.25rem 0.4rem;
  flex-shrink: 0;
}

.combo-gauge {
  flex: 1;
  height: 6px;
  background: rgba(255,255,255,0.08);
  border-radius: 3px;
  overflow: hidden;
  position: relative;
}

.combo-gauge__fill {
  height: 100%;
  border-radius: 3px;
  transition: width 0.3s cubic-bezier(.4,0,.2,1), background 0.4s;
}

.combo-gauge__fill.is-pulsing {
  animation: gauge-pulse 1.2s ease-in-out infinite;
}

.combo-gauge__fill.is-rainbow {
  animation: rainbow-slide 1.5s linear infinite;
  background-size: 200% 100% !important;
}

.gauge-dim-overlay {
  position: absolute;
  top: 0;
  bottom: 0;
  border-radius: 0 3px 3px 0;
  transition: width 1s linear;
  pointer-events: none;
}

.combo-text {
  font-size: 0.8rem;
  font-weight: 700;
  min-width: 32px;
  text-align: right;
  transition: color 0.3s;
}

/* ─────────────────────────────────────────────
   Mowi エリア
───────────────────────────────────────────── */
.mowi-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 0.75rem 1rem 0.5rem;
  gap: 0.5rem;
  min-height: 110px;
  flex-shrink: 0;
  transition: filter 0.8s;
}

.mowi-area--dimming {
  /* コンボ切れかけ：全体がじんわり暗くなる */
  filter: brightness(0.8) saturate(0.8);
}

.mowi-orb-wrap {
  position: relative;
  width: 80px;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.4s;
}

.orb-core {
  border-radius: 50%;
  transition: width 0.4s, height 0.4s, box-shadow 0.4s;
  animation: float-idle 3s ease-in-out infinite;
}

.orb-core.orb--trembling {
  animation: float-idle 3s ease-in-out infinite, tremble 0.15s linear infinite;
}

.orb-glow {
  position: absolute;
  inset: -12px;
  border-radius: 50%;
  animation: float-idle 3s ease-in-out infinite reverse;
}

.mowi--joy .orb-core {
  animation: float-idle 3s ease-in-out infinite, joy-bounce 0.4s ease-out;
}

.mowi--sad .mowi-orb-wrap {
  transform: translateY(6px);
  filter: brightness(0.65) saturate(0.4);
}

.mowi-dialogue {
  font-size: 1rem;
  color: rgba(255,255,255,0.65);
  letter-spacing: 0.06em;
  text-align: center;
  font-style: italic;
  min-height: 1.5rem;
  transition: color 0.3s;
}

/* ─────────────────────────────────────────────
   問題エリア（プロンプト + タイマー）
───────────────────────────────────────────── */
.question-area {
  padding: 0.5rem 1.5rem 0.75rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  border-bottom: 1px solid rgba(255,255,255,0.06);
  flex-shrink: 0;
}

.prompt-ja {
  font-size: 1.15rem;
  font-weight: 600;
  color: rgba(255,255,255,0.9);
  text-align: center;
  letter-spacing: 0.04em;
}

.timer-wrap {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  width: 100%;
}

.timer-icon {
  font-size: 0.9rem;
}

.timer-bar {
  flex: 1;
  height: 5px;
  background: rgba(255,255,255,0.1);
  border-radius: 3px;
  overflow: hidden;
}

.timer-fill {
  height: 100%;
  border-radius: 3px;
  background: #4A7AFF;
  transition: width 0.8s linear, background 0.3s;
}

.timer-fill.timer--warning {
  background: #FF9800;
}

.timer-fill.timer--critical {
  background: #F44336;
  animation: timer-blink 0.5s step-end infinite;
}

.timer-sec {
  font-size: 0.8rem;
  color: rgba(255,255,255,0.5);
  min-width: 28px;
  text-align: right;
  transition: color 0.3s;
}
.timer-sec.text--warning { color: #FF9800; font-weight: 700; }

/* ─────────────────────────────────────────────
   組み立てエリア
───────────────────────────────────────────── */
.build-area {
  padding: 0.75rem 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  min-height: 80px;
  flex-shrink: 0;
}

.build-slots {
  min-height: 52px;
  background: rgba(255,255,255,0.03);
  border: 1.5px dashed rgba(255,255,255,0.12);
  border-radius: 12px;
  padding: 0.6rem 0.75rem;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 0.4rem;
}

.placed-tiles {
  display: flex;
  flex-wrap: wrap;
  gap: 0.4rem;
  width: 100%;
}

.build-placeholder {
  font-size: 0.85rem;
  color: rgba(255,255,255,0.25);
  letter-spacing: 0.05em;
}

.correct-sentence-label {
  font-size: 0.9rem;
  color: #81c784;
  font-weight: 600;
  letter-spacing: 0.04em;
  width: 100%;
  text-align: center;
}

.btn-check {
  align-self: flex-end;
  padding: 0.5rem 1.25rem;
  background: rgba(74,122,255,0.1);
  border: 1.5px solid rgba(74,122,255,0.25);
  border-radius: 20px;
  color: rgba(74,122,255,0.7);
  font-size: 0.9rem;
  font-family: 'Noto Sans JP', sans-serif;
  cursor: pointer;
  transition: background 0.2s, border-color 0.2s, color 0.2s;
}

.btn-check.btn-check--ready {
  background: linear-gradient(135deg, #4A7AFF, #9B5CF6);
  border-color: transparent;
  color: white;
  font-weight: 700;
  box-shadow: 0 3px 14px rgba(74,122,255,0.35);
}

.btn-check:hover:not(:disabled) {
  opacity: 0.9;
}

/* ─────────────────────────────────────────────
   タイルスタイル（共通）
───────────────────────────────────────────── */
.tile {
  padding: 0.45rem 0.8rem;
  border-radius: 8px;
  font-size: 1rem;
  font-weight: 700;
  letter-spacing: 0.04em;
  cursor: pointer;
  transition: transform 0.12s, background 0.15s, opacity 0.15s;
  font-family: 'Noto Sans JP', sans-serif;
}

.tile:active:not(:disabled) {
  transform: scale(0.93);
}

/* Pool タイル */
.tile--pool {
  background: rgba(255,255,255,0.07);
  border: 1.5px solid rgba(255,255,255,0.13);
  color: #f0f0ff;
}

.tile--pool:hover:not(:disabled) {
  background: rgba(74,122,255,0.15);
  border-color: rgba(74,122,255,0.4);
  transform: scale(1.05) translateY(-2px);
}

/* Placed タイル */
.tile--placed {
  background: rgba(74,122,255,0.18);
  border: 1.5px solid rgba(74,122,255,0.45);
  color: #a8c4ff;
}

.tile--placed:hover:not(:disabled) {
  background: rgba(244,67,54,0.12);
  border-color: rgba(244,67,54,0.3);
  color: #ef9a9a;
}

.tile--correct {
  background: rgba(76,175,80,0.18) !important;
  border-color: #4CAF50 !important;
  color: #a5d6a7 !important;
  animation: correct-flash 0.3s ease-out;
}

.tile--wrong {
  background: rgba(244,67,54,0.15) !important;
  border-color: #F44336 !important;
  color: #ef9a9a !important;
  animation: wrong-shake 0.35s ease-out;
}

/* ─────────────────────────────────────────────
   タイルプール
───────────────────────────────────────────── */
.tile-pool {
  padding: 0.75rem 1.25rem 1.5rem;
  flex: 1;
  border-top: 1px solid rgba(255,255,255,0.06);
}

.tile-pool.pool--disabled {
  opacity: 0.4;
  pointer-events: none;
}

.tile-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}

/* ─────────────────────────────────────────────
   正解・不正解バー
───────────────────────────────────────────── */
.answer-result-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(13, 13, 26, 0.97);
  border-top: 1px solid rgba(255,255,255,0.08);
  padding: 1rem 1.25rem 1.75rem;
  display: flex;
  align-items: center;
  justify-content: space-between;
  backdrop-filter: blur(12px);
  z-index: 100;
}

.result-indicator {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.result-icon {
  font-size: 1.25rem;
  font-weight: 900;
}

.result-text {
  font-size: 1rem;
  font-weight: 700;
}

.result--correct .result-icon,
.result--correct .result-text { color: #4CAF50; }

.result--wrong .result-icon,
.result--wrong .result-text { color: #F44336; }

.btn-next {
  background: linear-gradient(135deg, #4A7AFF, #9B5CF6);
  border: none;
  border-radius: 24px;
  color: white;
  font-size: 0.95rem;
  font-weight: 700;
  padding: 0.6rem 1.75rem;
  cursor: pointer;
  font-family: 'Noto Sans JP', sans-serif;
  box-shadow: 0 3px 14px rgba(74,122,255,0.35);
  transition: opacity 0.2s;
}
.btn-next:hover { opacity: 0.9; }

/* ─────────────────────────────────────────────
   Transitions
───────────────────────────────────────────── */
.fade-text-enter-active,
.fade-text-leave-active { transition: opacity 0.3s; }
.fade-text-enter-from,
.fade-text-leave-to { opacity: 0; }

.slide-up-enter-active { transition: transform 0.35s cubic-bezier(.4,0,.2,1), opacity 0.3s; }
.slide-up-leave-active { transition: transform 0.25s ease-in, opacity 0.2s; }
.slide-up-enter-from   { transform: translateY(100%); opacity: 0; }
.slide-up-leave-to     { transform: translateY(100%); opacity: 0; }

.tile-move-move {
  transition: transform 0.2s ease;
}

/* ─────────────────────────────────────────────
   Keyframes
───────────────────────────────────────────── */
@keyframes float-idle {
  0%, 100% { transform: translateY(0); }
  50%       { transform: translateY(-6px); }
}

@keyframes joy-bounce {
  0%   { transform: translateY(0) scale(1); }
  30%  { transform: translateY(-14px) scale(1.1); }
  60%  { transform: translateY(-4px) scale(1.03); }
  100% { transform: translateY(0) scale(1); }
}

@keyframes tremble {
  0%   { transform: translateX(0) translateY(var(--float-offset, 0)); }
  25%  { transform: translateX(-2px); }
  75%  { transform: translateX(2px); }
  100% { transform: translateX(0); }
}

@keyframes correct-flash {
  0%   { background: rgba(76,175,80,0.6) !important; }
  100% { background: rgba(76,175,80,0.18) !important; }
}

@keyframes wrong-shake {
  0%   { transform: translateX(0); }
  20%  { transform: translateX(-5px); }
  40%  { transform: translateX(4px); }
  60%  { transform: translateX(-3px); }
  80%  { transform: translateX(2px); }
  100% { transform: translateX(0); }
}

@keyframes gauge-pulse {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.65; }
}

@keyframes rainbow-slide {
  0%   { background-position: 0% 50%; }
  100% { background-position: 200% 50%; }
}

@keyframes timer-blink {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.4; }
}
</style>
