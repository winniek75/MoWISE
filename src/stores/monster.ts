// ============================================================
// stores/monster.ts — Monster collection, feeding, gacha
// ============================================================
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface MonsterSpecies {
  id: string
  name_ja: string
  name_en: string
  category: string
  rarity: number
  stage1_img: string
  stage2_img: string
  stage3_img: string
  evolve_lv2: number
  evolve_lv3: number
  max_level: number
  description_ja?: string
}

export interface UserMonster {
  id: string
  user_id: string
  species_id: string
  nickname?: string
  level: number
  exp: number
  stage: number
  is_buddy: boolean
  obtained_at: string
  obtained_via: string
  // Joined
  species?: MonsterSpecies
}

export interface GachaResult {
  species_id: string
  name_ja: string
  name_en: string
  rarity: number
  category: string
  is_new: boolean
  stage1_img: string
}

export interface FeedResult {
  monster_id: string
  exp_gained: number
  new_exp: number
  new_level: number
  new_stage: number
  evolved: boolean
  coins_spent: number
}

export const useMonsterStore = defineStore('monster', () => {
  const species = ref<MonsterSpecies[]>([])
  const myMonsters = ref<UserMonster[]>([])
  const loading = ref(false)

  const buddy = computed(() => myMonsters.value.find(m => m.is_buddy))

  const collectedSpeciesIds = computed(() => new Set(myMonsters.value.map(m => m.species_id)))

  const collectionRate = computed(() => {
    if (species.value.length === 0) return 0
    return Math.round((collectedSpeciesIds.value.size / species.value.length) * 100)
  })

  const rarityLabel = (r: number) => ['', 'Normal', 'Rare', 'Super Rare', 'Legend'][r] ?? ''
  const rarityStars = (r: number) => '★'.repeat(r)

  async function fetchSpecies() {
    const { data } = await supabase
      .from('monster_species')
      .select('*')
      .order('sort_order')
    species.value = data ?? []
  }

  async function fetchMyMonsters() {
    const { data } = await supabase
      .from('user_monsters')
      .select('*, species:monster_species(*)')
      .order('obtained_at', { ascending: false })
    myMonsters.value = data ?? []
  }

  async function feedMonster(monsterId: string, foodAmount: number = 1): Promise<FeedResult | null> {
    const { data, error } = await supabase.rpc('feed_monster', {
      p_monster_id: monsterId,
      p_food_amount: foodAmount,
    })
    if (error) { console.error('[monster] feed:', error); return null }
    // Refresh monster data
    await fetchMyMonsters()
    return data as FeedResult
  }

  async function pullGacha(ticketType: string = 'normal'): Promise<GachaResult | null> {
    const { data, error } = await supabase.rpc('pull_gacha', {
      p_ticket_type: ticketType,
    })
    if (error) { console.error('[monster] gacha:', error); return null }
    // Refresh monsters
    await fetchMyMonsters()
    return data as GachaResult
  }

  async function setBuddy(monsterId: string) {
    const { error } = await supabase.rpc('set_buddy_monster', {
      p_monster_id: monsterId,
    })
    if (error) { console.error('[monster] setBuddy:', error); return }
    // Update local state
    for (const m of myMonsters.value) {
      m.is_buddy = m.id === monsterId
    }
  }

  function getSpeciesById(id: string): MonsterSpecies | undefined {
    return species.value.find(s => s.id === id)
  }

  function getStageImg(monster: UserMonster): string {
    const sp = monster.species || getSpeciesById(monster.species_id)
    if (!sp) return '/monsters/placeholder.svg'
    if (monster.stage === 3) return sp.stage3_img
    if (monster.stage === 2) return sp.stage2_img
    return sp.stage1_img
  }

  function expToNextLevel(monster: UserMonster): { current: number; needed: number; percent: number } {
    const currentLevelExp = (monster.level - 1) * 100
    const nextLevelExp = monster.level * 100
    const current = monster.exp - currentLevelExp
    const needed = 100
    return { current, needed, percent: Math.min(Math.round((current / needed) * 100), 100) }
  }

  return {
    species, myMonsters, loading,
    buddy, collectedSpeciesIds, collectionRate,
    rarityLabel, rarityStars,
    fetchSpecies, fetchMyMonsters,
    feedMonster, pullGacha, setBuddy,
    getSpeciesById, getStageImg, expToNextLevel,
  }
})
