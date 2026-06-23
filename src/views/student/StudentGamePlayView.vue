<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useGameStore } from '@/stores/game'
import type { GameScorePayload } from '@/lib/game-sdk'
import GameFrame from '@/components/game/GameFrame.vue'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const gameStore = useGameStore()

const gameId = route.params.gameId as string
const assignmentId = (route.query.assignmentId as string) || undefined
const classId = (route.query.classId as string) || undefined

const game = computed(() => gameStore.getGameById(gameId))
const showResult = ref(false)
const lastScore = ref<GameScorePayload | null>(null)

onMounted(() => {
  if (gameStore.catalog.length === 0) {
    gameStore.fetchCatalog()
  }
})

async function handleScore(payload: GameScorePayload) {
  if (!auth.userId) return
  await gameStore.saveScore({
    ...payload,
    userId: auth.userId,
    assignmentId,
    classId,
  })
}

async function handleComplete(payload: GameScorePayload) {
  if (!auth.userId) return
  await gameStore.saveScore({
    ...payload,
    userId: auth.userId,
    assignmentId,
    classId,
  })
  lastScore.value = payload
  showResult.value = true
}

function handleExit() {
  router.back()
}

function closeResult() {
  showResult.value = false
  router.back()
}
</script>

<template>
  <div class="fixed inset-0 bg-black z-50 flex flex-col">
    <!-- Top bar -->
    <div class="flex items-center justify-between px-4 py-2 bg-bg-surface">
      <button @click="handleExit" class="text-white/60 text-sm font-title">← 戻る</button>
      <p class="text-white font-title font-semibold text-sm">{{ game?.title_ja || gameId }}</p>
      <div class="w-12"></div>
    </div>

    <!-- Game iframe -->
    <div class="flex-1">
      <GameFrame
        v-if="game"
        :game-url="game.url"
        :game-id="gameId"
        :assignment-id="assignmentId"
        :class-id="classId"
        @score="handleScore"
        @complete="handleComplete"
        @exit="handleExit"
      />
      <div v-else class="flex items-center justify-center h-full text-white/50">
        Loading...
      </div>
    </div>

    <!-- Result overlay -->
    <div
      v-if="showResult && lastScore"
      class="absolute inset-0 bg-black/80 flex items-center justify-center z-60"
    >
      <div class="bg-bg-card rounded-3xl p-8 mx-6 max-w-sm w-full text-center">
        <p class="text-5xl mb-4">🎉</p>
        <h2 class="text-white font-title font-bold text-2xl mb-2">ゲーム完了！</h2>
        <div class="grid grid-cols-2 gap-4 mt-6">
          <div class="bg-bg-surface rounded-xl p-3">
            <p class="text-white/50 text-xs font-title">スコア</p>
            <p class="text-white font-title font-bold text-2xl">{{ lastScore.score }}</p>
          </div>
          <div class="bg-bg-surface rounded-xl p-3">
            <p class="text-white/50 text-xs font-title">正答率</p>
            <p class="text-white font-title font-bold text-2xl">{{ lastScore.accuracy ?? '-' }}%</p>
          </div>
          <div class="bg-bg-surface rounded-xl p-3">
            <p class="text-white/50 text-xs font-title">XP</p>
            <p class="text-brand-primary font-title font-bold text-xl">+{{ lastScore.xpEarned ?? 0 }}</p>
          </div>
          <div class="bg-bg-surface rounded-xl p-3">
            <p class="text-white/50 text-xs font-title">時間</p>
            <p class="text-white font-title font-bold text-xl">{{ lastScore.timeSpent ?? '-' }}s</p>
          </div>
        </div>
        <button
          @click="closeResult"
          class="mt-6 w-full bg-brand-primary text-white font-title font-bold py-3 rounded-xl"
        >
          完了
        </button>
      </div>
    </div>
  </div>
</template>
