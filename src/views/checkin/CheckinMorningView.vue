<template>
  <div
    class="checkin-morning"
    :class="`phase-${phase}`"
    :style="bgStyle"
    @click="handleScreenTap"
  >
    <!-- Phase: idle / selecting -->
    <Transition name="fade-up" mode="out-in">
      <div v-if="phase === 'idle'" class="phase-idle" key="idle">

        <!-- あとでやる（B-4-2 dismiss） -->
        <button class="later-link" @click.stop="dismissAndGoHome">あとでやる</button>

        <!-- ヘッダー -->
        <div class="header">
          <div class="date-badge">
            <span class="date-text">{{ formattedDate }}</span>
          </div>
          <h1 class="head-copy-ja">{{ headerJa }}</h1>
          <p class="head-copy-en">{{ headerEn }}</p>
        </div>

        <!-- Mowiオーブ（アイドル） -->
        <div class="mowi-area">
          <MowiOrb :state="'idle'" :brightness="mowiStore.brightness" />
        </div>

        <!-- 4択ボタン -->
        <div class="choices">
          <button
            v-for="choice in morningChoices"
            :key="choice.id"
            class="choice-btn"
            :class="{ 'is-tapped': selectedId === choice.id }"
            @click.stop="selectFeeling(choice)"
          >
            <span class="choice-emoji">{{ choice.emoji }}</span>
            <div class="choice-text">
              <span class="choice-ja">{{ choice.ja }}</span>
              <span class="choice-en">{{ choice.en }}</span>
            </div>
          </button>
        </div>
      </div>
    </Transition>

    <!-- Phase: mowi_reaction -->
    <Transition name="slide-up" mode="out-in">
      <div v-if="phase === 'mowi_reaction'" class="phase-reaction" key="reaction">
        <div class="mowi-reaction-area">
          <MowiOrb
            :state="selectedChoice?.mowiState ?? 'idle'"
            :brightness="mowiStore.brightness"
            :animated="true"
          />
        </div>

        <Transition name="fade-text">
          <div v-if="showSerifus" class="mowi-serifus">
            <p class="serif-ja">{{ selectedChoice?.mowiQuoteJa }}</p>
            <p class="serif-en">{{ selectedChoice?.mowiQuoteEn }}</p>
          </div>
        </Transition>

        <p class="skip-hint">タップしてスキップ</p>
      </div>
    </Transition>

    <!-- Phase: word_card -->
    <Transition name="card-up" mode="out-in">
      <div v-if="phase === 'word_card'" class="phase-word-card" key="card">
        <div class="word-card" :style="cardBgStyle">
          <div class="card-date">{{ formattedDate }}</div>
          <div class="card-mowi-mini">
            <MowiOrb
              :state="selectedChoice?.mowiState ?? 'idle'"
              :brightness="mowiStore.brightness"
              :size="'sm'"
            />
          </div>
          <div class="card-feeling">
            <span class="card-emoji">{{ selectedChoice?.emoji }}</span>
            <div class="card-feeling-text">
              <span class="card-feeling-ja">{{ selectedChoice?.ja }}</span>
              <span class="card-feeling-en">{{ selectedChoice?.en }}</span>
            </div>
          </div>
          <div class="card-quote">
            <p class="card-quote-ja">{{ typedQuoteJa }}</p>
            <p class="card-quote-en">{{ typedQuoteEn }}</p>
          </div>
          <div v-if="streakDays > 0" class="card-streak">
            🔥 {{ streakDays }}日連続
          </div>
        </div>

        <!-- 保存トースト -->
        <Transition name="toast">
          <div v-if="showSavedToast" class="saved-toast">
            ✓ 保存しました
          </div>
        </Transition>
      </div>
    </Transition>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useCheckinStore } from '@/stores/checkin'
import { useMowiStore } from '@/stores/mowi'
import MowiOrb from '@/components/mowi/MowiOrb.vue'
import type { MorningFeelingId } from '@/stores/checkin'
import type { MowiEmotionState } from '@/stores/mowi'
import { CHECKIN_HEADERS, FALLBACK_MOWI_LINE } from '@/data/checkinOptions'
import { setCheckinDismissed } from '@/composables/useCheckinGuard'

const headerJa = CHECKIN_HEADERS.morning.ja
const headerEn = CHECKIN_HEADERS.morning.en

function dismissAndGoHome() {
  setCheckinDismissed('morning')
  router.replace({ name: 'Home' })
}

