<template>
  <div class="layer0-screen">

    <!-- ヘッダー -->
    <header class="l0-header">
      <button class="btn-exit" @click="confirmExit">← 終了</button>
      <span class="l0-header__title">{{ patternId }} &nbsp; Layer 0</span>
      <span class="l0-header__progress">{{ currentIndex + 1 }} / {{ questions.length }}問</span>
    </header>

    <!-- Mowi エリア -->
    <div class="mowi-area">
      <MowiOrb
        :state="mowiState"
        :brightness="sessionStore.brightness"
        size="md"
        :animated="true"
      />
      <transition name="fade-text">
        <p v-if="mowiLine" class="mowi-dialogue">{{ mowiLine }}</p>
      </transition>
    </div>

    <!-- 問題エリア -->
    <div v-if="currentQ" class="question-area">

      <!-- フェーズ1: 聞き比べ -->
      <div v-if="phase === 'listen'" class="listen-phase">
        <p class="phase-label">── 聞き比べてみよう ──</p>
        <p class="meaning-ja">{{ currentQ.meaningJa }}</p>

        <div class="audio-buttons">
          <button
            class="audio-btn audio-btn--slow"
            :class="{ 'is-playing': playingType === 'slow' }"
            @click="playSlow"
          >
            <span class="audio-btn__icon">🐢</span>
            <span class="audio-btn__label">ゆっくり</span>
          </button>

          <button
            class="audio-btn audio-btn--natural"
            :class="{ 'is-playing': playingType === 'natural' }"
            @click="playNatural"
          >
            <span class="audio-btn__icon">⚡</span>
            <span class="audio-btn__label">ナチュラル</span>
          </button>
        </div>

        <!-- テキスト表示（再生後に表示） -->
        <transition name="fade-text">
          <div v-if="showTexts" class="text-compare">
            <p class="text-slow">{{ currentQ.slowText }}</p>
            <p class="text-natural">{{ currentQ.naturalText }}</p>
          </div>
        </transition>

        <button
          class="btn-next"
          :disabled="listenCount < 2"
          @click="goToQuiz"
        >
          {{ listenCount < 2 ? 'どちらも聞いてみよう' : 'クイズに挑戦' }}
        </button>
      </div>

      <!-- フェーズ2: クイズ -->
      <div v-if="phase === 'quiz'" class="quiz-phase">
        <p class="phase-label">── ナチュラルに聞こえるのはどっち？ ──</p>

        <div class="quiz-options">
          <button
            v-for="opt in currentQ.quiz.options"
            :key="opt.id"
            class="quiz-option"
            :class="{
              'is-selected': selectedOption === opt.id,
              'is-correct': isAnswered && opt.isNatural,
              'is-wrong': isAnswered && selectedOption === opt.id && !opt.isNatural,
            }"
            :disabled="isAnswered"
            @click="selectOption(opt)"
          >
            {{ opt.text }}
          </button>
        </div>

        <!-- 解説 -->
        <transition name="fade-text">
          <div v-if="isAnswered" class="explanation-card">
            <p class="explanation-text">{{ currentQ.quiz.explanation }}</p>
          </div>
        </transition>

        <button
          v-if="isAnswered"
          class="btn-next"
          @click="nextQuestion"
        >
          {{ isLast ? 'Layer 0 完了' : '次の問題' }}
        </button>
      </div>

    </div>

    <!-- 終了確認ダイアログ -->
    <Transition name="overlay-fade">
      <div v-if="showExitDialog" class="exit-overlay">
        <div class="exit-dialog">
          <p class="exit-title">練習を終了しますか？</p>
          <p class="exit-sub">今回の記録は保存されます</p>
          <div class="exit-btns">
            <button class="exit-btn exit-btn--cancel" @click="showExitDialog = false">続ける</button>
            <button class="exit-btn exit-btn--confirm" @click="exitSession">やめる</button>
          </div>
        </div>
      </div>
    </Transition>

  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '@/stores/session'
import { playSlowAudio, playNaturalAudio, stopCurrent } from '@/composables/useMowiseAudio'
import { getLayer0Questions } from '@/data/patternRegistry'
import MowiOrb from '@/components/mowi/MowiOrb.vue'
import type { Layer0Question } from '@/data/layerTypes'
import type { MowiEmotionState } from '@/stores/session'

const router = useRouter()
const sessionStore = useSessionStore()

