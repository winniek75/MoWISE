<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useMowiStore } from '@/stores/mowi'
import { useCheckinStore } from '@/stores/checkin'
import { supabase, isOfflineMode } from '@/lib/supabase'
import { getCurrentCheckinSession } from '@/composables/useCheckinGuard'
import MowiOrb from '@/components/mowi/MowiOrb.vue'

const router  = useRouter()
const auth    = useAuthStore()
const mowi    = useMowiStore()
const checkin = useCheckinStore()

const unreadFeedbacks = ref<any[]>([])

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

// ─── チェックインCTA（B-4-2） ─────────────────────────
const currentSession = computed(() => getCurrentCheckinSession())
const checkinCompleted = computed(() =>
  currentSession.value === 'morning' ? checkin.hasMorningCheckin : checkin.hasEveningCheckin
)
const checkinCtaLabel = computed(() =>
  currentSession.value === 'morning' ? '☀️ 朝のチェックイン' : '🌙 夜のチェックイン'
)
const checkinDoneLabel = computed(() =>
  currentSession.value === 'morning' ? '✓ 今日の朝チェックイン 完了' : '✓ 今日の夜チェックイン 完了'
)
function goToCheckin() {
  router.push({ name: currentSession.value === 'morning' ? 'CheckinMorning' : 'checkin-night' })
}

onMounted(async () => {
  await Promise.all([
    mowi.fetchMowiState(),
    checkin.fetchTodayCheckins(),
    checkin.fetchStreakDays(),
  ])
  // 未読フィードバック取得
  if (!isOfflineMode && auth.userId) {
    const { data } = await supabase
      .from('teacher_feedback')
      .select('*')
      .eq('student_id', auth.userId)
      .eq('is_read', false)
      .order('created_at', { ascending: false })
      .limit(5)
    unreadFeedbacks.value = data ?? []
  }
})

async function markRead(fbId: string) {
  await supabase
    .from('teacher_feedback')
    .update({ is_read: true })
    .eq('id', fbId)
  unreadFeedbacks.value = unreadFeedbacks.value.filter(f => f.id !== fbId)
}
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

      <!-- 先生からのフィードバック -->
      <div v-if="unreadFeedbacks.length > 0" class="w-full max-w-xs space-y-2">
        <div
          v-for="fb in unreadFeedbacks"
          :key="fb.id"
          class="bg-bg-card border border-brand-primary/20 rounded-2xl px-4 py-3 flex items-start gap-3"
        >
          <span class="text-lg mt-0.5">💬</span>
          <div class="flex-1 min-w-0">
            <p class="text-white/80 text-sm leading-relaxed">{{ fb.message }}</p>
            <p class="text-white/30 text-[10px] mt-1">{{ new Date(fb.created_at).toLocaleDateString('ja-JP', { month: 'short', day: 'numeric' }) }}</p>
          </div>
          <button
            @click="markRead(fb.id)"
            class="text-white/30 hover:text-white/60 text-xs shrink-0 mt-0.5"
            title="既読にする"
          >✕</button>
        </div>
      </div>

      <!-- ─── CTA エリア ─── -->
      <div class="w-full max-w-xs space-y-3">
        <!-- チェックインCTA（B-4-2 招待トーン） -->
        <button
          v-if="!checkinCompleted"
          class="w-full rounded-2xl py-4 px-5 bg-white/8 hover:bg-white/12 border border-white/10 text-left transition-colors"
          @click="goToCheckin"
        >
          <div class="text-white font-title font-semibold">{{ checkinCtaLabel }}</div>
          <div class="text-white/40 text-xs font-title mt-0.5">4タップで終わる</div>
        </button>
        <p
          v-else
          class="text-center text-white/40 text-xs font-title"
        >{{ checkinDoneLabel }}</p>

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
