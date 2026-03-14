<template>
  <div class="diff-feedback" :style="bgStyle">

    <!-- ── フェーズ1：差分カード ────────────────────── -->
    <Transition name="fade">
      <div v-if="phase === 'diff'" class="phase-diff">

        <!-- カード比較エリア -->
        <div class="cards-row">
          <!-- 朝カード -->
          <Transition name="slide-left">
            <div v-if="showCards" class="checkin-card checkin-card--morning">
              <span class="card-label">朝</span>
              <span class="card-emoji">{{ morningChoice?.emoji }}</span>
              <p class="card-ja">{{ morningChoice?.ja }}</p>
              <p class="card-en">{{ morningChoice?.en }}</p>
            </div>
          </Transition>

          <!-- 矢印 -->
          <Transition name="fade-arrow">
            <div v-if="showArrow" class="arrow-area">
              <div class="arrow">→</div>
            </div>
          </Transition>

          <!-- 夜カード -->
          <Transition name="slide-right">
            <div v-if="showCards" class="checkin-card checkin-card--evening">
              <span class="card-label">夜</span>
              <span class="card-emoji">{{ eveningChoice?.emoji }}</span>
              <p class="card-ja">{{ eveningChoice?.ja }}</p>
              <p class="card-en">{{ eveningChoice?.en }}</p>
            </div>
          </Transition>
        </div>

        <!-- Mowiオーブ -->
        <div class="mowi-orb-sm" :class="`mowi-orb--lv${mowiStore.brightness}`">
          <div class="orb-core" />
          <div class="orb-glow orb-glow--pulse" />
        </div>

        <!-- 朝×夜コンボセリフ -->
        <Transition name="slide-serif">
          <div v-if="showComboSerif" class="combo-serif">
            <p class="serif-ja">{{ comboSerif?.ja }}</p>
            <p class="serif-en">{{ comboSerif?.en }}</p>
          </div>
        </Transition>

        <!-- 保存ボタン -->
        <Transition name="fade-btn">
          <button
            v-if="showSaveBtn"
            class="save-btn"
            @click="goToSaveCard"
          >
            今日の記録を保存する
          </button>
        </Transition>

      </div>
    </Transition>

    <!-- ── フェーズ2：保存カード ────────────────────── -->
    <Transition name="slide-up">
      <div v-if="phase === 'card'" class="phase-card">

        <div class="record-card" :style="{ background: cardBgGradient }">
          <!-- 日付 -->
          <p class="card-date">📅 {{ todayLabel }}</p>

          <!-- 朝・夜 -->
          <div class="card-feelings">
            <div class="feeling-row">
              <span class="feeling-time">朝</span>
              <span class="feeling-emoji">{{ morningChoice?.emoji }}</span>
              <span class="feeling-text">{{ morningChoice?.en }}</span>
            </div>
            <div class="feeling-row">
              <span class="feeling-time">夜</span>
              <span class="feeling-emoji">{{ eveningChoice?.emoji }}</span>
              <span class="feeling-text">{{ eveningChoice?.en }}</span>
            </div>
          </div>

          <!-- コンボセリフ -->
          <p class="card-serif">「{{ comboSerif?.ja }}」</p>

          <!-- ストリーク -->
          <div v-if="checkinStore.streakDays > 0" class="card-streak">
            🔥 {{ checkinStore.streakDays }}日連続
          </div>

          <!-- MoWISEロゴ -->
          <p class="card-logo">MoWISE</p>
        </div>

        <!-- アクションボタン -->
        <div class="card-actions">
          <button class="action-btn action-btn--outline" @click="goHome">
            🏠 ホームへ
          </button>
        </div>

        <!-- 完了メッセージ -->
        <p class="complete-msg">今日も記録した ✅</p>
      </div>
    </Transition>

    <!-- トースト -->
    <Transition name="toast-in">
      <div v-if="showToast" class="toast">
        記録を保存しました
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
const MORNING_MAP = {
  morning_confident: { ja: '自信ある',     en: 'Ready for it',           emoji: '✨' },
  morning_okay:      { ja: 'まあまあかな', en: 'Somewhere in the middle', emoji: '😌' },
  morning_anxious:   { ja: '不安',         en: 'A little heavy',         emoji: '😟' },
  morning_unsure:    { ja: 'わからない',   en: "Can't tell yet",         emoji: '🌀' },
} as const

