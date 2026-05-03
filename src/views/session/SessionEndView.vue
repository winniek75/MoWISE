<template>
  <div class="session-end-screen">

    <!-- Mowi Grow アニメーション -->
    <div class="mowi-end-area">
      <div class="mowi-orb-wrap mowi--grow">
        <div class="orb-core" :style="orbStyle" />
        <div class="orb-glow" />
        <div class="orb-sparkles">
          <span v-for="i in 8" :key="i" class="sparkle" :style="sparkleStyle(i)" />
        </div>
      </div>
    </div>

    <!-- タイトル -->
    <p class="section-label">── 今日の練習、終わった ──</p>

    <!-- 記録カード -->
    <div class="record-card">
      <h2 class="record-title">今日の記録</h2>

      <div class="record-row">
        <span class="record-label">最大コンボ</span>
        <span class="record-value record-value--highlight">
          {{ sessionStore.maxCombo }} 連続
          <span v-if="sessionStore.maxCombo >= 5">🔥</span>
        </span>
      </div>

      <div class="record-row">
        <span class="record-label">正解率</span>
        <span class="record-value">{{ sessionStore.accuracy }}%</span>
      </div>

      <div class="record-row">
        <span class="record-label">獲得XP</span>
        <span class="record-value record-value--xp">+{{ sessionStore.xpEarned }} XP</span>
      </div>

      <!-- ★UP 表示エリア（セッション中に★が上がった場合） -->
      <div v-if="starUpText" class="star-up-row">
        <span class="star-change">{{ starUpText }}</span>
      </div>
    </div>

    <!-- 明日のお楽しみ -->
    <div class="teaser-block">
      <p class="teaser-label">── 明日のお楽しみ ──</p>
      <p class="teaser-text">{{ teaserCopy }}</p>
    </div>

    <!-- Mowiセリフ -->
    <p class="mowi-end-dialogue">{{ mowiEndLine }}</p>

    <div class="divider" />

    <!-- ★5マスター / 新パターン解禁 演出ボタン -->
    <div v-if="sessionStore.masteredPattern" class="milestone-banner" @click="goPatternMaster">
      <span class="milestone-icon">★</span>
      <span class="milestone-text">{{ sessionStore.masteredPattern.patternId }} をマスターした！</span>
      <span class="milestone-arrow">→</span>
    </div>

    <div v-else-if="sessionStore.unlockedPattern" class="milestone-banner milestone-banner--unlock" @click="goPatternUnlock">
      <span class="milestone-icon">NEW</span>
      <span class="milestone-text">{{ sessionStore.unlockedPattern.patternId }} が解禁された！</span>
      <span class="milestone-arrow">→</span>
    </div>

    <!-- アクションボタン -->
    <div class="action-btns">
      <button class="btn-night-checkin" @click="goNightCheckin">
        🌙 夜のチェックインへ
      </button>
      <button class="btn-home" @click="goHome">
        ホームに戻る
      </button>
    </div>

  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '@/stores/session'
import { useMowiStore } from '@/stores/mowi'
import { useAuthStore } from '@/stores/auth'
import { supabase, isOfflineMode } from '@/lib/supabase'

const router = useRouter()
const sessionStore = useSessionStore()
const mowiStore = useMowiStore()
const authStore = useAuthStore()

// ── Computed ──

const orbStyle = computed(() => {
  // セッション終了後は最大輝度に近い状態
  const br = Math.max(sessionStore.brightness, 7)
  const size = 64 + (br / 10) * 12
  return {
    width:  `${size}px`,
    height: `${size}px`,
    background: `radial-gradient(circle at 35% 35%, rgba(200,220,255,0.9), #4A7AFF 60%, #2a3a8f)`,
    boxShadow:  `0 0 ${20 + br * 4}px rgba(74,122,255,0.7), 0 0 ${40 + br * 6}px rgba(155,92,246,0.3)`,
  }
})

const patternId = computed(() => sessionStore.currentPattern?.patternId ?? 'P001')

/**
 * ★UP 表示テキスト（動的）
 */
const starUpText = computed(() => {
  const p = sessionStore.currentPattern
  if (!p) return ''
  const prev = p.currentStar
  const correctRate = sessionStore.correctCount / Math.max(1, sessionStore.totalQuestions)
  if (correctRate < 0.7) return ''
  const next = Math.min(prev + 1, 5)
  if (next <= prev) return ''
  const stars = (n: number) => '★'.repeat(n) + '☆'.repeat(5 - n)
  return `★ ${p.patternId}   ${stars(prev)} → ${stars(next)}`
})

