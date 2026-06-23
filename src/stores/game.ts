// ============================================================
// stores/game.ts - Game catalog & scores
// ============================================================
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { GameScorePayload } from '@/lib/game-sdk'

export interface GameCatalogItem {
  id: string
  title: string
  title_ja: string
  description?: string
  description_ja?: string
  category: string
  icon: string
  url: string
  thumbnail?: string
  difficulty: string
  is_free: boolean
  sort_order: number
}

export interface GameScore {
  id: string
  user_id: string
  game_id: string
  assignment_id?: string
  class_id?: string
  score: number
  max_score?: number
  accuracy?: number
  time_spent?: number
  xp_earned: number
  coins_earned: number
  completed: boolean
  played_at: string
}

export const useGameStore = defineStore('game', () => {
  const catalog = ref<GameCatalogItem[]>([])
  const recentScores = ref<GameScore[]>([])
  const loading = ref(false)

  const gamesByCategory = computed(() => {
    const map: Record<string, GameCatalogItem[]> = {}
    for (const g of catalog.value) {
      if (!map[g.category]) map[g.category] = []
      map[g.category].push(g)
    }
    return map
  })

  const categoryLabels: Record<string, string> = {
    vocabulary: '語彙・単語',
    grammar: '文法',
    phonics: 'フォニックス',
    writing: 'ライティング',
    listening: 'リスニング',
    mixed: 'ミックス',
  }

  async function fetchCatalog() {
    const { data, error } = await supabase
      .from('game_catalog')
      .select('*')
      .order('sort_order')
    if (error) { console.error('[game] fetchCatalog:', error); return }
    catalog.value = data ?? []
  }

  async function fetchRecentScores(userId: string, limit = 20) {
    const { data, error } = await supabase
      .from('game_scores')
      .select('*')
      .eq('user_id', userId)
      .order('played_at', { ascending: false })
      .limit(limit)
    if (error) { console.error('[game] fetchRecentScores:', error); return }
    recentScores.value = data ?? []
  }

  async function saveScore(payload: GameScorePayload & { userId: string; assignmentId?: string; classId?: string }) {
    const { data, error } = await supabase
      .from('game_scores')
      .insert({
        user_id: payload.userId,
        game_id: payload.gameId,
        assignment_id: payload.assignmentId ?? null,
        class_id: payload.classId ?? null,
        score: payload.score,
        max_score: payload.maxScore ?? null,
        accuracy: payload.accuracy ?? null,
        time_spent: payload.timeSpent ?? null,
        xp_earned: payload.xpEarned ?? 0,
        coins_earned: payload.coinsEarned ?? 0,
        completed: payload.completed ?? false,
        metadata: payload.metadata ?? {},
      })
      .select()
      .single()
    if (error) { console.error('[game] saveScore:', error); return null }
    recentScores.value.unshift(data)
    return data
  }

  function getGameById(id: string): GameCatalogItem | undefined {
    return catalog.value.find(g => g.id === id)
  }

  return {
    catalog, recentScores, loading,
    gamesByCategory, categoryLabels,
    fetchCatalog, fetchRecentScores, saveScore, getGameById,
  }
})
