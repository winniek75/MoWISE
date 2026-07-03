// ============================================================
// stores/reading.ts - MoWISE Reading (level-based extensive reading)
// ============================================================
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const sb = supabase as any

export const READING_STORAGE_BASE = `${import.meta.env.VITE_SUPABASE_URL}/storage/v1/object/public/reading`

export const READING_LEVELS = [
  { level: 1, code: 'seed',   name: 'Seed',   ja: '英検5級',   color: '#00FF88' },
  { level: 2, code: 'sprout', name: 'Sprout', ja: '英検4級',   color: '#00CECE' },
  { level: 3, code: 'leaf',   name: 'Leaf',   ja: '英検3級',   color: '#00BFFF' },
  { level: 4, code: 'branch', name: 'Branch', ja: '英検準2級', color: '#A78BFA' },
  { level: 5, code: 'tree',   name: 'Tree',   ja: '英検2級',   color: '#FF6B9D' },
  { level: 6, code: 'summit', name: 'Summit', ja: 'TOEIC 850', color: '#FFD700' },
] as const

export interface ReadingBook {
  id: string; book_no: string; level: number; level_code: string
  title: string; title_ja: string; genre: string; word_count: number
  cover_url: string | null; is_free: boolean; sort_order: number
}
export interface ReadingPage {
  id: string; page_no: number; body: string; image_url: string | null; audio_url: string | null
}
export interface ReadingQuiz {
  id: string; question_no: number
  format: 'match_picture' | 'true_false' | 'vocab_mc' | 'cloze_mc' | 'comprehension_mc'
  question: string; choices: string[]; answer_index: number; explanation_ja: string
}
export interface ReadingProgress {
  book_id: string; status: 'reading' | 'read' | 'quiz_done'
  quiz_score: number | null; quiz_attempts: number; listened: boolean
}
export interface WeeklyStats {
  week_label: string; books_read: number; pages_read: number; quiz_score_avg: number | null; recordings: number
}
export interface ReadingAssignment {
  id: string; class_id: string; book_id: string; teacher_id: string
  due_date: string | null; instructions: string | null
  created_at: string; book?: ReadingBook
}

export const XP_READ = 10
export const XP_LISTEN = 5
export const XP_QUIZ_PASS = 20
export const XP_RECORDING = 5

