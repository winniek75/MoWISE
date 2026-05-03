<template>
  <div class="min-h-screen bg-gray-50">
    <!-- ヘッダー -->
    <header class="bg-white border-b border-gray-200 px-6 py-4">
      <button @click="router.push('/teacher')" class="text-sm text-gray-400 hover:text-gray-600 mb-1">
        ← ダッシュボードへ
      </button>
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-bold text-gray-900">{{ currentClass?.class_name ?? 'クラス詳細' }}</h1>
        <div class="flex items-center gap-4">
          <button
            v-if="store.students.length > 0"
            @click="exportCSV"
            class="px-3 py-1.5 text-xs font-semibold text-indigo-600 border border-indigo-300 hover:bg-indigo-50 rounded-lg"
          >📥 CSV出力</button>
          <div v-if="currentClass" class="text-right">
            <p class="text-xs text-gray-400">クラスコード</p>
            <span class="font-mono text-xl font-bold tracking-widest text-indigo-600">
              {{ currentClass.class_code }}
            </span>
          </div>
        </div>
      </div>
    </header>

    <main class="max-w-4xl mx-auto px-6 py-8 space-y-6">

      <!-- 0 クラス統計サマリー -->
      <section v-if="store.students.length > 0" class="bg-white rounded-xl border border-gray-200 p-5">
        <h2 class="text-xs font-semibold text-gray-400 mb-3">📊 クラス統計</h2>
        <div class="grid grid-cols-4 gap-3 text-center">
          <div>
            <p class="text-2xl font-bold text-indigo-600">{{ store.students.length }}</p>
            <p class="text-xs text-gray-400">生徒数</p>
          </div>
          <div>
            <p class="text-2xl font-bold text-yellow-500">{{ classAvgMastery }}</p>
            <p class="text-xs text-gray-400">平均★</p>
          </div>
          <div>
            <p class="text-2xl font-bold text-green-500">{{ classActiveRate }}%</p>
            <p class="text-xs text-gray-400">直近7日活動率</p>
          </div>
          <div>
            <p class="text-2xl font-bold text-orange-500">{{ classAvgStreak }}</p>
            <p class="text-xs text-gray-400">平均連続日数</p>
          </div>
        </div>
        <div v-if="weakPatterns.length > 0" class="mt-4 pt-3 border-t border-gray-100">
          <p class="text-xs text-gray-400 mb-1">弱点パターン TOP3</p>
          <div class="flex gap-2">
            <span
              v-for="wp in weakPatterns"
              :key="wp"
              class="text-xs bg-red-50 text-red-600 font-mono font-semibold px-2 py-1 rounded"
            >{{ wp }}</span>
          </div>
        </div>
      </section>

      <!-- パターン範囲指定 -->
      <section v-if="currentClass" class="bg-white rounded-xl border border-gray-200 p-5">
        <div class="flex items-center justify-between">
          <h2 class="text-xs font-semibold text-gray-400">📚 今週のパターン範囲</h2>
          <button
            v-if="!editingRange"
            @click="editingRange = true"
            class="text-xs text-indigo-500 hover:text-indigo-700 font-medium"
          >変更</button>
        </div>
        <div v-if="!editingRange" class="mt-2">
          <p v-if="currentClass.current_pattern_range" class="text-lg font-bold text-gray-800">
            {{ currentClass.current_pattern_range }}
          </p>
          <p v-else class="text-sm text-gray-400">未設定（全パターン対象）</p>
        </div>
        <div v-else class="mt-3 flex items-center gap-3">
          <select v-model="rangeFrom" class="border border-gray-300 rounded-lg px-3 py-1.5 text-sm">
            <option v-for="p in patternOptions" :key="p" :value="p">{{ p }}</option>
          </select>
          <span class="text-gray-400">〜</span>
          <select v-model="rangeTo" class="border border-gray-300 rounded-lg px-3 py-1.5 text-sm">
            <option v-for="p in patternOptions" :key="p" :value="p">{{ p }}</option>
          </select>
          <button
            @click="savePatternRange"
            class="px-3 py-1.5 text-xs font-semibold text-white bg-indigo-500 hover:bg-indigo-600 rounded-lg"
          >保存</button>
          <button
            @click="editingRange = false"
            class="px-3 py-1.5 text-xs text-gray-500 hover:text-gray-700"
          >キャンセル</button>
        </div>
      </section>

      <!-- 1 承認待ち生徒 -->
      <section v-if="store.pendingMembers.length > 0">
        <h2 class="text-sm font-semibold text-orange-600 mb-3">
          ⏳ 参加申請中 {{ store.pendingMembers.length }}名
        </h2>
        <div class="bg-orange-50 border border-orange-200 rounded-xl divide-y divide-orange-100">
          <div
            v-for="m in store.pendingMembers"
            :key="m.id"
            class="flex items-center justify-between px-5 py-3"
          >
            <div>
              <p class="font-medium text-gray-900 text-sm">{{ m.users?.display_name }}</p>
              <p class="text-xs text-gray-400">{{ m.users?.email }}</p>
            </div>
            <div class="flex gap-2">
              <button
                @click="handleApprove(m.id)"
                class="px-3 py-1 text-xs font-semibold text-white bg-green-500 hover:bg-green-600 rounded-lg"
              >
                承認
              </button>
              <button
                @click="handleRemove(m.id)"
                class="px-3 py-1 text-xs font-semibold text-gray-600 border border-gray-300 hover:bg-gray-100 rounded-lg"
              >
                削除
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- 2 バッジ承認待ち -->
      <section v-if="store.pendingBadges.length > 0">
        <h2 class="text-sm font-semibold text-indigo-600 mb-3">
          🏅 チャートバッジ承認待ち {{ store.pendingBadges.length }}件
        </h2>
        <div class="bg-indigo-50 border border-indigo-200 rounded-xl divide-y divide-indigo-100">
          <div
            v-for="b in store.pendingBadges"
            :key="b.id"
            class="flex items-center justify-between px-5 py-4"
          >
            <div>
              <p class="font-medium text-gray-900 text-sm">
                {{ b.users?.display_name }}
                <span class="ml-2 text-indigo-600 font-bold">{{ areaLabel(b.area) }}</span>
              </p>
              <p class="text-xs text-gray-400">
                申請：{{ formatDate(b.applied_at) }}
                <span v-if="b.mastery_avg_at_apply"> ｜ 平均★{{ Number(b.mastery_avg_at_apply).toFixed(1) }}</span>
              </p>
            </div>
            <div class="flex gap-2">
              <button
                @click="handleApproveBadge(b.id)"
                class="px-3 py-1 text-xs font-semibold text-white bg-indigo-500 hover:bg-indigo-600 rounded-lg"
              >
                承認
              </button>
              <button
                @click="openRejectModal(b.id)"
                class="px-3 py-1 text-xs font-semibold text-gray-600 border border-gray-300 hover:bg-gray-100 rounded-lg"
              >
                却下
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- 3 生徒進捗一覧 -->
      <section>
        <h2 class="text-sm font-semibold text-gray-700 mb-3">
          👥 生徒一覧（{{ store.students.length }}名）
        </h2>

        <div v-if="store.loading" class="flex justify-center py-10">
          <div class="w-7 h-7 border-4 border-indigo-400 border-t-transparent rounded-full animate-spin"></div>
        </div>

        <div v-else-if="store.students.length === 0" class="text-center py-12 text-gray-400 text-sm">
          承認済みの生徒がいません。
        </div>

        <div v-else class="bg-white rounded-xl border border-gray-200 divide-y divide-gray-100">
          <div
            v-for="s in store.students"
            :key="s.student_id"
            class="px-5 py-4 cursor-pointer hover:bg-gray-50 transition-colors"
            @click="router.push({ name: 'TeacherStudent', params: { classId, studentId: s.student_id } })"
          >
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <!-- 名前・アラート -->
                <div class="flex items-center gap-2">
                  <p class="font-semibold text-gray-900">{{ s.display_name }}</p>
                  <!-- 不安アラート：直近3日で2日以上anxious -->
                  <span
                    v-if="s.anxious_days_last_3 >= 2"
                    class="text-xs bg-red-100 text-red-600 font-semibold px-2 py-0.5 rounded-full"
                    :title="`直近3日中${s.anxious_days_last_3}日「不安」チェックインがあります`"
                  >
                    🔴 要フォロー
                  </span>
                </div>
                <!-- 進捗数値 -->
                <div class="flex flex-wrap gap-4 mt-2 text-sm text-gray-600">
                  <span>Lv. <strong class="text-indigo-600">{{ s.mowi_level }}</strong></span>
                  <span>🔥 <strong>{{ s.streak_days }}</strong> 日連続</span>
                  <span v-if="s.avg_mastery_level">
                    平均★ <strong>{{ Number(s.avg_mastery_level).toFixed(1) }}</strong>
                  </span>
                  <span v-if="s.patterns_mastered">
                    完全習得 <strong>{{ s.patterns_mastered }}</strong> パターン
                  </span>
                  <span v-if="s.approved_badges">
                    🏅 バッジ <strong>{{ s.approved_badges }}</strong> 枚
                  </span>
                </div>
              </div>
              <!-- 直近チェックイン気分 -->
              <div class="ml-4 text-right">
                <p class="text-xs text-gray-400">今朝のチェックイン</p>
                <span class="text-lg">{{ moodEmoji(s.latest_morning_mood) }}</span>
              </div>
            </div>
            <!-- Roblox 進捗 -->
            <div v-if="store.robloxStats[s.student_id]" class="mt-3 bg-purple-50 rounded-lg px-4 py-2">
              <div class="flex items-center gap-2 mb-1">
                <span class="text-xs font-semibold text-purple-700">🎮 Roblox</span>
                <span
                  v-if="store.robloxStats[s.student_id].linked"
                  class="text-[10px] bg-green-100 text-green-700 px-1.5 py-0.5 rounded-full font-medium"
                >連携済み</span>
                <span
                  v-else
                  class="text-[10px] bg-gray-100 text-gray-500 px-1.5 py-0.5 rounded-full font-medium"
                >未連携</span>
              </div>
              <template v-if="store.robloxStats[s.student_id].linked">
                <div class="flex flex-wrap gap-3 text-xs text-gray-600">
                  <span v-if="store.robloxStats[s.student_id].roblox_display_name">
                    {{ store.robloxStats[s.student_id].roblox_display_name }}
                  </span>
                  <span v-if="store.robloxStats[s.student_id].town">
                    🪙 <strong>{{ store.robloxStats[s.student_id].town.word_coins }}</strong> コイン
                  </span>
                  <span v-if="store.robloxStats[s.student_id].town">
                    🏠 <strong>{{ store.robloxStats[s.student_id].town.total_buildings_built }}</strong> 建物
                  </span>
                  <span v-if="store.robloxStats[s.student_id].town">
                    📋 <strong>{{ store.robloxStats[s.student_id].town.total_missions_completed }}</strong> ミッション
                  </span>
                  <span v-if="store.robloxStats[s.student_id].total_sessions > 0">
                    🕹️ <strong>{{ store.robloxStats[s.student_id].total_sessions }}</strong> セッション
                  </span>
                  <span v-if="store.robloxStats[s.student_id].latest_session">
                    最高コンボ <strong>{{ store.robloxStats[s.student_id].latest_session.max_combo }}</strong>
                  </span>
                </div>
                <p v-if="store.robloxStats[s.student_id].last_sync_at" class="text-[10px] text-gray-400 mt-1">
                  最終同期：{{ formatDate(store.robloxStats[s.student_id].last_sync_at) }}
                </p>
              </template>
            </div>
            <!-- 最終練習日 -->
            <p v-if="s.last_practice_at" class="text-xs text-gray-400 mt-2">
              最終練習：{{ formatDate(s.last_practice_at) }}
            </p>
            <p v-else class="text-xs text-gray-400 mt-2">まだ練習なし</p>
          </div>
        </div>
      </section>
    </main>

    <!-- 却下モーダル -->
    <div
      v-if="rejectModal.open"
      class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
      @click.self="rejectModal.open = false"
    >
      <div class="bg-white rounded-2xl shadow-xl w-full max-w-sm mx-4 p-6">
        <h2 class="text-base font-bold text-gray-900 mb-3">却下理由（任意）</h2>
        <textarea
          v-model="rejectModal.reason"
          rows="3"
          placeholder="例：エリア1のパターンをもう少し練習してから申請してください。"
          class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-red-300 resize-none"
        ></textarea>
        <div class="flex gap-3 mt-4">
          <button
            @click="rejectModal.open = false"
            class="flex-1 py-2 text-sm text-gray-600 border border-gray-200 rounded-lg hover:bg-gray-50"
          >
            キャンセル
          </button>
          <button
            @click="handleRejectBadge"
            class="flex-1 py-2 text-sm font-semibold text-white bg-red-500 hover:bg-red-600 rounded-lg"
          >
            却下する
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useTeacherStore } from '@/stores/teacher'
import { supabase } from '@/lib/supabase'

