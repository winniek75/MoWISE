<script setup lang="ts">
import { onMounted, onBeforeUnmount, ref, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useReadingStore, XP_READ, XP_QUIZ_PASS } from '@/stores/reading'
import { useAuthStore } from '@/stores/auth'
import MatchPictureQuiz from '@/components/reading/MatchPictureQuiz.vue'
import TrueFalseQuiz from '@/components/reading/TrueFalseQuiz.vue'
import MultipleChoiceQuiz from '@/components/reading/MultipleChoiceQuiz.vue'

const route = useRoute()
const router = useRouter()
const store = useReadingStore()
const auth = useAuthStore()
const bookId = route.params.bookId as string
const isTeacher = computed(() => auth.isTeacher)

// === Section management ===
const section = ref<'dictation' | 'reading' | 'quiz'>('dictation')
const pageIndex = ref(0)
const quizIndex = ref(0)
const answered = ref<number | null>(null)
const correctCount = ref(0)
const xpEarned = ref(0)
const quizDone = ref(false)
const listenedPages = ref(new Set<number>())

const page = computed(() => store.currentPages[pageIndex.value])
const quiz = computed(() => store.currentQuizzes[quizIndex.value])
const isLastPage = computed(() => pageIndex.value === store.currentPages.length - 1)
const isFirstPage = computed(() => pageIndex.value === 0)
const totalPages = computed(() => store.currentPages.length)

// === Audio / Dictation ===
const playing = ref(false)
const highlightWord = ref(-1)
const playbackRate = ref(1)
const repeatMode = ref(false)
let audioEl: HTMLAudioElement | null = null

const words = computed(() => (page.value?.body ?? '').split(/\s+/))

function play() {
  stop()
  if (!page.value) return
  playing.value = true
  listenedPages.value.add(page.value.page_no)

  if (page.value.audio_url) {
    audioEl = new Audio(page.value.audio_url)
    audioEl.playbackRate = playbackRate.value
    audioEl.onended = onPlayEnd
    audioEl.onerror = onPlayEnd
    audioEl.play().catch(onPlayEnd)
    return
  }
  if (!('speechSynthesis' in window)) { onPlayEnd(); return }
  const u = new SpeechSynthesisUtterance(page.value.body)
  u.lang = 'en-US'
  u.rate = playbackRate.value * 0.85
  let wordIdx = 0
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
  if (repeatMode.value && page.value) {
    setTimeout(() => play(), 500)
    return
  }
  if (!isTeacher.value && listenedPages.value.size >= store.currentPages.length && store.currentPages.length > 0) {
    store.markListened(bookId)
  }
}

function stop() {
  if (audioEl) { audioEl.pause(); audioEl = null }
  if ('speechSynthesis' in window) speechSynthesis.cancel()
  playing.value = false
  highlightWord.value = -1
}

function setRate(rate: number) {
  playbackRate.value = rate
  if (audioEl) audioEl.playbackRate = rate
}

// === Reading aloud (recording) ===
const isRecording = ref(false)
const recordingTime = ref(0)
let recordingInterval: ReturnType<typeof setInterval> | null = null
let mediaRecorder: MediaRecorder | null = null
let recordedChunks: Blob[] = []

// Teacher model recording state
const teacherRecordingSaved = ref(false)

async function toggleRecording() {
  if (isRecording.value) {
    stopRecording()
    return
  }
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
    mediaRecorder = new MediaRecorder(stream)
    recordedChunks = []
    mediaRecorder.ondataavailable = (e) => { if (e.data.size > 0) recordedChunks.push(e.data) }
    mediaRecorder.onstop = async () => {
      stream.getTracks().forEach(t => t.stop())
      const blob = new Blob(recordedChunks, { type: 'audio/webm' })
      if (isTeacher.value) {
        await store.saveModelRecording(bookId, pageIndex.value, blob, recordingTime.value)
        teacherRecordingSaved.value = true
        setTimeout(() => { teacherRecordingSaved.value = false }, 2000)
      } else {
        await store.saveRecording(bookId, blob, recordingTime.value)
      }
    }
    mediaRecorder.start()
    isRecording.value = true
    recordingTime.value = 0
    recordingInterval = setInterval(() => { recordingTime.value++ }, 1000)
  } catch (e) {
    console.error('[recording] mic access denied', e)
  }
}

