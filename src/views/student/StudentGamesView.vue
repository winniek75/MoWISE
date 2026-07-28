<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useGameStore } from '@/stores/game'
import { useSubscriptionStore } from '@/stores/subscription'
import BottomNav from '@/components/common/BottomNav.vue'
import GameIcon from '@/components/game/GameIcon.vue'

const router = useRouter()
const gameStore = useGameStore()
const subStore = useSubscriptionStore()

const activeCategory = ref('all')

const categories = [
  { id: 'all', label: '全て' },
  { id: 'eiken', label: '英検対策' },
  { id: 'grammar', label: '文法' },
  { id: 'phonics', label: 'フォニックス' },
  { id: 'writing', label: 'ライティング' },
  { id: 'mixed', label: 'ミックス' },
]

const filteredGames = () => {
  if (activeCategory.value === 'all') return gameStore.catalog
  return gameStore.catalog.filter(g => g.category === activeCategory.value)
}

function playGame(gameId: string) {
  router.push({ name: 'StudentGamePlay', params: { gameId } })
}

onMounted(() => {
  gameStore.fetchCatalog()
})
</script>

<template>
  <div class="min-h-screen bg-bg-dark pb-28 safe-pt">
    <header class="px-5 pt-4 pb-3">
      <h1 class="text-white text-xl font-title font-bold">ゲームライブラリ</h1>
      <p class="text-white/25 text-xs font-title mt-0.5">{{ gameStore.catalog.length }} ゲーム</p>
    </header>

    <!-- リーディング入口（レベル別多読） -->
    <div class="px-5 mb-4">
      <button
        @click="router.push({ name: 'ReadingLibrary' })"
        class="w-full text-left bg-neo-card border border-white/[0.06] rounded-3xl p-4 flex items-center gap-4 active:scale-[0.98] transition-transform"
      >
        <span class="text-3xl">📖</span>
        <div class="flex-1">
          <p class="text-white text-sm font-title font-bold">リーディング</p>
          <p class="text-white/30 text-[11px] font-title">レベル別に読む・聴く・クイズ（英検・TOEIC形式）</p>
        </div>
        <span class="text-white/30 text-sm">→</span>
      </button>
    </div>

    <!-- Category filter -->
    <div class="px-5 mb-4 flex gap-2 overflow-x-auto no-scrollbar">
      <button
        v-for="cat in categories"
        :key="cat.id"
        @click="activeCategory = cat.id"
        class="shrink-0 px-4 py-1.5 rounded-full text-xs font-title font-semibold transition-all duration-200"
        :class="activeCategory === cat.id
          ? 'bg-neo-gradient text-white shadow-neo-sm'
          : 'bg-bg-card text-white/30 border border-white/[0.06] hover:text-white/50'"
      >
        {{ cat.label }}
      </button>
    </div>

    <!-- Games grid -->
    <div class="px-5 grid grid-cols-2 gap-3">
      <div
        v-for="game in filteredGames()"
        :key="game.id"
        class="neo-card cursor-pointer active:scale-[0.97] transition-all duration-150 hover:shadow-neo-md animate-pop-in"
        @click="playGame(game.id)"
      >
        <GameIcon :game-id="game.id" :category="game.category" class="mb-3" />
        <p class="text-white font-title font-semibold text-sm leading-tight">{{ game.title_ja }}</p>
        <p v-if="game.description_ja" class="text-white/30 text-[10px] font-title mt-1 line-clamp-2">{{ game.description_ja }}</p>
        <p class="text-white/15 text-[9px] font-title mt-1">{{ gameStore.categoryLabels[game.category] }}</p>
        <div v-if="!game.is_free && subStore.currentPlan === 'free'" class="mt-2">
          <span class="neo-badge orange !text-[9px]">PRO</span>
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
