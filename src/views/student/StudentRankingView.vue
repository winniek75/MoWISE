<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useStudentStore } from '@/stores/student'
import BottomNav from '@/components/common/BottomNav.vue'

const auth = useAuthStore()
const student = useStudentStore()

const selectedClassId = ref<string | null>(null)

const classes = computed(() => student.myClasses.map(m => ({
  id: (m as any).classes?.id ?? m.class_id,
  name: (m as any).classes?.class_name ?? 'Class',
})))

onMounted(async () => {
  if (auth.userId) {
    await student.fetchMyClasses(auth.userId)
    if (classes.value.length > 0) {
      selectedClassId.value = classes.value[0].id
      await student.fetchClassLeaderboard(classes.value[0].id)
    }
  }
})

async function selectClass(classId: string) {
  selectedClassId.value = classId
  await student.fetchClassLeaderboard(classId)
}

function isMe(userId: string) {
  return userId === auth.userId
}

const rankIcons = ['🥇', '🥈', '🥉']
</script>

<template>
  <div class="min-h-screen bg-bg-dark pb-28 safe-pt">
    <header class="px-5 pt-4 pb-3">
      <h1 class="text-white text-xl font-title font-bold">ランキング</h1>
    </header>

    <!-- Class selector -->
    <div v-if="classes.length > 1" class="px-5 mb-4 flex gap-2 overflow-x-auto no-scrollbar">
      <button
        v-for="cls in classes"
        :key="cls.id"
        @click="selectClass(cls.id)"
        class="shrink-0 px-4 py-1.5 rounded-full text-xs font-title font-semibold transition-all duration-200"
        :class="selectedClassId === cls.id
          ? 'bg-neo-gradient text-white shadow-neo-sm'
          : 'bg-bg-card text-white/30 border border-white/[0.06]'"
      >
        {{ cls.name }}
      </button>
    </div>

    <!-- No data -->
    <div v-if="student.leaderboard.length === 0" class="px-5 mt-12 text-center">
      <div class="w-14 h-14 mowi-orb glow-low mx-auto mb-4 animate-float" />
      <p class="text-white/40 font-title text-sm">まだランキングデータがありません</p>
      <p class="text-white/20 font-title text-xs mt-1">ゲームをプレイしてランキングに参加しましょう</p>
    </div>

    <!-- Leaderboard -->
    <div v-else class="px-5 space-y-2">
      <div
        v-for="entry in student.leaderboard"
        :key="entry.user_id"
        class="neo-card !py-3 !px-4 flex items-center gap-3 transition-all duration-200"
        :class="isMe(entry.user_id) ? '!border-brand-secondary/30 shadow-neo-cyan' : ''"
      >
        <!-- Rank -->
        <div class="w-8 text-center shrink-0">
          <span v-if="(entry.rank ?? 0) <= 3" class="text-xl">{{ rankIcons[(entry.rank ?? 1) - 1] }}</span>
          <span v-else class="text-white/30 font-title font-bold text-sm">{{ entry.rank }}</span>
        </div>

        <!-- Name -->
        <div class="flex-1 min-w-0">
          <p class="text-white font-title font-semibold text-sm truncate">
            {{ entry.display_name }}
            <span v-if="isMe(entry.user_id)" class="text-brand-secondary text-xs ml-1">(あなた)</span>
          </p>
          <p class="text-white/25 text-[10px] font-title">
            {{ entry.games_played }} ゲーム・正答率 {{ Math.round(entry.avg_accuracy ?? 0) }}%
          </p>
        </div>

        <!-- XP -->
        <div class="text-right shrink-0">
          <p class="text-brand-secondary font-title font-bold text-sm">{{ entry.total_xp }} XP</p>
          <p class="text-white/20 text-[10px] font-title">{{ entry.total_score }} pt</p>
        </div>
      </div>
    </div>

    <BottomNav />
  </div>
</template>

<style scoped>
.no-scrollbar::-webkit-scrollbar { display: none; }
.no-scrollbar { -ms-overflow-style: none; scrollbar-width: none; }
</style>