const route  = useRoute()
const router = useRouter()
const store  = useTeacherStore()

const classId      = route.params.classId as string
const currentClass = ref<any>(null)

const rejectModal = ref({ open: false, badgeId: '', reason: '' })

// パターン範囲指定
const editingRange = ref(false)
const rangeFrom = ref('P001')
const rangeTo = ref('P035')
const patternOptions = Array.from({ length: 35 }, (_, i) => `P${String(i + 1).padStart(3, '0')}`)

function exportCSV() {
  const header = '名前,Lv,連続日数,平均★,完全習得数,バッジ数,今朝の気分,最終練習日'
  const rows = store.students.map((s: any) => [
    s.display_name,
    s.mowi_level,
    s.streak_days,
    Number(s.avg_mastery_level ?? 0).toFixed(1),
    s.patterns_mastered ?? 0,
    s.approved_badges ?? 0,
    s.latest_morning_mood ?? '',
    s.last_practice_at ? new Date(s.last_practice_at).toLocaleDateString('ja-JP') : '',
  ].join(','))
  const bom = '\uFEFF'
  const csv = bom + [header, ...rows].join('\n')
  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${currentClass.value?.class_name ?? 'class'}_progress_${new Date().toISOString().slice(0, 10)}.csv`
  a.click()
  URL.revokeObjectURL(url)
}

async function savePatternRange() {
  const range = `${rangeFrom.value}〜${rangeTo.value}`
  await supabase
    .from('classes')
    .update({ current_pattern_range: range })
    .eq('id', classId)
  if (currentClass.value) currentClass.value.current_pattern_range = range
  editingRange.value = false
}

// ─── クラス統計 computed ────────────────────────────────────────
const classAvgMastery = computed(() => {
  const vals = store.students.map((s: any) => Number(s.avg_mastery_level ?? 0))
  if (vals.length === 0) return '0.0'
  return (vals.reduce((a: number, b: number) => a + b, 0) / vals.length).toFixed(1)
})

const classAvgStreak = computed(() => {
  const vals = store.students.map((s: any) => Number(s.streak_days ?? 0))
  if (vals.length === 0) return 0
  return Math.round(vals.reduce((a: number, b: number) => a + b, 0) / vals.length)
})

const classActiveRate = computed(() => {
  if (store.students.length === 0) return 0
  const sevenDaysAgo = Date.now() - 7 * 24 * 60 * 60 * 1000
  const active = store.students.filter((s: any) =>
    s.last_practice_at && new Date(s.last_practice_at).getTime() > sevenDaysAgo
  ).length
  return Math.round((active / store.students.length) * 100)
})

// 弱点パターンTOP3（クラス全体のpattern_progress取得後に表示）
const weakPatterns = ref<string[]>([])


onMounted(async () => {
  // クラス情報取得
  const { data } = await supabase
    .from('classes')
    .select('*')
    .eq('id', classId)
    .single()
  currentClass.value = data

  // 並行でデータ取得
  await Promise.all([
    store.fetchClassStudents(classId),
    store.fetchPendingMembers(classId),
    store.fetchPendingBadges(classId),
  ])

  // 生徒一覧取得後にRoblox統計を取得
  await store.fetchRobloxStats(classId)

  // 弱点パターンTOP3を取得
  await fetchWeakPatterns()
})

async function fetchWeakPatterns() {
  const studentIds = store.students.map((s: any) => s.student_id)
  if (studentIds.length === 0) return
  const { data } = await supabase
    .from('pattern_progress')
    .select('pattern_no, mastery_level')
    .in('user_id', studentIds)
  if (!data || data.length === 0) return
  // パターンごとの平均★を計算
  const totals: Record<string, { sum: number; count: number }> = {}
  for (const row of data as any[]) {
    if (!totals[row.pattern_no]) totals[row.pattern_no] = { sum: 0, count: 0 }
    totals[row.pattern_no].sum += row.mastery_level
    totals[row.pattern_no].count++
  }
  // 平均★が低い順にソートしてTOP3
  weakPatterns.value = Object.entries(totals)
    .map(([pno, v]) => ({ pno, avg: v.sum / v.count }))
    .sort((a, b) => a.avg - b.avg)
    .slice(0, 3)
    .map(x => x.pno)
}

async function handleApprove(memberId: string) {
  await store.approveMember(memberId)
  // 承認後に生徒一覧を再取得
  await store.fetchClassStudents(classId)
}

async function handleRemove(memberId: string) {
  if (!confirm('この生徒をクラスから削除しますか？')) return
  await store.removeMember(memberId)
}

async function handleApproveBadge(badgeId: string) {
  await store.approveBadge(badgeId)
}

function openRejectModal(badgeId: string) {
  rejectModal.value = { open: true, badgeId, reason: '' }
}

async function handleRejectBadge() {
  await store.rejectBadge(rejectModal.value.badgeId, rejectModal.value.reason)
  rejectModal.value.open = false
}

// ─── 表示ヘルパー ──────────────────────────────────────────────
function moodEmoji(mood: string | null): string {
  const map: Record<string, string> = {
    morning_great:  '✨',
    morning_doable: '🙂',
    morning_normal: '😐',
    morning_heavy:  '😮‍💨',
    morning_nope:   '😵',
  }
  return mood ? (map[mood] ?? '─') : '─'
}

function areaLabel(area: string): string {
  const map: Record<string, string> = {
    area1: 'エリア1 Hello Badge',
    area2: 'エリア2 Daily Badge',
    area3: 'エリア3 Travel Badge',
    area4: 'エリア4 Business Badge',
    area5: 'エリア5 World Badge',
  }
  return map[area] ?? area
}

function formatDate(iso: string): string {
  return new Date(iso).toLocaleDateString('ja-JP', {
    year: 'numeric', month: 'short', day: 'numeric',
  })
}
</script>
