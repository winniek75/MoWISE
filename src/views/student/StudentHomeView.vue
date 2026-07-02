<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useStudentStore } from '@/stores/student'
import BottomNav from '@/components/common/BottomNav.vue'
import GameIcon from '@/components/game/GameIcon.vue'

const router = useRouter()
const auth = useAuthStore()
const student = useStudentStore()

const pendingAssignments = computed(() =>
  student.myAssignments.filter(a => !a.my_completed)
)
const completedAssignments = computed(() =>
  student.myAssignments.filter(a => a.my_completed)
)

function isOverdue(dueDate?: string) {
  if (!dueDate) return false
  return new Date(dueDate) < new Date()
}

function formatDate(d?: string) {
  if (!d) return ''
  return new Date(d).toLocaleDateString('ja-JP', { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

onMounted(async () => {
  if (auth.userId) {
    await Promise.all([
      student.fetchMyAssignments(auth.userId),
      student.fetchMyClasses(auth.userId),
    ])
  }
})
</script>

<template>
  <div class="min-h-screen bg-bg-dark pb-28 safe-pt relative overflow-hidden">
    <!-- Background glow -->
    <div class="absolute top-0 right-[-20%] w-[400px] h-[400px] rounded-full bg-brand-primary/5 blur-[100px]" />

    <!-- Header -->
    <header class="px-5 pt-4 pb-3 relative z-10">
      <p class="text-brand-secondary text-[11px] font-title font-bold tracking-[0.2em] uppercase">MoWISE for Students</p>
      <div class="flex items-center justify-between mt-1">
        <h1 class="text-white text-xl font-title font-bold">{{ auth.displayName }}</h1>
        <div class="flex gap-2">
          <span class="neo-badge" style="background: rgba(250,204,21,0.15); color: #FACC15;">
            {{ auth.userRow?.coins ?? 0 }} コイン
          </span>
          <span class="neo-badge" style="background: rgba(108,92,231,0.15); color: #A78BFA;">
            {{ auth.userRow?.gacha_tickets ?? 0 }} チケット
          </span>
        </div>
      </div>
    </header>

    <!-- No class state -->
    <div v-if="student.myClasses.length === 0" class="px-5 mt-8 relative z-10">
      <div class="neo-card text-center !py-8">
        <div class="w-14 h-14 mowi-orb glow-low mx-auto mb-4 animate-float" />
        <p class="text-white font-title font-semibold">まだクラスに参加していません</p>
        <p class="text-white/30 text-sm mt-1 font-title">先生からクラスコードをもらって参加しましょう</p>
        <button
          @click="router.push({ name: 'StudentJoinClass' })"
          class="btn-neo mt-5"
        >
          クラスに参加する
        </button>
      </div>
    </div>

    <template v-else>
      <!-- Today's Tasks -->
      <section class="px-5 mt-4 relative z-10">
        <h2 class="neo-section-title">
          今日のタスク ({{ pendingAssignments.length }})
        </h2>

        <div v-if="pendingAssignments.length === 0" class="neo-card text-center !py-6">
          <p class="text-3xl mb-2">🎉</p>
          <p class="text-white/40 text-sm font-title">全てのタスクを完了しました！</p>
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="a in pendingAssignments"
            :key="a.id"
            class="neo-card active:scale-[0.98] transition-all duration-150 cursor-pointer hover:shadow-neo-md"
            @click="router.push({ name: 'StudentGamePlay', params: { gameId: a.game_id }, query: { assignmentId: a.id, classId: a.class_id } })"
          >
            <div class="flex items-center gap-3">
              <GameIcon :game-id="a.game_id" category="mixed" size="sm" />
              <div class="flex-1 min-w-0">
                <p class="text-white font-title font-semibold text-sm truncate">
                  {{ a.title || a.game_title_ja || a.game_id }}
                </p>
                <p class="text-white/25 text-xs font-title">{{ a.class_name }}</p>
              </div>
              <div v-if="a.due_date" class="text-right">
                <p class="text-xs font-title" :class="isOverdue(a.due_date) ? 'text-wrong' : 'text-white/30'">
                  {{ isOverdue(a.due_date) ? '期限切れ' : formatDate(a.due_date) }}
                </p>
              </div>
            </div>
            <div v-if="a.instructions" class="mt-2 text-white/30 text-xs">{{ a.instructions }}</div>
          </div>
        </div>
      </section>

      <!-- Completed -->
      <section v-if="completedAssignments.length > 0" class="px-5 mt-6 relative z-10">
        <h2 class="neo-section-title">
          完了済み ({{ completedAssignments.length }})
        </h2>
        <div class="space-y-2">
          <div
            v-for="a in completedAssignments"
            :key="a.id"
            class="neo-card !py-3 !px-4 flex items-center gap-3 opacity-60"
          >
            <GameIcon :game-id="a.game_id" category="mixed" size="sm" />
            <div class="flex-1 min-w-0">
              <p class="text-white/50 font-title text-sm truncate">{{ a.title || a.game_title_ja }}</p>
            </div>
            <span class="text-correct text-xs font-title font-semibold">✓ {{ a.my_best_score }}pt</span>
          </div>
        </div>
      </section>
    </template>

    <BottomNav />
  </div>
</template>
