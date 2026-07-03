<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useReadingStore, READING_LEVELS } from '@/stores/reading'
import { useAuthStore } from '@/stores/auth'
import BottomNav from '@/components/common/BottomNav.vue'

const router = useRouter()
const store = useReadingStore()
const auth = useAuthStore()
const activeLevel = ref(0)
const activeTab = ref<'library' | 'progress'>('library')

const filteredBooks = computed(() =>
  activeLevel.value === 0
    ? store.books
    : store.books.filter(b => b.level === activeLevel.value),
)

function levelMeta(level: number) {
  return READING_LEVELS.find(l => l.level === level)!
}

function openBook(bookId: string) {
  router.push({ name: 'ReadingBook', params: { bookId } })
}

function statusOf(bookId: string) {
  const p = store.progress[bookId]
  if (!p) return null
  if (p.status === 'quiz_done') return { label: `★${p.quiz_score}/5`, cls: 'bg-neo-gradient text-white' }
  if (p.status === 'read') return { label: '読了', cls: 'bg-white/10 text-white/60' }
  return { label: '読書中', cls: 'bg-white/10 text-white/40' }
}

onMounted(async () => {
  await store.fetchBooks()
  await store.fetchWeeklyStats()
  await store.fetchMyAssignments()
})
</script>

<template>
  <div class="min-h-screen bg-bg-dark pb-28 safe-pt">
    <header class="px-5 pt-4 pb-2">
      <h1 class="text-white text-xl font-title font-bold">リーディング</h1>
      <p class="text-white/25 text-xs font-title mt-0.5">読む・聴く・クイズで確かめる</p>
    </header>

    <!-- Tab: Library / Progress -->
    <div class="px-5 mb-3 flex gap-2">
      <button
        v-for="tab in [{ id: 'library', label: '📚 ライブラリ' }, { id: 'progress', label: '📊 きろく' }] as const"
        :key="tab.id"
        @click="activeTab = tab.id"
        class="flex-1 py-2 rounded-xl text-xs font-title font-semibold transition-all"
        :class="activeTab === tab.id
          ? 'bg-neo-gradient text-white shadow-neo-sm'
          : 'bg-bg-card text-white/30 border border-white/[0.06]'"
      >{{ tab.label }}</button>
    </div>

    <!-- ===== LIBRARY TAB ===== -->
    <template v-if="activeTab === 'library'">
      <!-- Stats summary -->
      <div class="px-5 mb-3">
        <div class="bg-bg-card border border-white/[0.06] rounded-2xl p-3 flex items-center gap-3">
          <div class="flex-1 text-center">
            <p class="text-white/40 text-[10px] font-title">読了</p>
            <p class="text-white text-lg font-title font-bold">{{ store.stats.booksRead }}<span class="text-[10px] text-white/40"> 冊</span></p>
          </div>
          <div class="w-px h-8 bg-white/[0.06]" />
          <div class="flex-1 text-center">
            <p class="text-white/40 text-[10px] font-title">クイズ合格</p>
            <p class="text-white text-lg font-title font-bold">{{ store.stats.quizDone }}<span class="text-[10px] text-white/40"> 冊</span></p>
          </div>
          <div class="w-px h-8 bg-white/[0.06]" />
          <div class="flex-1 text-center">
            <p class="text-white/40 text-[10px] font-title">平均スコア</p>
            <p class="text-white text-lg font-title font-bold">{{ store.stats.avgScore ?? '—' }}<span class="text-[10px] text-white/40"> /5</span></p>
          </div>
        </div>
      </div>

      <!-- Assignments -->
      <div v-if="store.assignments.length > 0" class="px-5 mb-3">
        <p class="text-white/40 text-[10px] font-title font-bold uppercase tracking-wider mb-1.5">課題</p>
        <div class="space-y-2">
          <button
            v-for="a in store.assignments"
            :key="a.id"
            @click="openBook(a.book_id)"
            class="w-full text-left bg-brand-primary/10 border border-brand-primary/20 rounded-xl p-3 flex items-center gap-3"
          >
            <span class="text-lg">📋</span>
            <div class="flex-1 min-w-0">
              <p class="text-white text-sm font-title font-semibold truncate">{{ a.book?.title ?? '課題' }}</p>
              <p v-if="a.instructions" class="text-white/40 text-[10px] font-title truncate">{{ a.instructions }}</p>
            </div>
            <div v-if="a.due_date" class="text-right">
              <p class="text-brand-accent text-[10px] font-title">期限</p>
              <p class="text-white/60 text-[10px] font-title">{{ new Date(a.due_date).toLocaleDateString('ja') }}</p>
            </div>
            <span class="text-white/30 text-sm">→</span>
          </button>
        </div>
      </div>

      <!-- Level tabs -->
      <div class="px-5 mb-3 flex gap-1.5 overflow-x-auto no-scrollbar">
        <button
          @click="activeLevel = 0"
          class="shrink-0 px-3 py-1.5 rounded-full text-[11px] font-title font-semibold transition-all"
          :class="activeLevel === 0
            ? 'bg-neo-gradient text-white shadow-neo-sm'
            : 'bg-bg-card text-white/30 border border-white/[0.06]'"
        >全て</button>
        <button
          v-for="lv in READING_LEVELS"
          :key="lv.level"
          @click="activeLevel = lv.level"
          class="shrink-0 px-3 py-1.5 rounded-full text-[11px] font-title font-semibold transition-all"
          :class="activeLevel === lv.level
            ? 'bg-neo-gradient text-white shadow-neo-sm'
            : 'bg-bg-card text-white/30 border border-white/[0.06]'"
        >{{ lv.name }}</button>
      </div>

      <!-- Book grid -->
      <div v-if="store.loading" class="px-5 py-8 text-center text-white/30 text-sm font-title">読み込み中...</div>
      <div v-else-if="filteredBooks.length === 0" class="px-5 py-8 text-center text-white/30 text-sm font-title">
        このレベルの本は準備中です
      </div>
      <div v-else class="px-5 grid grid-cols-2 gap-3">
        <button
          v-for="book in filteredBooks"
          :key="book.id"
          @click="openBook(book.id)"
          class="text-left bg-bg-card border border-white/[0.06] rounded-2xl overflow-hidden active:scale-[0.98] transition-transform"
        >
          <div class="aspect-[4/3] flex items-center justify-center bg-neo-card relative">
            <img v-if="book.cover_url" :src="book.cover_url" :alt="book.title" class="w-full h-full object-cover" />
            <span v-else class="text-3xl">📖</span>
            <span
              class="absolute top-1.5 left-1.5 px-1.5 py-0.5 rounded-full text-[9px] font-title font-bold text-black/80"
              :style="{ backgroundColor: levelMeta(book.level).color }"
            >{{ levelMeta(book.level).name }}</span>
            <span
              v-if="statusOf(book.id)"
              class="absolute top-1.5 right-1.5 px-1.5 py-0.5 rounded-full text-[9px] font-title font-bold"
              :class="statusOf(book.id)!.cls"
            >{{ statusOf(book.id)!.label }}</span>
          </div>
          <div class="p-2.5">
            <p class="text-white text-xs font-title font-semibold leading-snug">{{ book.title }}</p>
            <p class="text-white/30 text-[10px] font-title mt-0.5">{{ book.word_count }} words</p>
          </div>
        </button>
      </div>
    </template>

    <!-- ===== PROGRESS TAB ===== -->
    <template v-if="activeTab === 'progress'">
      <!-- Weekly chart -->
      <div class="px-5 mb-4">
        <p class="text-white/40 text-[10px] font-title font-bold uppercase tracking-wider mb-2">週ごとの読書量</p>
        <div v-if="store.weeklyStats.length === 0" class="bg-bg-card border border-white/[0.06] rounded-2xl p-6 text-center">
          <p class="text-white/30 text-sm font-title">まだデータがありません</p>
          <p class="text-white/20 text-[10px] font-title mt-1">本を読み始めると記録が表示されます</p>
        </div>
        <div v-else class="bg-bg-card border border-white/[0.06] rounded-2xl p-4">
          <div class="flex gap-2 items-end h-24">
            <div
              v-for="week in store.weeklyStats"
              :key="week.week_label"
              class="flex-1 flex flex-col items-center gap-1"
            >
              <p class="text-white text-xs font-title font-bold">{{ week.books_read }}</p>
              <div
                class="w-full rounded-t-lg bg-neo-gradient transition-all"
                :style="{ height: Math.max(8, week.books_read * 20) + 'px' }"
              />
              <p class="text-white/30 text-[9px] font-title">{{ week.week_label }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- Detail cards -->
      <div class="px-5 space-y-3">
        <div class="bg-bg-card border border-white/[0.06] rounded-2xl p-4">
          <div class="flex items-center gap-3 mb-3">
            <span class="text-2xl">📖</span>
            <div>
              <p class="text-white text-sm font-title font-bold">総読了数</p>
              <p class="text-white/40 text-[10px] font-title">これまでに読み終えた本</p>
            </div>
            <p class="ml-auto text-2xl font-title font-bold text-neo-gradient">{{ store.stats.booksRead }}</p>
          </div>
        </div>

        <div class="bg-bg-card border border-white/[0.06] rounded-2xl p-4">
          <div class="flex items-center gap-3 mb-3">
            <span class="text-2xl">🎯</span>
            <div>
              <p class="text-white text-sm font-title font-bold">クイズ合格</p>
              <p class="text-white/40 text-[10px] font-title">4問以上正解で合格</p>
            </div>
            <p class="ml-auto text-2xl font-title font-bold text-neon-green">{{ store.stats.quizDone }}</p>
          </div>
        </div>

        <div class="bg-bg-card border border-white/[0.06] rounded-2xl p-4">
          <div class="flex items-center gap-3">
            <span class="text-2xl">🎙</span>
            <div>
              <p class="text-white text-sm font-title font-bold">音読録音</p>
              <p class="text-white/40 text-[10px] font-title">今週の録音回数</p>
            </div>
            <p class="ml-auto text-2xl font-title font-bold text-neon-cyan">
              {{ store.weeklyStats.length > 0 ? store.weeklyStats[store.weeklyStats.length - 1].recordings : 0 }}
            </p>
          </div>
        </div>
      </div>
    </template>

    <BottomNav />
  </div>
</template>

<style scoped>
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
