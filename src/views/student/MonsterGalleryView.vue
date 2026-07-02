<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useMonsterStore } from '@/stores/monster'
import { useAuthStore } from '@/stores/auth'
import { useGameStore } from '@/stores/game'
import { useMissionStore } from '@/stores/mission'
import BottomNav from '@/components/common/BottomNav.vue'
import type { UserMonster } from '@/stores/monster'

const monsterStore = useMonsterStore()
const auth = useAuthStore()
const gameStore = useGameStore()
const missionStore = useMissionStore()

const activeTab = ref<'collection' | 'gallery' | 'gacha'>('collection')
const selectedMonster = ref<UserMonster | null>(null)
const feedAmount = ref(1)
const feedResult = ref<any>(null)
const gachaResult = ref<any>(null)
const gachaAnimating = ref(false)
const feedLoading = ref(false)

const userCoins = computed(() => auth.userRow?.coins ?? 0)
const userTickets = computed(() => auth.userRow?.gacha_tickets ?? 0)

const rarityColors: Record<number, string> = {
  1: 'text-white/60',
  2: 'text-neon-cyan',
  3: 'text-neon-yellow',
  4: 'text-neon-pink',
}

const rarityBg: Record<number, string> = {
  1: 'bg-white/[0.04] border-white/[0.08]',
  2: 'bg-neon-cyan/[0.06] border-neon-cyan/20',
  3: 'bg-neon-yellow/[0.06] border-neon-yellow/20',
  4: 'bg-neon-pink/[0.06] border-neon-pink/20',
}

onMounted(async () => {
  await Promise.all([
    monsterStore.fetchSpecies(),
    monsterStore.fetchMyMonsters(),
  ])
})

function selectMonster(m: UserMonster) {
  selectedMonster.value = m
  feedResult.value = null
}

async function handleFeed() {
  if (!selectedMonster.value) return
  feedLoading.value = true
  const result = await monsterStore.feedMonster(selectedMonster.value.id, feedAmount.value)
  feedLoading.value = false
  if (result) {
    feedResult.value = result
    if (auth.userId) {
      await auth.fetchUserRow(auth.userId)
      await missionStore.updateMissionProgress(auth.userId, 'feed_monster', 1)
    }
    selectedMonster.value = monsterStore.myMonsters.find(m => m.id === selectedMonster.value?.id) ?? null
  }
}

async function handleSetBuddy() {
  if (!selectedMonster.value) return
  await monsterStore.setBuddy(selectedMonster.value.id)
}

async function handleGacha() {
  gachaAnimating.value = true
  gachaResult.value = null
  // Animate delay
  await new Promise(r => setTimeout(r, 1500))
  const result = await monsterStore.pullGacha('normal')
  gachaAnimating.value = false
  if (result) {
    gachaResult.value = result
    if (auth.userId) {
      await auth.fetchUserRow(auth.userId)
      await missionStore.updateMissionProgress(auth.userId, 'pull_gacha', 1)
    }
  }
}

function closeMonsterDetail() {
  selectedMonster.value = null
  feedResult.value = null
}
</script>

