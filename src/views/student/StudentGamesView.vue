<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useGameStore } from '@/stores/game'
import { useSubscriptionStore } from '@/stores/subscription'
import BottomNav from '@/components/common/BottomNav.vue'

const router = useRouter()
const gameStore = useGameStore()
const subStore = useSubscriptionStore()

const activeCategory = ref('all')

const categories = [
  { id: 'all', label: '全て' },
  { id: 'vocabulary', label: '語彙' },
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
  <div class="min-h-screen bg-bg-dark pb-24 safe-pt">
    <header class="px-5 pt-4 pb-3">
      <h1 class="text-white text-xl font-title font-bold">ゲームライブラリ</h1>
      <p class="text-white/40 text-xs font-title mt-0.5">{{ gameStore.catalog.length }} ゲーム</p>
    </header>

    <!-- Category filter -->
    <div class="px-5 mb-4 flex gap-2 overflow-x-auto no-scrollbar">
      <button
        v-for="cat in categories"
        :key="cat.id"
        @click="activeCategory = cat.id"
        class="shrink-0 px-4 py-1.5 rounded-full text-xs font-title font-semibold transition-colors"
        :class="activeCategory === cat.id
          ? 'bg-brand-primary text-white'
          : 'bg-bg-card text-white/50 hover:text-white/80'"
      >
        {{ cat.label }}
      </button>
    </div>

    <!-- Games grid -->
    <div class="px-5 grid grid-cols-2 gap-3">
      <div
        v-for="game in filteredGames()"
        :key="game.id"
        class="bg-bg-card rounded-2xl p-4 cursor-pointer active:scale-[0.97] transition-transform"
        @click="playGame(game.id)"
      >
        <div class="text-3xl mb-2">{{ game.icon }}</div>
        <p class="text-white font-title font-semibold text-sm leading-tight">{{ game.title_ja }}</p>
        <p class="text-white/40 text-[10px] font-title mt-1">{{ gameStore.categoryLabels[game.category] }}</p>
        <div v-if="!game.is_free && subStore.currentPlan === 'free'" class="mt-2">
          <span class="text-[10px] bg-yellow-500/20 text-yellow-400 px-2 py-0.5 rounded-full font-title">PRO</span>
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
