<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useGameStore } from '@/stores/game'
import { useMissionStore } from '@/stores/mission'
import type { GameScorePayload } from '@/lib/game-sdk'
import GameFrame from '@/components/game/GameFrame.vue'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const gameStore = useGameStore()

const gameId = route.params.gameId as string
const assignmentId = (route.query.assignmentId as string) || undefined
const classId = (route.query.classId as string) || undefined

const missionStore = useMissionStore()

const game = computed(() => gameStore.getGameById(gameId))
const showResult = ref(false)
const lastScore = ref<GameScorePayload | null>(null)

onMounted(async () => {
  if (gameStore.catalog.length === 0) {
    await gameStore.fetchCatalog()
  }
  if (auth.userId) {
    await gameStore.fetchUserBadges(auth.userId)
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
  // Update mission: play_game
  await missionStore.updateMissionProgress(auth.userId, 'play_game', 1)
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

  // Update missions
  await missionStore.updateMissionProgress(auth.userId, 'complete_game', 1)
  if (payload.accuracy != null) {
    await missionStore.updateMissionProgress(auth.userId, 'accuracy_above', payload.accuracy)
  }
}

function handleExit() {
  gameStore.clearNewBadges()
  router.back()
}

function closeResult() {
  showResult.value = false
  gameStore.clearNewBadges()
  router.back()
}
</script>

<template>
  <div class="fixed inset-0 bg-black z-50 flex flex-col">
    <!-- Top bar -->
    <div class="flex items-center justify-between px-4 py-2 bg-bg-surface">
      <button @click="handleExit" class="text-white/40 text-sm font-title hover:text-white/60 transition-colors">← 戻る</button>
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
      <div v-else class="flex items-center justify-center h-full">
        <div class="w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full animate-spin" />
      </div>
    </div>

    <!-- Result overlay -->
    <div
      v-if="showResult && lastScore"
      class="absolute inset-0 bg-black/80 flex items-center justify-center z-60"
      style="backdrop-filter: blur(8px)"
    >
      <div class="neo-modal !max-w-sm mx-6 text-center">
        <p class="text-5xl mb-3">🎉</p>
        <h2 class="text-white font-title font-bold text-2xl mb-2">ゲーム完了！</h2>
        <div class="grid grid-cols-2 gap-3 mt-5">
          <div class="neo-card !p-3 text-center">
            <p class="text-white/30 text-[11px] font-title">スコア</p>
            <p class="text-white font-title font-bold text-2xl">{{ lastScore.score }}</p>
          </div>
          <div class="neo-card !p-3 text-center">
            <p class="text-white/30 text-[11px] font-title">正答率</p>
            <p class="text-white font-title font-bold text-2xl">{{ lastScore.accuracy ?? '-' }}%</p>
          </div>
          <div class="neo-card !p-3 text-center">
            <p class="text-white/30 text-[11px] font-title">コイン</p>
            <p class="text-neon-yellow font-title font-bold text-xl">+{{ gameStore.lastReward.coins }}</p>
          </div>
          <div class="neo-card !p-3 text-center">
            <p class="text-white/30 text-[11px] font-title">ガチャチケット</p>
            <p class="text-neon-purple font-title font-bold text-xl">+{{ gameStore.lastReward.tickets }}</p>
          </div>
        </div>

        <!-- New badges -->
        <div v-if="gameStore.newlyEarnedBadges.length > 0" class="mt-5 pt-4 border-t border-white/[0.06]">
          <p class="text-neon-yellow text-xs font-title font-bold uppercase tracking-wider mb-3">バッジ獲得！</p>
          <div class="flex justify-center gap-3">
            <div
              v-for="badge in gameStore.newlyEarnedBadges"
              :key="badge.id"
              class="flex flex-col items-center gap-1 animate-pop-in"
            >
              <div class="w-12 h-12 rounded-full bg-neon-yellow/10 flex items-center justify-center text-2xl border border-neon-yellow/20 shadow-neo-sm">
                {{ badge.icon }}
              </div>
              <span class="text-[10px] text-neon-yellow font-title font-semibold">{{ badge.title_ja }}</span>
            </div>
          </div>
        </div>

        <button
          @click="closeResult"
          class="btn-neo w-full mt-6"
        >
          完了
        </button>
      </div>
    </div>
  </div>
</template>
