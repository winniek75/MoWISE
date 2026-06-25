<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useGameStore } from '@/stores/game'
import { useTeacherStore } from '@/stores/teacher'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'
import BottomNav from '@/components/common/BottomNav.vue'
import GameIcon from '@/components/game/GameIcon.vue'

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
  <div class="min-h-screen bg-bg-dark pb-28">
    <header class="neo-header">
      <div class="max-w-5xl mx-auto">
        <p class="text-brand-secondary text-[11px] font-title font-bold tracking-[0.2em] uppercase">MoWISE for Teachers</p>
        <h1 class="text-xl font-title font-bold text-white mt-0.5">ゲームライブラリ</h1>
        <p class="text-sm text-white/30 mt-1">ゲームを選んでクラスに割り当て</p>
      </div>
    </header>

    <main class="max-w-5xl mx-auto px-5 py-6">
      <div v-for="(games, category) in gameStore.gamesByCategory" :key="category" class="mb-8">
        <h2 class="neo-section-title">
          {{ gameStore.categoryLabels[category] || category }}
        </h2>
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
          <div
            v-for="game in games"
            :key="game.id"
            class="neo-card hover:shadow-neo-md transition-all duration-200"
          >
            <div class="flex items-start gap-3">
              <GameIcon :game-id="game.id" :category="game.category" />
              <div class="flex-1">
                <p class="font-title font-bold text-white text-sm">{{ game.title_ja }}</p>
                <p class="text-xs text-white/30 mt-0.5">{{ game.description_ja || '' }}</p>
                <div class="flex gap-2 mt-3">
                  <button
                    @click="openAssign(game.id)"
                    class="btn-neo !py-1.5 !px-3 !text-xs !rounded-xl"
                  >
                    クラスに割り当て
                  </button>
                  <button
                    @click="previewGame(game.url)"
                    class="btn-ghost !text-xs border border-white/10 !rounded-xl"
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
      class="neo-overlay"
      @click.self="showAssignModal = false"
    >
      <div class="neo-modal">
        <div v-if="assignSuccess" class="text-center py-6">
          <div class="w-14 h-14 rounded-full bg-correct/20 flex items-center justify-center mx-auto mb-3">
            <svg class="w-7 h-7 text-correct" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
          </div>
          <p class="font-title font-bold text-white">割り当て完了！</p>
        </div>
        <template v-else>
          <h2 class="text-lg font-title font-bold text-white mb-5">ゲームを割り当て</h2>

          <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">クラス</label>
          <select v-model="selectedClassId" class="neo-input mb-3 appearance-none">
            <option v-for="cls in teacherStore.classes" :key="cls.id" :value="cls.id">
              {{ cls.class_name }}
            </option>
          </select>

          <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">タイトル（任意）</label>
          <input
            v-model="assignTitle"
            type="text"
            placeholder="例：今週の宿題"
            class="neo-input mb-3"
          />

          <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">指示（任意）</label>
          <textarea
            v-model="assignInstructions"
            placeholder="例：Grade 3を選んで10問やってみよう"
            rows="2"
            class="neo-input mb-3 resize-none"
          />

          <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">期限（任意）</label>
          <input
            v-model="assignDueDate"
            type="datetime-local"
            class="neo-input mb-4"
          />

          <div class="flex gap-3">
            <button
              @click="showAssignModal = false"
              class="btn-ghost flex-1 py-2.5 border border-white/10 rounded-2xl"
            >キャンセル</button>
            <button
              @click="handleAssign"
              :disabled="!selectedClassId || assigning"
              class="btn-neo flex-1"
            >{{ assigning ? '割り当て中...' : '割り当てる' }}</button>
          </div>
        </template>
      </div>
    </div>

    <BottomNav />
  </div>
</template>
