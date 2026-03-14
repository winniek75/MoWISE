<script setup lang="ts">
import { useRouter } from 'vue-router'
const router = useRouter()
</script>
<template>
  <div class="min-h-screen bg-bg-dark flex flex-col items-center justify-center gap-4 px-6">
    <div class="w-16 h-16 mowi-orb animate-mowi-pulse" />
    <p class="font-title text-white/60">CheckinEvening — Step M で実装</p>
    <button class="btn-outline text-sm" @click="router.back()">← 戻る</button>
  </div>
</template>
