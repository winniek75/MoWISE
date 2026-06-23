<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'
import { onGameEvent, offGameEvent, sendToGame, initGameListener } from '@/lib/game-sdk'
import type { GameScorePayload } from '@/lib/game-sdk'

const props = defineProps<{
  gameUrl: string
  gameId: string
  assignmentId?: string
  classId?: string
}>()

const emit = defineEmits<{
  score: [payload: GameScorePayload]
  complete: [payload: GameScorePayload]
  exit: []
  ready: []
}>()

const iframeRef = ref<HTMLIFrameElement | null>(null)
const isLoading = ref(true)

function handleScore(payload: GameScorePayload) {
  emit('score', payload)
}

function handleComplete(payload: GameScorePayload) {
  emit('complete', payload)
}

function handleExit() {
  emit('exit')
}

function handleReady() {
  isLoading.value = false
  emit('ready')
  // Send init config to game
  if (iframeRef.value) {
    sendToGame(iframeRef.value, 'INIT_GAME', {
      gameId: props.gameId,
      assignmentId: props.assignmentId,
      classId: props.classId,
    })
  }
}

onMounted(() => {
  initGameListener()
  onGameEvent('GAME_SCORE', handleScore)
  onGameEvent('GAME_COMPLETE', handleComplete)
  onGameEvent('GAME_EXIT', handleExit)
  onGameEvent('GAME_READY', handleReady as any)
})

onUnmounted(() => {
  offGameEvent('GAME_SCORE', handleScore)
  offGameEvent('GAME_COMPLETE', handleComplete)
  offGameEvent('GAME_EXIT', handleExit)
  offGameEvent('GAME_READY', handleReady as any)
})

function onIframeLoad() {
  // Fallback: if game doesn't send GAME_READY, hide loading after 3s
  setTimeout(() => { isLoading.value = false }, 3000)
}
</script>

<template>
  <div class="relative w-full h-full bg-black">
    <!-- Loading overlay -->
    <div
      v-if="isLoading"
      class="absolute inset-0 flex items-center justify-center bg-bg-dark z-10"
    >
      <div class="flex flex-col items-center gap-3">
        <div class="w-10 h-10 border-4 border-brand-primary border-t-transparent rounded-full animate-spin"></div>
        <p class="text-white/60 text-sm">Loading game...</p>
      </div>
    </div>

    <!-- Game iframe -->
    <iframe
      ref="iframeRef"
      :src="gameUrl"
      class="w-full h-full border-0"
      allow="autoplay; microphone; fullscreen"
      sandbox="allow-scripts allow-same-origin allow-popups allow-forms"
      @load="onIframeLoad"
    />
  </div>
</template>
