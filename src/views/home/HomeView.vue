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
const homeSerif = computed(() => {
  if (checkin.hasMorningCheckin && checkin.hasEveningCheckin) {
    return '今日の分、全部ある。また明日。'
  }
  if (checkin.hasMorningCheckin) {
    return checkin.todayMorning?.mowi_quote_ja ?? '今日も、ここから。'
  }
  return '今日も、ここから。'
})

/** CTA表示状態（4パターン） */
const ctaState = computed((): 'morning' | 'session' | 'evening' | 'done' => {
  if (!checkin.hasMorningCheckin) return 'morning'
  if (checkin.hasFullCheckin) return 'done'
  const hour = new Date().getHours()
  if (hour >= 17) return 'evening'  // 17時以降は夜チェックインを優先表示
  return 'session'
})

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

      <!-- チェックインバッジ -->
      <div class="flex gap-3 text-xs font-title">
        <span :class="checkin.hasMorningCheckin ? 'text-correct' : 'text-white/20'">☀️ 朝</span>
        <span :class="checkin.hasEveningCheckin ? 'text-correct' : 'text-white/20'">🌙 夜</span>
        <span v-if="checkin.hasFullCheckin" class="text-yellow-400">🎉 今日完了</span>
      </div>

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

      <!-- ─── CTA エリア（4パターン） ─── -->
      <div class="w-full max-w-xs space-y-3">

        <!-- ① 朝チェックイン未完了 -->
        <template v-if="ctaState === 'morning'">
          <button
            class="btn-primary w-full text-lg font-title"
            @click="router.push({ name: 'CheckinMorning' })"
          >
            ☀️ 朝チェックイン
          </button>
        </template>

        <!-- ② 練習へ -->
        <template v-else-if="ctaState === 'session'">
          <button
            class="btn-primary w-full text-lg font-title"
            @click="router.push({ name: 'session-start' })"
          >
            ▶ デイリー練習を始める
          </button>
          <button
            class="btn-outline w-full font-title text-sm"
            @click="router.push({ name: 'CheckinEvening' })"
          >
            🌙 夜チェックイン
          </button>
        </template>

        <!-- ③ 夜チェックイン優先 -->
        <template v-else-if="ctaState === 'evening'">
          <button
            class="btn-primary w-full text-lg font-title"
            @click="router.push({ name: 'CheckinEvening' })"
          >
            🌙 夜チェックインへ
          </button>
          <button
            class="btn-outline w-full font-title text-sm"
            @click="router.push({ name: 'session-start' })"
          >
            ▶ 練習する
          </button>
        </template>

        <!-- ④ 全完了 -->
        <template v-else>
          <div class="text-center space-y-2">
            <p class="text-correct font-title text-lg">✓ 今日の記録、完了！</p>
            <p class="text-white/40 text-sm">また明日。Mowiが待ってる。</p>
          </div>
          <button
            class="btn-outline w-full font-title text-sm"
            @click="router.push({ name: 'session-start' })"
          >
            もう一度練習する
          </button>
        </template>

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
