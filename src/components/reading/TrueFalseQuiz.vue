<script setup lang="ts">
import type { ReadingQuiz } from '@/stores/reading'

const props = defineProps<{ quiz: ReadingQuiz; answered: number | null }>()
const emit = defineEmits<{ answer: [index: number] }>()

function choiceClass(i: number) {
  if (props.answered === null)
    return i === 0
      ? 'bg-bg-card border-white/[0.08] text-[#00FF88] active:scale-[0.97]'
      : 'bg-bg-card border-white/[0.08] text-[#FF6B9D] active:scale-[0.97]'
  if (i === props.quiz.answer_index) return 'bg-bg-card border-2 border-[#00FF88] text-white shadow-neo-sm'
  if (i === props.answered) return 'bg-bg-card border-2 border-[#FF6B9D] text-white/50 opacity-60'
  return 'bg-bg-card border-white/[0.08] text-white/30 opacity-40'
}
</script>

<template>
  <div>
    <p class="text-white/40 text-xs font-title mb-2">正しければ True、まちがっていれば False</p>
    <p class="text-white text-xl font-title font-bold mb-6 leading-relaxed">{{ quiz.question }}</p>
    <div class="grid grid-cols-2 gap-3">
      <button
        v-for="(label, i) in quiz.choices"
        :key="i"
        :disabled="answered !== null"
        @click="emit('answer', i)"
        class="py-6 rounded-3xl border text-lg font-title font-bold transition-all"
        :class="choiceClass(i)"
      >
        {{ label === 'True' ? '⭕ True' : '❌ False' }}
      </button>
    </div>
  </div>
</template>
