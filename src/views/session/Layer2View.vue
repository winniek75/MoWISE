<template>
  <div class="layer2-screen">

    <!-- ヘッダー -->
    <header class="l2-header">
      <button class="btn-exit" @click="confirmExit">← 終了</button>
      <span class="l2-header__title">{{ gameMode.patternId.value }} &nbsp; Layer 2</span>
      <span class="l2-header__progress">{{ currentIndex + 1 }} / {{ questions.length }}問</span>
    </header>

    <!-- コンボゲージ -->
    <div class="combo-gauge-wrap">
      <div class="combo-gauge">
        <div
          class="combo-gauge__fill"
          :class="{ 'is-rainbow': sessionStore.combo >= 10, 'is-pulsing': sessionStore.combo >= 5 }"
          :style="gaugeStyle"
        />
      </div>
      <span v-if="sessionStore.combo >= 3" class="combo-text" :style="{ color: sessionStore.comboColor }">
        {{ sessionStore.combo }}
      </span>
    </div>

    <!-- Mowi エリア -->
    <div class="mowi-area">
      <div class="mowi-orb-wrap" :class="mowiStateClass">
        <div class="orb-core" :style="orbStyle" />
        <div class="orb-glow" :style="glowStyle" />
        <!-- 実装時は MowiOrb.vue に差し替え -->
        <!-- <MowiOrb :state="sessionStore.mowiEmotionState" :brightness="sessionStore.brightness" size="md" /> -->
      </div>
      <transition name="fade-text">
        <p v-if="mowiDialogue" class="mowi-dialogue">{{ mowiDialogue }}</p>
      </transition>
    </div>

    <!-- 問題エリア -->
    <div v-if="currentQ" class="question-area">
      <!-- 日本語プロンプト -->
      <p class="prompt-ja">{{ currentQ.promptJa }}</p>

      <!-- スロット表示 -->
      <div class="slot-row">
        <span class="slot-prefix">{{ currentQ.slotPrefix }}</span>
        <span
          class="slot-blank"
          :class="{
            'slot--filled':    selectedChoice !== null,
            'slot--correct':   isAnswered && selectedChoice?.isCorrect,
            'slot--wrong':     isAnswered && selectedChoice && !selectedChoice.isCorrect,
          }"
        >
          {{ selectedChoice ? selectedChoice.text : '___' }}
        </span>
        <span v-if="currentQ.slotSuffix" class="slot-suffix">{{ currentQ.slotSuffix }}</span>
      </div>
    </div>

    <!-- 選択肢 -->
    <div class="choices-grid">
      <button
        v-for="choice in currentQ.choices"
        :key="choice.id"
        class="choice-btn"
        :class="{
          'is-selected':   selectedChoice?.id === choice.id && !isAnswered,
          'is-correct':    isAnswered && choice.isCorrect,
          'is-wrong':      isAnswered && selectedChoice?.id === choice.id && !choice.isCorrect,
          'is-dimmed':     isAnswered && !choice.isCorrect && selectedChoice?.id !== choice.id,
        }"
        :disabled="isAnswered"
        @click="selectAnswer(choice)"
      >
        <span class="choice-label">{{ choice.text }}</span>
      </button>
    </div>

    <!-- 不正解後パネル -->
    <transition name="slide-up">
      <div v-if="showWrongPanel" class="wrong-panel">
        <div class="wrong-panel__inner">

          <!-- 「なぜ？」ボタン（任意） -->
          <transition name="fade-text">
            <button
              v-if="!showExplanation"
              class="btn-why"
              @click="showExplanation = true"
            >
              なぜ？
            </button>
          </transition>

          <!-- 解説テキスト -->
          <transition name="fade-text">
            <div v-if="showExplanation" class="explanation-box">
              <p class="explanation-text">{{ currentQ.explanation }}</p>
            </div>
          </transition>

          <!-- 次へボタン -->
          <button class="btn-next" @click="nextQuestion">
            次へ →
          </button>
        </div>
      </div>
    </transition>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '@/stores/session'
import { useGameMode } from '@/composables/useGameMode'
import type { Layer2Choice } from '@/data/p001Questions'

const router = useRouter()
const sessionStore = useSessionStore()
const gameMode = useGameMode()

// ── State ──

const questions = gameMode.layer2Questions
const currentIndex = ref(0)
const selectedChoice = ref<Layer2Choice | null>(null)
const isAnswered = ref(false)
const showWrongPanel = ref(false)
const showExplanation = ref(false)

// Mowiセリフの表示制御
const mowiDialogue = ref<string>('')
let mowiClearTimer: ReturnType<typeof setTimeout> | null = null

// 正解後の自動進行タイマー
let autoNextTimer: ReturnType<typeof setTimeout> | null = null

// 正解数の追跡（Layer 2 クリア判定用）
const correctInLayer2 = ref(0)