// ── パターンID ──
const patternId = computed(() => sessionStore.currentPattern?.patternId ?? 'P001')
const questions = computed(() => getLayer0Questions(patternId.value))

// ── 問題進行 ──
const currentIndex = ref(0)
const currentQ = computed<Layer0Question | null>(() => questions.value[currentIndex.value] ?? null)
const isLast = computed(() => currentIndex.value >= questions.value.length - 1)

// ── フェーズ管理 ──
const phase = ref<'listen' | 'quiz'>('listen')
const listenCount = ref(0)
const showTexts = ref(false)
const playingType = ref<'slow' | 'natural' | null>(null)

// ── クイズ ──
const selectedOption = ref<string | null>(null)
const isAnswered = ref(false)

// ── Mowi ──
const mowiState = ref<MowiEmotionState>('idle')
const mowiLine = ref('音を聞いてみよう。')

// ── 終了ダイアログ ──
const showExitDialog = ref(false)

// ── Audio ──
async function playSlow() {
  if (!currentQ.value) return
  stopCurrent()
  playingType.value = 'slow'
  mowiLine.value = 'ゆっくり聞いてみて。'
  await playSlowAudio(currentQ.value.slowAudio, currentQ.value.slowText)
  listenCount.value = Math.max(listenCount.value, 1)
  showTexts.value = true
  setTimeout(() => { playingType.value = null }, 2000)
}

async function playNatural() {
  if (!currentQ.value) return
  stopCurrent()
  playingType.value = 'natural'
  mowiLine.value = '今度はナチュラル。違い、聞こえた？'
  await playNaturalAudio(currentQ.value.naturalAudio, currentQ.value.naturalText)
  listenCount.value = 2
  showTexts.value = true
  setTimeout(() => { playingType.value = null }, 2000)
}

// ── Phase transition ──
function goToQuiz() {
  phase.value = 'quiz'
  mowiLine.value = 'どっちが自然に聞こえた？'
  mowiState.value = 'think'
}

function selectOption(opt: { id: string; isNatural: boolean }) {
  selectedOption.value = opt.id
  isAnswered.value = true

  if (opt.isNatural) {
    sessionStore.recordAnswer(true)
    mowiState.value = 'joy'
    mowiLine.value = '聞こえてる。その耳、いいよ。'
  } else {
    sessionStore.recordAnswer(false)
    mowiState.value = 'sad'
    mowiLine.value = 'もう一回聞くと、違いがわかるよ。'
  }
}

function nextQuestion() {
  if (isLast.value) {
    // Layer 0 完了 → Layer 1 へ
    router.push({ name: 'session-layer1' })
    return
  }
  // 次の問題へリセット
  currentIndex.value++
  phase.value = 'listen'
  listenCount.value = 0
  showTexts.value = false
  playingType.value = null
  selectedOption.value = null
  isAnswered.value = false
  mowiState.value = 'idle'
  mowiLine.value = '音を聞いてみよう。'
}

// ── Exit ──
function confirmExit() {
  showExitDialog.value = true
}

function exitSession() {
  showExitDialog.value = false
  router.push({ name: 'session-end' })
}
</script>

<style scoped>
.layer0-screen {
  min-height: 100vh;
  background: #0d0d1a;
  color: #f0f0ff;
  display: flex;
  flex-direction: column;
  font-family: 'Noto Sans JP', sans-serif;
  padding-bottom: 2rem;
}

/* ヘッダー */
.l0-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0.75rem 1rem;
  background: rgba(255, 255, 255, 0.03);
  border-bottom: 1px solid rgba(255, 255, 255, 0.06);
}

.btn-exit {
  background: none;
  border: none;
  color: rgba(255, 255, 255, 0.5);
  font-size: 0.85rem;
  cursor: pointer;
  font-family: inherit;
}

.l0-header__title {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.6);
  font-weight: 600;
}

.l0-header__progress {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.35);
}

/* Mowi */
.mowi-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 1.5rem 1rem 1rem;
  gap: 0.75rem;
}

.mowi-dialogue {
  font-size: 0.95rem;
  color: rgba(255, 255, 255, 0.6);
  font-style: italic;
  text-align: center;
  letter-spacing: 0.04em;
}

/* 問題エリア */
.question-area {
  flex: 1;
  padding: 0 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 1.25rem;
}

.phase-label {
  font-size: 0.78rem;
  color: rgba(255, 255, 255, 0.3);
  letter-spacing: 0.2em;
  text-align: center;
}

