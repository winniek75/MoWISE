// ============================================================
// stores/subscription.ts - Subscription management
// ============================================================
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export interface Subscription {
  id: string
  user_id: string
  plan: 'free' | 'basic' | 'pro'
  stripe_customer_id?: string
  stripe_subscription_id?: string
  status: 'active' | 'past_due' | 'canceled' | 'trialing'
  current_period_start?: string
  current_period_end?: string
  max_students: number
  max_classes: number
  max_games: number
}

export const PLAN_LIMITS = {
  free:  { max_students: 5,  max_classes: 1, max_games: 3,  price: 0 },
  basic: { max_students: 30, max_classes: 3, max_games: 99, price: 980 },
  pro:   { max_students: 999, max_classes: 99, max_games: 99, price: 2980 },
} as const

export const useSubscriptionStore = defineStore('subscription', () => {
  const subscription = ref<Subscription | null>(null)
  const loading = ref(false)

  const currentPlan = computed(() => subscription.value?.plan ?? 'free')
  const isActive = computed(() => subscription.value?.status === 'active' || subscription.value?.status === 'trialing')
  const limits = computed(() => PLAN_LIMITS[currentPlan.value])

  const canAddStudent = (currentCount: number) => currentCount < (subscription.value?.max_students ?? 5)
  const canAddClass = (currentCount: number) => currentCount < (subscription.value?.max_classes ?? 1)
  const canUseGame = (gameIsFree: boolean) => {
    if (gameIsFree) return true
    return currentPlan.value !== 'free'
  }

  async function fetchSubscription(userId: string) {
    loading.value = true
    const { data, error } = await supabase
      .from('subscriptions')
      .select('*')
      .eq('user_id', userId)
      .single()
    if (error && error.code !== 'PGRST116') {
      console.error('[subscription] fetch:', error)
    }
    subscription.value = data ?? null
    // Create free sub if none exists
    if (!data) {
      const { data: newSub } = await supabase
        .from('subscriptions')
        .insert({
          user_id: userId,
          plan: 'free',
          status: 'active',
          max_students: 5,
          max_classes: 1,
          max_games: 3,
        })
        .select()
        .single()
      subscription.value = newSub
    }
    loading.value = false
  }

  return {
    subscription, loading,
    currentPlan, isActive, limits,
    canAddStudent, canAddClass, canUseGame,
    fetchSubscription,
  }
})
