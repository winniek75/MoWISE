import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase, isOfflineMode } from '@/lib/supabase'

// デモ用パターンデータ
const DEMO_PATTERNS = [
  { pattern_no: 'P001', pattern_text: 'S is ～', area: 'area1' },
  { pattern_no: 'P002', pattern_text: 'This is ～', area: 'area1' },
  { pattern_no: 'P003', pattern_text: 'Nice to meet you', area: 'area1' },
  { pattern_no: 'P004', pattern_text: 'I like ～', area: 'area1' },
  { pattern_no: 'P005', pattern_text: 'I want ～', area: 'area1' },
]

export const useZukanStore = defineStore('zukan', () => {
  const patterns  = ref<any[]>([])
  const progress  = ref<Record<string, any>>({})
  const loading   = ref(false)

  async function fetchAll() {
    if (isOfflineMode) {
      patterns.value = DEMO_PATTERNS
      loading.value = false
      return
    }
    loading.value = true
    const { data: { user } } = await supabase.auth.getUser()

    const [{ data: ps }, { data: pr }] = await Promise.all([
      supabase.from('patterns').select('*').order('pattern_no'),
      supabase.from('pattern_progress').select('*').eq('user_id', user!.id),
    ])

    patterns.value = ps ?? []
    progress.value = Object.fromEntries((pr ?? []).map(p => [p.pattern_id, p]))
    loading.value = false
  }

  async function fetchDetail(patternNo: string) {
    const { data } = await supabase
      .from('patterns')
      .select('*, examples:pattern_content(examples), evolution_to:patterns!evolution_of(*)')
      .eq('pattern_no', patternNo)
      .single()
    return data
  }

  async function fetchProgress(patternNo: string) {
    const { data: { user } } = await supabase.auth.getUser()
    const { data } = await supabase
      .from('pattern_progress')
      .select('*')
      .eq('user_id', user!.id)
      .eq('pattern_id', patternNo)
      .single()
    return data
  }

  function patternsByArea(areaId: string) {
    const rangeMap: Record<string, [number, number]> = {
      area1: [1, 20], area2: [21, 35]
    }
    const [min, max] = rangeMap[areaId] ?? [1, 35]
    return patterns.value
      .filter(p => {
        const n = parseInt(p.pattern_no.replace('P', ''))
        return n >= min && n <= max
      })
      .map(p => ({ ...p, star_level: progress.value[p.pattern_no]?.star_level ?? 0 }))
  }

  function isAreaUnlocked(area: number): boolean {
    if (area === 1) return true
    if (area === 2) {
      // P020が★3以上で解禁
      return (progress.value['P020']?.star_level ?? 0) >= 3
    }
    return false
  }

  return { patterns, loading, fetchAll, fetchDetail, fetchProgress, patternsByArea, isAreaUnlocked }
})
