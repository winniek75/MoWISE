<template>
  <div class="min-h-screen bg-gray-50">
    <!-- ヘッダー -->
    <header class="bg-white border-b border-gray-200 px-6 py-4">
      <button @click="router.back()" class="text-sm text-gray-400 hover:text-gray-600 mb-1">
        ← クラスへ戻る
      </button>
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-bold text-gray-900">{{ student?.display_name ?? '生徒詳細' }}</h1>
        <div v-if="student" class="text-right">
          <span
            v-if="student.anxious_days_last_3 >= 2"
            class="text-xs bg-red-100 text-red-600 font-semibold px-2 py-0.5 rounded-full"
          >🔴 要フォロー</span>
        </div>
      </div>
    </header>

    <main v-if="loading" class="flex justify-center py-20">
      <div class="w-8 h-8 border-4 border-indigo-400 border-t-transparent rounded-full animate-spin"></div>
    </main>

    <main v-else-if="student" class="max-w-2xl mx-auto px-6 py-8 space-y-6">

      <!-- サマリーカード -->
      <section class="bg-white rounded-xl border border-gray-200 p-5">
        <h2 class="text-xs font-semibold text-gray-400 mb-3">学習サマリー</h2>
        <div class="grid grid-cols-3 gap-4 text-center">
          <div>
            <p class="text-2xl font-bold text-indigo-600">{{ student.mowi_level }}</p>
            <p class="text-xs text-gray-400">Mowi Lv.</p>
          </div>
          <div>
            <p class="text-2xl font-bold text-orange-500">{{ student.streak_days }}</p>
            <p class="text-xs text-gray-400">🔥 連続日数</p>
          </div>
          <div>
            <p class="text-2xl font-bold text-yellow-500">{{ Number(student.avg_mastery_level ?? 0).toFixed(1) }}</p>
            <p class="text-xs text-gray-400">平均★</p>
          </div>
        </div>
        <div class="grid grid-cols-2 gap-4 text-center mt-4 pt-4 border-t border-gray-100">
          <div>
            <p class="text-lg font-bold text-gray-700">{{ student.patterns_mastered ?? 0 }}</p>
            <p class="text-xs text-gray-400">完全習得パターン</p>
          </div>
          <div>
            <p class="text-lg font-bold text-gray-700">{{ student.approved_badges ?? 0 }}</p>
            <p class="text-xs text-gray-400">🏅 バッジ</p>
          </div>
        </div>
      </section>

      <!-- パターン別進捗 -->
      <section class="bg-white rounded-xl border border-gray-200 p-5">
        <h2 class="text-xs font-semibold text-gray-400 mb-3">パターン別進捗</h2>

        <div v-if="patternProgress.length === 0" class="text-center py-6 text-gray-400 text-sm">
          まだ練習データがありません。
        </div>

        <div v-else class="space-y-2">
          <div
            v-for="p in patternProgress"
            :key="p.pattern_no"
            class="flex items-center justify-between px-3 py-2.5 rounded-lg hover:bg-gray-50"
          >
            <div class="flex items-center gap-3">
              <span class="text-xs font-mono font-bold text-indigo-600 w-10">{{ p.pattern_no }}</span>
              <div class="flex gap-0.5">
                <span
                  v-for="i in 5"
                  :key="i"
                  class="text-sm"
                  :class="i <= p.mastery_level ? 'text-yellow-400' : 'text-gray-200'"
                >★</span>
              </div>
            </div>
            <div class="flex items-center gap-3 text-xs text-gray-500">
              <div class="flex gap-1">
                <span :class="p.layer0_done ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-400'" class="px-1.5 py-0.5 rounded font-medium">L0</span>
                <span :class="p.layer1_done ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-400'" class="px-1.5 py-0.5 rounded font-medium">L1</span>
                <span :class="p.layer2_done ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-400'" class="px-1.5 py-0.5 rounded font-medium">L2</span>
                <span :class="p.layer3_done ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-400'" class="px-1.5 py-0.5 rounded font-medium">L3</span>
              </div>
              <span v-if="p.correct_count + p.wrong_count > 0" class="text-gray-400">
                {{ Math.round(p.correct_count / (p.correct_count + p.wrong_count) * 100) }}%
              </span>
            </div>
          </div>
        </div>
      </section>

      <!-- チェックイン履歴 -->
      <section class="bg-white rounded-xl border border-gray-200 p-5">
        <h2 class="text-xs font-semibold text-gray-400 mb-3">直近チェックイン（7日間）</h2>

        <div v-if="checkins.length === 0" class="text-center py-6 text-gray-400 text-sm">
          チェックイン記録がありません。
        </div>

        <div v-else class="space-y-2">
          <div
            v-for="c in checkins"
            :key="c.id"
            class="flex items-center justify-between px-3 py-2 rounded-lg hover:bg-gray-50"
          >
            <div class="flex items-center gap-3">
              <span class="text-lg">{{ c.type === 'morning' ? '🌅' : '🌙' }}</span>
              <div>
                <p class="text-sm text-gray-700">
                  {{ c.type === 'morning' ? '朝チェックイン' : '夜チェックイン' }}
                </p>
                <p class="text-xs text-gray-400">{{ formatDate(c.created_at) }}</p>
              </div>
            </div>
            <div class="text-right">
              <span class="text-lg">{{ feelingEmoji(c.feeling, c.result) }}</span>
            </div>
          </div>
        </div>
      </section>

      <!-- Roblox 統計 -->
      <section v-if="roblox" class="bg-purple-50 rounded-xl border border-purple-200 p-5">
        <h2 class="text-xs font-semibold text-purple-700 mb-3">🎮 Roblox 進捗</h2>
        <div v-if="!roblox.linked" class="text-center py-4 text-gray-400 text-sm">未連携</div>
        <template v-else>
          <div class="grid grid-cols-2 gap-4 text-center">
            <div>
              <p class="text-xl font-bold text-purple-700">{{ roblox.town?.word_coins ?? 0 }}</p>
              <p class="text-xs text-gray-500">🪙 コイン</p>
            </div>
            <div>
              <p class="text-xl font-bold text-purple-700">{{ roblox.town?.total_buildings_built ?? 0 }}</p>
              <p class="text-xs text-gray-500">🏠 建物</p>
            </div>
            <div>
              <p class="text-xl font-bold text-purple-700">{{ roblox.town?.total_missions_completed ?? 0 }}</p>
              <p class="text-xs text-gray-500">📋 ミッション</p>
            </div>
            <div>
              <p class="text-xl font-bold text-purple-700">{{ roblox.total_sessions ?? 0 }}</p>
              <p class="text-xs text-gray-500">🕹️ セッション数</p>
            </div>
          </div>
          <p v-if="roblox.last_sync_at" class="text-[10px] text-gray-400 mt-3 text-right">
            最終同期：{{ formatDate(roblox.last_sync_at) }}
          </p>
        </template>
      </section>

      <!-- フィードバック送信 -->
      <section class="bg-white rounded-xl border border-gray-200 p-5">
        <h2 class="text-xs font-semibold text-gray-400 mb-3">💬 フィードバック</h2>

        <!-- 過去のフィードバック -->
        <div v-if="feedbacks.length > 0" class="space-y-2 mb-4">
          <div
            v-for="fb in feedbacks"
            :key="fb.id"
            class="bg-indigo-50 rounded-lg px-4 py-2.5"
          >
            <p class="text-sm text-gray-800">{{ fb.message }}</p>
            <div class="flex items-center gap-2 mt-1">
              <span class="text-[10px] text-gray-400">{{ formatDate(fb.created_at) }}</span>
              <span v-if="fb.context_type" class="text-[10px] bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded">{{ fb.context_type }}</span>
              <span v-if="fb.is_read" class="text-[10px] text-green-500">既読</span>
            </div>
          </div>
        </div>

        <!-- 新規送信フォーム -->
        <div class="flex gap-2">
          <input
            v-model="newFeedback"
            type="text"
            placeholder="メッセージを入力..."
            class="flex-1 border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-300"
            @keydown.enter="sendFeedback"
          />
          <button
            @click="sendFeedback"
            :disabled="!newFeedback.trim() || sendingFeedback"
            class="px-4 py-2 text-sm font-semibold text-white bg-indigo-500 hover:bg-indigo-600 rounded-lg disabled:opacity-40"
          >
            {{ sendingFeedback ? '...' : '送信' }}
          </button>
        </div>
      </section>

      <!-- 最終練習日 -->
      <p v-if="student.last_practice_at" class="text-xs text-gray-400 text-center">
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
const checkins        = ref<any[]>([])
const roblox          = ref<any>(null)
const feedbacks       = ref<any[]>([])
const newFeedback     = ref('')
const sendingFeedback = ref(false)
const loading         = ref(true)

