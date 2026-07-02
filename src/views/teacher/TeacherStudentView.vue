<template>
  <div class="min-h-screen bg-bg-dark">
    <!-- Header -->
    <header class="neo-header">
      <button @click="router.back()" class="text-white/30 text-sm font-title hover:text-white/50 transition-colors mb-1">
        ← クラスへ戻る
      </button>
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-title font-bold text-white">{{ student?.display_name ?? '生徒詳細' }}</h1>
        <span
          v-if="student?.anxious_days_last_3 >= 2"
          class="neo-badge pink"
        >要フォロー</span>
      </div>
    </header>

    <main v-if="loading" class="flex justify-center py-20">
      <div class="w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full animate-spin" />
    </main>

    <main v-else-if="student" class="max-w-2xl mx-auto px-5 py-6 space-y-5">

      <!-- Summary -->
      <section class="neo-card">
        <h2 class="neo-section-title">学習サマリー</h2>
        <div class="grid grid-cols-3 gap-4 text-center">
          <div>
            <p class="text-2xl font-bold font-title text-neo-gradient">{{ student.mowi_level }}</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">Mowi Lv.</p>
          </div>
          <div>
            <p class="text-2xl font-bold font-title text-neon-orange">{{ student.streak_days }}</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">🔥 連続日数</p>
          </div>
          <div>
            <p class="text-2xl font-bold font-title text-neon-yellow">{{ Number(student.avg_mastery_level ?? 0).toFixed(1) }}</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">平均★</p>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-4 text-center mt-4 pt-4 border-t border-white/[0.06]">
          <div>
            <p class="text-lg font-bold font-title text-neon-cyan">{{ student.patterns_mastered ?? 0 }}</p>
            <p class="text-[11px] text-white/30 font-title">完全習得パターン</p>
          </div>
          <div>
            <p class="text-lg font-bold font-title text-neon-purple">{{ student.approved_badges ?? 0 }}</p>
            <p class="text-[11px] text-white/30 font-title">バッジ</p>
          </div>
        </div>
      </section>

      <!-- Pattern progress -->
      <section class="neo-card">
        <h2 class="neo-section-title">パターン別進捗</h2>
        <div v-if="patternProgress.length === 0" class="text-center py-6 text-white/25 text-sm font-title">
          まだ練習データがありません。
        </div>
        <div v-else class="space-y-1">
          <div
            v-for="p in patternProgress"
            :key="p.pattern_no"
            class="flex items-center justify-between px-3 py-2.5 rounded-xl hover:bg-white/[0.02] transition-colors"
          >
            <div class="flex items-center gap-3">
              <span class="text-xs font-mono font-bold text-neo-gradient w-10">{{ p.pattern_no }}</span>
              <div class="flex gap-0.5">
                <span
                  v-for="i in 5"
                  :key="i"
                  class="text-sm"
                  :class="i <= p.mastery_level ? 'text-star' : 'text-white/10'"
                >★</span>
              </div>
            </div>
            <div class="flex items-center gap-3 text-xs">
              <div class="flex gap-1">
                <span :class="p.layer0_done ? 'neo-badge green !py-0 !px-1.5 !text-[9px]' : 'neo-badge !py-0 !px-1.5 !text-[9px]'">L0</span>
                <span :class="p.layer1_done ? 'neo-badge green !py-0 !px-1.5 !text-[9px]' : 'neo-badge !py-0 !px-1.5 !text-[9px]'">L1</span>
                <span :class="p.layer2_done ? 'neo-badge green !py-0 !px-1.5 !text-[9px]' : 'neo-badge !py-0 !px-1.5 !text-[9px]'">L2</span>
                <span :class="p.layer3_done ? 'neo-badge green !py-0 !px-1.5 !text-[9px]' : 'neo-badge !py-0 !px-1.5 !text-[9px]'">L3</span>
              </div>
              <span v-if="p.correct_count + p.wrong_count > 0" class="text-white/25">
                {{ Math.round(p.correct_count / (p.correct_count + p.wrong_count) * 100) }}%
              </span>
            </div>
          </div>
        </div>
      </section>

      <!-- Game-level stats -->
      <section class="neo-card">
        <h2 class="neo-section-title">ゲーム別成績</h2>
        <div v-if="studentGameStats.length === 0" class="text-center py-6 text-white/25 text-sm font-title">
          まだプレイデータがありません。
        </div>
        <div v-else class="space-y-1">
          <div
            v-for="gs in studentGameStats"
            :key="gs.game_id"
            class="flex items-center justify-between px-3 py-2.5 rounded-xl hover:bg-white/[0.02] transition-colors"
          >
            <div class="flex-1">
              <p class="text-sm text-white font-title font-medium">{{ gs.game_title }}</p>
              <p class="text-[10px] text-white/20 font-title">{{ gs.play_count }}回 | 最高{{ gs.best_score }}点 | {{ gs.avg_time_spent ?? '-' }}秒/回</p>
            </div>
            <div class="text-right">
              <p class="font-title font-bold" :class="Number(gs.avg_accuracy) >= 80 ? 'text-neon-green' : Number(gs.avg_accuracy) >= 60 ? 'text-neon-yellow' : 'text-neon-pink'">
                {{ gs.avg_accuracy }}%
              </p>
              <p class="text-white/20 text-[10px] font-title">平均正答率</p>
            </div>
          </div>
        </div>
      </section>

      <!-- Roblox -->
      <section v-if="roblox" class="neo-card !border-neon-purple/15">
        <h2 class="neo-section-title !text-neon-purple">Roblox 進捗</h2>
        <div v-if="!roblox.linked" class="text-center py-4 text-white/25 text-sm font-title">未連携</div>
        <template v-else>
          <div class="grid grid-cols-2 gap-4 text-center">
            <div>
              <p class="text-xl font-bold font-title text-neon-purple">{{ roblox.town?.word_coins ?? 0 }}</p>
              <p class="text-[11px] text-white/30 font-title">🪙 コイン</p>
            </div>
            <div>
              <p class="text-xl font-bold font-title text-neon-purple">{{ roblox.town?.total_buildings_built ?? 0 }}</p>
              <p class="text-[11px] text-white/30 font-title">🏠 建物</p>
            </div>
            <div>
              <p class="text-xl font-bold font-title text-neon-purple">{{ roblox.town?.total_missions_completed ?? 0 }}</p>
              <p class="text-[11px] text-white/30 font-title">📋 ミッション</p>
            </div>
            <div>
              <p class="text-xl font-bold font-title text-neon-purple">{{ roblox.total_sessions ?? 0 }}</p>
              <p class="text-[11px] text-white/30 font-title">🕹️ セッション</p>
            </div>
          </div>
        </template>
      </section>

      <!-- Feedback -->
      <section class="neo-card">
        <h2 class="neo-section-title">フィードバック</h2>
        <div v-if="feedbacks.length > 0" class="space-y-2 mb-4">
          <div
            v-for="fb in feedbacks"
            :key="fb.id"
            class="bg-brand-primary/8 rounded-xl px-4 py-3 border border-brand-primary/10"
          >
            <p class="text-sm text-white/70">{{ fb.message }}</p>
            <div class="flex items-center gap-2 mt-1.5">
              <span class="text-[10px] text-white/20">{{ formatDate(fb.created_at) }}</span>
              <span v-if="fb.context_type" class="neo-badge !text-[9px] !py-0">{{ fb.context_type }}</span>
              <span v-if="fb.is_read" class="text-[10px] text-correct">既読</span>
            </div>
          </div>
        </div>
        <div class="flex gap-2">
          <input
            v-model="newFeedback"
            type="text"
            placeholder="メッセージを入力..."
            class="neo-input flex-1"
            @keydown.enter="sendFeedback"
          />
          <button
            @click="sendFeedback"
            :disabled="!newFeedback.trim() || sendingFeedback"
            class="btn-neo !px-5"
          >
            {{ sendingFeedback ? '...' : '送信' }}
          </button>
        </div>
      </section>

      <p v-if="student.last_practice_at" class="text-[11px] text-white/15 text-center font-title">
        最終練習：{{ formatDate(student.last_practice_at) }}
      </p>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useTeacherStore } from '@/stores/teacher'
