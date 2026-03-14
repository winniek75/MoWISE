<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router  = useRouter()
const auth    = useAuthStore()

const email       = ref('')
const password    = ref('')
const displayName = ref('')
const errorMsg    = ref('')
const isLogin     = ref(false)

async function submit() {
  errorMsg.value = ''

  // クライアント側バリデーション
  if (!email.value.trim()) { errorMsg.value = 'メールアドレスを入力してください。'; return }
  if (password.value.length < 8) { errorMsg.value = 'パスワードは8文字以上で入力してください。'; return }
  if (!isLogin.value && !displayName.value.trim()) { errorMsg.value = 'ニックネームを入力してください。'; return }

  try {
    if (isLogin.value) {
      await auth.signInWithEmail(email.value, password.value)
      router.push({ name: 'Home' })
    } else {
      await auth.signUpWithEmail(email.value, password.value, displayName.value)
      router.push({ name: 'Onboarding3' })
    }
  } catch (e: unknown) {
    errorMsg.value = (e as Error).message
  }
}
</script>

<template>
  <div class="min-h-screen flex flex-col safe-pt safe-pb px-6 py-10 gap-8">
    <!-- ヘッダー -->
    <div class="flex items-center gap-3">
      <button class="text-white/40 text-2xl" @click="$router.back()">←</button>
      <div class="w-8 h-8 mowi-orb grayscale" />
      <span class="font-title text-white/60 text-sm">{{ isLogin ? 'ログイン' : 'アカウント作成' }}</span>
    </div>

    <!-- フォーム -->
    <div class="flex-1 flex flex-col justify-center gap-6 max-w-sm mx-auto w-full">
      <h2 class="font-title text-2xl font-bold text-white">
        {{ isLogin ? 'おかえりなさい' : 'アカウントをつくる' }}
      </h2>

      <div class="space-y-4">
        <!-- 名前（新規のみ） -->
        <div v-if="!isLogin" class="space-y-1">
          <label class="text-white/60 text-sm font-title">ニックネーム</label>
          <input
            v-model="displayName"
            type="text"
            placeholder="例：タロウ"
            class="w-full bg-bg-surface border border-white/20 rounded-xl px-4 py-3 text-white placeholder-white/30 focus:border-brand-primary outline-none transition-colors"
          />
        </div>

        <!-- メール -->
        <div class="space-y-1">
          <label class="text-white/60 text-sm font-title">メールアドレス</label>
          <input
            v-model="email"
            type="email"
            placeholder="example@email.com"
            class="w-full bg-bg-surface border border-white/20 rounded-xl px-4 py-3 text-white placeholder-white/30 focus:border-brand-primary outline-none transition-colors"
          />
        </div>

        <!-- パスワード -->
        <div class="space-y-1">
          <label class="text-white/60 text-sm font-title">パスワード</label>
          <input
            v-model="password"
            type="password"
            placeholder="8文字以上"
            class="w-full bg-bg-surface border border-white/20 rounded-xl px-4 py-3 text-white placeholder-white/30 focus:border-brand-primary outline-none transition-colors"
          />
        </div>

        <!-- エラー -->
        <p v-if="errorMsg" class="text-wrong text-sm text-center">{{ errorMsg }}</p>
      </div>

      <!-- 送信ボタン -->
      <button
        class="btn-primary w-full text-base font-title"
        :disabled="auth.loading"
        @click="submit"
      >
        <span v-if="auth.loading">処理中…</span>
        <span v-else>{{ isLogin ? 'ログイン' : '次へ →' }}</span>
      </button>

      <!-- 切替 -->
      <button
        class="text-white/40 text-sm text-center underline"
        @click="isLogin = !isLogin"
      >
        {{ isLogin ? 'アカウントをつくる' : 'すでにアカウントをお持ちの方' }}
      </button>
    </div>
  </div>
</template>
