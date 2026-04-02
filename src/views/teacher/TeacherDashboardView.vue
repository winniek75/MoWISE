<template>
  <div class="min-h-screen bg-gray-50">
    <!-- ヘッダー -->
    <header class="bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <button @click="router.push({ name: 'Home' })" class="text-gray-500 text-sm font-bold">← 戻る</button>
        <div>
          <p class="text-xs text-gray-400 font-medium tracking-widest uppercase">MoWISE</p>
          <h1 class="text-xl font-bold text-gray-900">チャートマスター ダッシュボード</h1>
        </div>
      </div>
      <button
        @click="showCreateModal = true"
        class="flex items-center gap-2 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold px-4 py-2 rounded-lg transition-colors"
      >
        <span class="text-base">＋</span> クラスを作成
      </button>
    </header>

    <!-- メインコンテンツ -->
    <main class="max-w-4xl mx-auto px-6 py-8">

      <!-- ローディング -->
      <div v-if="store.loading" class="flex justify-center py-20">
        <div class="w-8 h-8 border-4 border-indigo-500 border-t-transparent rounded-full animate-spin"></div>
      </div>

      <!-- クラスなし -->
      <div v-else-if="store.classes.length === 0" class="text-center py-20">
        <p class="text-4xl mb-4">📚</p>
        <p class="text-gray-500">まだクラスがありません。</p>
        <p class="text-gray-400 text-sm mt-1">「クラスを作成」から始めましょう。</p>
      </div>

      <!-- クラス一覧 -->
      <div v-else class="grid gap-4">
        <div
          v-for="cls in store.classes"
          :key="cls.id"
          class="bg-white rounded-xl border border-gray-200 p-5 hover:shadow-md transition-shadow cursor-pointer"
          @click="router.push(`/teacher/${cls.id}`)"
        >
          <div class="flex items-start justify-between">
            <div>
              <h2 class="text-lg font-bold text-gray-900">{{ cls.class_name }}</h2>
              <p v-if="cls.description" class="text-sm text-gray-500 mt-0.5">{{ cls.description }}</p>
            </div>
            <!-- クラスコードバッジ -->
            <div class="text-right">
              <p class="text-xs text-gray-400 mb-1">クラスコード</p>
              <span class="font-mono text-lg font-bold tracking-widest text-indigo-600 bg-indigo-50 px-3 py-1 rounded-lg">
                {{ cls.class_code }}
              </span>
            </div>
          </div>
          <div class="flex items-center gap-4 mt-4 text-sm text-gray-500">
            <span>
              ステータス：
              <span :class="cls.status === 'active' ? 'text-green-600 font-medium' : 'text-gray-400'">
                {{ cls.status === 'active' ? '🟢 アクティブ' : '🔴 アーカイブ済み' }}
              </span>
            </span>
            <span>最大 {{ cls.max_students }} 名</span>
            <span class="ml-auto text-indigo-500 font-medium">詳細を見る →</span>
          </div>
        </div>
      </div>
    </main>

    <!-- クラス作成モーダル -->
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

        <p class="text-xs text-gray-400 mt-3">
          ※ クラスコードは自動生成されます。生徒はコードを入力してクラスに参加します。
        </p>

        <div class="flex gap-3 mt-6">
          <button
            @click="showCreateModal = false"
            class="flex-1 py-2.5 text-sm text-gray-600 border border-gray-200 rounded-lg hover:bg-gray-50"
          >
            キャンセル
          </button>
          <button
            @click="handleCreate"
            :disabled="!newClassName.trim() || creating"
            class="flex-1 py-2.5 text-sm font-semibold text-white bg-indigo-600 rounded-lg hover:bg-indigo-700 disabled:opacity-40 disabled:cursor-not-allowed"
          >
            {{ creating ? '作成中...' : '作成する' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useTeacherStore } from '@/stores/teacher'

const router = useRouter()
const store  = useTeacherStore()

const showCreateModal = ref(false)
const newClassName    = ref('')
const newClassDesc    = ref('')
const creating        = ref(false)

onMounted(() => store.fetchMyClasses())

async function handleCreate() {
  if (!newClassName.value.trim()) return
  creating.value = true
  await store.createClass({
    class_name:  newClassName.value.trim(),
    description: newClassDesc.value.trim() || undefined,
  })
  creating.value    = false
  showCreateModal.value = false
  newClassName.value    = ''
  newClassDesc.value    = ''
}
</script>