// ── Computed ──

const currentQ = computed(() => questions.value[currentIndex.value])

/**
 * コンボゲージのfill幅（0〜100%）
 * コンボ 0=0%, 1=8%, 2=16%, 3=30%, 5=50%, 7=70%, 10=100%
 */
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
}))

const orbStyle = computed(() => {
  const br = sessionStore.brightness
  const alpha = 0.3 + (br / 10) * 0.7
  const size = 48 + (br / 10) * 16
  return {
    width: `${size}px`,
    height: `${size}px`,
    background: `radial-gradient(circle at 35% 35%, rgba(160,188,255,${alpha}), #4A7AFF 60%, #2a3a8f)`,
    boxShadow: `0 0 ${10 + br * 3}px rgba(74,122,255,${0.3 + br * 0.07})`,
  }
})

const glowStyle = computed(() => {
  const br = sessionStore.brightness
  return {
    background: `radial-gradient(circle, rgba(74,122,255,${0.05 + br * 0.015}), transparent 70%)`,
  }
})

const mowiStateClass = computed(() => {
  const state = sessionStore.mowiEmotionState
  return {
    'mowi--joy':  state === 'joy',
    'mowi--sad':  state === 'sad',
    'mowi--grow': state === 'grow',
  }
})

// ── Lifecycle ──

onMounted(async () => {
  const patternId = sessionStore.currentPattern?.patternId ?? 'P001'
  await gameMode.loadPattern(patternId)
  sessionStore.mowiEmotionState = 'cheer'
  showMowiDialogue('言ってみる。')
})

onUnmounted(() => {
  clearAllTimers()
})

// ── Core Logic ──

/**
 * 選択肢タップ → 正誤判定
 */
function selectAnswer(choice: Layer2Choice) {
  if (isAnswered.value) return

  selectedChoice.value = choice
  isAnswered.value = true

  if (choice.isCorrect) {
    handleCorrect()
  } else {
    handleWrong(choice)
  }
}

/**
 * 正解フロー
 * H2設計書 ⑥ 正解フロー（800ms以内に次問へ）準拠
 */
function handleCorrect() {
  correctInLayer2.value++
  sessionStore.recordAnswer(true)

  // 正解音再生（stub）
  playAudio(currentQ.value.correctAudio)

  // Mowiセリフを store から取得（store が更新済み）
  showMowiDialogue(sessionStore.mowiDialogue)

  // 800ms後に次問へ自動進行
  autoNextTimer = setTimeout(() => {
    nextQuestion()
  }, 900)
}

/**
 * 不正解フロー
 * H2設計書 「なんか変」演出準拠
 * ① 赤ハイライト → ② 不自然音再生 → ③ Mowi「なんか変」
 * → ④ 正解ボタン緑 → ⑤「なぜ？」ボタン（任意）
 */
function handleWrong(_choice: Layer2Choice) {
  sessionStore.recordAnswer(false)

  // ① 即座に赤ハイライト（isAnswered=true で即反映）

  // ② 不正解音声再生（300ms後）
  setTimeout(() => {
    playWrongAudio(currentQ.value.fullSentence)
  }, 300)

  // ③ Mowi「なんか変」+ Sadアニメ
  setTimeout(() => {
    showMowiDialogue('…なんか変。')
  }, 300)

  // ④ 正解音声（正しい音を聞かせる）
  setTimeout(() => {
    playAudio(currentQ.value.correctAudio)
  }, 1200)

  // ⑤ 「なぜ？」パネル表示
  setTimeout(() => {
    showWrongPanel.value = true
    showExplanation.value = false
  }, 1400)
}

/**
 * 次の問題へ
 */
function nextQuestion() {
  clearAllTimers()
  showWrongPanel.value = false
  showExplanation.value = false
  selectedChoice.value = null
  isAnswered.value = false
  mowiDialogue.value = ''

  if (currentIndex.value + 1 >= questions.value.length) {
    // Layer 2 全問完了
    finishLayer2()
  } else {
    currentIndex.value++
    sessionStore.mowiEmotionState = 'cheer'

    // 次問Cheerセリフ
    const cheerLines = ['知ってる。出てくるはず。', '体に聞いてみて。', '最初の一語、そこから。', 'まず、言ってみる。']
    showMowiDialogue(cheerLines[currentIndex.value % cheerLines.length])
  }
}

/**
 * Layer 2 終了 → Layer 3 へ
 * クリア基準：6問中5問正解
 */
function finishLayer2() {
  sessionStore.completeLayer2()
  router.push({ name: 'session-layer3' })
}

// ── Helpers ──

