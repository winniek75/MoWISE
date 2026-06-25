<script setup lang="ts">
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useSubscriptionStore, PLAN_LIMITS } from '@/stores/subscription'
import BottomNav from '@/components/common/BottomNav.vue'

const router = useRouter()
const auth = useAuthStore()
const subStore = useSubscriptionStore()

const plans = [
  {
    id: 'free' as const,
    name: 'Free',
    price: '0',
    features: ['1クラス・5人まで', 'ゲーム3種類', '基本的な進捗管理'],
    color: 'white/50',
  },
  {
    id: 'basic' as const,
    name: 'Basic',
    price: '980',
    features: ['3クラス・30人まで', '全19ゲーム利用可能', '詳細な進捗ダッシュボード', '宿題・課題管理', 'クラスリーダーボード'],
    popular: true,
    color: 'brand-primary',
  },
  {
    id: 'pro' as const,
    name: 'Pro',
    price: '2,980',
    features: ['無制限クラス・無制限生徒', '全19ゲーム利用可能', '詳細な進捗ダッシュボード', 'カスタムブランド', '優先サポート', 'API アクセス'],
    color: 'brand-secondary',
  },
]

onMounted(async () => {
  if (auth.userId) {
    await subStore.fetchSubscription(auth.userId)
  }
})

async function selectPlan(planId: 'free' | 'basic' | 'pro') {
  if (planId === 'free' || planId === subStore.currentPlan) return
  alert(`Stripe決済ページへ遷移します（${PLAN_LIMITS[planId].price}円/月）\n※ 現在テスト中`)
}
</script>

<template>
  <div class="min-h-screen bg-bg-dark pb-28">
    <header class="neo-header">
      <div class="max-w-4xl mx-auto">
        <p class="text-brand-secondary text-[11px] font-title font-bold tracking-[0.2em] uppercase">MoWISE for Teachers</p>
        <h1 class="text-xl font-title font-bold text-white mt-0.5">プラン・お支払い</h1>
      </div>
    </header>

    <main class="max-w-4xl mx-auto px-5 py-8">
      <!-- Current plan info -->
      <div class="neo-card mb-8 !p-4">
        <p class="text-white/40 text-xs font-title">現在のプラン</p>
        <p class="text-lg font-title font-bold text-neo-gradient capitalize mt-0.5">{{ subStore.currentPlan }}</p>
        <p v-if="subStore.subscription?.current_period_end" class="text-[11px] text-white/25 mt-1">
          次回更新: {{ new Date(subStore.subscription.current_period_end).toLocaleDateString('ja-JP') }}
        </p>
      </div>

      <!-- Plan cards -->
      <div class="grid md:grid-cols-3 gap-4">
        <div
          v-for="plan in plans"
          :key="plan.id"
          class="neo-card relative transition-all duration-300"
          :class="[
            subStore.currentPlan === plan.id ? 'shadow-neo-lg !border-brand-primary/40' : '',
            plan.popular ? '!border-brand-primary/30' : ''
          ]"
        >
          <!-- Popular badge -->
          <div v-if="plan.popular" class="absolute -top-3 left-1/2 -translate-x-1/2">
            <span class="neo-badge !bg-neo-gradient !text-white !border-0 !text-[10px]">人気</span>
          </div>

          <h3 class="text-lg font-title font-bold text-white">{{ plan.name }}</h3>
          <div class="mt-2">
            <span class="text-3xl font-title font-bold text-neo-gradient">¥{{ plan.price }}</span>
            <span class="text-white/30 text-sm">/月</span>
          </div>

          <ul class="mt-5 space-y-2.5">
            <li v-for="f in plan.features" :key="f" class="flex items-start gap-2.5 text-sm text-white/60">
              <svg class="w-4 h-4 text-correct shrink-0 mt-0.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
              {{ f }}
            </li>
          </ul>

          <button
            @click="selectPlan(plan.id)"
            class="w-full mt-6 py-3 rounded-2xl text-sm font-title font-bold transition-all duration-200"
            :class="subStore.currentPlan === plan.id
              ? 'bg-white/5 text-white/30 cursor-default border border-white/[0.06]'
              : 'btn-neo'"
            :disabled="subStore.currentPlan === plan.id"
          >
            {{ subStore.currentPlan === plan.id ? '現在のプラン' : '選択する' }}
          </button>
        </div>
      </div>
    </main>

    <BottomNav />
  </div>
</template>
