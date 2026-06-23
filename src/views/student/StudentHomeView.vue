<script setup lang="ts">
import { onMounted, computed } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useStudentStore } from '@/stores/student'
import BottomNav from '@/components/common/BottomNav.vue'

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
  <div class="min-h-screen bg-bg-dark pb-24 safe-pt">
    <!-- Header -->
    <header class="px-5 pt-4 pb-3">
      <p class="text-white/40 text-xs font-title">MoWISE for Students</p>
      <div class="flex items-center justify-between mt-1">
        <h1 class="text-white text-xl font-title font-bold">{{ auth.displayName }}</h1>
        <div class="flex gap-2">
          <span class="bg-bg-card rounded-full px-3 py-1 text-white text-xs font-title">
            XP {{ auth.userRow?.total_xp ?? 0 }}
          </span>
        </div>
      </div>
    </header>

    <!-- No class state -->
    <div v-if="student.myClasses.length === 0" class="px-5 mt-8">
      <div class="bg-bg-card rounded-2xl p-6 text-center">
        <p class="text-4xl mb-3">📚</p>
        <p class="text-white font-title font-semibold">まだクラスに参加していません</p>
        <p class="text-white/50 text-sm mt-1">先生からクラスコードをもらって参加しましょう</p>
        <button
          @click="router.push({ name: 'StudentJoinClass' })"
          class="mt-4 bg-brand-primary text-white font-title font-semibold px-6 py-3 rounded-xl text-sm"
        >
          クラスに参加する
        </button>
      </div>
    </div>

    <template v-else>
      <!-- Today's Tasks -->
      <section class="px-5 mt-4">
        <h2 class="text-white/60 text-xs font-title font-semibold uppercase tracking-wider mb-3">
          今日のタスク ({{ pendingAssignments.length }})
        </h2>

        <div v-if="pendingAssignments.length === 0" class="bg-bg-card rounded-2xl p-5 text-center">
          <p class="text-3xl mb-2">🎉</p>
          <p class="text-white/60 text-sm font-title">全てのタスクを完了しました！</p>
        </div>

        <div v-else class="space-y-3">
          <div
            v-for="a in pendingAssignments"
            :key="a.id"
            class="bg-bg-card rounded-2xl p-4 active:scale-[0.98] transition-transform cursor-pointer"
            @click="router.push({ name: 'StudentGamePlay', params: { gameId: a.game_id }, query: { assignmentId: a.id, classId: a.class_id } })"
          >
            <div class="flex items-center gap-3">
              <span class="text-2xl">{{ a.game_icon || '🎮' }}</span>
              <div class="flex-1 min-w-0">
                <p class="text-white font-title font-semibold text-sm truncate">
                  {{ a.title || a.game_title_ja || a.game_id }}
                </p>
                <p class="text-white/40 text-xs font-title">{{ a.class_name }}</p>
              </div>
              <div v-if="a.due_date" class="text-right">
                <p class="text-xs font-title" :class="isOverdue(a.due_date) ? 'text-red-400' : 'text-white/40'">
                  {{ isOverdue(a.due_date) ? '期限切れ' : formatDate(a.due_date) }}
                </p>
              </div>
            </div>
            <div v-if="a.instructions" class="mt-2 text-white/50 text-xs">{{ a.instructions }}</div>
          </div>
        </div>
      </section>

      <!-- Completed -->
      <section v-if="completedAssignments.length > 0" class="px-5 mt-6">
        <h2 class="text-white/60 text-xs font-title font-semibold uppercase tracking-wider mb-3">
          完了済み ({{ completedAssignments.length }})
        </h2>
        <div class="space-y-2">
          <div
            v-for="a in completedAssignments"
            :key="a.id"
            class="bg-bg-card/50 rounded-xl p-3 flex items-center gap-3 opacity-70"
          >
            <span class="text-lg">{{ a.game_icon || '🎮' }}</span>
            <div class="flex-1 min-w-0">
              <p class="text-white/70 font-title text-sm truncate">{{ a.title || a.game_title_ja }}</p>
            </div>
            <span class="text-correct text-xs font-title font-semibold">✓ {{ a.my_best_score }}pt</span>
          </div>
        </div>
      </section>
    </template>

    <BottomNav />
  </div>
</template>
