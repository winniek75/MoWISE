<template>
  <div class="layer1-screen">

    <!-- ヘッダー -->
    <header class="l1-header">
      <button class="btn-exit" @click="confirmExit">← 終了</button>
      <span class="l1-header__title">{{ patternId }} &nbsp; Layer 1</span>
      <span class="l1-header__progress">{{ currentIndex + 1 }} / {{ questions.length }}問</span>
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

      <!-- 再生ボタン -->
      <div class="play-area">
        <button class="play-btn" :class="{ 'is-playing': isPlaying }" @click="playQuestion">
          <span class="play-icon">{{ isPlaying ? '🔊' : '▶' }}</span>
          <span class="play-label">{{ isPlaying ? '再生中…' : 'タップして聞く' }}</span>
        </button>
        <p v-if="currentQ.hintJa" class="hint-ja">{{ currentQ.hintJa }}</p>
      </div>

      <!-- 3択 -->
      <div class="choices">
        <button
          v-for="choice in currentQ.choices"
          :key="choice.id"
          class="choice-btn"
          :class="{
            'is-selected': selectedId === choice.id,
            'is-correct': isAnswered && choice.isCorrect,
            'is-wrong': isAnswered && selectedId === choice.id && !choice.isCorrect,
          }"
          :disabled="isAnswered"
          @click="selectChoice(choice)"
        >
          {{ choice.text }}
        </button>
      </div>

      <!-- 解説 -->
      <transition name="fade-text">
        <div v-if="isAnswered && currentQ.explanation" class="explanation-card">
          <p class="explanation-text">{{ currentQ.explanation }}</p>
        </div>
      </transition>

      <!-- 次へ -->
      <button
        v-if="isAnswered"
        class="btn-next"
        @click="nextQuestion"
      >
        {{ isLast ? 'Layer 1 完了' : '次の問題' }}
      </button>

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
import { playAudio as playMowiseAudio, stopCurrent } from '@/composables/useMowiseAudio'
import { getLayer1Questions } from '@/data/patternRegistry'
import MowiOrb from '@/components/mowi/MowiOrb.vue'
import type { Layer1Question, Layer1Choice } from '@/data/layerTypes'
import type { MowiEmotionState } from '@/stores/session'

const router = useRouter()
const sessionStore = useSessionStore()

// ── パターンID ──
const patternId = computed(() => sessionStore.currentPattern?.patternId ?? 'P001')
const questions = computed(() => getLayer1Questions(patternId.value))

// ── 問題進行 ──
const currentIndex = ref(0)
const currentQ = computed<Layer1Question | null>(() => questions.value[currentIndex.value] ?? null)
const isLast = computed(() => currentIndex.value >= questions.value.length - 1)

// ── 回答 ──
const selectedId = ref<string | null>(null)
const isAnswered = ref(false)
const isPlaying = ref(false)

// ── Mowi ──
const mowiState = ref<MowiEmotionState>('cheer')
const mowiLine = ref('聞いてみよう。')

// ── コンボゲージ ──
const gaugeStyle = computed(() => {
  const pct = Math.min((sessionStore.combo / 10) * 100, 100)
  return {
    width: `${pct}%`,
    background: sessionStore.comboColor === 'rainbow'
      ? 'linear-gradient(90deg, #FF6B6B, #FFD93D, #6BCB77, #4D96FF, #C77DFF)'
      : sessionStore.comboColor,
  }
})

// ── 終了ダイアログ ──
const showExitDialog = ref(false)

// ── Audio ──
async function playQuestion() {
  if (!currentQ.value) return
  isPlaying.value = true
  stopCurrent()
  await playMowiseAudio(currentQ.value.audio, currentQ.value.sentence)
  setTimeout(() => { isPlaying.value = false }, 1500)
}

// ── 回答処理 ──
function selectChoice(choice: Layer1Choice) {
  selectedId.value = choice.id
  isAnswered.value = true

  if (choice.isCorrect) {
    sessionStore.recordAnswer(true)
    mowiState.value = 'joy'
    const joyLines = ['聞こえてる。', '耳が覚えてきた。', '音がわかるようになってきた。']
    mowiLine.value = joyLines[Math.floor(Math.random() * joyLines.length)]
    // 正解音を再生
    if (currentQ.value) {
      playMowiseAudio(currentQ.value.audio, currentQ.value.sentence)
    }
  } else {
    sessionStore.recordAnswer(false)
    mowiState.value = 'sad'
    mowiLine.value = 'もう一回聞いてみて。違いがわかるよ。'
  }
}

function nextQuestion() {
  if (isLast.value) {
    // Layer 1 完了 → Layer 2 へ
    router.push({ name: 'session-layer2' })
    return
  }
  // リセット
  currentIndex.value++
  selectedId.value = null
  isAnswered.value = false
  isPlaying.value = false
  mowiState.value = 'cheer'
  mowiLine.value = '聞いてみよう。'
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
.layer1-screen {
  min-height: 100vh;
  background: #0d0d1a;
  color: #f0f0ff;
  display: flex;
  flex-direction: column;
  font-family: 'Noto Sans JP', sans-serif;
  padding-bottom: 2rem;
}

/* ヘッダー */
.l1-header {
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

.l1-header__title {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.6);
  font-weight: 600;
}

.l1-header__progress {
  font-size: 0.8rem;
  color: rgba(255, 255, 255, 0.35);
}

/* コンボゲージ */
.combo-gauge-wrap {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
}

.combo-gauge {
  flex: 1;
  height: 4px;
  background: rgba(255, 255, 255, 0.06);
  border-radius: 4px;
  overflow: hidden;
}

.combo-gauge__fill {
  height: 100%;
  border-radius: 4px;
  transition: width 0.4s ease, background 0.4s ease;
}

.combo-gauge__fill.is-pulsing {
  animation: gauge-pulse 1s ease-in-out infinite;
}

.combo-gauge__fill.is-rainbow {
  animation: gauge-pulse 1s ease-in-out infinite, rainbow-shift 2s linear infinite;
}

.combo-text {
  font-size: 0.85rem;
  font-weight: 800;
  min-width: 1.5rem;
  text-align: right;
}

@keyframes gauge-pulse {
  0%, 100% { opacity: 1; }
  50%      { opacity: 0.7; }
}

/* Mowi */
.mowi-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 1.25rem 1rem 0.75rem;
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

/* 再生エリア */
.play-area {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.5rem;
}

.play-btn {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 1rem 2rem;
  border-radius: 50px;
  border: 1px solid rgba(74, 122, 255, 0.3);
  background: rgba(74, 122, 255, 0.08);
  color: #f0f0ff;
  font-size: 1rem;
  cursor: pointer;
  font-family: inherit;
  transition: all 0.2s;
}

.play-btn:hover {
  background: rgba(74, 122, 255, 0.15);
  border-color: rgba(74, 122, 255, 0.5);
}

.play-btn.is-playing {
  border-color: rgba(74, 122, 255, 0.6);
  box-shadow: 0 0 20px rgba(74, 122, 255, 0.3);
}

.play-icon { font-size: 1.3rem; }

.play-label {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.7);
}

.hint-ja {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.35);
}

/* 3択 */
.choices {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.choice-btn {
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

.choice-btn:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.06);
  border-color: rgba(255, 255, 255, 0.2);
}

.choice-btn.is-correct {
  border-color: rgba(76, 175, 80, 0.6);
  background: rgba(76, 175, 80, 0.1);
  color: #81C784;
}

.choice-btn.is-wrong {
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
.btn-next:hover { opacity: 0.9; }

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
