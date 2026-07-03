<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useReadingStore, READING_LEVELS } from '@/stores/reading'
import BottomNav from '@/components/common/BottomNav.vue'

const router = useRouter()
const store = useReadingStore()
const activeLevel = ref(0) // 0 = 全て

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

onMounted(() => store.fetchBooks())
</script>

<template>
  <div class="min-h-screen bg-bg-dark pb-28 safe-pt">
    <header class="px-5 pt-4 pb-3">
      <h1 class="text-white text-xl font-title font-bold">リーディング</h1>
      <p class="text-white/25 text-xs font-title mt-0.5">読む・聴く・クイズで確かめる</p>
    </header>

    <!-- 進捗サマリ -->
    <div class="px-5 mb-4">
      <div class="bg-bg-card border border-white/[0.06] rounded-3xl p-4 flex items-center gap-4">
        <div class="flex-1">
          <p class="text-white/40 text-[10px] font-title">読了</p>
          <p class="text-white text-lg font-title font-bold">{{ store.stats.booksRead }}<span class="text-xs text-white/40"> 冊</span></p>
        </div>
        <div class="flex-1">
          <p class="text-white/40 text-[10px] font-title">クイズ合格</p>
          <p class="text-white text-lg font-title font-bold">{{ store.stats.quizDone }}<span class="text-xs text-white/40"> 冊</span></p>
        </div>
        <div class="flex-1">
          <p class="text-white/40 text-[10px] font-title">平均スコア</p>
          <p class="text-white text-lg font-title font-bold">{{ store.stats.avgScore ?? '—' }}<span class="text-xs text-white/40"> /5</span></p>
        </div>
      </div>
    </div>

    <!-- レベルタブ -->
    <div class="px-5 mb-4 flex gap-2 overflow-x-auto no-scrollbar">
      <button
        @click="activeLevel = 0"
        class="shrink-0 px-4 py-1.5 rounded-full text-xs font-title font-semibold transition-all duration-200"
        :class="activeLevel === 0
          ? 'bg-neo-gradient text-white shadow-neo-sm'
          : 'bg-bg-card text-white/30 border border-white/[0.06]'"
      >全て</button>
      <button
        v-for="lv in READING_LEVELS"
        :key="lv.level"
        @click="activeLevel = lv.level"
        class="shrink-0 px-4 py-1.5 rounded-full text-xs font-title font-semibold transition-all duration-200"
        :class="activeLevel === lv.level
          ? 'bg-neo-gradient text-white shadow-neo-sm'
          : 'bg-bg-card text-white/30 border border-white/[0.06]'"
      >{{ lv.name }} <span class="opacity-60">{{ lv.ja }}</span></button>
    </div>

    <!-- 冊子グリッド -->
    <div v-if="store.loading" class="px-5 py-10 text-center text-white/30 text-sm font-title">読み込み中…</div>
    <div v-else-if="filteredBooks.length === 0" class="px-5 py-10 text-center text-white/30 text-sm font-title">
      このレベルの本は準備中です
    </div>
    <div v-else class="px-5 grid grid-cols-2 gap-3">
      <button
        v-for="book in filteredBooks"
        :key="book.id"
        @click="openBook(book.id)"
        class="text-left bg-bg-card border border-white/[0.06] rounded-3xl overflow-hidden active:scale-[0.98] transition-transform"
      >
        <!-- 表紙（未配置はプレースホルダー） -->
        <div class="aspect-square flex items-center justify-center bg-neo-card relative">
          <img v-if="book.cover_url" :src="book.cover_url" :alt="book.title" class="w-full h-full object-cover" />
          <span v-else class="text-4xl">📖</span>
          <span
            class="absolute top-2 left-2 px-2 py-0.5 rounded-full text-[10px] font-title font-bold text-black/80"
            :style="{ backgroundColor: levelMeta(book.level).color }"
          >{{ levelMeta(book.level).name }}</span>
          <span
            v-if="statusOf(book.id)"
            class="absolute top-2 right-2 px-2 py-0.5 rounded-full text-[10px] font-title font-bold"
            :class="statusOf(book.id)!.cls"
          >{{ statusOf(book.id)!.label }}</span>
        </div>
        <div class="p-3">
          <p class="text-white text-sm font-title font-semibold leading-snug">{{ book.title }}</p>
          <p class="text-white/30 text-[11px] font-title mt-0.5">{{ book.title_ja }} ・ {{ book.word_count }} words</p>
        </div>
      </button>
    </div>

    <BottomNav />
  </div>
</template>
