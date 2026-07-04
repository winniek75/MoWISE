<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useReadingStore, READING_LEVELS } from '@/stores/reading'
import { useTeacherStore } from '@/stores/teacher'
import { supabase } from '@/lib/supabase'
import BottomNav from '@/components/common/BottomNav.vue'

const router = useRouter()
const readingStore = useReadingStore()
const teacherStore = useTeacherStore()

const activeTab = ref<'books' | 'assign' | 'progress' | 'recordings'>('books')
const selectedClassId = ref('')
const selectedBookId = ref('')
const assignDueDate = ref('')
const assignInstructions = ref('')
const assigning = ref(false)
const assignSuccess = ref(false)
const activeLevel = ref(0)

const classProgress = ref<any[]>([])
const classRecordings = ref<any[]>([])
const loadingData = ref(false)

function levelMeta(level: number) {
  return READING_LEVELS.find(l => l.level === level)!
}

const filteredBooks = computed(() =>
  activeLevel.value === 0
    ? readingStore.books
    : readingStore.books.filter(b => b.level === activeLevel.value),
)

function previewBook(bookId: string) {
  router.push({ name: 'ReadingBook', params: { bookId } })
}

function assignBook(bookId: string) {
  selectedBookId.value = bookId
  activeTab.value = 'assign'
}

async function handleAssign() {
  if (!selectedClassId.value || !selectedBookId.value) return
  assigning.value = true
  await readingStore.assignReading(
    selectedClassId.value, selectedBookId.value,
    assignDueDate.value || undefined, assignInstructions.value || undefined,
  )
  assigning.value = false
  assignSuccess.value = true
  setTimeout(() => { assignSuccess.value = false }, 2000)
}

async function loadClassData() {
  if (!selectedClassId.value) return
  loadingData.value = true
  try {
    const { data: members } = await supabase
      .from('class_members')
      .select('user_id')
      .eq('class_id', selectedClassId.value)
    const userIds = (members ?? []).map((m: any) => m.user_id)
    if (userIds.length === 0) { classProgress.value = []; classRecordings.value = []; return }

    const { data: progressData } = await (supabase as any)
      .from('reading_progress')
      .select('user_id, book_id, status, quiz_score, quiz_attempts, listened, updated_at, reading_books(title, level)')
      .in('user_id', userIds)
      .order('updated_at', { ascending: false })
    classProgress.value = progressData ?? []

    const { data: recordData } = await (supabase as any)
      .from('reading_recordings')
      .select('user_id, book_id, audio_path, duration_sec, created_at, reading_books(title)')
      .in('user_id', userIds)
      .order('created_at', { ascending: false })
      .limit(50)
    classRecordings.value = recordData ?? []

    const { data: users } = await supabase
      .from('users')
      .select('id, display_name')
      .in('id', userIds)
    const nameMap: Record<string, string> = {}
    for (const u of (users ?? [])) nameMap[(u as any).id] = (u as any).display_name
    classProgress.value = classProgress.value.map((p: any) => ({ ...p, student_name: nameMap[p.user_id] ?? '不明' }))
    classRecordings.value = classRecordings.value.map((r: any) => ({ ...r, student_name: nameMap[r.user_id] ?? '不明' }))
  } finally { loadingData.value = false }
}

async function playRecording(audioPath: string) {
  const { data } = await supabase.storage.from('recordings').createSignedUrl(audioPath, 300)
  if (data?.signedUrl) {
    const audio = new Audio(data.signedUrl)
    audio.play()
  }
}

onMounted(async () => {
  await Promise.all([readingStore.fetchBooks(), teacherStore.fetchMyClasses()])
  if (teacherStore.classes.length > 0) {
    selectedClassId.value = teacherStore.classes[0].id
    await loadClassData()
  }
})
</script>

