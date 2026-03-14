<template>
  <div class="min-h-screen bg-gray-50 pb-24">
    <header class="bg-white border-b border-gray-200 px-4 py-3">
      <h1 class="text-lg font-bold text-gray-900">📊 記録</h1>
      <!-- タブ切り替え -->
      <div class="flex mt-3 bg-gray-100 rounded-xl p-1">
        <button
          v-for="tab in tabs" :key="tab.id"
          @click="activeTab = tab.id"
          class="flex-1 py-1.5 text-xs font-bold rounded-lg transition-all"
          :class="activeTab === tab.id ? 'bg-white shadow text-indigo-600' : 'text-gray-400'"
        >{{ tab.label }}</button>
      </div>
    </header>

    <main class="px-4 py-5 space-y-4">
      <!-- ストリーク -->
      <div class="bg-white rounded-2xl p-4 flex items-center gap-4 shadow-sm">
        <span class="text-3xl">🔥</span>
        <div>
          <p class="text-2xl font-bold text-gray-900">{{ streak }}日連続</p>
          <p class="text-xs text-gray-400">現在のストリーク</p>
        </div>
      </div>

      <!-- 直近7日カレンダー -->
      <div class="bg-white rounded-2xl p-4 shadow-sm">
        <p class="text-xs font-bold text-gray-400 mb-3">直近7日</p>
        <div class="grid grid-cols-7 gap-1">
          <div v-for="day in last7Days" :key="day.date" class="flex flex-col items-center">
            <span class="text-xs text-gray-400 mb-1">{{ day.label }}</span>
            <div
              class="w-9 h-9 rounded-xl flex items-center justify-center text-sm"
              :class="day.hasMorning && day.hasEvening
                ? 'bg-indigo-500 text-white'
                : day.hasMorning
                ? 'bg-indigo-200 text-indigo-700'
                : 'bg-gray-100 text-gray-300'"
            >
              {{ day.hasMorning || day.hasEvening ? '✓' : '·' }}
            </div>
            <!-- 気分アイコン -->
            <span class="text-xs mt-0.5">{{ day.moodEmoji }}</span>
          </div>
        </div>
        <div class="flex gap-4 mt-3 text-xs text-gray-400">
          <span><span class="inline-block w-3 h-3 rounded bg-indigo-500 mr-1"></span>朝＋夕</span>
          <span><span class="inline-block w-3 h-3 rounded bg-indigo-200 mr-1"></span>朝のみ</span>
        </div>
      </div>

      <!-- 今週の練習サマリー -->
      <div class="bg-white rounded-2xl p-4 shadow-sm">
        <p class="text-xs font-bold text-gray-400 mb-3">今週の練習</p>
        <div class="grid grid-cols-3 gap-3 text-center">
          <div>
            <p class="text-xl font-bold text-indigo-600">{{ weekStats.sessions }}</p>
            <p class="text-xs text-gray-400">セッション</p>
          </div>
          <div>
            <p class="text-xl font-bold text-indigo-600">{{ weekStats.maxCombo }}</p>
            <p class="text-xs text-gray-400">最大コンボ</p>
          </div>
          <div>
            <p class="text-xl font-bold text-indigo-600">{{ weekStats.correctRate }}%</p>
            <p class="text-xs text-gray-400">正解率</p>
          </div>
        </div>
      </div>

      <!-- Mowiからの一言（今週のセリフ抜粋） -->
      <div v-if="latestMowiQuote" class="bg-indigo-50 rounded-2xl p-4">
        <p class="text-xs text-indigo-400 mb-1">Mowiより</p>
        <p class="text-sm font-bold text-indigo-800">「{{ latestMowiQuote }}」</p>
      </div>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabase'

const activeTab = ref('weekly')
const tabs = [
  { id: 'weekly', label: '今週' },
  { id: 'monthly', label: '今月' },
  { id: '3months', label: '3ヶ月' },
]

const streak          = ref(0)
const last7Days       = ref<any[]>([])
const weekStats       = ref({ sessions: 0, maxCombo: 0, correctRate: 0 })
const latestMowiQuote = ref('')

onMounted(async () => {
  const { data: { user } } = await supabase.auth.getUser()
  const now   = new Date()
  const since = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString()

  const [{ data: userRow }, { data: checkins }, { data: logs }] = await Promise.all([
    supabase.from('users').select('streak_days').eq('id', user!.id).single(),
    supabase.from('checkins').select('*').eq('user_id', user!.id).gte('created_at', since),
    supabase.from('flash_output_logs').select('*').eq('user_id', user!.id).gte('answered_at', since),
  ])

  streak.value = userRow?.streak_days ?? 0

  // 直近7日のチェックインデータを構築
  const dayLabels = ['日', '月', '火', '水', '木', '金', '土']
  last7Days.value = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(now)
    d.setDate(d.getDate() - (6 - i))
    const dateStr = d.toISOString().slice(0, 10)
    const dayCheckins = (checkins ?? []).filter((c: any) => c.created_at?.startsWith(dateStr))
    const morning = dayCheckins.find((c: any) => c.type === 'morning')
    const evening = dayCheckins.find((c: any) => c.type === 'evening')

    const moodMap: Record<string, string> = {
      morning_confident: '😊', morning_okay: '🙂', morning_anxious: '😟', morning_unsure: '😐'
    }

    return {
      date: dateStr,
      label: dayLabels[d.getDay()],
      hasMorning: !!morning,
      hasEvening: !!evening,
      moodEmoji: morning ? (moodMap[morning.feeling] ?? '') : '',
    }
  })

  // 週次統計
  const allLogs = logs ?? []
  const correct = allLogs.filter((l: any) => l.is_correct).length
  weekStats.value = {
    sessions:    new Set(allLogs.map((l: any) => l.session_id)).size,
    maxCombo:    Math.max(0, ...allLogs.map((l: any) => l.combo_at_time ?? 0)),
    correctRate: allLogs.length > 0 ? Math.round((correct / allLogs.length) * 100) : 0,
  }

  // 最新のMowiセリフ（夕チェックインから）
  const latest = (checkins ?? [])
    .filter((c: any) => c.type === 'evening' && c.mowi_quote_ja)
    .sort((a: any, b: any) => b.created_at.localeCompare(a.created_at))[0]
  latestMowiQuote.value = latest?.mowi_quote_ja ?? ''
})
</script>
