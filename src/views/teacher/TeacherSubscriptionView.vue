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
  },
  {
    id: 'basic' as const,
    name: 'Basic',
    price: '980',
    features: ['3クラス・30人まで', '全19ゲーム利用可能', '詳細な進捗ダッシュボード', '宿題・課題管理', 'クラスリーダーボード'],
    popular: true,
  },
  {
    id: 'pro' as const,
    name: 'Pro',
    price: '2,980',
    features: ['無制限クラス・無制限生徒', '全19ゲーム利用可能', '詳細な進捗ダッシュボード', 'カスタムブランド', '優先サポート', 'API アクセス'],
  },
]

onMounted(async () => {
  if (auth.userId) {
    await subStore.fetchSubscription(auth.userId)
  }
})

async function selectPlan(planId: 'free' | 'basic' | 'pro') {
  if (planId === 'free' || planId === subStore.currentPlan) return
  // TODO: Stripe Checkout integration
  alert(`Stripe決済ページへ遷移します（${PLAN_LIMITS[planId].price}円/月）\n※ 現在テスト中`)
}
</script>

<template>
  <div class="min-h-screen bg-gray-50 pb-24">
    <header class="bg-white border-b border-gray-200 px-6 py-4">
      <div class="max-w-4xl mx-auto">
        <p class="text-xs text-indigo-500 font-semibold tracking-widest uppercase">MoWISE for Teachers</p>
        <h1 class="text-xl font-bold text-gray-900 mt-0.5">プラン・お支払い</h1>
      </div>
    </header>

    <main class="max-w-4xl mx-auto px-6 py-8">
      <!-- Current plan info -->
      <div class="bg-white rounded-xl border border-gray-200 p-4 mb-8">
        <p class="text-sm text-gray-500">現在のプラン</p>
        <p class="text-lg font-bold text-gray-900 capitalize">{{ subStore.currentPlan }}</p>
        <p v-if="subStore.subscription?.current_period_end" class="text-xs text-gray-400 mt-1">
          次回更新: {{ new Date(subStore.subscription.current_period_end).toLocaleDateString('ja-JP') }}
        </p>
      </div>

      <!-- Plan cards -->
      <div class="grid md:grid-cols-3 gap-4">
        <div
          v-for="plan in plans"
          :key="plan.id"
          class="relative rounded-2xl border-2 p-6 transition-all"
          :class="subStore.currentPlan === plan.id
            ? 'border-indigo-500 bg-indigo-50'
            : plan.popular ? 'border-indigo-300 bg-white' : 'border-gray-200 bg-white'"
        >
          <!-- Popular badge -->
          <div v-if="plan.popular" class="absolute -top-3 left-1/2 -translate-x-1/2 bg-indigo-600 text-white text-xs font-bold px-3 py-0.5 rounded-full">
            人気
          </div>

          <h3 class="text-lg font-bold text-gray-900">{{ plan.name }}</h3>
          <div class="mt-2">
            <span class="text-3xl font-bold text-gray-900">¥{{ plan.price }}</span>
            <span class="text-gray-500 text-sm">/月</span>
          </div>

          <ul class="mt-4 space-y-2">
            <li v-for="f in plan.features" :key="f" class="flex items-start gap-2 text-sm text-gray-600">
              <span class="text-green-500 mt-0.5">✓</span>
              {{ f }}
            </li>
          </ul>

          <button
            @click="selectPlan(plan.id)"
            class="w-full mt-6 py-2.5 rounded-lg text-sm font-semibold transition-colors"
            :class="subStore.currentPlan === plan.id
              ? 'bg-gray-200 text-gray-500 cursor-default'
              : 'bg-indigo-600 hover:bg-indigo-700 text-white'"
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