const EVENING_MAP = {
  evening_said_it:   { ja: '言えた気がする', en: 'Something came out',  emoji: '💬' },
  evening_fun:       { ja: '楽しかった',     en: 'Actually enjoyed it', emoji: '😊' },
  evening_hard:      { ja: '難しかった',     en: "Couldn't get there",  emoji: '🤔' },
  evening_not_quite: { ja: 'しっくりこない', en: 'Not quite clicking',  emoji: '🌫' },
} as const

// 朝×夜コンボセリフマップ
type ComboKey = string
const COMBO_SERIFS: Record<ComboKey, { ja: string; en: string }> = {
  'morning_anxious:evening_said_it':   { ja: '不安だったのに、出た。それが力。',           en: 'Was anxious. And it came out. That\'s strength.' },
  'morning_confident:evening_hard':    { ja: '難しかった。だから、また自信になる。',       en: 'Hard. That becomes confidence again.' },
  'morning_unsure:evening_fun':        { ja: '始めたら、楽しかった。いつもそう。',         en: 'Started, and it was fun. Always is.' },
  'morning_okay:evening_not_quite':    { ja: '毎日、まあまあ。それが積み重なる。',         en: 'Pretty okay every day. It accumulates.' },
  'morning_anxious:evening_hard':      { ja: '全部、正直だった。それが一番。',             en: 'All of it was honest. That\'s best.' },
  'morning_confident:evening_said_it': { ja: '思った通り、出た。明日も来る。',             en: 'Just as expected. Tomorrow too.' },
  'morning_anxious:evening_not_quite': { ja: '不安から始まって、まあまあで終わった。上等。', en: 'Started anxious. Ended okay. That\'s good.' },
  'morning_unsure:evening_hard':       { ja: 'わからないまま難しかった。でも、来た。',     en: "Didn't know and it was hard. But you came." },
  'morning_okay:evening_fun':          { ja: '始めたら楽しくなった。それが英語。',         en: 'Started okay, ended fun. That\'s English.' },
  'morning_confident:evening_not_quite': { ja: '自信があった。まあまあで終わった。それも積み重なる。', en: 'Felt confident. Ended okay. That accumulates too.' },
  'morning_unsure:evening_said_it':    { ja: 'わからなかったのに、出た。それが成長。',     en: "Didn't know. And it came out. That's growth." },
  'morning_anxious:evening_fun':       { ja: '不安から、楽しさへ。今日が証明。',           en: 'From anxious to fun. Today proved it.' },
  'morning_okay:evening_said_it':      { ja: 'まあまあの朝に、言えた夜。その差。',         en: 'An okay morning. A said-it evening. That gap.' },
  'morning_okay:evening_hard':         { ja: 'まあまあから難しさへ。正直に進んだ。',       en: 'From okay to hard. Moved honestly.' },
  'morning_confident:evening_fun':     { ja: '自信と楽しさが重なった。この感覚、覚えてる。', en: 'Confidence and fun overlapped. Remember this.' },
  'morning_unsure:evening_not_quite':  { ja: 'わからないまま、しっくりこないまま。でも来た。', en: "Unsure, not clicking. But you came." },
}

const DEFAULT_SERIF = { ja: '今日も、来た。それが全部。', en: 'Came today too. That\'s everything.' }

// ─── 状態 ──────────────────────────────────────────────
type Phase = 'diff' | 'card'
const phase = ref<Phase>('diff')
const showCards = ref(false)
const showArrow = ref(false)
const showComboSerif = ref(false)
const showSaveBtn = ref(false)
const showToast = ref(false)
let autoTimer: ReturnType<typeof setTimeout> | null = null

// ─── computed ──────────────────────────────────────────
const morningFeeling = computed(() => (checkinStore.todayMorning?.feeling ?? null) as keyof typeof MORNING_MAP | null)
const eveningFeeling = computed(() => (checkinStore.todayEvening?.feeling ?? null) as keyof typeof EVENING_MAP | null)

const morningChoice = computed(() =>
  morningFeeling.value ? MORNING_MAP[morningFeeling.value] : null
)
const eveningChoice = computed(() =>
  eveningFeeling.value ? EVENING_MAP[eveningFeeling.value] : null
)

const comboKey = computed(() =>
  morningFeeling.value && eveningFeeling.value
    ? `${morningFeeling.value}:${eveningFeeling.value}`
    : null
)

const comboSerif = computed(() =>
  comboKey.value ? (COMBO_SERIFS[comboKey.value] ?? DEFAULT_SERIF) : DEFAULT_SERIF
)