.meaning-ja {
  font-size: 1.1rem;
  color: rgba(255, 255, 255, 0.7);
  text-align: center;
  font-weight: 600;
}

/* 聞き比べボタン */
.audio-buttons {
  display: flex;
  gap: 1rem;
  justify-content: center;
}

.audio-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.4rem;
  padding: 1.25rem 1.5rem;
  border-radius: 16px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  background: rgba(255, 255, 255, 0.03);
  color: #f0f0ff;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.2s;
  min-width: 130px;
}

.audio-btn:hover {
  background: rgba(255, 255, 255, 0.06);
}

.audio-btn.is-playing {
  border-color: rgba(74, 122, 255, 0.5);
  background: rgba(74, 122, 255, 0.1);
  box-shadow: 0 0 16px rgba(74, 122, 255, 0.2);
}

.audio-btn__icon {
  font-size: 1.8rem;
}

.audio-btn__label {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.5);
}

/* テキスト比較表示 */
.text-compare {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  padding: 1rem;
  background: rgba(255, 255, 255, 0.03);
  border-radius: 12px;
}

.text-slow {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.4);
  text-decoration: line-through;
}

.text-natural {
  font-size: 1.05rem;
  color: rgba(74, 122, 255, 0.9);
  font-weight: 600;
}

/* クイズ選択肢 */
.quiz-options {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.quiz-option {
  width: 100%;
  padding: 1rem 1.25rem;
  border-radius: 14px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  background: rgba(255, 255, 255, 0.03);
  color: #f0f0ff;
  font-size: 1rem;
  text-align: left;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.2s;
}

.quiz-option:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.2);
}

.quiz-option.is-correct {
  border-color: rgba(76, 175, 80, 0.6);
  background: rgba(76, 175, 80, 0.1);
  color: #81C784;
}

.quiz-option.is-wrong {
  border-color: rgba(244, 67, 54, 0.5);
  background: rgba(244, 67, 54, 0.08);
  color: #EF9A9A;
}

/* 解説 */
.explanation-card {
  padding: 1rem;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 12px;
}

.explanation-text {
  font-size: 0.88rem;
  color: rgba(255, 255, 255, 0.6);
  line-height: 1.7;
}

/* 次へボタン */
.btn-next {
  width: 100%;
  padding: 1rem;
  background: linear-gradient(135deg, #4A7AFF, #9B5CF6);
  border: none;
  border-radius: 14px;
  color: white;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  font-family: inherit;
  letter-spacing: 0.04em;
  box-shadow: 0 4px 20px rgba(74, 122, 255, 0.3);
  transition: opacity 0.2s;
  margin-top: auto;
}

.btn-next:disabled {
  opacity: 0.4;
  cursor: not-allowed;
  box-shadow: none;
}

.btn-next:hover:not(:disabled) { opacity: 0.9; }

/* 終了確認ダイアログ */
.exit-overlay {
  position: fixed;
  inset: 0;
  z-index: 50;
  display: flex;
  align-items: center;
  justify-content: center;
  background: rgba(0, 0, 0, 0.6);
}

.exit-dialog {
  background: #1a1a2e;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 20px;
  padding: 1.5rem;
  width: 85%;
  max-width: 320px;
  text-align: center;
}

.exit-title {
  font-size: 1rem;
  font-weight: 700;
  color: #f0f0ff;
  margin-bottom: 0.3rem;
}

.exit-sub {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.4);
  margin-bottom: 1.25rem;
}

.exit-btns {
  display: flex;
  gap: 0.75rem;
}

.exit-btn {
  flex: 1;
  padding: 0.75rem;
  border-radius: 12px;
  font-size: 0.9rem;
  font-weight: 600;
  cursor: pointer;
  font-family: inherit;
  border: none;
}

.exit-btn--cancel {
  background: linear-gradient(135deg, #4A7AFF, #9B5CF6);
  color: white;
}

.exit-btn--confirm {
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.15);
  color: rgba(255, 255, 255, 0.6);
}

/* Transitions */
.fade-text-enter-active { transition: all 0.4s ease-out; }
.fade-text-enter-from { opacity: 0; transform: translateY(8px); }

.overlay-fade-enter-active,
.overlay-fade-leave-active { transition: opacity 0.3s ease; }
.overlay-fade-enter-from,
.overlay-fade-leave-to { opacity: 0; }
</style>
