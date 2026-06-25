<script setup lang="ts">
const props = defineProps<{
  gameId: string
  category?: string
  size?: 'sm' | 'md' | 'lg'
}>()

const sizeMap = {
  sm: 'w-8 h-8 rounded-xl',
  md: 'w-12 h-12 rounded-2xl',
  lg: 'w-16 h-16 rounded-2xl',
}

const iconSize = {
  sm: 'w-4 h-4',
  md: 'w-6 h-6',
  lg: 'w-8 h-8',
}

const catClass = `cat-${props.category || 'mixed'}`
const sz = props.size || 'md'

// SVG path data per game (Lucide-style, 24x24 viewBox, stroke)
const icons: Record<string, string> = {
  // --- vocabulary ---
  'eiken-game':
    'M4 19.5v-15A2.5 2.5 0 016.5 2H20v20H6.5a2.5 2.5 0 010-5H20 M8 7h6 M8 11h4',
  'fallingwordbattle':
    'M13 2L3 14h9l-1 8 10-12h-9l1-8',
  'flashinput':
    'M4 7V4h16v3 M9 20h6 M12 4v16 M7.5 12.5L12 8l4.5 4.5',
  'eiken-sns-app':
    'M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z M8 10h.01 M12 10h.01 M16 10h.01',
  'eiken-challenge':
    'M6 9H4.5a2.5 2.5 0 010-5C4.5 4 5.1 3 6 3h12c.9 0 1.5 1 1.5 1a2.5 2.5 0 010 5H18 M6 9v10a2 2 0 002 2h8a2 2 0 002-2V9 M6 9h12 M10 13h4',

  // --- grammar ---
  'verbform-battle':
    'M14.5 17.5L3 6V3h3l11.5 11.5 M13 19l6-6 M7 3L3 7 M17 3l4 4 M14 16l-2 6 M10 8L4 14',
  'grammar-drill':
    'M10 2v7.527a2 2 0 01-.211.896L4.72 20.55a1 1 0 00.9 1.45h12.76a1 1 0 00.9-1.45l-5.069-10.127A2 2 0 0114 9.527V2 M8.5 2h7',
  'grammar-app':
    'M2 3h6a4 4 0 014 4v14a3 3 0 00-3-3H2z M22 3h-6a4 4 0 00-4 4v14a3 3 0 013-3h7z',
  'eiken-grammar-game':
    'M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z M12 8v4l3 3',
  'aredo-game':
    'M19.439 5.439A4.97 4.97 0 0016 4a4.97 4.97 0 00-4 2 4.97 4.97 0 00-4-2 4.97 4.97 0 00-3.439 1.439 M3 11h18 M3 11v6a4 4 0 004 4h10a4 4 0 004-4v-6 M12 11v10',
  'wh-questiongame':
    'M9.09 9a3 3 0 015.83 1c0 2-3 3-3 3 M12 17h.01 M12 22c5.523 0 10-4.477 10-10S17.523 2 12 2 2 6.477 2 12s4.477 10 10 10z',

  // --- phonics ---
  'phonics':
    'M9 18V5l12-2v13 M9 9l12-2 M6 21a3 3 0 100-6 3 3 0 000 6z M18 18a3 3 0 100-6 3 3 0 000 6z',
  'phonics-battle':
    'M11 4H4a2 2 0 00-2 2v14a2 2 0 002 2h14a2 2 0 002-2v-7 M18.5 2.5a2.121 2.121 0 013 3L12 15l-4 1 1-4 9.5-9.5z',
  'phonics-sounds':
    'M11 5L6 9H2v6h4l5 4V5z M15.54 8.46a5 5 0 010 7.07 M19.07 4.93a10 10 0 010 14.14',
  'sight-words-memory':
    'M9.5 2A2.5 2.5 0 0112 4.5v.793c.993.264 1.928.7 2.755 1.293 M14.5 2A2.5 2.5 0 0012 4.5 M2 12c1-.5 3-2 6-2s5 1.5 6 2c1-.5 3-2 6-2 M2 17c1-.5 3-2 6-2s5 1.5 6 2c1-.5 3-2 6-2',

  // --- writing ---
  'instant-english-app':
    'M12 19l7-7 3 3-7 7-3-3z M18 13l-1.5-7.5L2 2l3.5 14.5L13 18l5-5z M2 2l7.586 7.586 M11 13a2 2 0 110-4 2 2 0 010 4z',
  'sentence-dash':
    'M13 2L3 14h9l-1 8 10-12h-9l1-8',

  // --- mixed ---
  'wise-english-floor':
    'M3 21h18 M3 7v14 M21 7v14 M5 7V4h14v3 M9 21v-4h6v4 M9 7v4 M15 7v4 M5 11h14',
}

// Fallback: first letter
const fallbackLetter = (props.gameId || '?').charAt(0).toUpperCase()
</script>

<template>
  <div class="game-icon" :class="[catClass, sizeMap[sz]]">
    <svg
      v-if="icons[gameId]"
      :class="iconSize[sz]"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2"
      stroke-linecap="round"
      stroke-linejoin="round"
      class="text-white drop-shadow-sm"
    >
      <path :d="icons[gameId]" />
    </svg>
    <span v-else class="text-white font-title font-bold" :class="sz === 'sm' ? 'text-xs' : sz === 'lg' ? 'text-xl' : 'text-sm'">
      {{ fallbackLetter }}
    </span>
  </div>
</template>
