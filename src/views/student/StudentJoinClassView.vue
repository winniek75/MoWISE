<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useStudentStore } from '@/stores/student'

const router = useRouter()
const auth = useAuthStore()
const student = useStudentStore()

const classCode = ref('')
const joining = ref(false)
const error = ref('')
const success = ref(false)

async function handleJoin() {
  if (!classCode.value.trim() || !auth.userId) return
  joining.value = true
  error.value = ''
  try {
    await student.joinClass(auth.userId, classCode.value.trim())
    success.value = true
    setTimeout(() => router.push({ name: 'StudentHome' }), 1500)
  } catch (e: any) {
    error.value = e.message
  } finally {
    joining.value = false
  }
}
</script>

<template>
  <div class="min-h-screen bg-bg-dark flex flex-col safe-pt safe-pb">
    <header class="px-5 pt-4 pb-2">
      <button @click="router.back()" class="text-white/50 text-sm font-title">← 戻る</button>
    </header>

    <main class="flex-1 flex flex-col items-center justify-center px-8">
      <div v-if="success" class="text-center">
        <p class="text-5xl mb-4">🎉</p>
        <p class="text-white font-title font-bold text-xl">参加リクエスト送信！</p>
        <p class="text-white/50 text-sm font-title mt-2">先生の承認をお待ちください</p>
      </div>

      <div v-else class="w-full max-w-sm">
        <h1 class="text-white font-title font-bold text-2xl text-center mb-2">クラスに参加</h1>
        <p class="text-white/50 text-sm text-center mb-8">先生からもらったクラスコードを入力</p>

        <input
          v-model="classCode"
          type="text"
          placeholder="クラスコード（例: ABC123）"
          maxlength="6"
          class="w-full bg-bg-card text-white text-center text-2xl font-mono font-bold tracking-[0.5em] px-4 py-4 rounded-xl border border-white/10 focus:border-brand-primary focus:outline-none uppercase"
        />

        <p v-if="error" class="text-red-400 text-sm text-center mt-3">{{ error }}</p>

        <button
          @click="handleJoin"
          :disabled="classCode.length < 6 || joining"
          class="w-full mt-6 bg-brand-primary text-white font-title font-bold py-4 rounded-xl disabled:opacity-40 transition-opacity"
        >
          {{ joining ? '参加中...' : '参加する' }}
        </button>
      </div>
    </main>
  </div>
</template>