// ─── Types ────────────────────────────────────────────────────
interface MorningChoice {
  id: MorningFeelingId
  ja: string
  en: string
  emoji: string
  mowiState: MowiEmotionState
  mowiQuoteJa: string
  mowiQuoteEn: string
  bgColorReaction: string
  bgColorCard: string
  cardBg: string
}

// ─── Stores / Router ──────────────────────────────────────────
const router = useRouter()
const checkinStore = useCheckinStore()
const mowiStore = useMowiStore()

// ─── 朝チェックイン選択肢 B-4再定義版（5択） ─────────────────
// 個別 Mowi セリフは別タスクで本実装。本タスクでは FALLBACK_MOWI_LINE.morning を全カードに適用。
const morningChoices: MorningChoice[] = [
  {
    id: 'morning_great',
    ja: 'いい朝',
    en: 'Feeling good',
    emoji: '✨',
    mowiState: 'joy',
    mowiQuoteJa: FALLBACK_MOWI_LINE.morning.ja,
    mowiQuoteEn: FALLBACK_MOWI_LINE.morning.en,
    bgColorReaction: 'linear-gradient(160deg, #0d0d1a 0%, #1a1200 50%, #3d2800 100%)',
    bgColorCard: 'linear-gradient(160deg, #0d0d1a 0%, #1a1200 100%)',
    cardBg: 'linear-gradient(135deg, #2d2000 0%, #4a3300 100%)',
  },
  {
    id: 'morning_doable',
    ja: 'いけそう',
    en: 'Doable',
    emoji: '🙂',
    mowiState: 'cheer',
    mowiQuoteJa: FALLBACK_MOWI_LINE.morning.ja,
    mowiQuoteEn: FALLBACK_MOWI_LINE.morning.en,
    bgColorReaction: 'linear-gradient(160deg, #0d0d1a 0%, #1a1410 50%, #3d2c20 100%)',
    bgColorCard: 'linear-gradient(160deg, #0d0d1a 0%, #1a1410 100%)',
    cardBg: 'linear-gradient(135deg, #2d2418 0%, #4a3a28 100%)',
  },
  {
    id: 'morning_normal',
    ja: 'ふつう',
    en: 'Just normal',
    emoji: '😐',
    mowiState: 'idle',
    mowiQuoteJa: FALLBACK_MOWI_LINE.morning.ja,
    mowiQuoteEn: FALLBACK_MOWI_LINE.morning.en,
    bgColorReaction: 'linear-gradient(160deg, #0d0d1a 0%, #181820 50%, #28282e 100%)',
    bgColorCard: 'linear-gradient(160deg, #0d0d1a 0%, #181820 100%)',
    cardBg: 'linear-gradient(135deg, #1c1c24 0%, #2c2c34 100%)',
  },
  {
    id: 'morning_heavy',
    ja: 'だるい',
    en: 'A bit heavy',
    emoji: '😮‍💨',
    mowiState: 'sad',
    mowiQuoteJa: FALLBACK_MOWI_LINE.morning.ja,
    mowiQuoteEn: FALLBACK_MOWI_LINE.morning.en,
    bgColorReaction: 'linear-gradient(160deg, #0d0d1a 0%, #150d24 50%, #200d30 100%)',
    bgColorCard: 'linear-gradient(160deg, #0d0d1a 0%, #200d30 100%)',
    cardBg: 'linear-gradient(135deg, #150d24 0%, #200d30 100%)',
  },
  {
    id: 'morning_nope',
    ja: '無理かも',
    en: 'Not today',
    emoji: '😵',
    mowiState: 'think',
    mowiQuoteJa: FALLBACK_MOWI_LINE.morning.ja,
    mowiQuoteEn: FALLBACK_MOWI_LINE.morning.en,
    bgColorReaction: 'linear-gradient(160deg, #0d0d1a 0%, #0a0a14 50%, #050510 100%)',
    bgColorCard: 'linear-gradient(160deg, #0d0d1a 0%, #050510 100%)',
    cardBg: 'linear-gradient(135deg, #0a0a14 0%, #050510 100%)',
  },
]

// ─── State ────────────────────────────────────────────────────
type Phase = 'idle' | 'mowi_reaction' | 'word_card'
const phase = ref<Phase>('idle')
const selectedId = ref<MorningFeelingId | null>(null)
const selectedChoice = ref<MorningChoice | null>(null)
const showSerifus = ref(false)
const showSavedToast = ref(false)

const typedQuoteJa = ref('')
const typedQuoteEn = ref('')

