<script setup lang="ts">
import { READING_STORAGE_BASE, type ReadingQuiz } from '@/stores/reading'

const props = defineProps<{ quiz: ReadingQuiz; bookNo: string; answered: number | null }>()
const emit = defineEmits<{ answer: [index: number] }>()

function imgUrl(file: string) {
  return `${READING_STORAGE_BASE}/${props.bookNo}/${file}`
}
function choiceClass(i: number) {
  if (props.answered === null) return 'border-white/[0.08] active:scale-[0.97]'
  if (i === props.quiz.answer_index) return 'border-2 border-[#00FF88] shadow-neo-sm'
  if (i === props.answered) return 'border-2 border-[#FF6B9D] opacity-60'
  return 'border-white/[0.08] opacity-40'
}
</script>

<template>
  <div>
    <p class="text-white text-lg font-title font-bold mb-4">{{ quiz.question }}</p>
    <div class="grid grid-cols-2 gap-3">
      <button
        v-for="(file, i) in quiz.choices"
        :key="i"
        :disabled="answered !== null"
        @click="emit('answer', i)"
        class="aspect-square rounded-3xl overflow-hidden bg-bg-card border transition-all"
        :class="choiceClass(i)"
      >
        <img
          :src="imgUrl(file)"
          :alt="`choice ${i + 1}`"
          class="w-full h-full object-cover"
          @error="($event.target as HTMLImageElement).outerHTML = `<div class='w-full h-full flex items-center justify-center text-white/30 text-xs font-title'>${['A','B','C','D'][i]}</div>`"
        />
      </button>
    </div>
  </div>
</template>