const todayLabel = computed(() => {
  const d = new Date()
  const weekdays = ['日', '月', '火', '水', '木', '金', '土']
  return `${d.getFullYear()}年${d.getMonth() + 1}月${d.getDate()}日（${weekdays[d.getDay()]}）`
})

const bgStyle = computed(() => ({
  background: 'linear-gradient(180deg, #0f172a 0%, #1e1b4b 100%)',
}))

const cardBgGradient = computed(() => {
  const morningId = morningFeeling.value
  const eveningId = eveningFeeling.value
  if (morningId === 'morning_confident' && eveningId === 'evening_fun') {
    return 'linear-gradient(135deg, #fef3c7, #fde68a)'
  }
  if (eveningId === 'evening_hard' || eveningId === 'evening_not_quite') {
    return 'linear-gradient(135deg, #eff6ff, #e0e7ff)'
  }
  return 'linear-gradient(135deg, #f0fdf4, #dcfce7)'
})

// ─── アニメーション順序 ────────────────────────────────
function startAnimation() {
  // 600ms: カード左右スライドイン
  setTimeout(() => { showCards.value = true }, 100)
  // 矢印フェードイン
  setTimeout(() => { showArrow.value = true }, 700)
  // コンボセリフ
  setTimeout(() => { showComboSerif.value = true }, 1000)
  // 保存ボタン
  setTimeout(() => { showSaveBtn.value = true }, 1800)
  // 2500ms後に自動で保存カードへ
  autoTimer = setTimeout(goToSaveCard, 4000)
}

function goToSaveCard() {
  if (autoTimer) { clearTimeout(autoTimer); autoTimer = null }
  phase.value = 'card'
  // トースト表示
  setTimeout(() => { showToast.value = true }, 300)
  setTimeout(() => { showToast.value = false }, 1500)
}

function goHome() {
  router.push({ name: 'Home' })
}

// ─── lifecycle ────────────────────────────────────────
onMounted(async () => {
  await checkinStore.fetchTodayCheckins()
  await mowiStore.fetchMowiState()
  startAnimation()
})
</script>

<style scoped>
.diff-feedback {
  min-height: 100svh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 24px 20px;
}

/* ── 差分フェーズ ─────────────────────────────────────── */
.phase-diff {
  width: 100%;
  max-width: 400px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 28px;
}

.cards-row {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  justify-content: center;
}

.checkin-card {
  flex: 1;
  max-width: 150px;
  border-radius: 16px;
  padding: 16px 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  backdrop-filter: blur(8px);
}

.checkin-card--morning {
  background: rgba(251, 191, 36, 0.12);
  border: 1.5px solid rgba(251, 191, 36, 0.3);
}

.checkin-card--evening {
  background: rgba(139, 92, 246, 0.12);
  border: 1.5px solid rgba(139, 92, 246, 0.3);
}

.card-label {
  font-size: 11px;
  font-weight: 700;
  color: #94a3b8;
  letter-spacing: 0.05em;
  font-family: 'Noto Sans JP', sans-serif;
}

.card-emoji {
  font-size: 28px;
}

.card-ja {
  font-size: 13px;
  font-weight: 600;
  color: #e2e8f0;
  text-align: center;
  font-family: 'Noto Sans JP', sans-serif;
}

.card-en {
  font-size: 10px;
  color: #64748b;
  font-style: italic;
  text-align: center;
}

.arrow-area {
  flex-shrink: 0;
}

.arrow {
  font-size: 20px;
  color: #475569;
}

/* ── Mowiオーブ（小） ─────────────────────────────────── */
.mowi-orb-sm {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
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
  0%, 100% { opacity: 0.4; transform: scale(1); }
  50% { opacity: 0.9; transform: scale(1.15); }
}

/* brightness levels */
.mowi-orb--lv3 .orb-core { filter: brightness(0.6) grayscale(0.4); }
.mowi-orb--lv5 .orb-core { filter: brightness(0.9); }
.mowi-orb--lv7 .orb-core { filter: brightness(1.15) saturate(1.2); }
.mowi-orb--lv9 .orb-core { filter: brightness(1.5) saturate(1.6); }
.mowi-orb--lv10 .orb-core { filter: brightness(1.8) saturate(2.0); }

/* ── コンボセリフ ─────────────────────────────────────── */
.combo-serif {
  text-align: center;
  max-width: 320px;
  padding: 0 8px;
}

.serif-ja {
  font-size: 20px;
  font-weight: 700;
  color: #f1f5f9;
  font-family: 'Noto Sans JP', sans-serif;
  line-height: 1.65;
  margin-bottom: 6px;
}