function stopRecording() {
  if (mediaRecorder && mediaRecorder.state !== 'inactive') mediaRecorder.stop()
  isRecording.value = false
  if (recordingInterval) { clearInterval(recordingInterval); recordingInterval = null }
}

function formatTime(s: number) {
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, '0')}`
}

// === Page navigation ===
function nextPage() {
  stop()
  if (!isLastPage.value) pageIndex.value++
}
function prevPage() {
  stop()
  if (pageIndex.value > 0) pageIndex.value--
}

// Swipe
let touchX = 0
function onTouchStart(e: TouchEvent) { touchX = e.touches[0].clientX }
function onTouchEnd(e: TouchEvent) {
  const dx = e.changedTouches[0].clientX - touchX
  if (dx < -50) nextPage()
  if (dx > 50) prevPage()
}

// === Navigation (role-aware) ===
function goBack() {
  stop()
  if (isTeacher.value) {
    router.push({ name: 'TeacherReading' })
  } else {
    router.push({ name: 'ReadingLibrary' })
  }
}

// === Quiz ===
async function startQuiz() {
  stop()
  if (!isTeacher.value) {
    const alreadyRead = store.progress[bookId] && store.progress[bookId].status !== 'reading'
    await store.markRead(bookId)
    if (!alreadyRead) xpEarned.value += XP_READ
  }
  section.value = 'quiz'
  quizIndex.value = 0
  correctCount.value = 0
  answered.value = null
  quizDone.value = false
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
  if (!isTeacher.value) {
    const passedFirst = await store.submitQuiz(bookId, correctCount.value)
    if (passedFirst) xpEarned.value += XP_QUIZ_PASS
  }
  quizDone.value = true
}

function quizComponent(format: string) {
  if (format === 'match_picture') return MatchPictureQuiz
  if (format === 'true_false') return TrueFalseQuiz
  return MultipleChoiceQuiz
}

// Reset page when switching sections
watch(section, () => {
  stop()
  stopRecording()
  pageIndex.value = 0
})

onMounted(() => store.fetchBook(bookId))
onBeforeUnmount(() => { stop(); stopRecording() })
</script>

<template>
  <div class="h-screen bg-bg-dark flex flex-col overflow-hidden safe-pt">
    <!-- Header -->
    <header class="shrink-0 px-4 pt-3 pb-2 flex items-center gap-2">
      <button @click="goBack()" class="text-white/40 text-xs font-title">← 戻る</button>
      <p class="flex-1 text-white text-sm font-title font-bold truncate text-center">{{ store.currentBook?.title }}</p>
      <span v-if="isTeacher" class="shrink-0 px-2 py-0.5 rounded-full bg-brand-accent/20 text-brand-accent text-[9px] font-title font-bold">講師モード</span>
      <p v-if="section !== 'quiz'" class="text-white/30 text-[11px] font-title">{{ pageIndex + 1 }}/{{ totalPages }}</p>
      <p v-else class="text-white/30 text-[11px] font-title">Q{{ quizIndex + 1 }}/{{ store.currentQuizzes.length }}</p>
    </header>

    <!-- Section tabs -->
    <div class="shrink-0 px-4 pb-2 flex gap-1.5">
      <button
        v-for="tab in ([
          { id: 'dictation', label: 'ディクテーション', icon: '🎧' },
          { id: 'reading', label: '音読', icon: '🗣' },
          { id: 'quiz', label: 'クイズ', icon: '🎯' },
        ] as const)"
        :key="tab.id"
        @click="tab.id === 'quiz' ? startQuiz() : (section = tab.id)"
        class="flex-1 py-2 rounded-xl text-[11px] font-title font-semibold transition-all"
        :class="section === tab.id
          ? 'bg-neo-gradient text-white shadow-neo-sm'
          : 'bg-bg-card text-white/30 border border-white/[0.06]'"
      >{{ tab.icon }} {{ tab.label }}</button>
    </div>

    <!-- Loading -->
    <div v-if="store.loading" class="flex-1 flex items-center justify-center text-white/30 text-sm font-title">
      読み込み中...
    </div>

    <!-- ========== DICTATION SECTION ========== -->
    <template v-else-if="section === 'dictation' && page">
      <div
        class="flex-1 flex flex-col px-4 min-h-0"
        @touchstart="onTouchStart"
        @touchend="onTouchEnd"
      >
        <!-- Book page area -->
        <div class="flex-1 min-h-0 bg-[#1e1e40] rounded-2xl border border-white/[0.06] p-4 flex flex-col">
          <!-- Image + text row -->
          <div class="flex gap-3 flex-1 min-h-0 overflow-auto reading-scroll">
            <!-- Small thumbnail -->
            <div v-if="page.image_url" class="shrink-0 w-20 h-20 rounded-xl overflow-hidden bg-bg-card">
              <img :src="page.image_url" class="w-full h-full object-cover" />
            </div>
            <div v-else class="shrink-0 w-20 h-20 rounded-xl bg-bg-card flex items-center justify-center">
              <span class="text-2xl opacity-30">📖</span>
            </div>

            <!-- Text with karaoke highlight -->
            <div class="flex-1">
              <p class="text-white text-base leading-[1.9] font-title">
                <template v-for="(w, i) in words" :key="i">
                  <span
                    class="transition-all duration-150 rounded px-0.5"
                    :class="highlightWord === i
                      ? 'text-[#00CECE] bg-[#00CECE]/15 font-bold scale-105 inline-block'
                      : 'text-white/90'"
                  >{{ w }}</span>{{ ' ' }}
                </template>
              </p>
            </div>
          </div>

          <!-- Page dots -->
          <div class="shrink-0 flex justify-center gap-1 mt-2 pt-2 border-t border-white/[0.06]">
            <span
              v-for="i in totalPages"
              :key="i"
              class="w-1.5 h-1.5 rounded-full transition-colors"
              :class="i - 1 === pageIndex ? 'bg-brand-secondary' : 'bg-white/15'"
            />
          </div>
        </div>

        <!-- Audio controls -->
        <div class="shrink-0 pt-3 pb-2">
          <div class="flex items-center justify-center gap-3">
            <!-- Speed control -->
            <div class="flex gap-1">
              <button
                v-for="rate in [0.7, 1, 1.3]"
                :key="rate"
                @click="setRate(rate)"
                class="px-2 py-1 rounded-lg text-[10px] font-title font-bold transition-all"
                :class="playbackRate === rate
                  ? 'bg-brand-secondary/20 text-brand-secondary'
                  : 'text-white/30'"
              >{{ rate }}x</button>
            </div>

            <!-- Play button -->
            <button
              @click="playing ? stop() : play()"
              class="w-12 h-12 rounded-full bg-neo-gradient shadow-neo-md flex items-center justify-center text-white text-lg active:scale-95 transition-transform"
            >{{ playing ? '⏸' : '▶' }}</button>

            <!-- Repeat toggle -->
            <button
              @click="repeatMode = !repeatMode"
              class="px-2 py-1 rounded-lg text-[10px] font-title font-bold transition-all"
              :class="repeatMode ? 'bg-brand-accent/20 text-brand-accent' : 'text-white/30'"
            >🔁 リピート</button>
          </div>
        </div>

        <!-- Page navigation -->
        <div class="shrink-0 flex gap-2 pb-3">
          <button
            v-if="!isFirstPage"
            @click="prevPage"
            class="flex-1 py-2.5 rounded-xl bg-bg-card border border-white/[0.06] text-white/50 text-xs font-title font-semibold"
          >← まえ</button>
          <button
            @click="isLastPage ? startQuiz() : nextPage()"
            class="flex-1 py-2.5 rounded-xl bg-neo-gradient text-white text-xs font-title font-bold shadow-neo-sm"
          >{{ isLastPage ? 'クイズへ →' : 'つぎ →' }}</button>
        </div>
      </div>
    </template>

    <!-- ========== READING ALOUD SECTION ========== -->
    <template v-else-if="section === 'reading' && page">
      <div
        class="flex-1 flex flex-col px-4 min-h-0"
        @touchstart="onTouchStart"
        @touchend="onTouchEnd"
      >
        <!-- Book page area -->
        <div class="flex-1 min-h-0 bg-[#1e1e40] rounded-2xl border border-white/[0.06] p-4 flex flex-col">
          <div class="flex gap-3 flex-1 min-h-0 overflow-auto reading-scroll">
            <div v-if="page.image_url" class="shrink-0 w-20 h-20 rounded-xl overflow-hidden bg-bg-card">
              <img :src="page.image_url" class="w-full h-full object-cover" />
            </div>
            <div v-else class="shrink-0 w-20 h-20 rounded-xl bg-bg-card flex items-center justify-center">
              <span class="text-2xl opacity-30">📖</span>
            </div>
            <div class="flex-1">
              <p class="text-white text-lg leading-[2] font-title font-medium">
                {{ page.body }}
              </p>
            </div>
          </div>
          <div class="shrink-0 flex justify-center gap-1 mt-2 pt-2 border-t border-white/[0.06]">
            <span
              v-for="i in totalPages"
              :key="i"
              class="w-1.5 h-1.5 rounded-full transition-colors"
              :class="i - 1 === pageIndex ? 'bg-neon-green' : 'bg-white/15'"
            />
          </div>
        </div>

        <!-- Recording controls -->
        <div class="shrink-0 pt-3 pb-2 flex flex-col items-center gap-1">
          <button
            @click="toggleRecording"
            class="w-14 h-14 rounded-full flex items-center justify-center text-white text-lg active:scale-95 transition-all"
            :class="isRecording
              ? 'bg-red-500 shadow-[0_0_20px_rgba(239,68,68,0.4)] animate-pulse'
              : 'bg-neo-gradient shadow-neo-md'"
          >{{ isRecording ? '⏹' : '🎙' }}</button>
          <p v-if="isRecording" class="text-red-400 text-xs font-title font-bold">
            録音中 {{ formatTime(recordingTime) }}
          </p>
          <p v-else-if="teacherRecordingSaved" class="text-neon-green text-xs font-title font-bold">
            お手本音声を保存しました
          </p>
          <p v-else class="text-white/25 text-[10px] font-title">
            {{ isTeacher ? 'お手本音読を録音（生徒に公開）' : 'タップして音読を録音' }}
          </p>
        </div>

        <!-- Page navigation -->
        <div class="shrink-0 flex gap-2 pb-3">
          <button
            v-if="!isFirstPage"
            @click="prevPage"
            class="flex-1 py-2.5 rounded-xl bg-bg-card border border-white/[0.06] text-white/50 text-xs font-title font-semibold"
          >← まえ</button>
          <button
            @click="isLastPage ? startQuiz() : nextPage()"
            class="flex-1 py-2.5 rounded-xl bg-neo-gradient text-white text-xs font-title font-bold shadow-neo-sm"
          >{{ isLastPage ? 'クイズへ →' : 'つぎ →' }}</button>
        </div>
      </div>
    </template>

    <!-- ========== QUIZ SECTION ========== -->
    <template v-else-if="section === 'quiz'">
      <!-- Quiz result -->
      <div v-if="quizDone" class="flex-1 flex flex-col items-center justify-center px-5 animate-pop-in">
        <p class="text-5xl mb-3">{{ correctCount >= 4 ? '🎉' : '💪' }}</p>
        <p class="text-white text-xl font-title font-bold mb-1">{{ correctCount }} / {{ store.currentQuizzes.length }} 正解</p>
        <p v-if="isTeacher" class="text-white/40 text-sm font-title mb-4">
          クイズの確認完了
        </p>
        <p v-else class="text-white/40 text-sm font-title mb-4">
          {{ correctCount >= 4 ? 'すばらしい！合格です' : 'もう一度チャレンジしよう' }}
        </p>
        <div v-if="xpEarned > 0 && !isTeacher" class="px-4 py-1.5 rounded-full bg-neo-gradient shadow-neo-md mb-6">
          <p class="text-white text-sm font-title font-bold">+{{ xpEarned }} XP</p>
        </div>
        <div class="w-full flex flex-col gap-2 px-4">
          <button
            @click="section = 'dictation'; pageIndex = 0; quizDone = false"
            class="w-full py-3 rounded-xl bg-bg-card border border-white/[0.06] text-white/60 text-sm font-title"
          >もう一度読む</button>
          <button
            @click="goBack()"
            class="w-full py-3 rounded-xl bg-neo-gradient text-white text-sm font-title font-bold shadow-neo-sm"
          >{{ isTeacher ? 'リーディング管理へ戻る' : 'ライブラリへ戻る' }}</button>
        </div>
      </div>

      <!-- Quiz questions -->
      <div v-else-if="quiz" class="flex-1 flex flex-col px-4 min-h-0">
        <!-- Progress dots -->
        <div class="shrink-0 flex gap-1.5 justify-center mb-3">
          <span
            v-for="(q, i) in store.currentQuizzes"
            :key="q.id"
            class="w-2 h-2 rounded-full"
            :class="i < quizIndex ? 'bg-brand-secondary' : i === quizIndex ? 'bg-white' : 'bg-white/15'"
          />
        </div>

        <div class="flex-1 min-h-0 overflow-auto reading-scroll">
          <component
            :is="quizComponent(quiz.format)"
            :quiz="quiz"
            :book-no="store.currentBook?.book_no ?? ''"
            :answered="answered"
            @answer="onAnswer"
          />

          <!-- Answer feedback -->
          <div v-if="answered !== null" class="mt-4 animate-slide-up">
            <div
              class="rounded-xl p-3 border"
              :class="answered === quiz.answer_index
                ? 'bg-[#00FF88]/5 border-[#00FF88]/30'
                : 'bg-[#FF6B9D]/5 border-[#FF6B9D]/30'"
            >
              <p class="text-sm font-title font-bold mb-0.5"
                :class="answered === quiz.answer_index ? 'text-[#00FF88]' : 'text-[#FF6B9D]'">
                {{ answered === quiz.answer_index ? '⭕ せいかい！' : '❌ ざんねん...' }}
              </p>
              <p class="text-white/70 text-xs font-title leading-relaxed">{{ quiz.explanation_ja }}</p>
            </div>
          </div>
        </div>

        <div v-if="answered !== null" class="shrink-0 py-3">
          <button
            @click="nextQuiz"
            class="w-full py-2.5 rounded-xl bg-neo-gradient text-white text-sm font-title font-bold shadow-neo-sm"
          >{{ quizIndex < store.currentQuizzes.length - 1 ? 'つぎの問題 →' : '結果を見る' }}</button>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.reading-scroll::-webkit-scrollbar { width: 3px; }
.reading-scroll::-webkit-scrollbar-thumb { background: rgba(255,255,255,0.1); border-radius: 3px; }
.reading-scroll::-webkit-scrollbar-track { background: transparent; }
</style>
