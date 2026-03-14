<template>
  <div class="min-h-screen bg-gray-50 pb-24">
    <header class="bg-white border-b border-gray-200 px-4 py-3 flex items-center justify-between">
      <div class="flex items-center gap-3">
        <button @click="router.push({ name: 'Home' })" class="text-gray-500 text-sm font-bold">← 戻る</button>
        <h1 class="text-lg font-bold text-gray-900">📖 パターン図鑑</h1>
      </div>
      <button @click="searchActive = !searchActive" class="text-gray-500 p-1">🔍</button>
    </header>

    <!-- 検索バー -->
    <div v-if="searchActive" class="px-4 py-2 bg-white border-b">
      <input v-model="searchQuery" type="text" placeholder="パターンを検索..."
        class="w-full border border-gray-300 rounded-xl px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400" />
    </div>

    <main class="px-4 py-4">
      <div v-if="store.loading" class="flex justify-center py-16">
        <div class="w-7 h-7 border-4 border-indigo-400 border-t-transparent rounded-full animate-spin"></div>
      </div>
      <template v-else>
        <template v-for="area in areas" :key="area.id">
          <!-- エリアヘッダー -->
          <div class="mb-3 mt-6 first:mt-0">
            <div class="flex items-center gap-2">
              <h2 class="text-sm font-bold text-gray-700">{{ area.label }}</h2>
              <span v-if="!area.unlocked" class="text-xs bg-gray-200 text-gray-500 px-2 py-0.5 rounded-full">
                🔒 {{ area.unlockCondition }}
              </span>
            </div>
            <p class="text-xs text-gray-400">{{ area.range }}</p>
          </div>
          <!-- 3列グリッド -->
          <div class="grid grid-cols-3 gap-2 mb-2">
            <div
              v-for="p in filteredPatterns(area)"
              :key="p.id"
              @click="goToDetail(p)"
              class="aspect-square rounded-2xl p-2 flex flex-col items-center justify-center cursor-pointer active:scale-95 transition-transform"
              :class="area.unlocked ? 'bg-white border border-gray-200 shadow-sm hover:shadow-md' : 'bg-gray-100'"
            >
              <p class="text-xs font-bold text-indigo-600 mb-1">{{ p.pattern_no }}</p>
              <p class="text-xs text-gray-700 text-center leading-tight line-clamp-2">{{ p.pattern_text }}</p>
              <div class="flex mt-1.5">
                <span v-for="n in 5" :key="n" class="text-[10px]"
                  :class="n <= (p.star_level ?? 0) ? 'text-yellow-400' : 'text-gray-200'">★</span>
              </div>
            </div>
          </div>
        </template>
      </template>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useZukanStore } from '@/stores/zukan'

const router       = useRouter()
const store        = useZukanStore()
const searchActive = ref(false)
const searchQuery  = ref('')

const areas = computed(() => [
  { id: 'area1', label: 'エリア1：はじまりの文', range: 'P001〜P020', unlocked: true, unlockCondition: '' },
  { id: 'area2', label: 'エリア2：街の市場',   range: 'P021〜P035', unlocked: store.isAreaUnlocked(2), unlockCondition: 'P020が★3以上で解禁' },
])

onMounted(() => store.fetchAll())

function filteredPatterns(area: any) {
  return store.patternsByArea(area.id).filter((p: any) =>
    !searchQuery.value ||
    p.pattern_no.includes(searchQuery.value) ||
    p.pattern_text.toLowerCase().includes(searchQuery.value.toLowerCase())
  )
}

function goToDetail(pattern: any) {
  router.push(`/zukan/${pattern.pattern_no}`)
}
</script>