import { supabase } from '@/lib/supabase'

const route  = useRoute()
const router = useRouter()
const store  = useTeacherStore()

const classId   = route.params.classId as string
const studentId = route.params.studentId as string

const student         = ref<any>(null)
const patternProgress = ref<any[]>([])
const studentGameStats = ref<any[]>([])
const roblox          = ref<any>(null)
const feedbacks       = ref<any[]>([])
const newFeedback     = ref('')
const sendingFeedback = ref(false)
const loading         = ref(true)

onMounted(async () => {
  const { data: summary } = await supabase
    .from('student_class_summary')
    .select('*')
    .eq('class_id', classId)
    .eq('student_id', studentId)
    .maybeSingle()
  student.value = summary

  const { data: progress } = await supabase
    .from('pattern_progress')
    .select('*')
    .eq('user_id', studentId)
    .order('pattern_no')
  patternProgress.value = progress ?? []

  const { data: gameStatsData } = await supabase
    .from('student_game_stats')
    .select('*')
    .eq('user_id', studentId)
    .eq('class_id', classId)
    .order('play_count', { ascending: false })
  studentGameStats.value = gameStatsData ?? []

  if (store.robloxStats[studentId]) {
    roblox.value = store.robloxStats[studentId]
  }

  const { data: fbData } = await supabase
    .from('teacher_feedback')
    .select('*')
    .eq('student_id', studentId)
    .eq('class_id', classId)
    .order('created_at', { ascending: false })
    .limit(20)
  feedbacks.value = fbData ?? []

  loading.value = false
})

async function sendFeedback() {
  const msg = newFeedback.value.trim()
  if (!msg) return
  sendingFeedback.value = true
  const { data: { user } } = await supabase.auth.getUser()
  const { data, error } = await supabase
    .from('teacher_feedback')
    .insert({
      teacher_id: user!.id,
      student_id: studentId,
      class_id: classId,
      message: msg,
      context_type: 'general',
    })
    .select()
    .single()
  if (!error && data) {
    feedbacks.value.unshift(data)
  }
  newFeedback.value = ''
  sendingFeedback.value = false
}

function feelingEmoji(feeling: string | null, result: string | null): string {
  if (feeling) {
    const map: Record<string, string> = {
      morning_great: '✨', morning_doable: '🙂', morning_normal: '😐',
      morning_heavy: '😮‍💨', morning_nope: '😵',
    }
    return map[feeling] ?? '─'
  }
  if (result) {
    const map: Record<string, string> = {
      evening_done: '🎉', evening_came_out: '💬', evening_normal: '😐',
      evening_drained: '😩', evening_nope: '🚫',
    }
    return map[result] ?? '─'
  }
  return '─'
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('ja-JP', {
    month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit',
  })
}
</script>