onMounted(async () => {
  // 生徒サマリー（student_class_summary ビューから）
  const { data: summary } = await supabase
    .from('student_class_summary')
    .select('*')
    .eq('class_id', classId)
    .eq('student_id', studentId)
    .maybeSingle()
  student.value = summary

  // パターン別進捗
  const { data: progress } = await supabase
    .from('pattern_progress')
    .select('*')
    .eq('user_id', studentId)
    .order('pattern_no')
  patternProgress.value = progress ?? []

  // 直近7日のチェックイン
  const sevenDaysAgo = new Date()
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7)
  const { data: checkinData } = await supabase
    .from('checkins')
    .select('*')
    .eq('user_id', studentId)
    .gte('created_at', sevenDaysAgo.toISOString())
    .order('created_at', { ascending: false })
  checkins.value = checkinData ?? []

  // Roblox統計（既にstoreにあれば再利用）
  if (store.robloxStats[studentId]) {
    roblox.value = store.robloxStats[studentId]
  }

  // フィードバック履歴取得
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

// ─── 表示ヘルパー ──────────────────────────────────────────────
function feelingEmoji(feeling: string | null, result: string | null): string {
  if (feeling) {
    const map: Record<string, string> = {
      morning_confident: '😊', morning_okay: '🙂',
      morning_anxious: '😟', morning_unsure: '😐',
    }
    return map[feeling] ?? '─'
  }
  if (result) {
    const map: Record<string, string> = {
      evening_said_it: '🎉', evening_fun: '😄',
      evening_hard: '😤', evening_not_quite: '🤔',
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
