<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useReadingStore, XP_READ, XP_QUIZ_PASS } from '@/stores/reading'
import MatchPictureQuiz from '@/components/reading/MatchPictureQuiz.vue'
import TrueFalseQuiz from '@/components/reading/TrueFalseQuiz.vue'
import MultipleChoiceQuiz from '@/components/reading/MultipleChoiceQuiz.vue'

const route = useRoute()
const router = useRouter()
const store = useReadingStore()
const bookId = route.params.bookId as string

// ─── フェーズ管理: read → quiz → result ───
const phase = ref<'read' | 'quiz' | 'result'>('read')
const pageIndex = ref(0)
const quizIndex = ref(0)
const answered = ref<number | null>(null)
const correctCount = ref(0)
const xpEarned = ref(0)
const listenedPages = ref(new Set<number>())

const page = computed(() => store.currentPages[pageIndex.value])
const quiz = computed(() => store.currentQuizzes[quizIndex.value])
const isLastPage = computed(() => pageIndex.value === store.currentPages.length - 1)

// ─── 音声再生（audio_url優先、なければWeb Speech合成でハイライト） ───
const playing = ref(false)
const highlightWord = ref(-1)
let audioEl: HTMLAudioElement | null = null

const words = computed(() => (page.value?.body ?? '').split(/\s+/))

function play() {
  stop()
  if (!page.value) return
  playing.value = true
  listenedPages.value.add(page.value.page_no)

  if (page.value.audio_url) {
    audioEl = new Audio(page.value.audio_url)
    audioEl.onended = onPlayEnd
    audioEl.onerror = onPlayEnd
    audioEl.play().catch(onPlayEnd)
    return
  }
  // フォールバック: speechSynthesis（単語境界でハイライト）
  if (!('speechSynthesis' in window)) { onPlayEnd(); return }
  const u = new SpeechSynthesisUtterance(page.value.body)
  u.lang = 'en-US'
  u.rate = 0.85
  u.onboundary = (e) => {
    if (e.name !== 'word') return
    let acc = 0
    for (let i = 0; i < words.value.length; i++) {
      if (e.charIndex <= acc + words.value[i].length) { highlightWord.value = i; break }
      acc += words.value[i].length + 1
    }
  }
  u.onend = onPlayEnd
  u.onerror = onPlayEnd
  speechSynthesis.speak(u)
}

function onPlayEnd() {
  playing.value = false
  highlightWord.value = -1
  // 全ページ聴取チェック
  if (listenedPages.value.size >= store.currentPages.length && store.currentPages.length > 0) {
    store.markListened(bookId).then(() => { /* XP+5はストア側で初回のみ */ })
  }
}

function stop() {
  if (audioEl) { audioEl.pause(); audioEl = null }
  if ('speechSynthesis' in window) speechSynthesis.cancel()
  playing.value = false
  highlightWord.value = -1
}

// ─── ページ送り ───
function nextPage() {
  stop()
  if (!isLastPage.value) pageIndex.value++
}
function prevPage() {
  stop()
  if (pageIndex.value > 0) pageIndex.value--
}

// スワイプ対応
let touchX = 0
function onTouchStart(e: TouchEvent) { touchX = e.touches[0].clientX }
function onTouchEnd(e: TouchEvent) {
  const dx = e.changedTouches[0].clientX - touchX
  if (dx < -50) nextPage()
  if (dx > 50) prevPage()
}

// ─── クイズ ───
async function startQuiz() {
  stop()
  const alreadyRead = store.progress[bookId] && store.progress[bookId].status !== 'reading'
  await store.markRead(bookId)
  if (!alreadyRead) xpEarned.value += XP_READ
  phase.value = 'quiz'
  quizIndex.value = 0
  correctCount.value = 0
  answered.value = null
}

function onAnswer(index: number) {
  if (answered.value !== null) return
  answered.value = index
  if (index === quiz.value.answer_index) correctCount.value++
}

async function nextQuiz() {
  answered.value = null
  if (quizIndex.value < store.currentQuizzes.length - 1) {
    quizIndex.value++
    return
  }
  // 全問終了
  const passedFirst = await store.submitQuiz(bookId, correctCount.value)
  if (passedFirst) xpEarned.value += XP_QUIZ_PASS
  phase.value = 'result'
}

function quizComponent(format: string) {
  if (format === 'match_picture') return MatchPictureQuiz
  if (format === 'true_false') return TrueFalseQuiz
  return MultipleChoiceQuiz
}

onMounted(() => store.fetchBook(bookId))
onBeforeUnmount(stop)
</script>

