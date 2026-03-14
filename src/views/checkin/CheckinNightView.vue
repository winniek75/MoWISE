<template>
  <div class="checkin-night" :style="bgStyle" @click="handleScreenTap">

    <!-- ── フェーズ1：選択画面 ─────────────────────── -->
    <Transition name="fade-out">
      <div v-if="phase === 'select'" class="phase-select" @click.stop>

        <!-- ヘッダー -->
        <div class="night-header">
          <span class="night-icon">🌙</span>
          <p class="night-label">今日の練習、どうだった？</p>
          <p class="night-label-en">How did it feel today?</p>
        </div>

        <!-- Mowiオーブ（夜版・くすんだ輝き） -->
        <div class="mowi-area">
          <div class="mowi-orb mowi-orb--night" :class="`mowi-orb--lv${mowiStore.brightness}`">
            <div class="orb-core" />
            <div class="orb-glow" />
          </div>
        </div>

        <!-- 4択ボタン -->
        <div class="choices">
          <button
            v-for="choice in eveningChoices"
            :key="choice.id"
            class="choice-btn"
            :class="{ 'is-tapped': tappedId === choice.id }"
            @click.stop="selectFeeling(choice.id)"
          >
            <span class="choice-emoji">{{ choice.emoji }}</span>
            <span class="choice-ja">{{ choice.ja }}</span>
            <span class="choice-en">{{ choice.en }}</span>
          </button>
        </div>

        <!-- ストリーク -->
        <div v-if="checkinStore.streakDays > 0" class="streak-badge">
          🔥 {{ checkinStore.streakDays }}日連続
        </div>
      </div>
    </Transition>

    <!-- ── フェーズ2：Mowiリアクション ──────────────── -->
    <Transition name="slide-up">
      <div v-if="phase === 'reaction'" class="phase-reaction">
        <div class="mowi-orb mowi-orb--reaction" :class="`mowi-orb--lv${mowiStore.brightness}`">
          <div class="orb-core" />
          <div class="orb-glow orb-glow--pulse" />
        </div>

        <Transition name="fade-text">
          <div v-if="showSerifText" class="serif-block">
            <p class="serif-ja">{{ currentSerif?.ja }}</p>
            <p class="serif-en">{{ currentSerif?.en }}</p>
          </div>
        </Transition>

        <p class="tap-hint">タップで次へ</p>
      </div>
    </Transition>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useCheckinStore } from '@/stores/checkin'
import { useMowiStore } from '@/stores/mowi'

const router = useRouter()
const checkinStore = useCheckinStore()
const mowiStore = useMowiStore()

// ─── 定数 ──────────────────────────────────────────────
const EVENING_CHOICES = [
  {
    id: 'evening_said_it',
    ja: '言えた気がする',
    en: 'Something came out',
    emoji: '💬',
    bgFrom: '#1a1a2e',
    bgTo: '#92400e',
    cardBg: '#fef3c7',
  },
  {
    id: 'evening_fun',
    ja: '楽しかった',
    en: 'Actually enjoyed it',
    emoji: '😊',
    bgFrom: '#1a1a3e',
    bgTo: '#7c2d12',
    cardBg: '#fff7ed',
  },
  {
    id: 'evening_hard',
    ja: '難しかった',
    en: "Couldn't get there",
    emoji: '🤔',
    bgFrom: '#0f1a2a',
    bgTo: '#1e3a5f',
    cardBg: '#eff6ff',
  },
  {
    id: 'evening_not_quite',
    ja: 'しっくりこない',
    en: 'Not quite clicking',
    emoji: '🌫',
    bgFrom: '#1a0f2a',
    bgTo: '#4c1d95',
    cardBg: '#f5f3ff',
  },
] as const

type EveningFeelingId = (typeof EVENING_CHOICES)[number]['id']

