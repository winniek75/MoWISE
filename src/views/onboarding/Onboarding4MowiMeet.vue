<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router    = useRouter()
const phase     = ref<'dark' | 'appear' | 'speak'>('dark')
const mowiLine  = ref('')

const lines = [
  'ここにいる。',
  'まだ、かすかに。',
  'あなたが英語を話すとき、ぼくは輝く。',
]

onMounted(async () => {
  await delay(800)
  phase.value = 'appear'
  await delay(1200)
  phase.value = 'speak'
  for (const line of lines) {
    mowiLine.value = ''
    for (const ch of line) {
      mowiLine.value += ch
      await delay(60)
    }
    await delay(1000)
  }
})

function delay(ms: number) {
  return new Promise(r => setTimeout(r, ms))
}
</script>

<template>
  <div
    class="min-h-screen flex flex-col items-center justify-center safe-pt safe-pb px-6 gap-12 cursor-pointer"
    @click="router.push({ name: 'Onboarding5' })"
  >
    <!-- 背景光 -->
    <Transition name="bg-glow">
      <div v-if="phase !== 'dark'"
           class="absolute inset-0 pointer-events-none"
           style="background: radial-gradient(circle at 50% 42%, rgba(155,92,246,0.06) 0%, transparent 65%);" />
    </Transition>

    <!-- Mowiオーブ：最初はモノクロ（grayscale = growth_stage 0） -->
    <Transition name="mowi-appear">
      <div v-if="phase !== 'dark'" class="relative">
        <div
          class="w-36 h-36 mowi-orb transition-all duration-1500"
          :class="phase === 'dark' ? 'grayscale opacity-10' : 'grayscale opacity-60'"
        />
        <!-- 光の粒子 -->
        <div v-if="phase === 'speak'" class="absolute inset-0 rounded-full border border-brand-secondary/20 scale-150 animate-ping"
             style="animation-duration: 2.5s;" />
      </div>
    </Transition>

    <!-- Mowiセリフ -->
    <Transition name="fade-up">
      <div v-if="phase === 'speak'" class="text-center max-w-xs">
        <p class="mowi-quote text-lg text-white/70 min-h-[3rem]">
          {{ mowiLine }}
          <span class="animate-pulse">|</span>
        </p>
      </div>
    </Transition>

    <!-- スキップヒント -->
    <Transition name="fade-up">
      <p v-if="phase === 'speak'" class="text-white/20 text-xs font-title absolute bottom-10">
        タップして進む
      </p>
    </Transition>
  </div>
</template>

<style scoped>
.mowi-appear-enter-active { transition: all 1.2s ease-out; }
.mowi-appear-enter-from   { opacity: 0; transform: scale(0.6); }

.bg-glow-enter-active { transition: opacity 1.5s ease; }
.bg-glow-enter-from   { opacity: 0; }

.fade-up-enter-active { transition: all 0.6s ease-out; }
.fade-up-enter-from   { opacity: 0; transform: translateY(12px); }
</style>
