<template>
  <div class="min-h-screen bg-gradient-to-b from-[#0d0d1a] to-[#1a1040] text-white flex flex-col">

    <!-- ヘッダー -->
    <header class="flex items-center justify-between px-4 pt-safe pt-4 pb-2">
      <button @click="confirmExit" class="text-white/60 text-sm px-2 py-1">× 終了</button>
      <div class="text-sm font-bold text-white/80">{{ currentPatternId }} つくる SVO</div>
      <div class="text-sm text-white/60">{{ currentIndex + 1 }}/{{ questions.length }}問</div>
    </header>

    <!-- コンボゲージ -->
    <div class="px-4 mb-3">
      <div class="flex items-center justify-between mb-1">
        <span class="text-xs text-white/50">COMBO</span>
        <span class="text-sm font-bold text-white/70">{{ combo }}</span>
      </div>
      <div class="h-2.5 bg-white/10 rounded-full overflow-hidden">
        <div
          class="h-full rounded-full transition-all duration-200 ease-out"
          :class="combo >= 5 ? 'bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400'
                : combo >= 3 ? 'bg-blue-400'
                : 'bg-gray-400'"
          :style="{ width: `${Math.min(combo * 10, 100)}%` }"
        ></div>
      </div>
    </div>

    <!-- Mowiエリア -->
    <div class="flex flex-col items-center py-3">
      <MowiOrb :brightness="mowiGlow" :emotion="mowiEmotion" class="w-20 h-20" />
      <p v-if="mowiLine" class="mt-1.5 text-sm text-white/60 text-center">{{ mowiLine }}</p>
    </div>

    <!-- 日本語提示 -->
    <div class="mx-4 mb-3 bg-white/10 rounded-xl px-4 py-3 text-center">
      <span class="text-base font-bold">🇯🇵 {{ currentQuestion?.japanese }}</span>
    </div>

    <!-- SVOスロット -->
    <div class="mx-4 mb-4">
      <p class="text-xs text-white/40 mb-2 text-center">文を作ってみて。</p>
      <div class="flex gap-2 justify-center flex-wrap">
        <!-- 固定語・可変スロット -->
        <template v-for="(slot, i) in allSlots" :key="`slot-${i}`">
          <div
            v-if="slot.fixed"
            class="px-3 py-2 rounded-xl text-sm font-bold bg-white/10 text-white/40"
          >{{ slot.word }}</div>
          <div
            v-else
            class="px-3 py-2 rounded-xl text-sm font-bold min-w-[60px] text-center border-2 transition-all duration-200"
            :class="slot.filled
              ? svoSlotClass(slot.role) + ' border-transparent cursor-pointer'
              : 'bg-white/5 border-white/20 text-white/30'"
            :style="{ minWidth: `${Math.max(slot.word.length * 12 + 24, 64)}px` }"
            @click="slot.filled ? clearSlot(i) : null"
          >
            {{ slot.filled ? slot.word : '' }}
          </div>
        </template>
      </div>
    </div>

    <!-- 単語ブロック -->
    <div class="mx-4 mb-4">
      <p class="text-xs text-white/40 mb-2 text-center">単語ブロック（タップで選択）</p>
      <div class="flex flex-wrap gap-2 justify-center">
        <button
          v-for="(block, i) in wordBlocks"
          :key="i"
          :disabled="block.used"
          @click="selectBlock(block, i)"
          class="px-4 py-2.5 rounded-xl text-sm font-bold transition-all duration-150 active:scale-95"
          :class="block.used ? 'opacity-30 cursor-not-allowed ' + svoBlockBg(block.role)
                             : svoBlockBg(block.role) + ' hover:brightness-110'"
        >
          {{ block.word }}
        </button>
      </div>
    </div>

    <!-- 送信ボタン -->
    <div class="mx-4 mb-6">
      <button
        @click="submitAnswer"
        :disabled="!allSlotsFilled"
        class="w-full py-3.5 rounded-2xl font-bold text-base transition-all duration-200"
        :class="allSlotsFilled ? 'bg-indigo-500 hover:bg-indigo-400 text-white' : 'bg-white/10 text-white/30'"
      >
        ✓ 送信
      </button>
    </div>

    <!-- 終了確認ダイアログ -->
    <div v-if="showExitDialog" class="fixed inset-0 bg-black/60 flex items-center justify-center z-50">
      <div class="bg-[#1a1040] border border-white/20 rounded-2xl p-6 mx-8 text-center">
        <p class="font-bold text-lg mb-1">練習を終了しますか？</p>
        <p class="text-sm text-white/50 mb-6">今回の記録は保存されます</p>
        <div class="flex gap-3">
          <button @click="showExitDialog = false" class="flex-1 py-2.5 rounded-xl border border-white/20 text-sm">続ける</button>
          <button @click="exitSession" class="flex-1 py-2.5 rounded-xl bg-indigo-500 text-sm font-bold">はい</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useSessionStore } from '@/stores/session'
import { useMowiStore } from '@/stores/mowi'
import { supabase } from '@/lib/supabase'
import MowiOrb from '@/components/mowi/MowiOrb.vue'

