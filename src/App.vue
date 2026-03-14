<script setup lang="ts">
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()

onMounted(async () => {
  await auth.initialize()
})
</script>

<template>
  <div id="app-root" class="min-h-screen bg-bg-dark">
    <RouterView v-if="!auth.loading" />
    <!-- 初期ローディング -->
    <div
      v-else
      class="min-h-screen flex items-center justify-center bg-bg-dark"
    >
      <div class="flex flex-col items-center gap-4">
        <!-- Mowiオーブ（ローディング中はグレー） -->
        <div
          class="w-20 h-20 mowi-orb grayscale animate-mowi-pulse"
          aria-hidden="true"
        />
        <p class="text-white/50 text-sm font-title">MoWISE</p>
      </div>
    </div>
  </div>
</template>