.serif-en {
  font-size: 13px;
  color: #64748b;
  font-style: italic;
}

.save-btn {
  padding: 14px 32px;
  background: rgba(139, 92, 246, 0.2);
  border: 1.5px solid rgba(139, 92, 246, 0.5);
  border-radius: 9999px;
  color: #c4b5fd;
  font-size: 14px;
  font-weight: 600;
  font-family: 'Noto Sans JP', sans-serif;
  cursor: pointer;
  transition: background 200ms ease;
}

.save-btn:active {
  background: rgba(139, 92, 246, 0.35);
}

/* ── 保存カードフェーズ ───────────────────────────────── */
.phase-card {
  width: 100%;
  max-width: 380px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 24px;
}

.record-card {
  width: 100%;
  border-radius: 24px;
  padding: 28px 24px;
  display: flex;
  flex-direction: column;
  gap: 16px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
}

.card-date {
  font-size: 13px;
  color: #475569;
  font-family: 'Noto Sans JP', sans-serif;
}

.card-feelings {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.feeling-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.feeling-time {
  font-size: 11px;
  font-weight: 700;
  color: #94a3b8;
  width: 20px;
  font-family: 'Noto Sans JP', sans-serif;
}

.feeling-emoji {
  font-size: 20px;
}

.feeling-text {
  font-size: 14px;
  color: #334155;
  font-style: italic;
}

.card-serif {
  font-size: 16px;
  font-weight: 700;
  color: #1e293b;
  line-height: 1.7;
  font-family: 'Noto Sans JP', sans-serif;
  border-left: 3px solid #7c3aed;
  padding-left: 12px;
}

.card-streak {
  font-size: 13px;
  color: #ea580c;
  font-weight: 600;
}

.card-logo {
  font-size: 11px;
  color: #94a3b8;
  letter-spacing: 0.1em;
  text-align: right;
  font-weight: 600;
}

.card-actions {
  display: flex;
  gap: 12px;
}

.action-btn {
  flex: 1;
  padding: 14px;
  border-radius: 16px;
  font-size: 14px;
  font-weight: 600;
  font-family: 'Noto Sans JP', sans-serif;
  cursor: pointer;
  transition: opacity 150ms ease;
}

.action-btn--outline {
  background: transparent;
  border: 1.5px solid rgba(255, 255, 255, 0.2);
  color: #94a3b8;
}

.complete-msg {
  font-size: 13px;
  color: #4ade80;
  font-family: 'Noto Sans JP', sans-serif;
}

/* ── トースト ──────────────────────────────────────────── */
.toast {
  position: fixed;
  bottom: 40px;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(30, 41, 59, 0.95);
  color: #e2e8f0;
  padding: 10px 24px;
  border-radius: 9999px;
  font-size: 13px;
  font-family: 'Noto Sans JP', sans-serif;
  backdrop-filter: blur(8px);
  box-shadow: 0 4px 16px rgba(0, 0, 0, 0.4);
  pointer-events: none;
}

/* ── トランジション ───────────────────────────────────── */
.fade-enter-active, .fade-leave-active { transition: opacity 300ms ease; }
.fade-enter-from, .fade-leave-to { opacity: 0; }

.slide-left-enter-active { transition: all 600ms cubic-bezier(0, 0, 0.2, 1); }
.slide-left-enter-from { opacity: 0; transform: translateX(-40px); }

.slide-right-enter-active { transition: all 600ms cubic-bezier(0, 0, 0.2, 1); }
.slide-right-enter-from { opacity: 0; transform: translateX(40px); }

.fade-arrow-enter-active { transition: opacity 200ms ease 0.7s; }
.fade-arrow-enter-from { opacity: 0; }

.slide-serif-enter-active { transition: all 300ms cubic-bezier(0, 0, 0.2, 1); }
.slide-serif-enter-from { opacity: 0; transform: translateY(16px); }

.fade-btn-enter-active { transition: opacity 300ms ease; }
.fade-btn-enter-from { opacity: 0; }

.slide-up-enter-active { transition: all 400ms cubic-bezier(0, 0, 0.2, 1); }
.slide-up-enter-from { opacity: 0; transform: translateY(40px); }

.toast-in-enter-active, .toast-in-leave-active { transition: all 300ms ease; }
.toast-in-enter-from, .toast-in-leave-to { opacity: 0; transform: translateX(-50%) translateY(10px); }
</style>
