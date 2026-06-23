<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useGameStore } from '@/stores/game'
import { useTeacherStore } from '@/stores/teacher'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import BottomNav from '@/components/common/BottomNav.vue'

const router = useRouter()
const gameStore = useGameStore()
const teacherStore = useTeacherStore()
const auth = useAuthStore()

const showAssignModal = ref(false)
const selectedGame = ref<string | null>(null)
const selectedClassId = ref<string>('')
const assignTitle = ref('')
const assignInstructions = ref('')
const assignDueDate = ref('')
const assigning = ref(false)
const assignSuccess = ref(false)

onMounted(async () => {
  await Promise.all([
    gameStore.fetchCatalog(),
    teacherStore.fetchMyClasses(),
  ])
  if (teacherStore.classes.length > 0) {
    selectedClassId.value = teacherStore.classes[0].id
  }
})

function openAssign(gameId: string) {
  selectedGame.value = gameId
  const game = gameStore.getGameById(gameId)
  assignTitle.value = game?.title_ja ?? ''
  assignInstructions.value = ''
  assignDueDate.value = ''
  assignSuccess.value = false
  showAssignModal.value = true
}

async function handleAssign() {
  if (!selectedGame.value || !selectedClassId.value || !auth.userId) return
  assigning.value = true
  const { error } = await supabase
    .from('assignments')
    .insert({
      class_id: selectedClassId.value,
      teacher_id: auth.userId,
      game_id: selectedGame.value,
      title: assignTitle.value || null,
      instructions: assignInstructions.value || null,
      due_date: assignDueDate.value || null,
    })
  assigning.value = false
  if (error) {
    console.error('[assign]', error)
    return
  }
  assignSuccess.value = true
  setTimeout(() => { showAssignModal.value = false }, 1200)
}

function previewGame(url: string) {
  window.open(url, '_blank')
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 pb-24">
    <header class="bg-white border-b border-gray-200 px-6 py-4">
      <div class="max-w-5xl mx-auto">
        <p class="text-xs text-indigo-500 font-semibold tracking-widest uppercase">MoWISE for Teachers</p>
        <h1 class="text-xl font-bold text-gray-900 mt-0.5">ゲームライブラリ</h1>
        <p class="text-sm text-gray-500 mt-1">ゲームを選んでクラスに割り当て</p>
      </div>
    </header>

    <main class="max-w-5xl mx-auto px-6 py-6">
      <!-- Games by category -->
      <div v-for="(games, category) in gameStore.gamesByCategory" :key="category" class="mb-8">
        <h2 class="text-sm font-bold text-gray-700 mb-3 uppercase tracking-wider">
          {{ gameStore.categoryLabels[category] || category }}
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          <div
            v-for="game in games"
            :key="game.id"
            class="bg-white rounded-xl border border-gray-200 p-4 hover:shadow-md transition-shadow"
          >
            <div class="flex items-start gap-3">
              <span class="text-3xl">{{ game.icon }}</span>
              <div class="flex-1">
                <p class="font-bold text-gray-900 text-sm">{{ game.title_ja }}</p>
                <p class="text-xs text-gray-500 mt-0.5">{{ game.description_ja || '' }}</p>
                <div class="flex gap-2 mt-3">
                  <button
                    @click="openAssign(game.id)"
                    class="bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold px-3 py-1.5 rounded-lg transition-colors"
                  >
                    クラスに割り当て
                  </button>
                  <button
                    @click="previewGame(game.url)"
                    class="bg-gray-100 hover:bg-gray-200 text-gray-700 text-xs font-semibold px-3 py-1.5 rounded-lg transition-colors"
                  >
                    プレビュー
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Assign modal -->
    <div
      v-if="showAssignModal"
      class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
      @click.self="showAssignModal = false"
    >
      <div class="bg-white rounded-2xl shadow-xl w-full max-w-md mx-4 p-6">
        <div v-if="assignSuccess" class="text-center py-4">
          <p class="text-4xl mb-2">✅</p>
          <p class="font-bold text-gray-900">割り当て完了！</p>
        </div>
        <template v-else>
          <h2 class="text-lg font-bold text-gray-900 mb-4">ゲームを割り当て</h2>

          <label class="block text-sm font-medium text-gray-700 mb-1">クラス</label>
          <select v-model="selectedClassId" class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm mb-3">
            <option v-for="cls in teacherStore.classes" :key="cls.id" :value="cls.id">
              {{ cls.class_name }}
            </option>
          </select>

          <label class="block text-sm font-medium text-gray-700 mb-1">タイトル（任意）</label>
          <input
            v-model="assignTitle"
            type="text"
            placeholder="例：今週の宿題"
            class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm mb-3"
          />

          <label class="block text-sm font-medium text-gray-700 mb-1">指示（任意）</label>
          <textarea
            v-model="assignInstructions"
            placeholder="例：Grade 3を選んで10問やってみよう"
            rows="2"
            class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm mb-3"
          />

          <label class="block text-sm font-medium text-gray-700 mb-1">期限（任意）</label>
          <input
            v-model="assignDueDate"
            type="datetime-local"
            class="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm mb-4"
          />

          <div class="flex gap-3">
            <button
              @click="showAssignModal = false"
              class="flex-1 py-2.5 text-sm text-gray-600 border border-gray-200 rounded-lg"
            >キャンセル</button>
            <button
              @click="handleAssign"
              :disabled="!selectedClassId || assigning"
              class="flex-1 py-2.5 text-sm font-semibold text-white bg-indigo-600 rounded-lg disabled:opacity-40"
            >{{ assigning ? '割り当て中...' : '割り当てる' }}</button>
          </div>
        </template>
      </div>
    </div>

    <BottomNav />
  </div>
</template>