export const useReadingStore = defineStore('reading', () => {
  const books = ref<ReadingBook[]>([])
  const progress = ref<Record<string, ReadingProgress>>({})
  const loading = ref(false)
  const currentBook = ref<ReadingBook | null>(null)
  const currentPages = ref<ReadingPage[]>([])
  const currentQuizzes = ref<ReadingQuiz[]>([])
  const weeklyStats = ref<WeeklyStats[]>([])
  const assignments = ref<ReadingAssignment[]>([])

  // === Teacher data ===
  const studentProgress = ref<any[]>([])
  const studentRecordings = ref<any[]>([])

  const booksByLevel = computed(() => {
    const map: Record<number, ReadingBook[]> = {}
    for (const b of books.value) {
      if (!map[b.level]) map[b.level] = []
      map[b.level].push(b)
    }
    return map
  })

  const stats = computed(() => {
    const entries = Object.values(progress.value)
    const done = entries.filter(p => p.status === 'quiz_done')
    const scores = done.map(p => p.quiz_score ?? 0)
    return {
      booksRead: entries.filter(p => p.status !== 'reading').length,
      quizDone: done.length,
      avgScore: scores.length ? Math.round((scores.reduce((a, c) => a + c, 0) / scores.length) * 10) / 10 : null,
    }
  })

  // === Fetch functions ===
  async function fetchBooks() {
    loading.value = true
    try {
      const { data, error } = await supabase.from('reading_books').select('*').order('level').order('sort_order')
      if (error) throw error
      books.value = (data ?? []) as ReadingBook[]
      await fetchProgress()
    } catch (e) { console.error('[reading] fetchBooks', e) }
    finally { loading.value = false }
  }

  async function fetchProgress() {
    const auth = useAuthStore()
    if (!auth.user?.id) return
    const { data } = await supabase.from('reading_progress')
      .select('book_id, status, quiz_score, quiz_attempts, listened')
      .eq('user_id', auth.user.id)
    progress.value = {}
    for (const p of (data ?? []) as ReadingProgress[]) progress.value[p.book_id] = p
  }

  async function fetchBook(bookId: string) {
    loading.value = true
    try {
      const [bookRes, pageRes, quizRes] = await Promise.all([
        sb.from('reading_books').select('*').eq('id', bookId).single(),
        sb.from('reading_pages').select('id, page_no, body, image_url, audio_url').eq('book_id', bookId).order('page_no'),
        sb.from('reading_quizzes').select('id, question_no, format, question, choices, answer_index, explanation_ja').eq('book_id', bookId).order('question_no'),
      ])
      currentBook.value = (bookRes.data ?? null) as ReadingBook | null
      currentPages.value = (pageRes.data ?? []) as ReadingPage[]
      currentQuizzes.value = ((quizRes.data ?? []) as ReadingQuiz[]).map(q => ({
        ...q,
        choices: Array.isArray(q.choices) ? q.choices : JSON.parse(q.choices as unknown as string),
      }))
    } finally { loading.value = false }
  }

  async function addXp(amount: number) {
    try { await sb.rpc('reading_add_xp', { amount }) } catch (e) { console.error('[reading] addXp', e) }
  }

  async function markRead(bookId: string) {
    const auth = useAuthStore()
    if (!auth.user?.id) return
    const prev = progress.value[bookId]
    if (prev && prev.status !== 'reading') return
    await sb.from('reading_progress').upsert(
      { user_id: auth.user.id, book_id: bookId, status: 'read', updated_at: new Date().toISOString() },
      { onConflict: 'user_id,book_id' },
    )
    await addXp(XP_READ)
    await fetchProgress()
  }

  async function markListened(bookId: string) {
    const auth = useAuthStore()
    if (!auth.user?.id) return
    const prev = progress.value[bookId]
    if (prev?.listened) return
    await sb.from('reading_progress').upsert(
      { user_id: auth.user.id, book_id: bookId, listened: true, updated_at: new Date().toISOString() },
      { onConflict: 'user_id,book_id' },
    )
    await addXp(XP_LISTEN)
    await fetchProgress()
  }

  async function submitQuiz(bookId: string, score: number): Promise<boolean> {
    const auth = useAuthStore()
    if (!auth.user?.id) return false
    const prev = progress.value[bookId]
    const firstPass = score >= 4 && (!prev || prev.status !== 'quiz_done' || (prev.quiz_score ?? 0) < 4)
    await sb.from('reading_progress').upsert(
      {
        user_id: auth.user.id, book_id: bookId, status: 'quiz_done',
        quiz_score: Math.max(score, prev?.quiz_score ?? 0),
        quiz_attempts: (prev?.quiz_attempts ?? 0) + 1,
        completed_at: new Date().toISOString(), updated_at: new Date().toISOString(),
      },
      { onConflict: 'user_id,book_id' },
    )
    if (firstPass) await addXp(XP_QUIZ_PASS)
    await fetchProgress()
    return firstPass
  }

  // === Recording ===
  async function saveRecording(bookId: string, blob: Blob, durationSec: number) {
    const auth = useAuthStore()
    if (!auth.user?.id) return
    const path = `${auth.user.id}/${bookId}_${Date.now()}.webm`
    const { error: uploadErr } = await supabase.storage.from('recordings').upload(path, blob)
    if (uploadErr) { console.error('[recording] upload', uploadErr); return }
    await sb.from('reading_recordings').insert({
      user_id: auth.user.id, book_id: bookId, audio_path: path, duration_sec: durationSec,
    })
    await addXp(XP_RECORDING)
  }

  // === Weekly stats ===
  async function fetchWeeklyStats() {
    const auth = useAuthStore()
    if (!auth.user?.id) return
    const fourWeeksAgo = new Date(Date.now() - 28 * 86400000).toISOString()
    const { data: progressData } = await sb.from('reading_progress')
      .select('book_id, status, quiz_score, updated_at')
      .eq('user_id', auth.user.id)
      .gte('updated_at', fourWeeksAgo)
    const { data: recordingData } = await sb.from('reading_recordings')
      .select('id, created_at')
      .eq('user_id', auth.user.id)
      .gte('created_at', fourWeeksAgo)

    const weeks: Record<string, WeeklyStats> = {}
    const getWeek = (d: string) => {
      const dt = new Date(d)
      const start = new Date(dt)
      start.setDate(dt.getDate() - dt.getDay())
      return `${start.getMonth() + 1}/${start.getDate()}`
    }
    for (const p of (progressData ?? [])) {
      const w = getWeek(p.updated_at)
      if (!weeks[w]) weeks[w] = { week_label: w, books_read: 0, pages_read: 0, quiz_score_avg: null, recordings: 0 }
      if (p.status !== 'reading') weeks[w].books_read++
    }
    for (const r of (recordingData ?? [])) {
      const w = getWeek(r.created_at)
      if (!weeks[w]) weeks[w] = { week_label: w, books_read: 0, pages_read: 0, quiz_score_avg: null, recordings: 0 }
      weeks[w].recordings++
    }
    weeklyStats.value = Object.values(weeks).sort((a, b) => a.week_label.localeCompare(b.week_label))
  }

  // === Assignments (student view) ===
  async function fetchMyAssignments() {
    const auth = useAuthStore()
    if (!auth.user?.id) return
    const { data } = await sb.from('reading_assignments')
      .select('*, reading_books(*)')
      .order('created_at', { ascending: false })
    assignments.value = (data ?? []).map((a: any) => ({ ...a, book: a.reading_books }))
  }

  // === Teacher functions ===
  async function assignReading(classId: string, bookId: string, dueDate?: string, instructions?: string) {
    const auth = useAuthStore()
    if (!auth.user?.id) return
    await sb.from('reading_assignments').insert({
      class_id: classId, book_id: bookId, teacher_id: auth.user.id,
      due_date: dueDate || null, instructions: instructions || null,
    })
  }

  async function fetchStudentReadingProgress(classId: string) {
    const { data } = await sb.rpc('get_class_reading_progress', { p_class_id: classId })
    studentProgress.value = data ?? []
  }

  async function fetchStudentRecordings(classId: string) {
    const { data } = await sb.rpc('get_class_reading_recordings', { p_class_id: classId })
    studentRecordings.value = data ?? []
  }

  return {
    books, progress, loading, currentBook, currentPages, currentQuizzes,
    booksByLevel, stats, weeklyStats, assignments,
    studentProgress, studentRecordings,
    fetchBooks, fetchBook, markRead, markListened, submitQuiz,
    saveRecording, fetchWeeklyStats, fetchMyAssignments,
    assignReading, fetchStudentReadingProgress, fetchStudentRecordings,
  }
})
