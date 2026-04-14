<template>
  <div class="session-start-screen">

    <!-- ヘッダー -->
    <header class="session-header">
      <button class="btn-back" @click="goBack">
        <span class="back-arrow">←</span> ホーム
      </button>
      <span class="header-title">今日の練習</span>
      <span class="header-spacer" />
    </header>

    <!-- Mowi エリア -->
    <div class="mowi-zone">
      <div class="mowi-orb-wrap">
        <!-- MowiOrb.vue を使用（M-1で作成済み） -->
        <!-- <MowiOrb state="idle" :brightness="5" size="md" /> -->
        <!-- ↓ フォールバック：MowiOrb.vue 読み込み前の仮表示 -->
        <div class="mowi-orb-fallback" :class="mowiPulseClass">
          <div class="orb-core" />
          <div class="orb-glow" />
        </div>
      </div>
      <transition name="fade-dialogue">
        <p class="mowi-text">{{ mowiLine }}</p>
      </transition>
    </div>

    <!-- パターンカード一覧 -->
    <div class="patterns-section">
      <h2 class="section-label">── 今日のパターン ──</h2>

      <div class="pattern-cards">
        <div
          v-for="pattern in todayPatterns"
          :key="pattern.patternId"
          class="pattern-card"
          :class="{ 'weak-point': pattern.isWeakPoint }"
          @click="startSinglePattern(pattern)"
        >
          <!-- 弱点バッジ -->
          <div v-if="pattern.isWeakPoint" class="weak-badge">⚠ 弱点</div>

          <div class="card-left">
            <span class="pattern-id">{{ pattern.patternId }}</span>
            <div class="star-row">
              <span
                v-for="i in 5"
                :key="i"
                class="star"
                :class="{ 'star--on': i <= pattern.currentStar }"
              >★</span>
            </div>
          </div>
          <div class="card-right">
            <p class="pattern-label">{{ pattern.patternLabel }}</p>
            <p class="pattern-ja">{{ pattern.patternJa }}</p>
            <span class="layer-badge">Layer {{ pattern.startLayer }} から</span>
          </div>
          <span class="card-arrow">→</span>
        </div>
      </div>
    </div>

    <!-- 区切り線 -->
    <div class="divider" />

    <!-- 所要時間・開始ボタン -->
    <div class="start-zone">
      <p class="time-estimate">推定 {{ estimatedMinutes }} 分</p>
      <button
        class="btn-start"
        :class="{ 'is-loading': isStarting }"
        @click="startSession"
        :disabled="isStarting"
      >
        <span v-if="!isStarting">▶ 練習を始める（{{ todayPatterns.length }} パターン）</span>
        <span v-else class="loading-dots">準備中…</span>
      </button>
    </div>

  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore, type SessionPattern } from '@/stores/session'
import { useAuthStore } from '@/stores/auth'
import { supabase, isOfflineMode } from '@/lib/supabase'

const router = useRouter()
const sessionStore = useSessionStore()
const authStore = useAuthStore()

// ── State ──

const isStarting = ref(false)
const isLoadingPatterns = ref(true)
const todayPatterns = ref<SessionPattern[]>([])

// Mowiセリフ（Cheer/Idle からランダム）
const mowiLines = [
  '体を使う。頭じゃなく。',
  '今日のセッション、始まる。',
  '少しずつ、遠くに届く。',
  '今日の英語、出してみよう。',
  '言ってみる。',
  'また動かす。',
]
const mowiLine = ref(mowiLines[Math.floor(Math.random() * mowiLines.length)])

// ── Computed ──

const estimatedMinutes = computed(() => todayPatterns.value.length * 5)

const mowiPulseClass = computed(() => 'pulse-idle')

// ── Lifecycle ──

onMounted(async () => {
  await loadTodayPatterns()
})

/**
 * 今日の練習パターンを取得
 * patterns テーブルから最大4つ選択。進捗がある場合はそれを考慮。
 */
