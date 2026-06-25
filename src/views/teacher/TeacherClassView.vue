<template>
  <div class="min-h-screen bg-bg-dark">
    <!-- Header -->
    <header class="neo-header">
      <button @click="router.push('/teacher')" class="text-white/30 text-sm font-title hover:text-white/50 transition-colors mb-1">
        ← ダッシュボードへ
      </button>
      <div class="flex items-center justify-between">
        <h1 class="text-xl font-title font-bold text-white">{{ currentClass?.class_name ?? 'クラス詳細' }}</h1>
        <div class="flex items-center gap-4">
          <button
            v-if="store.students.length > 0"
            @click="exportCSV"
            class="btn-ghost !text-xs border border-white/10 !rounded-xl"
          >CSV出力</button>
          <div v-if="currentClass" class="text-right">
            <p class="text-[10px] text-white/25 font-title">クラスコード</p>
            <span class="font-mono text-xl font-bold tracking-[0.2em] text-neo-gradient">
              {{ currentClass.class_code }}
            </span>
          </div>
        </div>
      </div>
    </header>

    <main class="max-w-4xl mx-auto px-5 py-6 space-y-5">

      <!-- Class stats -->
      <section v-if="store.students.length > 0" class="neo-card">
        <h2 class="neo-section-title">クラス統計</h2>
        <div class="grid grid-cols-4 gap-3 text-center">
          <div>
            <p class="text-2xl font-bold font-title text-neo-gradient">{{ store.students.length }}</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">生徒数</p>
          </div>
          <div>
            <p class="text-2xl font-bold font-title text-neon-yellow">{{ classAvgMastery }}</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">平均★</p>
          </div>
          <div>
            <p class="text-2xl font-bold font-title text-neon-green">{{ classActiveRate }}%</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">直近7日活動率</p>
          </div>
          <div>
            <p class="text-2xl font-bold font-title text-neon-orange">{{ classAvgStreak }}</p>
            <p class="text-[11px] text-white/30 font-title mt-0.5">平均連続日数</p>
          </div>
        </div>
        <div v-if="weakPatterns.length > 0" class="mt-4 pt-3 border-t border-white/[0.06]">
          <p class="text-[11px] text-white/25 mb-2 font-title">弱点パターン TOP3</p>
          <div class="flex gap-2">
            <span
              v-for="wp in weakPatterns"
              :key="wp"
              class="neo-badge pink"
            >{{ wp }}</span>
          </div>
        </div>
      </section>

      <!-- Pattern range -->
      <section v-if="currentClass" class="neo-card">
        <div class="flex items-center justify-between">
          <h2 class="neo-section-title !mb-0">今週のパターン範囲</h2>
          <button
            v-if="!editingRange"
            @click="editingRange = true"
            class="text-xs text-brand-secondary hover:text-brand-secondary/80 font-title font-medium"
          >変更</button>
        </div>
        <div v-if="!editingRange" class="mt-2">
          <p v-if="currentClass.current_pattern_range" class="text-lg font-bold text-white font-title">
            {{ currentClass.current_pattern_range }}
          </p>
          <p v-else class="text-sm text-white/25">未設定（全パターン対象）</p>
        </div>
        <div v-else class="mt-3 flex items-center gap-3">
          <select v-model="rangeFrom" class="neo-input !w-auto !py-2">
            <option v-for="p in patternOptions" :key="p" :value="p">{{ p }}</option>
          </select>
          <span class="text-white/30">〜</span>
          <select v-model="rangeTo" class="neo-input !w-auto !py-2">
            <option v-for="p in patternOptions" :key="p" :value="p">{{ p }}</option>
          </select>
          <button @click="savePatternRange" class="btn-neo !py-2 !px-3 !text-xs !rounded-xl">保存</button>
          <button @click="editingRange = false" class="btn-ghost !text-xs">キャンセル</button>
        </div>
      </section>

      <!-- Pending members -->
      <section v-if="store.pendingMembers.length > 0">
        <h2 class="text-sm font-title font-semibold text-neon-orange mb-3">
          参加申請中 {{ store.pendingMembers.length }}名
        </h2>
        <div class="neo-card !p-0 divide-y divide-white/[0.05]">
          <div
            v-for="m in store.pendingMembers"
            :key="m.id"
            class="flex items-center justify-between px-5 py-3"
          >
            <div>
              <p class="font-title font-medium text-white text-sm">{{ m.users?.display_name }}</p>
              <p class="text-xs text-white/25">{{ m.users?.email }}</p>
            </div>
            <div class="flex gap-2">
              <button @click="handleApprove(m.id)" class="btn-neo !py-1.5 !px-3 !text-xs !rounded-xl">承認</button>
              <button @click="handleRemove(m.id)" class="btn-ghost !text-xs border border-white/10 !rounded-xl">削除</button>
            </div>
          </div>
        </div>
      </section>

      <!-- Pending badges -->
      <section v-if="store.pendingBadges.length > 0">
        <h2 class="text-sm font-title font-semibold text-neon-purple mb-3">
          チャートバッジ承認待ち {{ store.pendingBadges.length }}件
        </h2>
        <div class="neo-card !p-0 divide-y divide-white/[0.05]">
          <div
            v-for="b in store.pendingBadges"
            :key="b.id"
            class="flex items-center justify-between px-5 py-4"
          >
            <div>
              <p class="font-title font-medium text-white text-sm">
                {{ b.users?.display_name }}
                <span class="ml-2 text-neo-gradient font-bold">{{ areaLabel(b.area) }}</span>
              </p>
              <p class="text-xs text-white/25">
                申請：{{ formatDate(b.applied_at) }}
                <span v-if="b.mastery_avg_at_apply"> | 平均★{{ Number(b.mastery_avg_at_apply).toFixed(1) }}</span>
              </p>
            </div>
            <div class="flex gap-2">
              <button @click="handleApproveBadge(b.id)" class="btn-neo !py-1.5 !px-3 !text-xs !rounded-xl">承認</button>
              <button @click="openRejectModal(b.id)" class="btn-ghost !text-xs border border-white/10 !rounded-xl">却下</button>
            </div>
          </div>
        </div>
      </section>

      <!-- Students list -->
      <section>
        <h2 class="text-sm font-title font-semibold text-white/60 mb-3">
          生徒一覧（{{ store.students.length }}名）
        </h2>

        <div v-if="store.loading" class="flex justify-center py-10">
          <div class="w-7 h-7 border-2 border-brand-primary border-t-transparent rounded-full animate-spin" />
        </div>

        <div v-else-if="store.students.length === 0" class="text-center py-12 text-white/25 text-sm font-title">
          承認済みの生徒がいません。
        </div>

        <div v-else class="space-y-2">
          <div
            v-for="s in store.students"
            :key="s.student_id"
            class="neo-card cursor-pointer hover:shadow-neo-md active:scale-[0.99] transition-all duration-200"
            @click="router.push({ name: 'TeacherStudent', params: { classId, studentId: s.student_id } })"
          >
            <div class="flex items-start justify-between">
              <div class="flex-1">
                <div class="flex items-center gap-2">
                  <p class="font-title font-semibold text-white">{{ s.display_name }}</p>
                  <span
                    v-if="s.anxious_days_last_3 >= 2"
                    class="neo-badge pink !text-[10px]"
                  >要フォロー</span>
                </div>
                <div class="flex flex-wrap gap-3 mt-2 text-sm text-white/40">
                  <span>Lv. <strong class="text-neo-gradient">{{ s.mowi_level }}</strong></span>
                  <span>🔥 <strong class="text-neon-orange">{{ s.streak_days }}</strong> 日</span>
                  <span v-if="s.avg_mastery_level">★ <strong class="text-neon-yellow">{{ Number(s.avg_mastery_level).toFixed(1) }}</strong></span>
                  <span v-if="s.patterns_mastered">習得 <strong class="text-neon-cyan">{{ s.patterns_mastered }}</strong></span>
                  <span v-if="s.approved_badges">バッジ <strong class="text-neon-purple">{{ s.approved_badges }}</strong></span>
                </div>
              </div>
              <div class="ml-4 text-right">
                <p class="text-[10px] text-white/20 font-title">今朝</p>
                <span class="text-lg">{{ moodEmoji(s.latest_morning_mood) }}</span>
              </div>
            </div>
            <!-- Roblox -->
            <div v-if="store.robloxStats[s.student_id]" class="mt-3 bg-neon-purple/5 rounded-xl px-4 py-2 border border-neon-purple/10">
              <div class="flex items-center gap-2 mb-1">
                <span class="text-[11px] font-title font-semibold text-neon-purple">Roblox</span>
                <span
                  v-if="store.robloxStats[s.student_id].linked"
                  class="neo-badge green !text-[9px] !py-0"
                >連携済み</span>
                <span v-else class="neo-badge !text-[9px] !py-0">未連携</span>
              </div>
              <template v-if="store.robloxStats[s.student_id].linked">
                <div class="flex flex-wrap gap-3 text-xs text-white/40">
                  <span v-if="store.robloxStats[s.student_id].roblox_display_name">{{ store.robloxStats[s.student_id].roblox_display_name }}</span>
                  <span v-if="store.robloxStats[s.student_id].town">🪙 <strong>{{ store.robloxStats[s.student_id].town.word_coins }}</strong></span>
                  <span v-if="store.robloxStats[s.student_id].town">🏠 <strong>{{ store.robloxStats[s.student_id].town.total_buildings_built }}</strong></span>
                  <span v-if="store.robloxStats[s.student_id].town">📋 <strong>{{ store.robloxStats[s.student_id].town.total_missions_completed }}</strong></span>
                  <span v-if="store.robloxStats[s.student_id].total_sessions > 0">🕹️ <strong>{{ store.robloxStats[s.student_id].total_sessions }}</strong></span>
                  <span v-if="store.robloxStats[s.student_id].latest_session">コンボ <strong>{{ store.robloxStats[s.student_id].latest_session.max_combo }}</strong></span>
                </div>
              </template>
            </div>
            <p v-if="s.last_practice_at" class="text-[11px] text-white/15 mt-2 font-title">
              最終練習：{{ formatDate(s.last_practice_at) }}
            </p>
            <p v-else class="text-[11px] text-white/15 mt-2 font-title">まだ練習なし</p>
          </div>
        </div>
      </section>
    </main>

    <!-- Reject modal -->
    <div
      v-if="rejectModal.open"
      class="neo-overlay"
      @click.self="rejectModal.open = false"
    >
      <div class="neo-modal !max-w-sm">
        <h2 class="text-base font-title font-bold text-white mb-3">却下理由（任意）</h2>
        <textarea
          v-model="rejectModal.reason"
          rows="3"
          placeholder="例：エリア1のパターンをもう少し練習してから申請してください。"
          class="neo-input resize-none"
        />
        <div class="flex gap-3 mt-4">
          <button @click="rejectModal.open = false" class="btn-ghost flex-1 py-2.5 border border-white/10 rounded-2xl">キャンセル</button>
          <button @click="handleRejectBadge" class="flex-1 py-2.5 text-sm font-title font-bold text-white bg-wrong rounded-2xl active:scale-95 transition-transform">却下する</button>
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

