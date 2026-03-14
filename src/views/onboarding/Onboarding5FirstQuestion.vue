<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useMowiStore } from '@/stores/mowi'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const mowi   = useMowiStore()
const auth   = useAuthStore()

// P001 Layer 0 のサンプル問題（hardcode for onboarding）
const question = {
  prompt: '次の英語を聞いて、合うものを選んでください',
  english: "I'm tired.",
  choices: ['疲れた', '嬉しい', '眠い', '悲しい'],
  correct: 0,
}

const selected  = ref<number | null>(null)
const phase     = ref<'question' | 'correct' | 'complete'>('question')
const mowiPhase = ref<'gray' | 'glow'>('gray')

async function choose(idx: number) {
  if (selected.value !== null) return
  selected.value = idx
  if (idx === question.correct) {
    phase.value     = 'correct'
    mowiPhase.value = 'glow'   // 正解で初めてMowiが光る
    if (auth.userId) await mowi.unlockFirstLight(auth.userId)
    await delay(2200)
    phase.value = 'complete'
  }
}

function delay(ms: number) {
  return new Promise(r => setTimeout(r, ms))
}

function goHome() {
  router.replace({ name: 'Home' })
}
</script>

<template>
  <div class="min-h-screen flex flex-col safe-pt safe-pb px-6 py-10 gap-8">

    <!-- Mowiオーブ：正解で輝く -->
    <div class="flex justify-center">
      <div
        class="w-24 h-24 mowi-orb transition-all duration-1000"
        :class="{
          'grayscale': mowiPhase === 'gray',
          'glow-mid animate-mowi-glow': mowiPhase === 'glow',
        }"
      />
    </div>

    <!-- 問題フェーズ -->
    <Transition name="fade-up" mode="out-in">
      <!-- 問題表示 -->
      <div v-if="phase === 'question'" key="q" class="flex flex-col gap-6">
        <div class="mowisse-card text-center space-y-3">
          <p class="text-white/50 text-sm font-title">{{ question.prompt }}</p>
          <p class="pattern-text">"{{ question.english }}"</p>
        </div>

        <div class="grid grid-cols-2 gap-3">
          <button
            v-for="(c, i) in question.choices"
            :key="i"
            class="mowisse-card text-center py-4 font-title text-white transition-all duration-150 active:scale-95"
            :class="{
              'border-correct bg-correct/10': selected === i && i === question.correct,
              'border-wrong   bg-wrong/10':   selected === i && i !== question.correct,
            }"
            @click="choose(i)"
          >
            {{ c }}
          </button>
        </div>
      </div>

      <!-- 正解フィードバック -->
      <div v-else-if="phase === 'correct'" key="correct" class="flex flex-col items-center gap-6 text-center">
        <div class="text-5xl">✨</div>
        <div class="space-y-2">
          <p class="font-title text-2xl font-bold text-white">正解！</p>
          <p class="mowi-quote">"I'm tired." — 疲れた。</p>
        </div>
        <p class="text-white/50 text-sm leading-relaxed max-w-xs">
          Mowiが光った。<br/>
          あなたが英語を使うたびに、<br/>少しずつ輝いていく。
        </p>
      </div>

      <!-- 完了 -->
      <div v-else key="complete" class="flex flex-col items-center gap-8 text-center">
        <p class="mowi-quote text-xl">準備できた。</p>
        <button class="btn-primary w-full max-w-xs font-title text-lg" @click="goHome">
          MoWISEをはじめる →
        </button>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.fade-up-enter-active { transition: all 0.5s ease-out; }
.fade-up-enter-from   { opacity: 0; transform: translateY(16px); }
.fade-up-leave-active { transition: all 0.3s ease-in; }
.fade-up-leave-to     { opacity: 0; transform: translateY(-8px); }
</style>
