<script setup lang="ts">
import type { ReadingQuiz } from '@/stores/reading'

const props = defineProps<{ quiz: ReadingQuiz; answered: number | null }>()
const emit = defineEmits<{ answer: [index: number] }>()

const FORMAT_HINT: Record<string, string> = {
  vocab_mc: '語彙問題（英検形式）',
  cloze_mc: '空所補充（TOEIC形式）',
  comprehension_mc: '内容一致',
}

function choiceClass(i: number) {
  if (props.answered === null) return 'border-white/[0.08] text-white/80 active:scale-[0.98]'
  if (i === props.quiz.answer_index) return 'border-2 border-[#00FF88] text-white shadow-neo-sm'
  if (i === props.answered) return 'border-2 border-[#FF6B9D] text-white/50 opacity-60'
  return 'border-white/[0.08] text-white/30 opacity-40'
}
</script>

<template>
  <div>
    <p class="text-white/40 text-xs font-title mb-2">{{ FORMAT_HINT[quiz.format] ?? '' }}</p>
    <p class="text-white text-lg font-title font-bold mb-5 leading-relaxed whitespace-pre-line">{{ quiz.question }}</p>
    <div class="flex flex-col gap-3">
      <button
        v-for="(choice, i) in quiz.choices"
        :key="i"
        :disabled="answered !== null"
        @click="emit('answer', i)"
        class="w-full text-left px-4 py-3.5 rounded-2xl bg-bg-card border text-sm font-title transition-all"
        :class="choiceClass(i)"
      >
        <span class="text-white/30 font-bold mr-2">{{ ['A', 'B', 'C', 'D'][i] }}</span>{{ choice }}
      </button>
    </div>
  </div>
</template>