// ─── Computed ─────────────────────────────────────────────────
const formattedDate = computed(() => {
  const now = new Date()
  const y = now.getFullYear()
  const m = now.getMonth() + 1
  const d = now.getDate()
  const dow = ['日', '月', '火', '水', '木', '金', '土'][now.getDay()]
  return `${y}年${m}月${d}日（${dow}）`
})

const streakDays = computed(() => checkinStore.streakDays)

const bgStyle = computed(() => {
  if (phase.value === 'idle') return { background: '#0d0d1a' }
  if (phase.value === 'mowi_reaction' && selectedChoice.value) {
    return { background: selectedChoice.value.bgColorReaction, transition: 'background 1s ease' }
  }
  if (phase.value === 'word_card' && selectedChoice.value) {
    return { background: selectedChoice.value.bgColorCard, transition: 'background 0.8s ease' }
  }
  return { background: '#0d0d1a' }
})

const cardBgStyle = computed(() => {
  if (!selectedChoice.value) return {}
  return { background: selectedChoice.value.cardBg }
})

// ─── Methods ──────────────────────────────────────────────────

async function selectFeeling(choice: MorningChoice) {
  if (selectedId.value) return
  selectedId.value = choice.id
  selectedChoice.value = choice

  await sleep(200)
  phase.value = 'mowi_reaction'

  await sleep(500)
  showSerifus.value = true

  await sleep(800)
  proceedToWordCard()
}

function handleScreenTap() {
  if (phase.value === 'mowi_reaction') {
    proceedToWordCard()
  } else if (phase.value === 'word_card') {
    proceedToHome()
  }
}

async function proceedToWordCard() {
  if (phase.value !== 'mowi_reaction') return
  phase.value = 'word_card'

  if (selectedChoice.value) {
    typeWriter(selectedChoice.value.mowiQuoteJa, typedQuoteJa, 20)
    await sleep(300)
    typeWriter(selectedChoice.value.mowiQuoteEn, typedQuoteEn, 18)
  }

  // DB保存（非同期・ノンブロッキング）
  saveCheckin()

  await sleep(2000)
  proceedToHome()
}

async function proceedToHome() {
  showSavedToast.value = true
  await sleep(800)
  router.push({ name: 'Home' })
}

async function saveCheckin() {
  if (!selectedChoice.value) return
  await checkinStore.saveMorningCheckin({
    feeling: selectedChoice.value.id,
    mowiQuoteJa: selectedChoice.value.mowiQuoteJa,
    mowiQuoteEn: selectedChoice.value.mowiQuoteEn,
  })
  await mowiStore.updateAfterMorningCheckin(selectedChoice.value.id)
}

function typeWriter(text: string, target: { value: string }, msPerChar: number) {
  target.value = ''
  let i = 0
  const interval = setInterval(() => {
    if (i >= text.length) { clearInterval(interval); return }
    target.value += text[i]
    i++
  }, msPerChar)
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms))
}

// ─── Lifecycle ────────────────────────────────────────────────
onMounted(async () => {
  await checkinStore.fetchStreakDays()
  await mowiStore.fetchMowiState()
})
</script>

<style scoped>
.checkin-morning {
  min-height: 100dvh;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 24px 20px;
  position: relative;
  overflow: hidden;
  font-family: 'Noto Sans JP', sans-serif;
  transition: background 1s ease;
}

.phase-idle {
  width: 100%;
  max-width: 400px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 32px;
}

.later-link {
  position: absolute;
  top: max(16px, env(safe-area-inset-top));
  right: 20px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.35);
  background: transparent;
  border: none;
  padding: 8px 12px;
  cursor: pointer;
  letter-spacing: 0.04em;
  font-family: 'Noto Sans JP', sans-serif;
  transition: color 0.2s ease;
}
.later-link:hover { color: rgba(255, 255, 255, 0.6); }

.header { text-align: center; }

.date-badge {
  display: inline-block;
  padding: 4px 14px;
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 20px;
  margin-bottom: 16px;
}

.date-text {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.45);
  letter-spacing: 0.05em;
}

.head-copy-ja {
  font-size: 22px;
  font-weight: 700;
  color: #ffffff;
  margin: 0 0 6px;
  letter-spacing: 0.02em;
}

.head-copy-en {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.4);
  margin: 0;
  letter-spacing: 0.08em;
  font-style: italic;
}

