<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useMowiStore } from '@/stores/mowi'
import { useCheckinStore } from '@/stores/checkin'
import MowiOrb from '@/components/mowi/MowiOrb.vue'

const router  = useRouter()
const auth    = useAuthStore()
const mowi    = useMowiStore()
const checkin = useCheckinStore()

/** ホーム表示用Mowiセリフ */
const mowiLines = [
  '今日も、ここにいる。',
  '言葉は、体の中にある。',
  '使われるのを、待っている。',
  '少しずつ、遠くに届く。',
  '始めよう。',
]
const homeSerif = computed(() =>
  mowiLines[Math.floor(Math.random() * mowiLines.length)]
)

onMounted(async () => {
  await Promise.all([
    mowi.fetchMowiState(),
    checkin.fetchTodayCheckins(),
    checkin.fetchStreakDays(),
  ])
})
</script>

<template>
  <div class="min-h-screen bg-bg-dark flex flex-col safe-pt safe-pb">

    <!-- ヘッダー -->
    <header class="px-5 pt-4 pb-2 flex justify-between items-center">
      <div>
        <p class="text-white/40 text-xs font-title">WISE English Club</p>
        <p class="text-white font-title font-semibold">{{ auth.displayName }}</p>
      </div>
      <div class="flex items-center gap-2">
        <div class="flex items-center gap-1 bg-bg-card rounded-full px-3 py-1">
          <span class="text-sm">🔥</span>
          <span class="text-white text-sm font-title font-semibold">{{ checkin.streakDays }}</span>
        </div>
        <div class="flex items-center gap-1 bg-bg-card rounded-full px-3 py-1">
          <span class="text-brand-primary text-xs font-title">XP</span>
          <span class="text-white text-sm font-title font-semibold">{{ auth.userRow?.total_xp ?? 0 }}</span>
        </div>
      </div>
    </header>

    <!-- Mowi中央エリア -->
    <main class="flex-1 flex flex-col items-center justify-center px-6 gap-8">

      <!-- Mowiオーブ -->
      <MowiOrb
        :state="mowi.emotionState"
        :brightness="mowi.homeBrightness"
        size="lg"
      />

      <!-- Mowiセリフ -->
      <div class="text-center max-w-xs">
        <p class="mowi-quote text-base">
          {{ homeSerif }}
        </p>
      </div>

      <!-- ─── CTA エリア ─── -->
      <div class="w-full max-w-xs space-y-3">
        <button
          class="btn-primary w-full text-lg font-title"
          @click="router.push({ name: 'session-start' })"
        >
          ▶ 練習を始める
        </button>
      </div>
    </main>

    <!-- ボトムナビ -->
    <nav class="px-6 pb-4 border-t border-white/5 pt-3 flex justify-around">
      <button class="flex flex-col items-center gap-1 text-white transition-colors">
        <span class="text-xl">🏠</span>
        <span class="text-xs font-title">ホーム</span>
      </button>
      <button
        class="flex flex-col items-center gap-1 text-white/40 hover:text-white transition-colors"
        @click="router.push({ name: 'session-start' })"
      >
        <span class="text-xl">⚔️</span>
        <span class="text-xs font-title">練習</span>
      </button>
      <button
        class="flex flex-col items-center gap-1 text-white/40 hover:text-white transition-colors"
        @click="router.push({ name: 'Zukan' })"
      >
        <span class="text-xl">📖</span>
        <span class="text-xs font-title">図鑑</span>
      </button>
      <button
        class="flex flex-col items-center gap-1 text-white/40 hover:text-white transition-colors"
        @click="router.push({ name: 'Settings' })"
      >
        <span class="text-xl">⚙️</span>
        <span class="text-xs font-title">設定</span>
      </button>
      <button
        v-if="auth.isTeacher"
        class="flex flex-col items-center gap-1 text-white/40 hover:text-white transition-colors"
        @click="router.push({ name: 'TeacherDashboard' })"
      >
        <span class="text-xl">👨‍🏫</span>
        <span class="text-xs font-title">ダッシュボード</span>
      </button>
    </nav>

  </div>
</template>