function showMowiDialogue(text: string) {
  mowiDialogue.value = ''
  if (mowiClearTimer) clearTimeout(mowiClearTimer)
  // 次tick で表示（transition 発火のため）
  setTimeout(() => {
    mowiDialogue.value = text
  }, 30)
  // 4秒後に消す
  mowiClearTimer = setTimeout(() => {
    mowiDialogue.value = ''
  }, 4000)
}

function playAudio(filename?: string) {
  if (!filename) return
  const baseUrl = import.meta.env.VITE_SUPABASE_URL
  // ファイル名から pattern_no を抽出してStorageパスを構築
  // 例: P001_L3_correct_1.mp3 → patterns/P001/L3/P001_L3_answer_1.mp3
  const match = filename.match(/^(P\d+)_L(\d)_(?:correct|answer)_(\d+)\.mp3$/)
  if (match) {
    const [, patternNo, layer, seq] = match
    const url = `${baseUrl}/storage/v1/object/public/mowise-audio/patterns/${patternNo}/L${layer}/${patternNo}_L${layer}_answer_${seq}.mp3`
    const audio = new Audio(url)
    audio.play().catch((e) => console.warn('[Audio] play failed:', e))
  }
}

function playWrongAudio(_sentence: string) {
  // 不正解時の音声は現在未実装（MVPでは省略）
}

function clearAllTimers() {
  if (autoNextTimer)  clearTimeout(autoNextTimer)
  if (mowiClearTimer) clearTimeout(mowiClearTimer)
}

function confirmExit() {
  // TODO: 確認ダイアログ後に home へ
  clearAllTimers()
  router.push({ name: 'Home' })
}
</script>

<style scoped>
/* ─────────────────────────────────────────────
   ベース
───────────────────────────────────────────── */
.layer2-screen {
  min-height: 100vh;
  background: #0d0d1a;
  color: #f0f0ff;
  display: flex;
  flex-direction: column;
  font-family: 'Noto Sans JP', sans-serif;
  overflow: hidden;
}

/* ─────────────────────────────────────────────
   ヘッダー
───────────────────────────────────────────── */
.l2-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.9rem 1.25rem;
  border-bottom: 1px solid rgba(255,255,255,0.07);
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

.l2-header__title {
  font-size: 0.9rem;
  color: rgba(255,255,255,0.6);
  letter-spacing: 0.1em;
}

.l2-header__progress {
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
}

.combo-gauge {
  flex: 1;
  height: 6px;
  background: rgba(255,255,255,0.08);
  border-radius: 3px;
  overflow: hidden;
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
  padding: 1.5rem 1rem 0.75rem;
  gap: 0.75rem;
  min-height: 130px;
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

.orb-glow {
  position: absolute;
  inset: -12px;
  border-radius: 50%;
  transition: background 0.4s;
  animation: float-idle 3s ease-in-out infinite reverse;
}

/* Joy: 上に弾む */
.mowi--joy .orb-core {
  animation: float-idle 3s ease-in-out infinite, joy-bounce 0.4s ease-out;
}

/* Sad: うなだれる */
.mowi--sad .mowi-orb-wrap {
  transform: translateY(6px);
  filter: brightness(0.7) saturate(0.5);
}

/* Grow: 輝き増す */
.mowi--grow .orb-core {
  animation: float-idle 3s ease-in-out infinite, grow-pulse 0.6s ease-out;
}

.mowi-dialogue {
  font-size: 1rem;
  color: rgba(255,255,255,0.65);
  letter-spacing: 0.06em;
  text-align: center;
  font-style: italic;
  min-height: 1.5rem;
}

/* ─────────────────────────────────────────────
   問題エリア
───────────────────────────────────────────── */
.question-area {
  padding: 0.5rem 1.5rem 1.25rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
  border-bottom: 1px solid rgba(255,255,255,0.06);
}

.prompt-ja {
  font-size: 1.1rem;
  color: rgba(255,255,255,0.55);
  text-align: center;
  letter-spacing: 0.03em;
}

.slot-row {
  display: flex;
  align-items: baseline;
  gap: 0.5rem;
  font-size: 1.5rem;
  font-weight: 700;
  letter-spacing: 0.04em;
}

.slot-prefix,
.slot-suffix {
  color: #f0f0ff;
}

.slot-blank {
  min-width: 80px;
  padding: 0.15rem 0.6rem;
  border-radius: 8px;
  text-align: center;
  border: 2px dashed rgba(74, 122, 255, 0.5);
  color: rgba(74,122,255,0.8);
  font-size: 1.2rem;
  transition: border-color 0.2s, background 0.2s, color 0.2s;
  background: rgba(74,122,255,0.06);
}

.slot-blank.slot--filled {
  border-style: solid;
  border-color: rgba(74,122,255,0.7);
  color: #f0f0ff;
}

.slot-blank.slot--correct {
  border-color: #4CAF50;
  background: rgba(76,175,80,0.12);
  color: #81c784;
}

.slot-blank.slot--wrong {
  border-color: #F44336;
  background: rgba(244,67,54,0.12);
  color: #ef9a9a;
}

/* ─────────────────────────────────────────────
   選択肢
───────────────────────────────────────────── */
.choices-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.75rem;
  padding: 1.25rem 1.25rem;
}