async function loadTodayPatterns() {
  isLoadingPatterns.value = true

  try {
    // パターンマスターデータを取得（P001〜P035）
    const { data: rawPatterns, error: pErr } = await supabase
      .from('patterns')
      .select('pattern_no, pattern_text, japanese')
      .order('sort_order')

    const allPatterns = (rawPatterns ?? []) as Array<{
      pattern_no: string; pattern_text: string; japanese: string
    }>

    if (pErr || allPatterns.length === 0) {
      todayPatterns.value = FALLBACK_PATTERNS
      isLoadingPatterns.value = false
      return
    }

    // ユーザー進捗を取得（ログイン済みの場合）
    let progressMap = new Map<string, any>()
    if (authStore.userId && !isOfflineMode) {
      const { data: progress } = await supabase
        .from('pattern_progress')
        .select('pattern_no, mastery_level, layer0_done, layer1_done, layer2_done, layer3_done')
        .eq('user_id', authStore.userId)

      for (const p of (progress ?? []) as any[]) {
        progressMap.set(p.pattern_no, p)
      }
    }

    // パターンを選択（未完了を優先、最大4つ）
    const selected: SessionPattern[] = []
    for (const p of allPatterns) {
      if (selected.length >= 4) break
      const prog = progressMap.get(p.pattern_no)
      const stars = prog?.mastery_level ?? 0
      if (stars >= 5) continue // マスター済みはスキップ

      const startLayer = !prog?.layer0_done ? 0
        : !prog?.layer1_done ? 1
        : !prog?.layer2_done ? 2
        : 3

      selected.push({
        patternId: p.pattern_no,
        patternLabel: p.pattern_text,
        patternJa: p.japanese,
        currentStar: stars,
        startLayer: startLayer as 0 | 1 | 2 | 3,
        isWeakPoint: false,
      })
    }

    todayPatterns.value = selected.length > 0 ? selected : FALLBACK_PATTERNS

  } catch (e) {
    console.warn('[SessionStart] pattern load failed:', e)
    todayPatterns.value = FALLBACK_PATTERNS
  } finally {
    isLoadingPatterns.value = false
  }
}

// Supabase 取得失敗時のフォールバック
const FALLBACK_PATTERNS: SessionPattern[] = [
  { patternId: 'P001', patternLabel: '[代名詞] + be動詞 + [状態/情報]', patternJa: '〜は…です', currentStar: 0, startLayer: 0, isWeakPoint: false },
  { patternId: 'P002', patternLabel: 'This is [名詞].', patternJa: 'これは〜です', currentStar: 0, startLayer: 0, isWeakPoint: false },
  { patternId: 'P003', patternLabel: 'I like [名詞/動名詞].', patternJa: '〜が好きです', currentStar: 0, startLayer: 0, isWeakPoint: false },
  { patternId: 'P004', patternLabel: 'I want [名詞].', patternJa: '〜が欲しいです', currentStar: 0, startLayer: 0, isWeakPoint: false },
]

// ── Actions ──

async function startSession() {
  isStarting.value = true
  try {
    await sessionStore.startSession(todayPatterns.value)
    router.push({ name: 'session-layer0' })
  } catch (e) {
    console.error('セッション開始エラー:', e)
    isStarting.value = false
  }
}

/** パターンカードをタップして1パターンだけ練習 */
async function startSinglePattern(pattern: SessionPattern) {
  isStarting.value = true
  try {
    await sessionStore.startSession([pattern])
    router.push({ name: 'session-layer0' })
  } catch (e) {
    console.error('セッション開始エラー:', e)
    isStarting.value = false
  }
}

function goBack() {
  router.replace({ name: 'Home' })
}
</script>

<style scoped>
/* ─────────────────────────────────────────────
   レイアウト / 基本
───────────────────────────────────────────── */
.session-start-screen {
  min-height: 100vh;
  background: #0d0d1a;
  color: #f0f0ff;
  display: flex;
  flex-direction: column;
  font-family: 'Noto Sans JP', sans-serif;
  padding-bottom: 2rem;
}

/* ─────────────────────────────────────────────
   ヘッダー
───────────────────────────────────────────── */
.session-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 1rem 1.25rem;
  border-bottom: 1px solid rgba(255,255,255,0.07);
}