<template>
  <div class="min-h-screen bg-bg-dark pb-28">
    <header class="neo-header">
      <div class="max-w-4xl mx-auto">
        <button @click="router.push({ name: 'TeacherGames' })" class="text-white/30 text-sm font-title mb-1">← ゲームライブラリ</button>
        <h1 class="text-xl font-title font-bold text-white">リーディング管理</h1>
        <p class="text-white/30 text-sm mt-0.5">本の確認・課題配信・生徒の進捗</p>
      </div>
    </header>

    <main class="max-w-4xl mx-auto px-5 py-5">
      <!-- Tabs -->
      <div class="flex gap-1 mb-4 overflow-x-auto no-scrollbar">
        <button
          v-for="tab in [
            { id: 'books', label: '📚 本の一覧' },
            { id: 'assign', label: '📋 課題配信' },
            { id: 'progress', label: '📊 生徒進捗' },
            { id: 'recordings', label: '🎙 音読録音' },
          ] as const"
          :key="tab.id"
          @click="activeTab = tab.id"
          class="shrink-0 flex-1 py-2 rounded-xl text-[11px] font-title font-semibold transition-all"
          :class="activeTab === tab.id
            ? 'bg-neo-gradient text-white shadow-neo-sm'
            : 'bg-bg-card text-white/30 border border-white/[0.06]'"
        >{{ tab.label }}</button>
      </div>

      <!-- ===== BOOKS TAB ===== -->
      <div v-if="activeTab === 'books'">
        <!-- Level filter -->
        <div class="mb-4 flex gap-1.5 overflow-x-auto no-scrollbar">
          <button
            @click="activeLevel = 0"
            class="shrink-0 px-3 py-1.5 rounded-full text-[11px] font-title font-semibold transition-all"
            :class="activeLevel === 0
              ? 'bg-neo-gradient text-white shadow-neo-sm'
              : 'bg-bg-card text-white/30 border border-white/[0.06]'"
          >全て ({{ readingStore.books.length }})</button>
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

        <div v-if="readingStore.loading" class="text-center py-8 text-white/30 text-sm font-title">読み込み中...</div>
        <div v-else-if="filteredBooks.length === 0" class="text-center py-8 text-white/30 text-sm font-title">
          このレベルの本はまだありません
        </div>
        <div v-else class="space-y-3">
          <div
            v-for="book in filteredBooks"
            :key="book.id"
            class="neo-card"
          >
            <div class="flex items-start gap-3">
              <!-- Cover thumbnail -->
              <div class="shrink-0 w-16 h-16 rounded-xl overflow-hidden bg-neo-card flex items-center justify-center">
                <img v-if="book.cover_url" :src="book.cover_url" class="w-full h-full object-cover" />
                <span v-else class="text-2xl">📖</span>
              </div>

              <!-- Book info -->
              <div class="flex-1 min-w-0">
                <div class="flex items-center gap-2 mb-0.5">
                  <span
                    class="px-1.5 py-0.5 rounded-full text-[9px] font-title font-bold text-black/80"
                    :style="{ backgroundColor: levelMeta(book.level).color }"
                  >{{ levelMeta(book.level).name }}</span>
                  <span class="text-white/20 text-[9px] font-title">{{ levelMeta(book.level).ja }}</span>
                </div>
                <p class="text-white text-sm font-title font-bold leading-snug">{{ book.title }}</p>
                <p class="text-white/40 text-[10px] font-title mt-0.5">
                  {{ book.title_ja }} &middot; {{ book.word_count }} words &middot; {{ book.genre }}
                </p>
              </div>
            </div>

            <!-- Action buttons -->
            <div class="flex gap-2 mt-3">
              <button
                @click="previewBook(book.id)"
                class="flex-1 py-2 rounded-xl bg-neo-gradient text-white text-xs font-title font-bold shadow-neo-sm active:scale-[0.98] transition-transform"
              >中身を見る ▶</button>
              <button
                @click="assignBook(book.id)"
                class="flex-1 py-2 rounded-xl bg-bg-card border border-white/[0.06] text-white/60 text-xs font-title font-semibold active:scale-[0.98] transition-transform"
              >課題に配信</button>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== ASSIGN TAB ===== -->
      <div v-if="activeTab === 'assign'" class="space-y-4">
        <!-- Class selector -->
        <div>
          <label class="block text-white/40 text-[10px] font-title font-bold uppercase tracking-wider mb-1">クラス選択</label>
          <select v-model="selectedClassId" @change="loadClassData" class="neo-input w-full appearance-none">
            <option v-for="cls in teacherStore.classes" :key="cls.id" :value="cls.id">{{ cls.class_name }}</option>
          </select>
        </div>

        <div v-if="assignSuccess" class="neo-card text-center py-6">
          <p class="text-neon-green text-lg font-title font-bold">課題を配信しました</p>
        </div>
        <template v-else>
          <div>
            <label class="block text-white/40 text-[10px] font-title font-bold uppercase tracking-wider mb-1">本を選択</label>
            <select v-model="selectedBookId" class="neo-input w-full appearance-none">
              <option value="">-- 選択してください --</option>
              <option v-for="book in readingStore.books" :key="book.id" :value="book.id">
                [{{ book.level_code }}] {{ book.title }} ({{ book.word_count }} words)
              </option>
            </select>
          </div>

          <!-- Selected book preview -->
          <div v-if="selectedBookId" class="neo-card !p-3">
            <div class="flex items-center gap-3">
              <span class="text-2xl">📖</span>
              <div class="flex-1">
                <p class="text-white text-sm font-title font-semibold">
                  {{ readingStore.books.find(b => b.id === selectedBookId)?.title }}
                </p>
                <p class="text-white/40 text-[10px] font-title">
                  {{ readingStore.books.find(b => b.id === selectedBookId)?.word_count }} words
                </p>
              </div>
              <button
                @click="previewBook(selectedBookId)"
                class="px-3 py-1.5 rounded-lg bg-brand-secondary/20 text-brand-secondary text-[10px] font-title font-bold"
              >プレビュー</button>
            </div>
          </div>

          <div>
            <label class="block text-white/40 text-[10px] font-title font-bold uppercase tracking-wider mb-1">指示（任意）</label>
            <textarea v-model="assignInstructions" rows="2" placeholder="例: ディクテーションをして、音読も録音してね" class="neo-input w-full resize-none" />
          </div>
          <div>
            <label class="block text-white/40 text-[10px] font-title font-bold uppercase tracking-wider mb-1">期限（任意）</label>
            <input v-model="assignDueDate" type="date" class="neo-input w-full" />
          </div>
          <button
            @click="handleAssign"
            :disabled="!selectedBookId || !selectedClassId || assigning"
            class="btn-neo w-full"
          >{{ assigning ? '配信中...' : 'この本を課題に配信する' }}</button>
        </template>
      </div>

      <!-- ===== PROGRESS TAB ===== -->
      <div v-if="activeTab === 'progress'">
        <div class="mb-4">
          <label class="block text-white/40 text-[10px] font-title font-bold uppercase tracking-wider mb-1">クラス選択</label>
          <select v-model="selectedClassId" @change="loadClassData" class="neo-input w-full appearance-none">
            <option v-for="cls in teacherStore.classes" :key="cls.id" :value="cls.id">{{ cls.class_name }}</option>
          </select>
        </div>
        <div v-if="loadingData" class="text-center py-8 text-white/30 text-sm font-title">読み込み中...</div>
        <div v-else-if="classProgress.length === 0" class="text-center py-8 text-white/30 text-sm font-title">
          生徒のリーディング記録がまだありません
        </div>
        <div v-else class="space-y-2">
          <div
            v-for="p in classProgress"
            :key="`${p.user_id}-${p.book_id}`"
            class="neo-card flex items-center gap-3"
          >
            <div class="w-8 h-8 rounded-full bg-neo-gradient flex items-center justify-center text-white text-xs font-bold">
              {{ (p.student_name ?? '?')[0] }}
            </div>
            <div class="flex-1 min-w-0">
              <p class="text-white text-sm font-title font-semibold truncate">{{ p.student_name }}</p>
              <p class="text-white/40 text-[10px] font-title truncate">{{ p.reading_books?.title ?? '' }}</p>
            </div>
            <div class="text-right">
              <span
                class="px-2 py-0.5 rounded-full text-[10px] font-title font-bold"
                :class="{
                  'bg-neon-green/20 text-neon-green': p.status === 'quiz_done',
                  'bg-neon-cyan/20 text-neon-cyan': p.status === 'read',
                  'bg-white/10 text-white/40': p.status === 'reading',
                }"
              >
                {{ p.status === 'quiz_done' ? `★${p.quiz_score}/5` : p.status === 'read' ? '読了' : '読書中' }}
              </span>
              <p class="text-white/20 text-[9px] font-title mt-0.5">{{ new Date(p.updated_at).toLocaleDateString('ja') }}</p>
            </div>
          </div>
        </div>
      </div>

      <!-- ===== RECORDINGS TAB ===== -->
      <div v-if="activeTab === 'recordings'">
        <div class="mb-4">
          <label class="block text-white/40 text-[10px] font-title font-bold uppercase tracking-wider mb-1">クラス選択</label>
          <select v-model="selectedClassId" @change="loadClassData" class="neo-input w-full appearance-none">
            <option v-for="cls in teacherStore.classes" :key="cls.id" :value="cls.id">{{ cls.class_name }}</option>
          </select>
        </div>
        <div v-if="loadingData" class="text-center py-8 text-white/30 text-sm font-title">読み込み中...</div>
        <div v-else-if="classRecordings.length === 0" class="text-center py-8 text-white/30 text-sm font-title">
          音読録音がまだありません
        </div>
        <div v-else class="space-y-2">
          <div
            v-for="r in classRecordings"
            :key="r.id || r.audio_path"
            class="neo-card flex items-center gap-3"
          >
            <button
              @click="playRecording(r.audio_path)"
              class="w-10 h-10 rounded-full bg-neo-gradient flex items-center justify-center text-white active:scale-95 transition-transform"
            >▶</button>
            <div class="flex-1 min-w-0">
              <p class="text-white text-sm font-title font-semibold truncate">{{ r.student_name }}</p>
              <p class="text-white/40 text-[10px] font-title truncate">{{ r.reading_books?.title ?? '' }}</p>
            </div>
            <div class="text-right">
              <p class="text-white/60 text-xs font-title">{{ Math.floor((r.duration_sec ?? 0) / 60) }}:{{ String((r.duration_sec ?? 0) % 60).padStart(2, '0') }}</p>
              <p class="text-white/20 text-[9px] font-title">{{ new Date(r.created_at).toLocaleDateString('ja') }}</p>
            </div>
          </div>
        </div>
      </div>
    </main>

    <BottomNav />
  </div>
</template>

<style scoped>
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
