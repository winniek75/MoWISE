<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { supabase } from '@/lib/supabase'

const router  = useRouter()
const auth    = useAuthStore()
const code    = ref('')
const error   = ref('')
const loading = ref(false)

async function joinClass() {
  if (!code.value.trim()) { skip(); return }
  loading.value = true
  error.value = ''
  const { data: cls } = await supabase
    .from('classes')
    .select('id, class_name')
    .eq('class_code', code.value.trim().toUpperCase())
    .eq('status', 'active')
    .single()

  if (!cls) {
    error.value = 'クラスコードが見つかりません。'
    loading.value = false; return
  }

  await supabase.from('class_members').insert({
    class_id:       cls.id,
    user_id:        auth.userId!,
    status:         'pending',
    joined_via_code: code.value.trim(),
  })
  loading.value = false
  router.push({ name: 'Onboarding4' })
}

function skip() {
  router.push({ name: 'Onboarding4' })
}
</script>

<template>
  <div class="min-h-screen flex flex-col safe-pt safe-pb px-6 py-10 gap-8">
    <div class="flex items-center gap-3">
      <button class="text-white/40 text-2xl" @click="$router.back()">←</button>
      <span class="font-title text-white/60 text-sm">クラスに参加</span>
    </div>

    <div class="flex-1 flex flex-col justify-center gap-6 max-w-sm mx-auto w-full">
      <div class="space-y-2">
        <h2 class="font-title text-2xl font-bold text-white">先生からの<br/>クラスコード</h2>
        <p class="text-white/50 text-sm leading-relaxed">
          英語教室の先生からもらった<br/>6桁のコードを入力してください。
        </p>
      </div>

      <div class="space-y-1">
        <input
          v-model="code"
          type="text"
          placeholder="例：ABC123"
          maxlength="6"
          class="w-full bg-bg-surface border border-white/20 rounded-xl px-4 py-4 text-white text-center text-2xl font-title tracking-widest placeholder-white/20 focus:border-brand-primary outline-none uppercase"
        />
        <p v-if="error" class="text-wrong text-sm text-center">{{ error }}</p>
      </div>

      <button class="btn-primary w-full font-title" :disabled="loading" @click="joinClass">
        {{ loading ? '参加中…' : 'クラスに参加する →' }}
      </button>

      <button class="text-white/40 text-sm text-center underline" @click="skip">
        コードがない・あとで入力する
      </button>
    </div>
  </div>
</template>
