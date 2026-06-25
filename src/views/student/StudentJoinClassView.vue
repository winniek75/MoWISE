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
  <div class="min-h-screen bg-bg-dark flex flex-col safe-pt safe-pb relative overflow-hidden">
    <!-- Background glow -->
    <div class="absolute top-[20%] left-[10%] w-[300px] h-[300px] rounded-full bg-brand-primary/8 blur-[80px] animate-glow-pulse" />

    <header class="px-5 pt-4 pb-2 relative z-10">
      <button @click="router.back()" class="text-white/30 text-sm font-title hover:text-white/50 transition-colors">← 戻る</button>
    </header>

    <main class="flex-1 flex flex-col items-center justify-center px-8 relative z-10">
      <div v-if="success" class="text-center animate-pop-in">
        <div class="w-16 h-16 rounded-full bg-correct/15 flex items-center justify-center mx-auto mb-4">
          <svg class="w-8 h-8 text-correct" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5"><path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/></svg>
        </div>
        <p class="text-white font-title font-bold text-xl">参加リクエスト送信！</p>
        <p class="text-white/30 text-sm font-title mt-2">先生の承認をお待ちください</p>
      </div>

      <div v-else class="w-full max-w-sm">
        <h1 class="text-white font-title font-bold text-2xl text-center mb-2">クラスに参加</h1>
        <p class="text-white/30 text-sm text-center mb-8 font-title">先生からもらったクラスコードを入力</p>

        <input
          v-model="classCode"
          type="text"
          placeholder="ABC123"
          maxlength="6"
          class="neo-input !text-center !text-2xl !font-mono !font-bold !tracking-[0.5em] !py-5 uppercase"
        />

        <p v-if="error" class="text-neon-pink text-sm text-center mt-3">{{ error }}</p>

        <button
          @click="handleJoin"
          :disabled="classCode.length < 6 || joining"
          class="btn-neo w-full mt-6"
        >
          {{ joining ? '参加中...' : '参加する' }}
        </button>
      </div>
    </main>
  </div>
</template>
