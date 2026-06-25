<template>
  <div class="min-h-screen bg-bg-dark pb-28">
    <!-- Header -->
    <header class="neo-header">
      <div class="max-w-5xl mx-auto flex items-center justify-between">
        <div>
          <p class="text-brand-secondary text-[11px] font-title font-bold tracking-[0.2em] uppercase">MoWISE for Teachers</p>
          <h1 class="text-xl font-title font-bold text-white mt-0.5">ダッシュボード</h1>
        </div>
        <div class="flex items-center gap-3">
          <span class="text-sm text-white/40 font-title">{{ auth.displayName }}</span>
          <button
            @click="showCreateModal = true"
            class="btn-neo !py-2 !px-4 !text-xs"
          >
            + クラスを作成
          </button>
        </div>
      </div>
    </header>

    <main class="max-w-5xl mx-auto px-5 py-6">
      <!-- Plan banner -->
      <div v-if="subStore.currentPlan === 'free'" class="neo-card mb-6 !p-4 relative overflow-hidden">
        <div class="absolute inset-0 bg-neo-gradient opacity-[0.08]" />
        <div class="relative flex items-center justify-between">
          <div>
            <p class="text-white font-title font-bold">Free プラン</p>
            <p class="text-white/40 text-sm mt-0.5">1クラス5人まで・ゲーム3種類 → アップグレードで全機能解放</p>
          </div>
          <button
            @click="router.push({ name: 'TeacherSubscription' })"
            class="btn-outline !py-2 !px-4 !text-xs shrink-0"
          >
            アップグレード
          </button>
        </div>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-3 gap-3 mb-6">
        <div class="neo-stat">
          <p class="stat-value">{{ teacherStore.classes.length }}</p>
          <p class="stat-label">クラス数</p>
        </div>
        <div class="neo-stat">
          <p class="stat-value">{{ totalStudents }}</p>
          <p class="stat-label">総生徒数</p>
        </div>
        <div class="neo-stat">
          <p class="stat-value">{{ weeklyGames }}</p>
          <p class="stat-label">今週のゲーム数</p>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="teacherStore.loading" class="flex justify-center py-20">
        <div class="w-8 h-8 border-2 border-brand-primary border-t-transparent rounded-full animate-spin" />
      </div>

      <!-- Empty state -->
      <div v-else-if="teacherStore.classes.length === 0" class="text-center py-20">
        <div class="w-16 h-16 mowi-orb glow-low mx-auto mb-4 animate-float" />
        <p class="text-white/50 font-title">まだクラスがありません</p>
        <p class="text-white/25 text-sm mt-1 font-title">「クラスを作成」から始めましょう</p>
      </div>

      <!-- Classes list -->
      <div v-else class="space-y-3">
        <div
          v-for="cls in teacherStore.classes"
          :key="cls.id"
          class="neo-card cursor-pointer hover:shadow-neo-md active:scale-[0.99] transition-all duration-200"
          @click="router.push({ name: 'TeacherClass', params: { classId: cls.id } })"
        >
          <div class="flex items-start justify-between">
            <div>
              <h2 class="text-lg font-title font-bold text-white">{{ cls.class_name }}</h2>
              <p v-if="cls.description" class="text-sm text-white/40 mt-0.5">{{ cls.description }}</p>
            </div>
            <div class="text-right">
              <p class="text-[10px] text-white/30 mb-1 font-title">クラスコード</p>
              <span class="font-mono text-lg font-bold tracking-[0.2em] text-neo-gradient">
                {{ cls.class_code }}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-4 mt-4 text-sm">
            <span class="neo-badge" :class="cls.status === 'active' ? 'green' : ''">
              {{ cls.status === 'active' ? 'Active' : 'Archived' }}
            </span>
            <span class="ml-auto text-brand-secondary font-title font-medium text-sm">管理 →</span>
          </div>
        </div>
      </div>
    </main>

    <!-- Create class modal -->
    <div
      v-if="showCreateModal"
      class="neo-overlay"
      @click.self="showCreateModal = false"
    >
      <div class="neo-modal">
        <h2 class="text-lg font-title font-bold text-white mb-5">新しいクラスを作成</h2>
        <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">クラス名 <span class="text-neon-pink">*</span></label>
        <input
          v-model="newClassName"
          type="text"
          placeholder="例：中学2年A組"
          class="neo-input mb-4"
        />
        <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">メモ（任意）</label>
        <input
          v-model="newClassDesc"
          type="text"
          placeholder="例：2026年度 春学期"
          class="neo-input"
        />
        <p class="text-[11px] text-white/20 mt-3">クラスコードは自動生成されます</p>
        <div class="flex gap-3 mt-6">
          <button
            @click="showCreateModal = false"
            class="btn-ghost flex-1 py-2.5 border border-white/10 rounded-2xl"
          >キャンセル</button>
          <button
            @click="handleCreate"
            :disabled="!newClassName.trim() || creating"
            class="btn-neo flex-1"
          >{{ creating ? '作成中...' : '作成する' }}</button>
        </div>
      </div>
    </div>

    <BottomNav />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useTeacherStore } from '@/stores/teacher'
import { useSubscriptionStore } from '@/stores/subscription'
import BottomNav from '@/components/common/BottomNav.vue'

const router = useRouter()
const auth = useAuthStore()
const teacherStore = useTeacherStore()
const subStore = useSubscriptionStore()

const showCreateModal = ref(false)
const newClassName = ref('')
const newClassDesc = ref('')
const creating = ref(false)

const totalStudents = ref(0)
const weeklyGames = ref(0)

onMounted(async () => {
  await teacherStore.fetchMyClasses()
  if (auth.userId) {
    await subStore.fetchSubscription(auth.userId)
  }
})

async function handleCreate() {
  if (!newClassName.value.trim()) return
  creating.value = true
  await teacherStore.createClass({
    class_name: newClassName.value.trim(),
    description: newClassDesc.value.trim() || undefined,
  })
  creating.value = false
  showCreateModal.value = false
  newClassName.value = ''
  newClassDesc.value = ''
}
</script>