const EVENING_SERIFS: Record<EveningFeelingId, { ja: string; en: string }[]> = {
  evening_said_it: [
    { ja: '言えた。それが今日の全部。', en: "Said it. That's all of today." },
    { ja: '出た分だけ、本物になった。', en: 'What came out became real.' },
    { ja: 'また今日も、動いた。', en: 'Moved again today.' },
  ],
  evening_fun: [
    { ja: '楽しいとき、一番速く入る。', en: 'Fun is when it enters fastest.' },
    { ja: '楽しさが、英語の速さになる。', en: 'Fun becomes the speed of English.' },
    { ja: '今日みたいな日が、続くといい。', en: 'More days like today.' },
  ],
  evening_hard: [
    { ja: '難しかった分、深く入った。', en: 'Hard means it went deeper.' },
    { ja: '難しいとき、一番成長してる。', en: 'Hardest times are the biggest growth.' },
    { ja: 'ぶつかった。それが記憶になる。', en: 'Hit a wall. That becomes memory.' },
  ],
  evening_not_quite: [
    { ja: 'しっくりこない日がある。それも記録。', en: "Not clicking. That's recorded too." },
    { ja: 'まだ形になってない。でも、来てる。', en: "Not formed yet. But it's coming." },
    { ja: '正直に感じた。それが一番。', en: 'Felt it honestly. That matters most.' },
  ],
}

// ─── 状態 ──────────────────────────────────────────────
type Phase = 'select' | 'reaction'
const phase = ref<Phase>('select')
const tappedId = ref<EveningFeelingId | null>(null)
const selectedChoice = ref<(typeof EVENING_CHOICES)[number] | null>(null)
const showSerifText = ref(false)
const autoTimer = ref<ReturnType<typeof setTimeout> | null>(null)

// ─── computed ──────────────────────────────────────────
const eveningChoices = computed(() => EVENING_CHOICES)

const bgStyle = computed(() => {
  if (!selectedChoice.value) {
    return { background: 'linear-gradient(180deg, #0f0f1a 0%, #1a1a2e 100%)' }
  }
  return {
    background: `linear-gradient(180deg, ${selectedChoice.value.bgFrom} 0%, ${selectedChoice.value.bgTo} 100%)`,
    transition: 'background 1s ease',
  }
})

const currentSerif = computed(() => {
  if (!tappedId.value) return null
  const serifs = EVENING_SERIFS[tappedId.value]
  return serifs[Math.floor(Math.random() * serifs.length)]
})

// ─── 選択処理 ──────────────────────────────────────────
async function selectFeeling(id: EveningFeelingId) {
  if (tappedId.value) return // 二重タップ防止

  tappedId.value = id
  selectedChoice.value = EVENING_CHOICES.find((c) => c.id === id) ?? null

  // ボタンアニメ後にリアクション画面へ
  setTimeout(() => {
    phase.value = 'reaction'
    setTimeout(() => { showSerifText.value = true }, 200)
  }, 300)

  // DB保存（ノンブロッキング）
  checkinStore.saveEveningCheckin(id)
  await mowiStore.updateMowiStateAfterCheckin('night', id)

  // 800ms後に差分フィードバックへ（自動遷移）
  autoTimer.value = setTimeout(goToDiff, 2800)
}

function handleScreenTap() {
  if (phase.value === 'reaction') {
    clearTimer()
    goToDiff()
  }
}

function clearTimer() {
  if (autoTimer.value) {
    clearTimeout(autoTimer.value)
    autoTimer.value = null
  }
}

function goToDiff() {
  router.push({ name: 'checkin-diff' })
}

// ─── lifecycle ────────────────────────────────────────
onMounted(async () => {
  await checkinStore.fetchTodayCheckins()
  await mowiStore.fetchMowiState()
})
</script>

<style scoped>
.checkin-night {
  min-height: 100svh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px 20px;
  transition: background 1s ease;
  cursor: default;
}

/* ── 選択画面 ───────────────────────────────────────── */
.phase-select {
  width: 100%;
  max-width: 400px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 28px;
}

.night-header {
  text-align: center;
}

.night-icon {
  font-size: 28px;
}

.night-label {
  font-size: 20px;
  font-weight: 700;
  color: #e2e8f0;
  margin: 8px 0 4px;
  font-family: 'Noto Sans JP', sans-serif;
}

.night-label-en {
  font-size: 13px;
  color: #94a3b8;
  font-style: italic;
}

/* ── Mowiオーブ ──────────────────────────────────────── */
.mowi-area {
  position: relative;
}