/**
 * 「終わり際の予告」コピー（H2設計書 ⑦ ロジック準拠）
 */
const teaserCopy = computed(() => {
  const pid = patternId.value
  if (sessionStore.maxCombo >= 10) {
    return `${pid} の次のステージまであと少し。次は音声録音に挑戦できる。`
  }
  if (sessionStore.accuracy >= 80) {
    return `${pid} が ★3 になった。次のパターンが解禁されるかも。`
  }
  return `また明日、ここに。${pid} が少し深くなった。`
})

/**
 * Mowiセリフ（セッション終了 TRIGGER_SESSION_END）
 * スコアに応じて分岐
 */
const mowiEndLine = computed(() => {
  if (sessionStore.maxCombo >= 10) return '全部、体に入った。次の形が見えてきた。'
  if (sessionStore.accuracy >= 80) return '今日の分、確かにある。'
  if (sessionStore.accuracy >= 60) return '積み重なってる。見えなくても。'
  return 'また来た。また動いた。'
})

// ── Helpers ──

function sparkleStyle(i: number) {
  const angle = (i / 8) * 360
  const distance = 48 + Math.random() * 16
  const size = 4 + Math.random() * 4
  return {
    left:   `calc(50% + ${Math.cos(angle * Math.PI / 180) * distance}px)`,
    top:    `calc(50% + ${Math.sin(angle * Math.PI / 180) * distance}px)`,
    width:  `${size}px`,
    height: `${size}px`,
    animationDelay: `${i * 0.15}s`,
  }
}

// ── Navigation ──

function goPatternMaster() {
  const m = sessionStore.masteredPattern
  if (!m) return
  router.push({
    name: 'pattern-master',
    query: {
      patternId: m.patternId,
      patternText: m.patternLabel,
      patternJa: m.patternJa,
      ...(m.evolutionId ? { evolutionId: m.evolutionId, evolutionText: m.evolutionText } : {}),
      ...(sessionStore.unlockedPattern ? {
        unlockPatternId: sessionStore.unlockedPattern.patternId,
        unlockPatternText: sessionStore.unlockedPattern.patternLabel,
        unlockPatternJa: sessionStore.unlockedPattern.patternJa,
      } : {}),
    },
  })
}

function goPatternUnlock() {
  const u = sessionStore.unlockedPattern
  if (!u) return
  router.push({
    name: 'pattern-unlock',
    query: {
      patternId: u.patternId,
      patternText: u.patternLabel,
      patternJa: u.patternJa,
    },
  })
}

function goNightCheckin() {
  sessionStore.endSession()
  router.push({ name: 'checkin-night' })
}

function goHome() {
  sessionStore.endSession()
  router.push({ name: 'Home' })
}

onMounted(async () => {
  // セッション正解率でMowi brightnessを更新
  const correctRate = sessionStore.correctCount / Math.max(1, sessionStore.totalQuestions)
  await mowiStore.updateAfterSession(correctRate)

  // pattern_progress に進捗を保存
  await saveProgress()
})

