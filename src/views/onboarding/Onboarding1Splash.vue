<script setup lang="ts">
import { useRouter } from 'vue-router'
import { onMounted, ref } from 'vue'

const router  = useRouter()
const visible = ref(false)

onMounted(() => {
  setTimeout(() => { visible.value = true }, 100)
})
</script>

<template>
  <div class="min-h-screen flex flex-col items-center justify-center safe-pt safe-pb px-6">
    <!-- 背景エフェクト -->
    <div class="absolute inset-0 pointer-events-none">
      <div class="absolute top-1/4 left-1/2 -translate-x-1/2 w-96 h-96 rounded-full"
           style="background: radial-gradient(circle, rgba(74,122,255,0.08) 0%, transparent 70%)" />
    </div>

    <!-- コンテンツ -->
    <Transition name="fade-up">
      <div v-if="visible" class="flex flex-col items-center gap-10 text-center">
        <!-- Mowiオーブ（スプラッシュでグレー） -->
        <div class="relative">
          <div class="w-28 h-28 mowi-orb grayscale animate-mowi-pulse" />
          <!-- 光のリング -->
          <div class="absolute inset-0 rounded-full border border-white/10 scale-125 animate-ping"
               style="animation-duration: 3s;" />
        </div>

        <!-- タイトル -->
        <div class="space-y-2">
          <h1 class="font-title text-5xl font-bold text-white tracking-tight">
            MoWISE
          </h1>
          <p class="text-white/50 text-sm tracking-widest font-title uppercase">
            もっと賢く、英語と生きる
          </p>
        </div>

        <!-- 始めるボタン -->
        <button
          class="btn-primary w-full max-w-xs text-lg font-title"
          @click="router.push({ name: 'Onboarding2' })"
        >
          はじめる
        </button>

        <!-- ログイン済みの方 -->
        <button
          class="text-white/40 text-sm underline"
          @click="router.push({ name: 'Onboarding2' })"
        >
          ログインはこちら
        </button>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.fade-up-enter-active { transition: all 0.7s ease-out; }
.fade-up-enter-from  { opacity: 0; transform: translateY(24px); }
</style>
