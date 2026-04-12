<template>
  <div class="pattern-unlock-screen">

    <!-- 背景グリッド光 -->
    <div class="bg-grid">
      <div class="grid-line" v-for="i in 6" :key="i" :style="gridLineStyle(i)" />
    </div>

    <!-- 図鑑カード登場演出 -->
    <Transition name="card-reveal" appear>
      <div class="unlock-card">

        <!-- 新パターンアイコン -->
        <div class="card-glow" />
        <div class="card-header">
          <span class="new-badge">NEW</span>
          <span class="pattern-id">{{ patternId }}</span>
        </div>

        <h2 class="pattern-text">{{ patternText }}</h2>
        <p class="pattern-ja">{{ patternJa }}</p>

        <!-- ★初期状態 -->
        <div class="stars-row">
          <span class="star-empty">☆</span>
          <span class="star-empty">☆</span>
          <span class="star-empty">☆</span>
          <span class="star-empty">☆</span>
          <span class="star-empty">☆</span>
        </div>

      </div>
    </Transition>

    <!-- Mowi（小さめ・横に浮かぶ） -->
    <div class="mowi-area">
      <MowiOrb
        state="joy"
        :brightness="7"
        size="md"
        :animated="true"
      />
    </div>

    <!-- Mowiセリフ -->
    <Transition name="fade-up" appear>
      <p class="mowi-dialogue">{{ mowiLine }}</p>
    </Transition>

    <!-- アクション -->
    <div class="action-area">
      <button class="btn-practice" @click="goPractice">
        さっそく練習する
      </button>
      <button class="btn-later" @click="goNext">
        あとで
      </button>
    </div>

  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import MowiOrb from '@/components/mowi/MowiOrb.vue'

const router = useRouter()
const route = useRoute()

// ── パターン情報 ──
const patternId = computed(() =>
  (route.query.patternId as string) || 'P???'
)

const patternText = computed(() =>
  (route.query.patternText as string) || ''
)

const patternJa = computed(() =>
  (route.query.patternJa as string) || ''
)

/**
 * Mowiセリフ（Joy: 新パターン解禁時の語りかけ）
 * AGENTS.md 準拠：FirstPattern「初めて会ったね、この言葉と。」
 */
const unlockLines = [
  '初めて会ったね、この言葉と。',
  '新しい形が、見えてきた。',
  'まだ知らない自分がいる。楽しみだね。',
  'ここから始まる。',
  '次の扉が開いた。',
]

const mowiLine = computed(() =>
  unlockLines[Math.floor(Math.random() * unlockLines.length)]
)

// ── Navigation ──
function goPractice() {
  // 新パターンで即練習開始
  router.replace({ name: 'session-start', query: { patternId: patternId.value } })
}

function goNext() {
  // 夜チェックインプロンプトへ（通常フロー）
  router.replace({ name: 'session-end' })
}

// ── 背景グリッドライン ──
function gridLineStyle(i: number) {
  const y = (i / 6) * 100
  return {
    top: `${y}%`,
    animationDelay: `${i * 0.3}s`,
  }
}
</script>

<style scoped>
.pattern-unlock-screen {
  min-height: 100vh;
  background: #0d0d1a;
  color: #f0f0ff;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  font-family: 'Noto Sans JP', sans-serif;
  padding: 2rem 1.25rem;
  gap: 1.5rem;
  position: relative;
  overflow: hidden;
}

/* 背景グリッド */
.bg-grid {
  position: absolute;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

.grid-line {
  position: absolute;
  left: 0;
  right: 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(74, 122, 255, 0.15), transparent);
  animation: grid-scan 3s ease-in-out infinite;
}

@keyframes grid-scan {
  0%, 100% { opacity: 0; transform: scaleX(0.3); }
  50%      { opacity: 1; transform: scaleX(1); }
}

/* 図鑑カード */
.unlock-card {
  width: 100%;
  max-width: 320px;
  background: rgba(255, 255, 255, 0.04);
  border: 1px solid rgba(74, 122, 255, 0.3);
  border-radius: 20px;
  padding: 2rem 1.5rem;
  text-align: center;
  position: relative;
  overflow: hidden;
  z-index: 1;
}

.card-glow {
  position: absolute;
  inset: -2px;
  border-radius: 20px;
  background: linear-gradient(135deg, rgba(74, 122, 255, 0.15), rgba(155, 92, 246, 0.15));
  filter: blur(20px);
  z-index: -1;
}

.card-header {
  display: flex;
  justify-content: center;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 1rem;
}

.new-badge {
  font-size: 0.7rem;
  font-weight: 800;
  color: #0d0d1a;
  background: linear-gradient(135deg, #4A7AFF, #9B5CF6);
  padding: 0.2rem 0.6rem;
  border-radius: 6px;
  letter-spacing: 0.12em;
  animation: badge-glow 2s ease-in-out infinite;
}

@keyframes badge-glow {
  0%, 100% { box-shadow: 0 0 8px rgba(74, 122, 255, 0.4); }
  50%      { box-shadow: 0 0 16px rgba(74, 122, 255, 0.8); }
}

.pattern-id {
  font-size: 1.1rem;
  font-weight: 700;
  color: rgba(255, 255, 255, 0.6);
  letter-spacing: 0.06em;
}

.pattern-text {
  font-size: 1.3rem;
  font-weight: 700;
  color: #f0f0ff;
  margin-bottom: 0.25rem;
  letter-spacing: 0.03em;
}

.pattern-ja {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.4);
  margin-bottom: 1rem;
}

.stars-row {
  display: flex;
  justify-content: center;
  gap: 0.3rem;
}

.star-empty {
  font-size: 1.3rem;
  color: rgba(255, 255, 255, 0.15);
}

/* Mowi */
.mowi-area {
  z-index: 1;
}

/* Mowiセリフ */
.mowi-dialogue {
  font-size: 1.05rem;
  color: rgba(255, 255, 255, 0.7);
  font-style: italic;
  letter-spacing: 0.06em;
  text-align: center;
  z-index: 1;
}

/* アクション */
.action-area {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  z-index: 1;
  margin-top: 0.5rem;
}

.btn-practice {
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
  box-shadow: 0 4px 20px rgba(74, 122, 255, 0.3);
  transition: opacity 0.2s;
}
.btn-practice:hover { opacity: 0.9; }

.btn-later {
  width: 100%;
  padding: 0.75rem;
  background: transparent;
  border: 1px solid rgba(255, 255, 255, 0.15);
  border-radius: 14px;
  color: rgba(255, 255, 255, 0.5);
  font-size: 0.9rem;
  cursor: pointer;
  font-family: 'Noto Sans JP', sans-serif;
  transition: border-color 0.2s, color 0.2s;
}
.btn-later:hover {
  border-color: rgba(255, 255, 255, 0.3);
  color: rgba(255, 255, 255, 0.8);
}

/* Transitions */
.card-reveal-enter-active {
  transition: all 0.8s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.card-reveal-enter-from {
  opacity: 0;
  transform: scale(0.8) translateY(30px);
}

.fade-up-enter-active {
  transition: all 0.6s ease-out 0.4s;
}
.fade-up-enter-from {
  opacity: 0;
  transform: translateY(20px);
}
</style>