const router       = useRouter()
const sessionStore = useSessionStore()
const mowiStore    = useMowiStore()

const questions      = ref<any[]>([])
const currentIndex   = ref(0)
const combo          = ref(0)
const mowiLine       = ref('この並びを体に聞かせてみて。')
const mowiEmotion    = ref<'idle'|'joy'|'sad'|'cheer'>('cheer')
const showExitDialog = ref(false)
const sessionLogs    = ref<any[]>([])

// スロット構造：固定語 + 可変スロット
const allSlots  = ref<{ word: string; role: string; fixed: boolean; filled: boolean }[]>([])
const wordBlocks = ref<{ word: string; role: string; used: boolean }[]>([])

const currentPatternId = computed(() => sessionStore.currentPattern?.patternId ?? 'P001')
const currentQuestion  = computed(() => questions.value[currentIndex.value])
const allSlotsFilled   = computed(() => allSlots.value.filter(s => !s.fixed).every(s => s.filled))
const mowiGlow = computed(() => combo.value >= 5 ? 7 : combo.value >= 3 ? 5 : 3)

onMounted(async () => {
  const { data } = await supabase
    .from('pattern_content')
    .select('layer_2_questions')
    .eq('pattern_id', currentPatternId.value)
    .single()
  questions.value = data?.layer_2_questions ?? []
  setupQuestion()
})

function setupQuestion() {
  const q = currentQuestion.value
  if (!q) return
  // スロット構築（固定語 + 空スロット）
  allSlots.value = q.slots.map((s: any) => ({
    word: s.fixed ? s.word : '',
    role: s.role,
    fixed: s.fixed,
    filled: s.fixed,
  }))
  // ブロック（正解 + ダミー シャッフル）
  const all = [...q.answer_blocks, ...(q.dummy_blocks ?? [])].sort(() => Math.random() - 0.5)
  wordBlocks.value = all.map((b: any) => ({ word: b.word, role: b.role, used: false }))
}

function selectBlock(block: { word: string; role: string; used: boolean }, _i: number) {
  const slot = allSlots.value.find(s => !s.fixed && !s.filled)
  if (!slot) return
  block.used = true
  slot.filled = true
  slot.word = block.word
}

function clearSlot(slotIndex: number) {
  const slot = allSlots.value[slotIndex]
  if (slot.fixed) return
  const block = wordBlocks.value.find(b => b.word === slot.word && b.used)
  if (block) block.used = false
  slot.filled = false
  slot.word = ''
}

function submitAnswer() {
  if (!allSlotsFilled.value) return
  const responseMs = 3000 // SVO は時間無制限、固定値で記録
  const userAnswer = allSlots.value.map(s => s.word).join(' ')
  const correct    = userAnswer === currentQuestion.value?.answer

  sessionLogs.value.push({ pattern_id: currentPatternId.value, is_correct: correct, response_ms: responseMs, layer: 2 })

  if (correct) {
    combo.value++
    mowiEmotion.value = 'joy'
    mowiLine.value = ['その感じ。', 'ちゃんと並んでる。', '感覚が通ってきた。'][Math.floor(Math.random() * 3)]
    setTimeout(nextQuestion, 700)
  } else {
    combo.value = 0
    mowiEmotion.value = 'sad'
    mowiLine.value = '…なんか変。'
    // スロットをリセット
    allSlots.value.forEach(s => { if (!s.fixed) { s.filled = false; s.word = '' } })
    wordBlocks.value.forEach(b => b.used = false)
  }
}

function nextQuestion() {
  if (currentIndex.value < questions.value.length - 1) {
    currentIndex.value++
    setupQuestion()
    mowiLine.value = 'この並びを体に聞かせてみて。'
    mowiEmotion.value = 'cheer'
  } else {
    finishSession()
  }
}

async function finishSession() {
  if (sessionLogs.value.length > 0) await supabase.from('flash_output_logs').insert(sessionLogs.value)
  const { data: { user } } = await supabase.auth.getUser()
  await supabase.from('pattern_progress').upsert(
    { user_id: user!.id, pattern_id: currentPatternId.value, layer_2_cleared: true, star_level: 3, last_attempted_at: new Date().toISOString() },
    { onConflict: 'user_id,pattern_id' }
  )
  router.push({ name: 'session-end' })
}

function confirmExit() { showExitDialog.value = true }
async function exitSession() {
  if (sessionLogs.value.length > 0) await supabase.from('flash_output_logs').insert(sessionLogs.value)
  router.push({ name: 'session-end' })
}

// SVO色クラス
function svoSlotClass(role: string): string {
  const map: Record<string, string> = { S: 'bg-blue-500 text-white', V: 'bg-red-500 text-white', O: 'bg-yellow-400 text-black' }
  return map[role] ?? 'bg-white/20 text-white'
}
function svoBlockBg(role: string): string {
  const map: Record<string, string> = { S: 'bg-blue-500/70 text-white', V: 'bg-red-500/70 text-white', O: 'bg-yellow-400/70 text-black', fixed: 'bg-white/10 text-white/60' }
  return map[role] ?? 'bg-white/20 text-white'
}
</script>
