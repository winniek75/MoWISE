<script setup lang="ts">
/**
 * CheckinEveningView → CheckinNightView へのリダイレクト
 * ホーム画面の「夜チェックイン」ボタンは CheckinEvening ルートを使うが、
 * 実装本体は CheckinNightView にある。
 */
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'

const router = useRouter()

onMounted(() => {
  router.replace({ name: 'checkin-night' })
})
</script>
<template>
  <div class="min-h-screen bg-bg-dark" />
</template>
