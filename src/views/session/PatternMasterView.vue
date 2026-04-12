<template>
  <div class="pattern-master-screen">

    <!-- 背景パーティクル -->
    <div class="bg-particles">
      <span v-for="i in 20" :key="i" class="bg-particle" :style="bgParticleStyle(i)" />
    </div>

    <!-- Mowi Grow 演出 -->
    <div class="mowi-area">
      <MowiOrb
        state="grow"
        :brightness="10"
        size="lg"
        :animated="true"
      />
    </div>

    <!-- マスター宣言 -->
    <Transition name="fade-up" appear>
      <div class="master-badge">
        <div class="stars-row">
          <span v-for="i in 5" :key="i" class="star-icon">★</span>
        </div>
        <h1 class="master-title">Pattern Master!</h1>
        <p class="pattern-label">{{ patternId }} {{ patternText }}</p>
        <p class="pattern-ja">{{ patternJa }}</p>
      </div>
    </Transition>

    <!-- Mowiセリフ -->
    <Transition name="fade-up" appear>
      <p class="mowi-dialogue">{{ mowiLine }}</p>
    </Transition>

    <!-- 進化形プレビュー（あれば） -->
    <Transition name="fade-up" appear>
      <div v-if="evolutionPattern" class="evolution-card">
        <p class="evolution-label">── 進化形が解禁された ──</p>
        <div class="evolution-info">
          <span class="evolution-id">{{ evolutionPattern.id }}</span>
          <span class="evolution-text">{{ evolutionPattern.text }}</span>
        </div>
      </div>
    </Transition>

    <!-- アクション -->
    <div class="action-area">
      <button class="btn-continue" @click="proceed">
        次へ進む
      </button>
    </div>

  </div>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useSessionStore } from '@/stores/session'
import MowiOrb from '@/components/mowi/MowiOrb.vue'

const router = useRouter()
const route = useRoute()
const sessionStore = useSessionStore()

// ── Props via route query ──
const patternId = computed(() =>
  (route.query.patternId as string) || sessionStore.currentPattern?.patternId || 'P001'
)

const patternText = computed(() =>
  (route.query.patternText as string) || sessionStore.currentPattern?.patternLabel || ''
)

const patternJa = computed(() =>
  (route.query.patternJa as string) || sessionStore.currentPattern?.patternJa || ''
)

// ── 進化形（あれば） ──
const evolutionPattern = computed(() => {
  const evoId = route.query.evolutionId as string
  const evoText = route.query.evolutionText as string
  if (evoId && evoText) {
    return { id: evoId, text: evoText }
  }
  return null
})

/**
 * Mowiセリフ（Grow: ★5マスター時の語りかけ）
 * AGENTS.md 準拠：「Mowiがそこで見ていたから言える、具体的な一言」
 */
const masterLines = [
  'ここまで来たのは、毎日の分だよ。',
  '最初に会ったときと、全然違う。',
  'もう体が覚えてる。忘れない。',
  '全部、自分のものになった。',
  'この言葉は、もう君の一部だよ。',
]

const mowiLine = computed(() =>
  masterLines[Math.floor(Math.random() * masterLines.length)]
)

// ── Navigation ──
function proceed() {
  // 新パターン解禁があればそちらへ、なければセッション終了フローへ
  const unlockId = route.query.unlockPatternId as string
  if (unlockId) {
    router.replace({
      name: 'pattern-unlock',
      query: {
        patternId: unlockId,
        patternText: route.query.unlockPatternText,
        patternJa: route.query.unlockPatternJa,
      },
    })
  } else {
    router.replace({ name: 'session-end' })
  }
}

// ── 背景パーティクル ──
function bgParticleStyle(i: number) {
  const size = 2 + Math.random() * 4
  const x = Math.random() * 100
  const delay = Math.random() * 4
  const duration = 3 + Math.random() * 4
  return {
    width: `${size}px`,
    height: `${size}px`,
    left: `${x}%`,
    animationDelay: `${delay}s`,
    animationDuration: `${duration}s`,
  }
}

