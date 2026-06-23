<template>
  <div class="min-h-screen bg-gray-50 pb-24">
    <!-- Header -->
    <header class="bg-white border-b border-gray-200 px-6 py-4">
      <div class="max-w-5xl mx-auto flex items-center justify-between">
        <div>
          <p class="text-xs text-indigo-500 font-semibold tracking-widest uppercase">MoWISE for Teachers</p>
          <h1 class="text-xl font-bold text-gray-900 mt-0.5">ダッシュボード</h1>
        </div>
        <div class="flex items-center gap-3">
          <span class="text-sm text-gray-500">{{ auth.displayName }}</span>
          <button
            @click="showCreateModal = true"
            class="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold px-4 py-2 rounded-lg transition-colors"
          >
            + クラスを作成
          </button>
        </div>
      </div>
    </header>

    <main class="max-w-5xl mx-auto px-6 py-6">
      <!-- Plan banner -->
      <div v-if="subStore.currentPlan === 'free'" class="bg-gradient-to-r from-indigo-500 to-purple-500 rounded-xl p-4 mb-6 flex items-center justify-between">
        <div>
          <p class="text-white font-semibold">Free プラン</p>
          <p class="text-white/70 text-sm">1クラス5人まで・ゲーム3種類 →アップグレードで全機能解放</p>
        </div>
        <button
          @click="router.push({ name: 'TeacherSubscription' })"
          class="bg-white text-indigo-600 font-semibold px-4 py-2 rounded-lg text-sm hover:bg-gray-100"
        >
          アップグレード
        </button>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-3 gap-4 mb-6">
        <div class="bg-white rounded-xl border border-gray-200 p-4">
          <p class="text-sm text-gray-500">クラス数</p>
          <p class="text-2xl font-bold text-gray-900">{{ teacherStore.classes.length }}</p>
        </div>
        <div class="bg-white rounded-xl border border-gray-200 p-4">
          <p class="text-sm text-gray-500">総生徒数</p>
          <p class="text-2xl font-bold text-gray-900">{{ totalStudents }}</p>
        </div>
        <div class="bg-white rounded-xl border border-gray-200 p-4">
          <p class="text-sm text-gray-500">今週のゲーム数</p>
          <p class="text-2xl font-bold text-gray-900">{{ weeklyGames }}</p>
        </div>
      </div>

      <!-- Loading -->
      <div v-if="teacherStore.loading" class="flex justify-center py-20">
        <div class="w-8 h-8 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
      </div>

      <!-- Classes list -->
      <div v-else-if="teacherStore.classes.length === 0" class="text-center py-20">
        <p class="text-4xl mb-4">📚</p>
        <p class="text-gray-500">まだクラスがありません</p>
        <p class="text-gray-400 text-sm mt-1">「クラスを作成」から始めましょう</p>
      </div>

      <div v-else class="space-y-4">
        <div
          v-for="cls in teacherStore.classes"
          :key="cls.id"
          class="bg-white rounded-xl border border-gray-200 p-5 hover:shadow-md transition-shadow cursor-pointer"
          @click="router.push({ name: 'TeacherClass', params: { classId: cls.id } })"
        >
          <div class="flex items-start justify-between">
            <div>
              <h2 class="text-lg font-bold text-gray-900">{{ cls.class_name }}</h2>
              <p v-if="cls.description" class="text-sm text-gray-500 mt-0.5">{{ cls.description }}</p>
            </div>
            <div class="text-right">
              <p class="text-xs text-gray-400 mb-1">クラスコード</p>
              <span class="font-mono text-lg font-bold tracking-widest text-indigo-600 bg-indigo-50 px-3 py-1 rounded-lg">
                {{ cls.class_code }}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-4 mt-4 text-sm text-gray-500">
            <span :class="cls.status === 'active' ? 'text-green-600' : 'text-gray-400'">
              {{ cls.status === 'active' ? 'Active' : 'Archived' }}
            </span>
            <span class="ml-auto text-indigo-500 font-medium">管理 →</span>
          </div>
        </div>
      </div>
    </main>

    <!-- Create class modal -->
    <div
      v-if="showCreateModal"
      class="fixed inset-0 bg-black/40 flex items-center justify-center z-50"
      @click.self="showCreateModal = false"
    >
      <div class="bg-white rounded-2xl shadow-xl w-full max-w-md mx-4 p-6">
        <h2 class="text-lg font-bold text-gray-900 mb-4">新しいクラスを作成</h2>
        <label class="block text-sm font-medium text-gray-700 mb-1">クラス名 <span class="text-red-500">*</span></label>
        <input
          v-model="newClassName"
          type="text"
          placeholder="例：中学2年A組"
          class="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
        />
        <label class="block text-sm font-medium text-gray-700 mt-4 mb-1">メモ（任意）</label>
        <input
          v-model="newClassDesc"
          type="text"
          placeholder="例：2026年度 春学期"
          class="w-full border border-gray-300 rounded-lg px-4 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400"
        />
        <p class="text-xs text-gray-400 mt-3">クラスコードは自動生成されます</p>
        <div class="flex gap-3 mt-6">
          <button
            @click="showCreateModal = false"
            class="flex-1 py-2.5 text-sm text-gray-600 border border-gray-200 rounded-lg hover:bg-gray-50"
          >キャンセル</button>
          <button
            @click="handleCreate"
            :disabled="!newClassName.trim() || creating"
            class="flex-1 py-2.5 text-sm font-semibold text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 disabled:opacity-40"
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