async function saveProgress() {
  if (isOfflineMode || !authStore.userId) return
  const pattern = sessionStore.currentPattern
  if (!pattern) return

  try {
    // 既存の進捗を確認
    const { data: existing } = await supabase
      .from('pattern_progress')
      .select('*')
      .eq('user_id', authStore.userId)
      .eq('pattern_no', pattern.patternId)
      .maybeSingle()

    const correctRate = sessionStore.correctCount / Math.max(1, sessionStore.totalQuestions)
    const passed = correctRate >= 0.7

    if (existing) {
      // 既存レコード更新
      const updates: Record<string, any> = {
        correct_count: (existing as any).correct_count + sessionStore.correctCount,
        wrong_count: (existing as any).wrong_count + sessionStore.wrongCount,
        updated_at: new Date().toISOString(),
      }
      // Layer完了フラグを更新（passした場合）
      if (passed) {
        if (sessionStore.currentLayer === 0) updates.layer0_done = true
        if (sessionStore.currentLayer === 1) updates.layer1_done = true
        if (sessionStore.layer2Cleared) updates.layer2_done = true
        if (sessionStore.layer3Cleared) updates.layer3_done = true
        // ★を上げる（最大5）
        const currentStars = (existing as any).mastery_level ?? 0
        if (currentStars < 5) {
          const newStars = Math.min(currentStars + 1, 5)
          updates.mastery_level = newStars
          // ★5到達 → masteredPattern セット
          if (newStars === 5) {
            sessionStore.masteredPattern = {
              patternId: pattern.patternId,
              patternLabel: pattern.patternLabel,
              patternJa: pattern.patternJa,
            }
          }
          // ★3到達 → 次パターン解禁チェック
          if (newStars >= 3 && currentStars < 3) {
            await checkUnlockNextPattern(pattern.patternId)
          }
        }
      }
      await supabase
        .from('pattern_progress')
        .update(updates)
        .eq('id', (existing as any).id)
    } else {
      // 新規レコード作成
      const newStars = passed ? 1 : 0
      await supabase
        .from('pattern_progress')
        .insert({
          user_id: authStore.userId,
          pattern_no: pattern.patternId,
          mastery_level: newStars,
          layer0_done: passed && sessionStore.currentLayer === 0,
          layer1_done: false,
          layer2_done: false,
          layer3_done: false,
          correct_count: sessionStore.correctCount,
          wrong_count: sessionStore.wrongCount,
        })
    }
  } catch (e) {
    console.warn('[SessionEnd] saveProgress failed:', e)
  }
}

/** 次パターン解禁チェック（★3到達時） */
async function checkUnlockNextPattern(currentPatternId: string) {
  try {
    const num = parseInt(currentPatternId.replace('P', ''), 10)
    const nextNo = `P${String(num + 1).padStart(3, '0')}`
    // 次パターンがDB上に存在するか確認
    const { data: nextPattern } = await supabase
      .from('patterns')
      .select('pattern_no, pattern_text, japanese')
      .eq('pattern_no', nextNo)
      .maybeSingle()
    if (!nextPattern) return
    // 既に進捗がある場合は解禁済み
    const { data: alreadyExists } = await supabase
      .from('pattern_progress')
      .select('id')
      .eq('user_id', authStore.userId!)
      .eq('pattern_no', nextNo)
      .maybeSingle()
    if (alreadyExists) return
    sessionStore.unlockedPattern = {
      patternId: (nextPattern as any).pattern_no,
      patternLabel: (nextPattern as any).pattern_text,
      patternJa: (nextPattern as any).japanese,
    }
  } catch (e) {
    console.warn('[SessionEnd] checkUnlockNextPattern failed:', e)
  }
}
</script>

<style scoped>
.session-end-screen {
  min-height: 100vh;
  background: #0d0d1a;
  color: #f0f0ff;
  display: flex;
  flex-direction: column;
  align-items: center;
  font-family: 'Noto Sans JP', sans-serif;
  padding: 2rem 1.25rem 3rem;
  gap: 1.5rem;
}

/* Mowi */
.mowi-end-area {
  padding-top: 1rem;
}