<template>
  <div class="min-h-screen bg-bg-dark safe-pt flex flex-col">
    <!-- ヘッダー -->
    <header class="px-5 pt-4 pb-3 flex items-center gap-3">
      <button @click="stop(); router.push({ name: 'ReadingLibrary' })" class="text-white/40 text-sm font-title">← 戻る</button>
      <div class="flex-1 min-w-0">
        <p class="text-white text-sm font-title font-bold truncate">{{ store.currentBook?.title }}</p>
      </div>
      <p v-if="phase === 'read'" class="text-white/30 text-xs font-title">
        {{ pageIndex + 1 }} / {{ store.currentPages.length }}
      </p>
      <p v-else-if="phase === 'quiz'" class="text-white/30 text-xs font-title">
        Q{{ quizIndex + 1 }} / {{ store.currentQuizzes.length }}
      </p>
    </header>

    <div v-if="store.loading" class="flex-1 flex items-center justify-center text-white/30 text-sm font-title">
      読み込み中…
    </div>

    <!-- ═══ 読書フェーズ ═══ -->
    <div
      v-else-if="phase === 'read' && page"
      class="flex-1 flex flex-col px-5 pb-8"
      @touchstart="onTouchStart"
      @touchend="onTouchEnd"
    >
      <!-- 挿絵 -->
      <div class="rounded-3xl overflow-hidden bg-neo-card aspect-[4/3] flex items-center justify-center mb-5">
        <img v-if="page.image_url" :src="page.image_url" :alt="`page ${page.page_no}`" class="w-full h-full object-cover" />
        <span v-else class="text-6xl opacity-40">🐱</span>
      </div>

      <!-- 本文（再生中の単語をハイライト） -->
      <p class="text-white text-2xl font-title font-bold leading-relaxed text-center mb-6">
        <template v-for="(w, i) in words" :key="i">
          <span
            :class="highlightWord === i ? 'text-brand-secondary bg-brand-secondary/10 rounded px-0.5' : ''"
          >{{ w }}</span>{{ ' ' }}
        </template>
      </p>

      <!-- 再生ボタン -->
      <div class="flex justify-center mb-auto">
        <button
          @click="playing ? stop() : play()"
          class="w-14 h-14 rounded-full bg-neo-gradient shadow-neo-md flex items-center justify-center text-white text-xl active:scale-95 transition-transform"
        >{{ playing ? '⏸' : '▶' }}</button>
      </div>

      <!-- ナビゲーション -->
      <div class="flex gap-3 mt-6">
        <button
          v-if="pageIndex > 0"
          @click="prevPage"
          class="flex-1 py-3.5 rounded-2xl bg-bg-card border border-white/[0.06] text-white/50 text-sm font-title font-semibold"
        >← まえ</button>
        <button
          v-if="!isLastPage"
          @click="nextPage"
          class="flex-1 py-3.5 rounded-2xl bg-neo-gradient text-white text-sm font-title font-bold shadow-neo-sm"
        >つぎ →</button>
        <button
          v-else
          @click="startQuiz"
          class="flex-1 py-3.5 rounded-2xl bg-neo-gradient text-white text-sm font-title font-bold shadow-neo-md"
        >クイズへ 🎯</button>
      </div>
    </div>

    <!-- ═══ クイズフェーズ ═══ -->
    <div v-else-if="phase === 'quiz' && quiz" class="flex-1 flex flex-col px-5 pb-8">
      <!-- 進捗ドット -->
      <div class="flex gap-1.5 justify-center mb-6">
        <span
          v-for="(q, i) in store.currentQuizzes"
          :key="q.id"
          class="w-2 h-2 rounded-full"
          :class="i < quizIndex ? 'bg-brand-secondary' : i === quizIndex ? 'bg-white' : 'bg-white/15'"
        />
      </div>

      <component
        :is="quizComponent(quiz.format)"
        :quiz="quiz"
        :book-no="store.currentBook?.book_no ?? ''"
        :answered="answered"
        @answer="onAnswer"
      />

      <!-- 正誤＋日本語解説 -->
      <div v-if="answered !== null" class="mt-5 animate-slideUp">
        <div
          class="rounded-2xl p-4 border"
          :class="answered === quiz.answer_index
            ? 'bg-[#00FF88]/5 border-[#00FF88]/30'
            : 'bg-[#FF6B9D]/5 border-[#FF6B9D]/30'"
        >
          <p class="text-sm font-title font-bold mb-1"
             :class="answered === quiz.answer_index ? 'text-[#00FF88]' : 'text-[#FF6B9D]'">
            {{ answered === quiz.answer_index ? '⭕ せいかい！' : '❌ ざんねん…' }}
          </p>
          <p class="text-white/70 text-sm font-title leading-relaxed">{{ quiz.explanation_ja }}</p>
        </div>
        <button
          @click="nextQuiz"
          class="w-full mt-4 py-3.5 rounded-2xl bg-neo-gradient text-white text-sm font-title font-bold shadow-neo-sm"
        >{{ quizIndex < store.currentQuizzes.length - 1 ? 'つぎの問題 →' : '結果を見る 🏁' }}</button>
      </div>
    </div>

    <!-- ═══ 結果フェーズ ═══ -->
    <div v-else-if="phase === 'result'" class="flex-1 flex flex-col items-center justify-center px-5 pb-8 animate-popIn">
      <p class="text-6xl mb-4">{{ correctCount >= 4 ? '🎉' : '💪' }}</p>
      <p class="text-white text-2xl font-title font-bold mb-1">{{ correctCount }} / {{ store.currentQuizzes.length }} 正解</p>
      <p class="text-white/40 text-sm font-title mb-6">
        {{ correctCount >= 4 ? 'すばらしい！合格です' : 'もう一度読んでチャレンジしよう' }}
      </p>
      <div v-if="xpEarned > 0" class="px-5 py-2 rounded-full bg-neo-gradient shadow-neo-md mb-8">
        <p class="text-white text-sm font-title font-bold">+{{ xpEarned }} XP GET!</p>
      </div>
      <div class="w-full flex flex-col gap-3">
        <button
          @click="phase = 'read'; pageIndex = 0"
          class="w-full py-3.5 rounded-2xl bg-bg-card border border-white/[0.06] text-white/60 text-sm font-title font-semibold"
        >もう一度読む</button>
        <button
          @click="router.push({ name: 'ReadingLibrary' })"
          class="w-full py-3.5 rounded-2xl bg-neo-gradient text-white text-sm font-title font-bold shadow-neo-sm"
        >ライブラリへ戻る</button>
      </div>
    </div>
  </div>
</template>