.btn-back {
  background: none;
  border: none;
  color: rgba(255,255,255,0.5);
  font-size: 0.9rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 0.25rem;
  transition: color 0.2s;
}
.btn-back:hover { color: #fff; }

.back-arrow { font-size: 1rem; }

.header-title {
  font-size: 1rem;
  font-weight: 600;
  color: rgba(255,255,255,0.85);
  letter-spacing: 0.05em;
}
.header-spacer { width: 60px; }

/* ─────────────────────────────────────────────
   Mowi エリア
───────────────────────────────────────────── */
.mowi-zone {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 2rem 1rem 1.5rem;
  gap: 1rem;
}

.mowi-orb-wrap { position: relative; }

/* MowiOrb.vue がない場合のフォールバック */
.mowi-orb-fallback {
  position: relative;
  width: 80px;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.orb-core {
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: radial-gradient(circle at 35% 35%, #a0bcff, #4A7AFF 60%, #2a3a8f);
  box-shadow: 0 0 20px rgba(74, 122, 255, 0.5);
  animation: idle-float 3s ease-in-out infinite;
}

.orb-glow {
  position: absolute;
  inset: -10px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(74,122,255,0.15), transparent 70%);
  animation: idle-float 3s ease-in-out infinite reverse;
}

.mowi-text {
  font-size: 1.05rem;
  color: rgba(255, 255, 255, 0.7);
  letter-spacing: 0.06em;
  text-align: center;
  font-style: italic;
}

/* ─────────────────────────────────────────────
   パターンカード
───────────────────────────────────────────── */
.patterns-section {
  padding: 0 1.25rem;
  flex: 1;
}

.section-label {
  text-align: center;
  font-size: 0.78rem;
  color: rgba(255,255,255,0.35);
  letter-spacing: 0.2em;
  margin-bottom: 1rem;
}

.pattern-cards {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.pattern-card {
  position: relative;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.09);
  border-radius: 12px;
  padding: 1rem 1.25rem;
  display: flex;
  align-items: center;
  gap: 1rem;
  transition: border-color 0.2s, background 0.2s;
  cursor: pointer;
}

.pattern-card:hover {
  border-color: rgba(74,122,255,0.3);
  background: rgba(74,122,255,0.06);
}

.pattern-card:active {
  transform: scale(0.98);
}

.card-arrow {
  font-size: 1rem;
  color: rgba(255,255,255,0.25);
  margin-left: auto;
  flex-shrink: 0;
}

.pattern-card.weak-point {
  border-color: rgba(255, 152, 0, 0.3);
  background: rgba(255, 152, 0, 0.05);
}

.weak-badge {
  position: absolute;
  top: -0.5rem;
  left: 1rem;
  background: #FF9800;
  color: #000;
  font-size: 0.65rem;
  font-weight: 700;
  padding: 0.1rem 0.5rem;
  border-radius: 20px;
  letter-spacing: 0.05em;
}

.card-left {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.4rem;
  min-width: 50px;
}

.pattern-id {
  font-size: 0.75rem;
  color: #4A7AFF;
  font-weight: 700;
  letter-spacing: 0.1em;
}

.star-row { display: flex; gap: 1px; }
.star { font-size: 0.75rem; color: rgba(255,255,255,0.2); }
.star--on { color: #FFD700; }

.card-right {
  flex: 1;
}

.pattern-label {
  font-size: 0.95rem;
  font-weight: 600;
  color: #f0f0ff;
  margin-bottom: 0.2rem;
}

.pattern-ja {
  font-size: 0.8rem;
  color: rgba(255,255,255,0.5);
  margin-bottom: 0.4rem;
}

.layer-badge {
  font-size: 0.7rem;
  background: rgba(74,122,255,0.15);
  color: #7ba8ff;
  border: 1px solid rgba(74,122,255,0.25);
  padding: 0.15rem 0.6rem;
  border-radius: 20px;
}

/* ─────────────────────────────────────────────
   区切り線・開始エリア
───────────────────────────────────────────── */
.divider {
  height: 1px;
  background: rgba(255,255,255,0.07);
  margin: 1.5rem 1.25rem 0;
}

.start-zone {
  padding: 1.25rem 1.25rem 0.5rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
}

.time-estimate {
  font-size: 0.8rem;
  color: rgba(255,255,255,0.4);
  letter-spacing: 0.05em;
}

.btn-start {
  width: 100%;
  padding: 1rem 1.5rem;
  background: linear-gradient(135deg, #4A7AFF, #9B5CF6);
  color: white;
  font-size: 1rem;
  font-weight: 700;
  border: none;
  border-radius: 14px;
  cursor: pointer;
  letter-spacing: 0.04em;
  transition: opacity 0.2s, transform 0.1s;
  box-shadow: 0 4px 20px rgba(74, 122, 255, 0.35);
}
.btn-start:hover:not(:disabled) {
  opacity: 0.9;
  transform: translateY(-1px);
}
.btn-start:active:not(:disabled) {
  transform: translateY(0);
}
.btn-start.is-loading,
.btn-start:disabled { opacity: 0.5; cursor: not-allowed; }

.loading-dots {
  animation: blink 1.2s step-end infinite;
}

/* ─────────────────────────────────────────────
   Transitions
───────────────────────────────────────────── */
.fade-dialogue-enter-active,
.fade-dialogue-leave-active { transition: opacity 0.4s; }
.fade-dialogue-enter-from,
.fade-dialogue-leave-to { opacity: 0; }

/* ─────────────────────────────────────────────
   Animations
───────────────────────────────────────────── */
@keyframes idle-float {
  0%, 100% { transform: translateY(0px); }
  50%       { transform: translateY(-6px); }
}

@keyframes blink {
  0%, 100% { opacity: 1; }
  50%       { opacity: 0.4; }
}
</style>