<template>
  <div class="min-h-screen bg-bg-dark pb-28 safe-pt">
    <header class="px-5 pt-4 pb-3">
      <h1 class="text-white text-xl font-title font-bold">モンスター図鑑</h1>
      <div class="flex items-center gap-3 mt-1">
        <span class="text-white/30 text-xs font-title">コレクション {{ monsterStore.collectionRate }}%</span>
        <span class="text-neon-yellow text-xs font-title">{{ userCoins }} コイン</span>
        <span class="text-neon-purple text-xs font-title">{{ userTickets }} チケット</span>
      </div>
    </header>

    <!-- Tabs -->
    <div class="px-5 mb-4 flex gap-2">
      <button v-for="tab in [
        { id: 'collection', label: 'コレクション' },
        { id: 'gallery', label: '図鑑' },
        { id: 'gacha', label: 'ガチャ' },
      ]" :key="tab.id"
        @click="activeTab = tab.id as any"
        class="px-4 py-1.5 rounded-full text-xs font-title font-semibold transition-all"
        :class="activeTab === tab.id
          ? 'bg-neo-gradient text-white shadow-neo-sm'
          : 'bg-bg-card text-white/30 border border-white/[0.06]'"
      >{{ tab.label }}</button>
    </div>

    <!-- Collection tab: My monsters -->
    <div v-if="activeTab === 'collection'" class="px-5">
      <!-- Buddy display -->
      <div v-if="monsterStore.buddy" class="neo-card mb-4 text-center">
        <p class="text-white/30 text-[10px] font-title mb-2">相棒モンスター</p>
        <div class="w-20 h-20 mx-auto rounded-2xl bg-white/[0.04] flex items-center justify-center text-4xl mb-2">
          {{ monsterStore.buddy.species?.name_ja?.charAt(0) ?? '?' }}
        </div>
        <p class="text-white font-title font-bold">{{ monsterStore.buddy.nickname || monsterStore.buddy.species?.name_ja }}</p>
        <p class="text-white/30 text-xs font-title">Lv.{{ monsterStore.buddy.level }} | Stage {{ monsterStore.buddy.stage }}</p>
      </div>

      <div v-if="monsterStore.myMonsters.length === 0" class="text-center py-12 text-white/25 text-sm font-title">
        まだモンスターがいません。ガチャを回そう！
      </div>

      <div class="grid grid-cols-3 gap-3">
        <div
          v-for="m in monsterStore.myMonsters"
          :key="m.id"
          @click="selectMonster(m)"
          class="neo-card cursor-pointer active:scale-95 transition-all text-center !p-3 border"
          :class="[rarityBg[m.species?.rarity ?? 1], m.is_buddy ? '!border-neon-yellow/40' : '']"
        >
          <div class="w-12 h-12 mx-auto rounded-xl bg-white/[0.06] flex items-center justify-center text-2xl mb-1.5">
            {{ m.species?.name_ja?.charAt(0) ?? '?' }}
          </div>
          <p class="text-white font-title font-semibold text-[11px] leading-tight">{{ m.species?.name_ja }}</p>
          <p class="text-white/25 text-[9px] font-title mt-0.5">Lv.{{ m.level }}</p>
          <p :class="rarityColors[m.species?.rarity ?? 1]" class="text-[9px] font-title">{{ monsterStore.rarityStars(m.species?.rarity ?? 1) }}</p>
        </div>
      </div>
    </div>

    <!-- Gallery tab: All species (pokedex) -->
    <div v-if="activeTab === 'gallery'" class="px-5">
      <div class="grid grid-cols-3 gap-3">
        <div
          v-for="sp in monsterStore.species"
          :key="sp.id"
          class="neo-card text-center !p-3"
          :class="monsterStore.collectedSpeciesIds.has(sp.id) ? '' : 'opacity-40'"
        >
          <div class="w-12 h-12 mx-auto rounded-xl bg-white/[0.06] flex items-center justify-center text-2xl mb-1.5">
            {{ monsterStore.collectedSpeciesIds.has(sp.id) ? sp.name_ja.charAt(0) : '?' }}
          </div>
          <p class="text-white font-title font-semibold text-[11px] leading-tight">
            {{ monsterStore.collectedSpeciesIds.has(sp.id) ? sp.name_ja : '???' }}
          </p>
          <p :class="rarityColors[sp.rarity]" class="text-[9px] font-title mt-0.5">
            {{ monsterStore.rarityStars(sp.rarity) }}
          </p>
          <p class="text-white/20 text-[9px] font-title">{{ gameStore.categoryLabels[sp.category] || sp.category }}</p>
        </div>
      </div>
    </div>

    <!-- Gacha tab -->
    <div v-if="activeTab === 'gacha'" class="px-5">
      <div class="neo-card text-center !py-8">
        <p class="text-white/40 text-sm font-title mb-4">チケットを使ってモンスターをゲット！</p>

        <!-- Gacha animation area -->
        <div class="w-32 h-32 mx-auto rounded-full flex items-center justify-center mb-6 transition-all duration-500"
          :class="gachaAnimating
            ? 'bg-neon-purple/20 animate-pulse scale-110 shadow-[0_0_40px_rgba(108,92,231,0.4)]'
            : 'bg-white/[0.04]'"
        >
          <span v-if="gachaAnimating" class="text-5xl animate-spin">🥚</span>
          <span v-else-if="gachaResult" class="text-5xl">{{ gachaResult.name_ja?.charAt(0) }}</span>
          <span v-else class="text-5xl">🎰</span>
        </div>

        <!-- Gacha result -->
        <div v-if="gachaResult && !gachaAnimating" class="mb-6 animate-pop-in">
          <p v-if="gachaResult.is_new" class="text-neon-yellow text-xs font-title font-bold mb-1">NEW!</p>
          <p class="text-white font-title font-bold text-lg">{{ gachaResult.name_ja }}</p>
          <p :class="rarityColors[gachaResult.rarity]" class="text-sm font-title">
            {{ monsterStore.rarityStars(gachaResult.rarity) }} {{ monsterStore.rarityLabel(gachaResult.rarity) }}
          </p>
        </div>

        <button
          @click="handleGacha"
          :disabled="gachaAnimating || userTickets < 1"
          class="btn-neo !px-8"
        >
          {{ gachaAnimating ? 'ガチャ中...' : `ガチャを回す (1チケット)` }}
        </button>
        <p class="text-white/20 text-[10px] font-title mt-3">
          ★ Normal 60% | ★★ Rare 25% | ★★★ SR 12% | ★★★★ Legend 3%
        </p>
      </div>
    </div>

    <!-- Monster detail modal -->
    <div
      v-if="selectedMonster"
      class="neo-overlay"
      @click.self="closeMonsterDetail"
    >
      <div class="neo-modal !max-w-sm mx-6">
        <div class="text-center mb-4">
          <div class="w-24 h-24 mx-auto rounded-2xl flex items-center justify-center text-5xl mb-3"
            :class="rarityBg[selectedMonster.species?.rarity ?? 1]">
            {{ selectedMonster.species?.name_ja?.charAt(0) ?? '?' }}
          </div>
          <h2 class="text-white font-title font-bold text-lg">
            {{ selectedMonster.nickname || selectedMonster.species?.name_ja }}
          </h2>
          <p :class="rarityColors[selectedMonster.species?.rarity ?? 1]" class="text-sm font-title">
            {{ monsterStore.rarityStars(selectedMonster.species?.rarity ?? 1) }}
            {{ monsterStore.rarityLabel(selectedMonster.species?.rarity ?? 1) }}
          </p>
          <p class="text-white/30 text-xs font-title mt-1">{{ selectedMonster.species?.description_ja }}</p>
        </div>

        <!-- Stats -->
        <div class="grid grid-cols-3 gap-3 text-center mb-4">
          <div>
            <p class="text-neo-gradient font-title font-bold text-xl">{{ selectedMonster.level }}</p>
            <p class="text-white/30 text-[10px] font-title">Level</p>
          </div>
          <div>
            <p class="text-neon-cyan font-title font-bold text-xl">{{ selectedMonster.stage }}/3</p>
            <p class="text-white/30 text-[10px] font-title">Stage</p>
          </div>
          <div>
            <p class="text-neon-yellow font-title font-bold text-xl">{{ selectedMonster.exp }}</p>
            <p class="text-white/30 text-[10px] font-title">EXP</p>
          </div>
        </div>

        <!-- EXP bar -->
        <div class="mb-4">
          <div class="flex justify-between text-[10px] text-white/25 font-title mb-1">
            <span>EXP {{ monsterStore.expToNextLevel(selectedMonster).current }}/{{ monsterStore.expToNextLevel(selectedMonster).needed }}</span>
            <span>Next Lv.{{ selectedMonster.level + 1 }}</span>
          </div>
          <div class="w-full h-2 bg-white/[0.06] rounded-full overflow-hidden">
            <div class="h-full bg-neo-gradient rounded-full transition-all"
              :style="{ width: `${monsterStore.expToNextLevel(selectedMonster).percent}%` }" />
          </div>
        </div>

        <!-- Evolution info -->
        <div class="text-center text-[10px] text-white/20 font-title mb-4">
          <span v-if="selectedMonster.stage < 2">Stage 2 @ Lv.{{ selectedMonster.species?.evolve_lv2 }}</span>
          <span v-if="selectedMonster.stage < 3"> | Stage 3 @ Lv.{{ selectedMonster.species?.evolve_lv3 }}</span>
          <span v-if="selectedMonster.stage === 3" class="text-neon-yellow">MAX EVOLUTION</span>
        </div>

        <!-- Feed -->
        <div class="flex items-center gap-2 mb-3">
          <select v-model.number="feedAmount" class="neo-input !w-auto !py-2 text-center">
            <option :value="1">1個 (5コイン)</option>
            <option :value="3">3個 (15コイン)</option>
            <option :value="5">5個 (25コイン)</option>
            <option :value="10">10個 (50コイン)</option>
          </select>
          <button
            @click="handleFeed"
            :disabled="feedLoading || userCoins < feedAmount * 5"
            class="btn-neo flex-1 !py-2.5"
          >
            {{ feedLoading ? '...' : 'エサをあげる' }}
          </button>
        </div>

        <!-- Feed result -->
        <div v-if="feedResult" class="text-center text-sm font-title mb-3 animate-pop-in">
          <p class="text-neon-green">+{{ feedResult.exp_gained }} EXP → Lv.{{ feedResult.new_level }}</p>
          <p v-if="feedResult.evolved" class="text-neon-yellow font-bold text-lg mt-1 animate-glow-pulse">進化した！ Stage {{ feedResult.new_stage }}</p>
        </div>

        <!-- Actions -->
        <div class="flex gap-2">
          <button
            v-if="!selectedMonster.is_buddy"
            @click="handleSetBuddy"
            class="btn-ghost flex-1 border border-neon-yellow/20 text-neon-yellow !text-xs !rounded-xl"
          >相棒にする</button>
          <button @click="closeMonsterDetail" class="btn-ghost flex-1 border border-white/10 !text-xs !rounded-xl">閉じる</button>
        </div>
      </div>
    </div>

    <BottomNav />
  </div>
</template>