const weakPatterns = ref<string[]>([])

onMounted(async () => {
  const { data } = await supabase
    .from('classes')
    .select('*')
    .eq('id', classId)
    .single()
  currentClass.value = data

  await Promise.all([
    store.fetchClassStudents(classId),
    store.fetchPendingMembers(classId),
    store.fetchPendingBadges(classId),
  ])

  await store.fetchRobloxStats(classId)
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
  const totals: Record<string, { sum: number; count: number }> = {}
  for (const row of data as any[]) {
    if (!totals[row.pattern_no]) totals[row.pattern_no] = { sum: 0, count: 0 }
    totals[row.pattern_no].sum += row.mastery_level
    totals[row.pattern_no].count++
  }
  weakPatterns.value = Object.entries(totals)
    .map(([pno, v]) => ({ pno, avg: v.sum / v.count }))
    .sort((a, b) => a.avg - b.avg)
    .slice(0, 3)
    .map(x => x.pno)
}

async function handleApprove(memberId: string) {
  await store.approveMember(memberId)
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

function moodEmoji(mood: string | null): string {
  const map: Record<string, string> = {
    morning_great: '✨', morning_doable: '🙂', morning_normal: '😐',
    morning_heavy: '😮‍💨', morning_nope: '😵',
  }
  return mood ? (map[mood] ?? '─') : '─'
}

function areaLabel(area: string): string {
  const map: Record<string, string> = {
    area1: 'エリア1 Hello Badge', area2: 'エリア2 Daily Badge',
    area3: 'エリア3 Travel Badge', area4: 'エリア4 Business Badge',
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
