import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase, isOfflineMode } from '@/lib/supabase'

// デモ用パターンデータ
const DEMO_PATTERNS = [
  { pattern_no: 'P001', pattern_text: '[代名詞] + be動詞 + [状態/情報]', japanese: '〜は…です', area: 'area1', rarity: 1 },
  { pattern_no: 'P002', pattern_text: 'This is [名詞].', japanese: 'これは〜です', area: 'area1', rarity: 1 },
  { pattern_no: 'P003', pattern_text: 'I like [名詞/動名詞].', japanese: '〜が好きです', area: 'area1', rarity: 1 },
  { pattern_no: 'P004', pattern_text: 'I want [名詞].', japanese: '〜が欲しいです', area: 'area1', rarity: 1 },
  { pattern_no: 'P005', pattern_text: 'I have [名詞].', japanese: '〜を持っています', area: 'area1', rarity: 1 },
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
    try {
      const { data: { user } } = await supabase.auth.getUser()

      const [{ data: ps }, { data: pr }] = await Promise.all([
        supabase.from('patterns').select('*').order('pattern_no'),
        user
          ? supabase.from('pattern_progress').select('*').eq('user_id', user.id)
          : Promise.resolve({ data: [] }),
      ])

      patterns.value = ps ?? []
      progress.value = Object.fromEntries(
        (pr ?? []).map((p: any) => [p.pattern_no, p])
      )
    } catch (e) {
      console.warn('[zukan] fetchAll failed:', e)
      patterns.value = DEMO_PATTERNS
    } finally {
      loading.value = false
    }
  }

  async function fetchDetail(patternNo: string) {
    if (isOfflineMode) {
      return DEMO_PATTERNS.find(p => p.pattern_no === patternNo) ?? null
    }
    try {
      // パターン基本情報
      const { data: pattern } = await supabase
        .from('patterns')
        .select('*')
        .eq('pattern_no', patternNo)
        .single()

      if (!pattern) return null

      // 例文（Layer 3 の correct_answer から取得）
      const { data: content } = await supabase
        .from('pattern_content')
        .select('correct_answer, prompt_ja, audio_url_main')
        .eq('pattern_no', patternNo)
        .eq('layer', 3)
        .order('question_order')
        .limit(3)

      const examples = (content ?? []).map((c: any) => ({
        english: c.correct_answer,
        japanese: c.prompt_ja ?? '',
        audio_url: c.audio_url_main ?? '',
      }))

      // 進化形
      let evolution_to = null
      if (pattern.evolution_of) {
        const { data: evo } = await supabase
          .from('patterns')
          .select('pattern_no, pattern_text, japanese')
          .eq('pattern_no', pattern.evolution_of)
          .single()
        evolution_to = evo
      }

      return { ...pattern, examples, evolution_to }
    } catch (e) {
      console.warn('[zukan] fetchDetail failed:', e)
      return null
    }
  }

  async function fetchProgress(patternNo: string) {
    if (isOfflineMode) return null
    try {
      const { data: { user } } = await supabase.auth.getUser()
      if (!user) return null
      const { data } = await supabase
        .from('pattern_progress')
        .select('*')
        .eq('user_id', user.id)
        .eq('pattern_no', patternNo)
        .maybeSingle()
      return data
    } catch (e) {
      console.warn('[zukan] fetchProgress failed:', e)
      return null
    }
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
      .map(p => ({
        ...p,
        star_level: progress.value[p.pattern_no]?.mastery_level ?? 0,
      }))
  }

  function isAreaUnlocked(area: number): boolean {
    if (area === 1) return true
    if (area === 2) {
      return (progress.value['P020']?.mastery_level ?? 0) >= 3
    }
    return false
  }

  return { patterns, loading, fetchAll, fetchDetail, fetchProgress, patternsByArea, isAreaUnlocked }
})