.mowi-orb-wrap {
  position: relative;
  width: 100px;
  height: 100px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.orb-core {
  border-radius: 50%;
  animation: end-grow 0.8s ease-out both, float-idle 3s ease-in-out 0.8s infinite;
}

.orb-glow {
  position: absolute;
  inset: -18px;
  border-radius: 50%;
  background: radial-gradient(circle, rgba(74,122,255,0.2), transparent 70%);
  animation: glow-pulse 2s ease-in-out infinite;
}

.orb-sparkles {
  position: absolute;
  inset: 0;
}

.sparkle {
  position: absolute;
  border-radius: 50%;
  background: #FFD700;
  transform: translate(-50%, -50%);
  animation: sparkle-burst 1.5s ease-out infinite;
}

.section-label {
  font-size: 0.78rem;
  color: rgba(255,255,255,0.35);
  letter-spacing: 0.2em;
}

/* 記録カード */
.record-card {
  width: 100%;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.09);
  border-radius: 16px;
  padding: 1.25rem 1.5rem;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.record-title {
  font-size: 0.85rem;
  color: rgba(255,255,255,0.4);
  font-weight: 400;
  letter-spacing: 0.1em;
}

.record-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.record-label {
  font-size: 0.9rem;
  color: rgba(255,255,255,0.5);
}

.record-value {
  font-size: 1.05rem;
  font-weight: 700;
  color: #f0f0ff;
}

.record-value--highlight { color: #FF9800; }
.record-value--xp        { color: #9B5CF6; }

.star-up-row {
  padding-top: 0.5rem;
  border-top: 1px solid rgba(255,255,255,0.06);
}

.star-change {
  font-size: 0.85rem;
  color: #FFD700;
  font-weight: 600;
  letter-spacing: 0.05em;
}

/* テイザー */
.teaser-block {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
  align-items: center;
}

.teaser-label {
  font-size: 0.78rem;
  color: rgba(255,255,255,0.3);
  letter-spacing: 0.2em;
}

.teaser-text {
  font-size: 0.9rem;
  color: rgba(255,255,255,0.6);
  text-align: center;
  line-height: 1.7;
  letter-spacing: 0.03em;
}

/* Mowiセリフ */
.mowi-end-dialogue {
  font-size: 1.05rem;
  color: rgba(255,255,255,0.7);
  font-style: italic;
  letter-spacing: 0.06em;
  text-align: center;
}

.divider {
  width: 100%;
  height: 1px;
  background: rgba(255,255,255,0.07);
}

/* ボタン */
.action-btns {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.btn-night-checkin {
  width: 100%;
  padding: 1rem;
  background: linear-gradient(135deg, #4A7AFF, #9B5CF6);
  border: none;
  border-radius: 14px;
  color: white;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  font-family: 'Noto Sans JP', sans-serif;
  letter-spacing: 0.04em;
  box-shadow: 0 4px 20px rgba(74,122,255,0.3);
  transition: opacity 0.2s;
}
.btn-night-checkin:hover { opacity: 0.9; }

.btn-home {
  width: 100%;
  padding: 0.75rem;
  background: transparent;
  border: 1px solid rgba(255,255,255,0.15);
  border-radius: 14px;
  color: rgba(255,255,255,0.5);
  font-size: 0.9rem;
  cursor: pointer;
  font-family: 'Noto Sans JP', sans-serif;
  transition: border-color 0.2s, color 0.2s;
}
.btn-home:hover {
  border-color: rgba(255,255,255,0.3);
  color: rgba(255,255,255,0.8);
}

/* マイルストーンバナー */
.milestone-banner {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.9rem 1.25rem;
  background: rgba(255, 215, 0, 0.08);
  border: 1px solid rgba(255, 215, 0, 0.25);
  border-radius: 14px;
  cursor: pointer;
  transition: background 0.2s;
  animation: banner-appear 0.6s ease-out both 0.5s;
}
.milestone-banner:hover {
  background: rgba(255, 215, 0, 0.14);
}

.milestone-banner--unlock {
  background: rgba(74, 122, 255, 0.08);
  border-color: rgba(74, 122, 255, 0.25);
}
.milestone-banner--unlock:hover {
  background: rgba(74, 122, 255, 0.14);
}

.milestone-icon {
  font-size: 1.1rem;
  font-weight: 800;
  color: #FFD700;
  flex-shrink: 0;
}
.milestone-banner--unlock .milestone-icon {
  font-size: 0.7rem;
  color: #0d0d1a;
  background: linear-gradient(135deg, #4A7AFF, #9B5CF6);
  padding: 0.15rem 0.5rem;
  border-radius: 5px;
  letter-spacing: 0.1em;
}

.milestone-text {
  font-size: 0.9rem;
  color: rgba(255, 255, 255, 0.8);
  font-weight: 600;
  flex: 1;
}

.milestone-arrow {
  font-size: 1rem;
  color: rgba(255, 255, 255, 0.4);
}

@keyframes banner-appear {
  from { opacity: 0; transform: translateY(10px); }
  to   { opacity: 1; transform: translateY(0); }
}

/* Keyframes */
@keyframes float-idle {
  0%, 100% { transform: translateY(0); }
  50%       { transform: translateY(-7px); }
}

@keyframes end-grow {
  from { transform: scale(0.4); opacity: 0; }
  to   { transform: scale(1); opacity: 1; }
}

@keyframes glow-pulse {
  0%, 100% { opacity: 0.6; transform: scale(1); }
  50%       { opacity: 1;   transform: scale(1.12); }
}

@keyframes sparkle-burst {
  0%   { opacity: 0; transform: translate(-50%, -50%) scale(0); }
  30%  { opacity: 1; transform: translate(-50%, -50%) scale(1.2); }
  100% { opacity: 0; transform: translate(-50%, -50%) scale(0.3); }
}
</style>
