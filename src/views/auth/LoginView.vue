<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const loginMode = ref<'student' | 'teacher'>('student')

// Teacher login fields
const email = ref('')
const password = ref('')

// Student login fields
const classCode = ref('')
const pin = ref('')

const loading = ref(false)
const error = ref('')

// QR code auto-login support
onMounted(() => {
  const c = route.query.c as string | undefined
  const p = route.query.p as string | undefined
  if (c && p) {
    classCode.value = c.toUpperCase()
    pin.value = p
    loginMode.value = 'student'
    handleStudentLogin()
  }
})

async function handleTeacherLogin() {
  if (!email.value || !password.value) return
  loading.value = true
  error.value = ''
  try {
    await auth.signInWithEmail(email.value, password.value)
    router.push(auth.isTeacher ? { name: 'TeacherDashboard' } : { name: 'StudentHome' })
  } catch (e: any) {
    error.value = e.message || 'Login failed'
  } finally {
    loading.value = false
  }
}

async function handleStudentLogin() {
  if (!classCode.value || !pin.value) return
  loading.value = true
  error.value = ''
  try {
    await auth.signInAsStudent(classCode.value, pin.value)
    router.push({ name: 'StudentHome' })
  } catch (e: any) {
    error.value = e.message || 'Login failed'
  } finally {
    loading.value = false
  }
}

async function handleGoogle() {
  try {
    await auth.signInWithGoogle()
  } catch (e: any) {
    error.value = e.message
  }
}
</script>

<template>
  <div class="min-h-screen bg-bg-dark flex flex-col items-center justify-center px-6 relative overflow-hidden">
    <!-- Background glow effects -->
    <div class="absolute top-[-20%] left-[-10%] w-[500px] h-[500px] rounded-full bg-brand-primary/10 blur-[120px] animate-glow-pulse" />
    <div class="absolute bottom-[-20%] right-[-10%] w-[400px] h-[400px] rounded-full bg-brand-secondary/10 blur-[100px] animate-glow-pulse" style="animation-delay: 1s" />

    <div class="w-full max-w-sm relative z-10">
      <!-- Logo -->
      <div class="text-center mb-8">
        <div class="w-16 h-16 mowi-orb glow-mid mx-auto mb-4 animate-float" />
        <h1 class="text-4xl font-title font-bold text-neo-gradient">MoWISE</h1>
        <p class="text-white/30 text-sm font-title mt-2">for Teachers & Students</p>
      </div>

      <!-- Mode selector -->
      <div class="flex gap-2 mb-6 p-1 bg-bg-card rounded-2xl border border-white/[0.06]">
        <button
          @click="loginMode = 'student'; error = ''"
          class="flex-1 py-3 rounded-xl text-sm font-title font-semibold transition-all duration-200"
          :class="loginMode === 'student'
            ? 'bg-neo-gradient text-white shadow-neo-sm'
            : 'text-white/40 hover:text-white/60'"
        >
          生徒ログイン
        </button>
        <button
          @click="loginMode = 'teacher'; error = ''"
          class="flex-1 py-3 rounded-xl text-sm font-title font-semibold transition-all duration-200"
          :class="loginMode === 'teacher'
            ? 'bg-neo-gradient text-white shadow-neo-sm'
            : 'text-white/40 hover:text-white/60'"
        >
          先生ログイン
        </button>
      </div>

      <!-- Student PIN login -->
      <div v-if="loginMode === 'student'" class="space-y-4 animate-slide-up">
        <p class="text-white/40 text-xs text-center mb-2">先生からもらったクラスコードとPINを入力してね</p>
        <div>
          <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">クラスコード</label>
          <input
            v-model="classCode"
            type="text"
            placeholder="例：ABC123"
            maxlength="6"
            class="neo-input uppercase tracking-widest text-center text-lg"
            @input="classCode = classCode.toUpperCase()"
          />
        </div>
        <div>
          <label class="block text-white/40 text-[11px] font-title font-semibold uppercase tracking-wider mb-1.5">PIN</label>
          <input
            v-model="pin"
            type="text"
            inputmode="numeric"
            placeholder="4桁のPIN"
            maxlength="4"
            class="neo-input tracking-[0.5em] text-center text-lg"
          />
        </div>

        <p v-if="error" class="text-neon-pink text-sm text-center py-1">{{ error }}</p>

        <button
          @click="handleStudentLogin"
          :disabled="loading || classCode.length < 4 || pin.length < 4"
          class="btn-neo w-full"
        >
          {{ loading ? 'ログイン中...' : 'ログイン' }}
        </button>
      </div>

      <!-- Teacher email login -->
      <div v-else class="space-y-4 animate-slide-up">
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
            placeholder="********"
            class="neo-input"
          />
        </div>

        <p v-if="error" class="text-neon-pink text-sm text-center py-1">{{ error }}</p>

        <button
          @click="handleTeacherLogin"
          :disabled="loading || !email || !password"
          class="btn-neo w-full"
        >
          {{ loading ? 'ログイン中...' : 'ログイン' }}
        </button>

        <div class="neo-divider">
          <span class="text-white/20 text-xs font-title">or</span>
        </div>

        <button
          @click="handleGoogle"
          class="w-full bg-white/95 text-gray-800 font-semibold py-3.5 rounded-2xl text-sm flex items-center justify-center gap-2 active:scale-95 transition-transform shadow-neo-sm"
        >
          <svg class="w-5 h-5" viewBox="0 0 24 24"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 01-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z"/><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z"/><path fill="#FBBC05" d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z"/><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z"/></svg>
          Googleでログイン
        </button>

        <!-- Sign up link (teachers only) -->
        <p class="text-center text-white/30 text-sm mt-4">
          アカウントをお持ちでない方は
          <button @click="router.push({ name: 'Signup' })" class="text-brand-secondary font-semibold hover:underline">新規登録</button>
        </p>
      </div>
    </div>
  </div>
</template>
