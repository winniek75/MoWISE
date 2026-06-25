<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

const email = ref('')
const password = ref('')
const displayName = ref('')
const role = ref<'student' | 'teacher'>('teacher')
const loading = ref(false)
const error = ref('')

async function handleSignup() {
  if (!email.value || !password.value || !displayName.value) return
  loading.value = true
  error.value = ''
  try {
    await auth.signUpWithEmail(email.value, password.value, displayName.value, role.value)
    router.push(role.value === 'teacher' ? { name: 'TeacherDashboard' } : { name: 'StudentHome' })
  } catch (e: any) {
    error.value = e.message || '登録に失敗しました'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-bg-dark flex flex-col items-center justify-center px-6 relative overflow-hidden">
    <!-- Background glow -->
    <div class="absolute top-[-15%] right-[-10%] w-[450px] h-[450px] rounded-full bg-brand-accent/8 blur-[100px] animate-glow-pulse" />
    <div class="absolute bottom-[-15%] left-[-10%] w-[350px] h-[350px] rounded-full bg-brand-secondary/8 blur-[80px] animate-glow-pulse" style="animation-delay: 0.7s" />

    <div class="w-full max-w-sm relative z-10">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-title font-bold text-neo-gradient">MoWISE</h1>
        <p class="text-white/30 text-sm font-title mt-2">アカウント作成</p>
      </div>

      <!-- Role selector -->
      <div class="flex gap-2 mb-6 p-1 bg-bg-card rounded-2xl border border-white/[0.06]">
        <button
          @click="role = 'teacher'"
          class="flex-1 py-3 rounded-xl text-sm font-title font-semibold transition-all duration-200"
          :class="role === 'teacher'
            ? 'bg-neo-gradient text-white shadow-neo-sm'
            : 'text-white/40 hover:text-white/60'"
        >
          先生として登録
        </button>
        <button
          @click="role = 'student'"
          class="flex-1 py-3 rounded-xl text-sm font-title font-semibold transition-all duration-200"
          :class="role === 'student'
            ? 'bg-neo-gradient text-white shadow-neo-sm'
            : 'text-white/40 hover:text-white/60'"
        >
          生徒として登録
        </button>
      </div>

      <div class="space-y-4 animate-slide-up">
        <div>
          <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">表示名</label>
          <input
            v-model="displayName"
            type="text"
            :placeholder="role === 'teacher' ? '例：山田先生' : '例：たろう'"
            class="neo-input"
          />
        </div>
        <div>
          <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">メールアドレス</label>
          <input
            v-model="email"
            type="email"
            placeholder="email@example.com"
            class="neo-input"
          />
        </div>
        <div>
          <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">パスワード</label>
          <input
            v-model="password"
            type="password"
            placeholder="6文字以上"
            class="neo-input"
          />
        </div>

        <p v-if="error" class="text-neon-pink text-sm text-center py-1">{{ error }}</p>

        <button
          @click="handleSignup"
          :disabled="loading || !email || !password || !displayName"
          class="btn-neo w-full"
        >
          {{ loading ? '登録中...' : 'アカウント作成' }}
        </button>

        <p class="text-center text-white/20 text-xs mt-2">
          {{ role === 'teacher' ? 'Freeプラン（1クラス5人まで）が自動適用されます' : 'クラスコードを入力してクラスに参加できます' }}
        </p>
      </div>

      <p class="text-center text-white/30 text-sm mt-8">
        既にアカウントをお持ちの方は
        <button @click="router.push({ name: 'Login' })" class="text-brand-secondary font-semibold hover:underline">ログイン</button>
      </p>
    </div>
  </div>
</template>