.mowi-area {
  width: 120px;
  height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.choices {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.choice-btn {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 16px 20px;
  background: rgba(255, 255, 255, 0.06);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  cursor: pointer;
  transition: transform 0.1s ease, background 0.2s ease, border-color 0.2s ease;
  text-align: left;
}

.choice-btn:active,
.choice-btn.is-tapped {
  transform: scale(1.03);
  background: rgba(255, 255, 255, 0.12);
  border-color: rgba(255, 255, 255, 0.25);
}

.choice-emoji { font-size: 26px; line-height: 1; flex-shrink: 0; }

.choice-text { display: flex; flex-direction: column; gap: 2px; }

.choice-ja {
  font-size: 16px;
  font-weight: 600;
  color: #ffffff;
  letter-spacing: 0.02em;
}

.choice-en {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.45);
  letter-spacing: 0.04em;
}

.phase-reaction {
  width: 100%;
  max-width: 400px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 28px;
}

.mowi-reaction-area {
  width: 160px;
  height: 160px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.mowi-serifus { text-align: center; padding: 0 20px; }

.serif-ja {
  font-size: 20px;
  font-weight: 700;
  color: #ffffff;
  margin: 0 0 8px;
  letter-spacing: 0.03em;
  line-height: 1.5;
}

.serif-en {
  font-size: 14px;
  color: rgba(255, 255, 255, 0.5);
  margin: 0;
  font-style: italic;
  letter-spacing: 0.06em;
}

.skip-hint {
  font-size: 11px;
  color: rgba(255, 255, 255, 0.25);
  position: absolute;
  bottom: 32px;
  left: 50%;
  transform: translateX(-50%);
  letter-spacing: 0.06em;
}

.phase-word-card {
  width: 100%;
  max-width: 380px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
}

.word-card {
  width: 100%;
  border-radius: 24px;
  padding: 28px 24px;
  border: 1px solid rgba(255, 255, 255, 0.12);
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-date { font-size: 12px; color: rgba(255, 255, 255, 0.4); letter-spacing: 0.05em; }

.card-mowi-mini { width: 56px; height: 56px; }

.card-feeling { display: flex; align-items: center; gap: 12px; }

.card-emoji { font-size: 28px; }

.card-feeling-text { display: flex; flex-direction: column; gap: 2px; }

.card-feeling-ja { font-size: 17px; font-weight: 700; color: #ffffff; }

.card-feeling-en {
  font-size: 12px;
  color: rgba(255, 255, 255, 0.45);
  font-style: italic;
  letter-spacing: 0.04em;
}

.card-quote { border-top: 1px solid rgba(255, 255, 255, 0.1); padding-top: 16px; }

.card-quote-ja {
  font-size: 18px;
  font-weight: 600;
  color: #ffffff;
  margin: 0 0 6px;
  letter-spacing: 0.03em;
  line-height: 1.6;
  min-height: 1.6em;
}

.card-quote-en {
  font-size: 13px;
  color: rgba(255, 255, 255, 0.45);
  margin: 0;
  font-style: italic;
  letter-spacing: 0.05em;
  min-height: 1.4em;
}

.card-streak { font-size: 13px; color: rgba(255, 180, 80, 0.8); font-weight: 600; }

.saved-toast {
  position: fixed;
  bottom: 40px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(30, 30, 50, 0.95);
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 100px;
  padding: 10px 24px;
  font-size: 13px;
  color: rgba(255, 255, 255, 0.8);
  letter-spacing: 0.04em;
  white-space: nowrap;
  backdrop-filter: blur(12px);
}

.fade-up-enter-active { transition: all 0.4s ease; }
.fade-up-leave-active { transition: all 0.3s ease; }
.fade-up-enter-from  { opacity: 0; transform: translateY(20px); }
.fade-up-leave-to    { opacity: 0; transform: translateY(-10px); }

.slide-up-enter-active { transition: all 0.4s cubic-bezier(0.16, 1, 0.3, 1); }
.slide-up-leave-active { transition: all 0.25s ease; }
.slide-up-enter-from  { opacity: 0; transform: translateY(40px); }
.slide-up-leave-to    { opacity: 0; transform: translateY(-20px); }

.card-up-enter-active { transition: all 0.5s cubic-bezier(0.16, 1, 0.3, 1); }
.card-up-leave-active { transition: all 0.3s ease; }
.card-up-enter-from  { opacity: 0; transform: translateY(60px) scale(0.96); }
.card-up-leave-to    { opacity: 0; }

.fade-text-enter-active { transition: all 0.4s ease 0.1s; }
.fade-text-enter-from   { opacity: 0; transform: translateY(8px); }

.toast-enter-active { transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1); }
.toast-leave-active { transition: all 0.2s ease; }
.toast-enter-from  { opacity: 0; transform: translateX(-50%) translateY(12px); }
.toast-leave-to    { opacity: 0; }
</style>
