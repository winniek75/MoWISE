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
  <div class="min-h-screen bg-bg-dark flex flex-col items-center justify-center px-6">
    <div class="w-full max-w-sm">
      <div class="text-center mb-8">
        <h1 class="text-3xl font-title font-bold text-white">MoWISE</h1>
        <p class="text-white/40 text-sm font-title mt-1">アカウント作成</p>
      </div>

      <!-- Role selector -->
      <div class="flex gap-2 mb-6">
        <button
          @click="role = 'teacher'"
          class="flex-1 py-3 rounded-xl text-sm font-title font-semibold transition-colors"
          :class="role === 'teacher'
            ? 'bg-brand-primary text-white'
            : 'bg-bg-card text-white/50 border border-white/10'"
        >
          先生として登録
        </button>
        <button
          @click="role = 'student'"
          class="flex-1 py-3 rounded-xl text-sm font-title font-semibold transition-colors"
          :class="role === 'student'
            ? 'bg-brand-primary text-white'
            : 'bg-bg-card text-white/50 border border-white/10'"
        >
          生徒として登録
        </button>
      </div>

      <div class="space-y-4">
        <div>
          <label class="block text-white/60 text-xs font-title mb-1">表示名</label>
          <input
            v-model="displayName"
            type="text"
            :placeholder="role === 'teacher' ? '例：山田先生' : '例：たろう'"
            class="w-full bg-bg-card text-white px-4 py-3 rounded-xl border border-white/10 focus:border-brand-primary focus:outline-none text-sm"
          />
        </div>
        <div>
          <label class="block text-white/60 text-xs font-title mb-1">メールアドレス</label>
          <input
            v-model="email"
            type="email"
            placeholder="email@example.com"
            class="w-full bg-bg-card text-white px-4 py-3 rounded-xl border border-white/10 focus:border-brand-primary focus:outline-none text-sm"
          />
        </div>
        <div>
          <label class="block text-white/60 text-xs font-title mb-1">パスワード</label>
          <input
            v-model="password"
            type="password"
            placeholder="6文字以上"
            class="w-full bg-bg-card text-white px-4 py-3 rounded-xl border border-white/10 focus:border-brand-primary focus:outline-none text-sm"
          />
        </div>

        <p v-if="error" class="text-red-400 text-sm text-center">{{ error }}</p>

        <button
          @click="handleSignup"
          :disabled="loading || !email || !password || !displayName"
          class="w-full bg-brand-primary text-white font-title font-bold py-3.5 rounded-xl disabled:opacity-40"
        >
          {{ loading ? '登録中...' : 'アカウント作成' }}
        </button>

        <p class="text-center text-white/30 text-xs mt-2">
          {{ role === 'teacher' ? '先生アカウントにはFreeプラン（1クラス5人まで）が自動適用されます' : 'クラスコードを入力してクラスに参加できます' }}
        </p>
      </div>

      <p class="text-center text-white/40 text-sm mt-6">
        既にアカウントをお持ちの方は
        <button @click="router.push({ name: 'Login' })" class="text-brand-primary font-semibold">ログイン</button>
      </p>
    </div>
  </div>
</template>
