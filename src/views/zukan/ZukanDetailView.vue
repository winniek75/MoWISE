<template>
  <div class="min-h-screen bg-gray-50 pb-24">
    <header class="bg-white border-b border-gray-200 px-4 py-3 flex items-center gap-3">
      <button @click="router.back()" class="text-gray-500">←</button>
      <h1 class="font-bold text-gray-900">{{ pattern?.pattern_no }}</h1>
    </header>

    <div v-if="pattern" class="px-4 py-6 space-y-4">
      <!-- パターン本体 -->
      <div class="bg-white rounded-2xl p-5 shadow-sm">
        <p class="text-2xl font-bold text-gray-900 mb-1">{{ pattern.pattern_text }}</p>
        <p class="text-gray-500 text-base">{{ pattern.japanese }}</p>
        <!-- 星 -->
        <div class="flex gap-1 mt-3">
          <span v-for="n in 5" :key="n" class="text-xl"
            :class="n <= (progressData?.star_level ?? 0) ? 'text-yellow-400' : 'text-gray-200'">★</span>
        </div>
        <p class="text-xs text-gray-400 mt-1">Layer {{ progressData?.layer_completed ?? 0 }} まで完了</p>
      </div>

      <!-- 例文 -->
      <div class="bg-white rounded-2xl p-5 shadow-sm">
        <p class="text-xs font-bold text-gray-400 mb-3">例文</p>
        <div v-for="ex in pattern.examples" :key="ex.english" class="mb-3 last:mb-0">
          <div class="flex items-start gap-2">
            <button class="text-indigo-500 mt-0.5" @click="playAudio(ex.audio_url)">🔊</button>
            <div>
              <p class="font-bold text-gray-900">"{{ ex.english }}"</p>
              <p class="text-sm text-gray-500">{{ ex.japanese }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- 進化形 -->
      <div v-if="pattern.evolution_to" class="bg-indigo-50 rounded-2xl p-5">
        <p class="text-xs font-bold text-indigo-400 mb-2">進化形</p>
        <p class="font-bold text-indigo-700">{{ pattern.evolution_to.pattern_no }}：{{ pattern.evolution_to.pattern_text }}</p>
        <p class="text-sm text-indigo-500">★5で解禁</p>
      </div>

      <!-- 練習ボタン -->
      <button
        @click="startPractice"
        class="w-full py-4 bg-indigo-500 hover:bg-indigo-600 text-white font-bold rounded-2xl text-base active:scale-[0.98] transition-transform"
      >
        このパターンを練習する
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useZukanStore } from '@/stores/zukan'
import { useSessionStore } from '@/stores/session'

const route        = useRoute()
const router       = useRouter()
const zukanStore   = useZukanStore()
const sessionStore = useSessionStore()

const pattern      = ref<any>(null)
const progressData = ref<any>(null)
const patternNo    = route.params.id as string

onMounted(async () => {
  pattern.value      = await zukanStore.fetchDetail(patternNo)
  progressData.value = await zukanStore.fetchProgress(patternNo)
})

function playAudio(url: string) {
  if (url) new Audio(url).play()
}

function startPractice() {
  // sessionStore にパターンをセットして練習開始画面へ
  sessionStore.startSession([{
    patternId:    pattern.value.pattern_no,
    patternLabel: pattern.value.pattern_text,
    patternJa:    pattern.value.japanese,
    currentStar:  progressData.value?.star_level ?? 0,
    startLayer:   2,
  }])
  router.push('/session/start')
}
</script>
