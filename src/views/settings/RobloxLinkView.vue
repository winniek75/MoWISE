<template>
  <div class="min-h-screen bg-gray-50 pb-24">
    <!-- ヘッダ -->
    <header class="bg-white border-b border-gray-200 px-4 py-3 flex items-center gap-3">
      <button @click="router.push({ name: 'Settings' })" class="text-gray-500 text-sm font-bold">← 戻る</button>
      <h1 class="text-lg font-bold text-gray-900">⚙ 設定 &gt; Roblox 連携</h1>
    </header>

    <main class="px-4 py-6 space-y-6">
      <!-- Mowi 表示 + セリフ -->
      <section class="flex flex-col items-center gap-4 pt-2">
        <MowiOrb :state="mowiState" :brightness="7" size="md" />
        <p class="text-base text-gray-800 text-center font-medium leading-relaxed whitespace-pre-line">{{ mowiSpeech }}</p>
      </section>

      <!-- コード入力エリア -->
      <section v-if="!isSuccess">
        <div class="flex justify-center gap-2">
          <input
            v-for="(_, i) in 6"
            :key="i"
            :ref="el => { if (el) inputRefs[i] = el as HTMLInputElement }"
            v-model="digits[i]"
            type="text"
            inputmode="text"
            autocapitalize="characters"
            autocomplete="off"
            spellcheck="false"
            maxlength="1"
            class="w-12 h-14 text-center text-2xl font-bold text-gray-900 bg-white border-2 rounded-xl focus:outline-none focus:border-indigo-500 disabled:opacity-50"
            :class="errorMessage ? 'border-red-300' : 'border-gray-200'"
            :disabled="isSubmitting"
            @input="onInput(i, $event)"
            @keydown="onKeydown(i, $event)"
            @paste="onPaste(i, $event)"
            @focus="onFocus($event)"
          />
        </div>

        <!-- インラインエラー -->
        <p v-if="errorMessage" class="mt-3 text-sm text-red-600 text-center" role="alert">{{ errorMessage }}</p>

        <!-- 連携ボタン -->
        <button
          class="mt-6 w-full h-14 rounded-2xl font-bold text-base text-white transition-all"
          :class="canSubmit
            ? 'bg-gradient-to-r from-[#4A7AFF] to-[#9B5CF6] active:scale-[0.98]'
            : 'bg-gray-300 cursor-not-allowed'"
          :disabled="!canSubmit"
          @click="submit"
        >
          <span v-if="isSubmitting" class="inline-flex items-center gap-2">
            <span class="w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            連携中...
          </span>
          <span v-else>✅ 連携する</span>
        </button>

        <!-- 注意書き -->
        <p class="mt-4 text-xs text-gray-500 text-center leading-relaxed">
          ⚠️ Roblox のアカウントと紐付けます。<br />
          一度連携すると変更できません。
        </p>
      </section>

      <!-- 連携成功オーバーレイ -->
      <section v-else class="flex flex-col items-center gap-3 pt-4">
        <p class="text-xs text-gray-400">この画面は自動で閉じます</p>
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, nextTick } from 'vue'
import { useRouter } from 'vue-router'
import MowiOrb from '@/components/mowi/MowiOrb.vue'
import { useRobloxLink } from '@/composables/useRobloxLink'
import type { LinkVerifyErrorCode } from '@/composables/useRobloxLink'
import type { MowiEmotionState } from '@/stores/mowi'

const router = useRouter()
const { verifyLinkCode } = useRobloxLink()

const ALLOWED_CHARS = /^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]$/

const digits = ref<string[]>(['', '', '', '', '', ''])
const inputRefs: HTMLInputElement[] = []
const isSubmitting = ref(false)
const isSuccess = ref(false)
const errorMessage = ref('')
const errorCode = ref<LinkVerifyErrorCode | ''>('')

const canSubmit = computed(() => digits.value.every(d => d.length === 1) && !isSubmitting.value)

const mowiState = computed<MowiEmotionState>(() => {
  if (isSuccess.value) return 'joy'
  if (errorCode.value === 'UNKNOWN') return 'sleep'
  if (errorCode.value) return 'think'
  return 'grow'
})

const mowiSpeech = computed(() => {
  if (isSuccess.value) return 'MoWISE Town とつながった。'
  return 'MoWISE Town とつながる。'
})

function clearError() {
  errorMessage.value = ''
  errorCode.value = ''
}

function onFocus(e: FocusEvent) {
  const target = e.target as HTMLInputElement
  target.select()
}

function onInput(index: number, e: Event) {
  const target = e.target as HTMLInputElement
  const raw = (target.value || '').toUpperCase()

  // 紛らわしい文字を弾く + 単一文字制限
  const char = raw.split('').find(c => ALLOWED_CHARS.test(c)) ?? ''
  digits.value[index] = char

  if (char) {
    clearError()
    // 次マスへ移動
    if (index < 5) {
      nextTick(() => inputRefs[index + 1]?.focus())
    }
  } else {
    // 弾かれた場合は表示を空に同期
    target.value = ''
  }
}

function onKeydown(index: number, e: KeyboardEvent) {
  if (e.key === 'Backspace' && !digits.value[index] && index > 0) {
    e.preventDefault()
    nextTick(() => {
      inputRefs[index - 1]?.focus()
      digits.value[index - 1] = ''
    })
  } else if (e.key === 'ArrowLeft' && index > 0) {
    e.preventDefault()
    inputRefs[index - 1]?.focus()
  } else if (e.key === 'ArrowRight' && index < 5) {
    e.preventDefault()
    inputRefs[index + 1]?.focus()
  } else if (e.key === 'Enter' && canSubmit.value) {
    e.preventDefault()
    submit()
  }
}

function onPaste(index: number, e: ClipboardEvent) {
  e.preventDefault()
  const text = (e.clipboardData?.getData('text') || '').toUpperCase()
  const chars = text.split('').filter(c => ALLOWED_CHARS.test(c)).slice(0, 6)
  if (chars.length === 0) return

  // index から順番に埋める
  for (let i = 0; i < chars.length && (index + i) < 6; i++) {
    digits.value[index + i] = chars[i]
  }
  clearError()

  // 最後に埋めた位置の次にフォーカス
  const nextPos = Math.min(index + chars.length, 5)
  nextTick(() => inputRefs[nextPos]?.focus())
}

async function submit() {
  if (!canSubmit.value) return
  clearError()
  isSubmitting.value = true

  const code = digits.value.join('')
  const { data, error } = await verifyLinkCode(code)

  isSubmitting.value = false

  if (error) {
    errorCode.value = error.code
    errorMessage.value = error.message
    return
  }

  if (data?.linked) {
    isSuccess.value = true
    // 2 秒後に Settings 画面へ自動遷移
    setTimeout(() => {
      router.push({ name: 'Settings' })
    }, 2000)
  }
}

onMounted(() => {
  nextTick(() => inputRefs[0]?.focus())
})
</script>