.choice-btn {
  background: rgba(255,255,255,0.04);
  border: 1.5px solid rgba(255,255,255,0.1);
  border-radius: 12px;
  padding: 0.9rem 0.75rem;
  color: #f0f0ff;
  font-size: 1rem;
  font-weight: 600;
  cursor: pointer;
  transition: background 0.15s, border-color 0.15s, transform 0.1s;
  text-align: center;
  font-family: 'Noto Sans JP', sans-serif;
  letter-spacing: 0.03em;
}

.choice-btn:hover:not(:disabled) {
  background: rgba(74,122,255,0.12);
  border-color: rgba(74,122,255,0.4);
  transform: scale(1.02);
}

.choice-btn:active:not(:disabled) {
  transform: scale(0.97);
}

.choice-btn.is-selected {
  background: rgba(74,122,255,0.18);
  border-color: #4A7AFF;
}

.choice-btn.is-correct {
  background: rgba(76,175,80,0.15);
  border-color: #4CAF50;
  color: #a5d6a7;
  animation: correct-flash 0.3s ease-out;
}

.choice-btn.is-wrong {
  background: rgba(244,67,54,0.15);
  border-color: #F44336;
  color: #ef9a9a;
  animation: wrong-shake 0.35s ease-out;
}

.choice-btn.is-dimmed {
  opacity: 0.3;
}

.choice-btn:disabled {
  cursor: default;
}

.choice-label {
  font-size: 0.95rem;
}

/* ─────────────────────────────────────────────
   不正解パネル
───────────────────────────────────────────── */
.wrong-panel {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: rgba(18, 18, 35, 0.97);
  border-top: 1px solid rgba(255,255,255,0.08);
  padding: 1.25rem 1.25rem 2rem;
  backdrop-filter: blur(12px);
  z-index: 100;
}

.wrong-panel__inner {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  align-items: flex-start;
}

.btn-why {
  background: rgba(74,122,255,0.12);
  border: 1px solid rgba(74,122,255,0.3);
  border-radius: 20px;
  color: #7ba8ff;
  font-size: 0.9rem;
  padding: 0.4rem 1.25rem;
  cursor: pointer;
  font-family: 'Noto Sans JP', sans-serif;
  transition: background 0.2s;
}
.btn-why:hover { background: rgba(74,122,255,0.2); }

.explanation-box {
  width: 100%;
  background: rgba(255,255,255,0.04);
  border-radius: 10px;
  padding: 0.75rem 1rem;
}

.explanation-text {
  font-size: 0.9rem;
  color: rgba(255,255,255,0.65);
  line-height: 1.7;
  letter-spacing: 0.02em;
}

.btn-next {
  align-self: flex-end;
  background: linear-gradient(135deg, #4A7AFF, #9B5CF6);
  border: none;
  border-radius: 24px;
  color: white;
  font-size: 0.95rem;
  font-weight: 700;
  padding: 0.6rem 1.75rem;
  cursor: pointer;
  font-family: 'Noto Sans JP', sans-serif;
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

/* ─────────────────────────────────────────────
   Keyframes
───────────────────────────────────────────── */
@keyframes float-idle {
  0%, 100% { transform: translateY(0); }
  50%       { transform: translateY(-6px); }
}

@keyframes joy-bounce {
  0%   { transform: translateY(0) scale(1); }
  30%  { transform: translateY(-14px) scale(1.08); }
  60%  { transform: translateY(-4px) scale(1.03); }
  100% { transform: translateY(0) scale(1); }
}

@keyframes grow-pulse {
  0%   { box-shadow: 0 0 10px rgba(74,122,255,0.4); }
  50%  { box-shadow: 0 0 40px rgba(74,122,255,0.9), 0 0 80px rgba(155,92,246,0.5); }
  100% { box-shadow: 0 0 10px rgba(74,122,255,0.4); }
}

@keyframes correct-flash {
  0%   { background: rgba(76,175,80,0.5); }
  100% { background: rgba(76,175,80,0.15); }
}

@keyframes wrong-shake {
  0%   { transform: translateX(0); }
  20%  { transform: translateX(-6px); }
  40%  { transform: translateX(5px); }
  60%  { transform: translateX(-4px); }
  80%  { transform: translateX(3px); }
  100% { transform: translateX(0); }
}

@keyframes gauge-pulse {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.7; }
}

@keyframes rainbow-slide {
  0%   { background-position: 0% 50%; }
  100% { background-position: 200% 50%; }
}
</style>