.mowi-orb {
  width: 80px;
  height: 80px;
  border-radius: 50%;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
}

.mowi-orb--night {
  opacity: 0.75;
}

.orb-core {
  width: 60%;
  height: 60%;
  border-radius: 50%;
  background: radial-gradient(circle, #c4b5fd 0%, #7c3aed 60%, #4c1d95 100%);
  z-index: 1;
}

.orb-glow {
  position: absolute;
  inset: -8px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(139, 92, 246, 0.3) 0%, transparent 70%);
}

.orb-glow--pulse {
  animation: pulse-glow 2s ease-in-out infinite;
}

@keyframes pulse-glow {
  0%, 100% { opacity: 0.5; transform: scale(1); }
  50% { opacity: 1; transform: scale(1.15); }
}

/* brightness levels */
.mowi-orb--lv3 .orb-core { filter: brightness(0.6) grayscale(0.4); }
.mowi-orb--lv4 .orb-core { filter: brightness(0.75) grayscale(0.2); }
.mowi-orb--lv5 .orb-core { filter: brightness(0.9); }
.mowi-orb--lv6 .orb-core { filter: brightness(1.0); }
.mowi-orb--lv7 .orb-core { filter: brightness(1.15) saturate(1.2); }
.mowi-orb--lv8 .orb-core { filter: brightness(1.3) saturate(1.4); }
.mowi-orb--lv9 .orb-core { filter: brightness(1.5) saturate(1.6); }
.mowi-orb--lv10 .orb-core { filter: brightness(1.8) saturate(2.0); }

/* ── 選択肢 ──────────────────────────────────────────── */
.choices {
  display: flex;
  flex-direction: column;
  gap: 12px;
  width: 100%;
}

.choice-btn {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 20px;
  background: rgba(255, 255, 255, 0.08);
  border: 1.5px solid rgba(255, 255, 255, 0.15);
  border-radius: 16px;
  color: #e2e8f0;
  cursor: pointer;
  transition: transform 120ms ease, background 200ms ease;
  backdrop-filter: blur(8px);
  text-align: left;
}

.choice-btn:active,
.choice-btn.is-tapped {
  transform: scale(1.04);
  background: rgba(255, 255, 255, 0.18);
}

.choice-emoji {
  font-size: 22px;
  flex-shrink: 0;
}

.choice-ja {
  font-size: 16px;
  font-weight: 600;
  font-family: 'Noto Sans JP', sans-serif;
  flex: 1;
}

.choice-en {
  font-size: 12px;
  color: #94a3b8;
  font-style: italic;
}

.streak-badge {
  font-size: 13px;
  color: #fb923c;
  font-weight: 600;
  padding: 6px 14px;
  background: rgba(251, 146, 60, 0.15);
  border-radius: 9999px;
}

/* ── リアクション画面 ─────────────────────────────────── */
.phase-reaction {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 32px;
  padding: 40px 24px;
}

.mowi-orb--reaction {
  width: 120px;
  height: 120px;
}

.serif-block {
  text-align: center;
  max-width: 320px;
}

.serif-ja {
  font-size: 22px;
  font-weight: 700;
  color: #f1f5f9;
  font-family: 'Noto Sans JP', sans-serif;
  line-height: 1.6;
  margin-bottom: 8px;
}

.serif-en {
  font-size: 14px;
  color: #94a3b8;
  font-style: italic;
}

.tap-hint {
  font-size: 12px;
  color: rgba(148, 163, 184, 0.6);
  animation: blink 2s ease-in-out infinite;
}

@keyframes blink {
  0%, 100% { opacity: 0.6; }
  50% { opacity: 0.2; }
}

/* ── トランジション ───────────────────────────────────── */
.fade-out-leave-active { transition: opacity 300ms ease; }
.fade-out-leave-to { opacity: 0; }

.slide-up-enter-active { transition: all 400ms cubic-bezier(0, 0, 0.2, 1); }
.slide-up-enter-from { opacity: 0; transform: translateY(40px); }

.fade-text-enter-active { transition: opacity 200ms ease; }
.fade-text-enter-from { opacity: 0; }
</style>