onMounted(() => {
  // 将来的に効果音再生を追加
})
</script>

<style scoped>
.pattern-master-screen {
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

/* 背景パーティクル */
.bg-particles {
  position: absolute;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

.bg-particle {
  position: absolute;
  bottom: -10px;
  border-radius: 50%;
  background: rgba(255, 215, 0, 0.6);
  animation: particle-rise linear infinite;
}

@keyframes particle-rise {
  0%   { transform: translateY(0) scale(1); opacity: 0; }
  10%  { opacity: 0.8; }
  90%  { opacity: 0.3; }
  100% { transform: translateY(-100vh) scale(0.3); opacity: 0; }
}

/* Mowi */
.mowi-area {
  z-index: 1;
}

/* マスターバッジ */
.master-badge {
  text-align: center;
  z-index: 1;
}

.stars-row {
  display: flex;
  justify-content: center;
  gap: 0.4rem;
  margin-bottom: 0.75rem;
}

.star-icon {
  font-size: 1.8rem;
  color: #FFD700;
  animation: star-pop 0.4s ease-out both;
  text-shadow: 0 0 12px rgba(255, 215, 0, 0.8);
}

.star-icon:nth-child(1) { animation-delay: 0.1s; }
.star-icon:nth-child(2) { animation-delay: 0.2s; }
.star-icon:nth-child(3) { animation-delay: 0.3s; }
.star-icon:nth-child(4) { animation-delay: 0.4s; }
.star-icon:nth-child(5) { animation-delay: 0.5s; }

@keyframes star-pop {
  0%   { transform: scale(0) rotate(-30deg); opacity: 0; }
  60%  { transform: scale(1.3) rotate(10deg); opacity: 1; }
  100% { transform: scale(1) rotate(0deg); opacity: 1; }
}

.master-title {
  font-size: 1.6rem;
  font-weight: 800;
  background: linear-gradient(135deg, #FFD700, #FF9800, #FFD700);
  background-clip: text;
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  letter-spacing: 0.08em;
  margin-bottom: 0.75rem;
}

.pattern-label {
  font-size: 1.1rem;
  color: rgba(255, 255, 255, 0.85);
  font-weight: 600;
  letter-spacing: 0.04em;
}

.pattern-ja {
  font-size: 0.85rem;
  color: rgba(255, 255, 255, 0.45);
  margin-top: 0.25rem;
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

/* 進化形カード */
.evolution-card {
  width: 100%;
  background: rgba(255, 215, 0, 0.06);
  border: 1px solid rgba(255, 215, 0, 0.2);
  border-radius: 16px;
  padding: 1rem 1.25rem;
  text-align: center;
  z-index: 1;
}

.evolution-label {
  font-size: 0.78rem;
  color: rgba(255, 215, 0, 0.5);
  letter-spacing: 0.2em;
  margin-bottom: 0.5rem;
}

.evolution-info {
  display: flex;
  justify-content: center;
  gap: 0.5rem;
  align-items: baseline;
}

.evolution-id {
  font-size: 0.85rem;
  color: #FFD700;
  font-weight: 700;
}

.evolution-text {
  font-size: 0.95rem;
  color: rgba(255, 255, 255, 0.7);
}

/* アクション */
.action-area {
  width: 100%;
  z-index: 1;
  margin-top: 0.5rem;
}

.btn-continue {
  width: 100%;
  padding: 1rem;
  background: linear-gradient(135deg, #FFD700, #FF9800);
  border: none;
  border-radius: 14px;
  color: #0d0d1a;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  font-family: 'Noto Sans JP', sans-serif;
  letter-spacing: 0.04em;
  box-shadow: 0 4px 20px rgba(255, 215, 0, 0.3);
  transition: opacity 0.2s;
}
.btn-continue:hover { opacity: 0.9; }

/* Transitions */
.fade-up-enter-active {
  transition: all 0.6s ease-out;
}
.fade-up-enter-from {
  opacity: 0;
  transform: translateY(20px);
}
</style>
