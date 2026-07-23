<script setup lang="ts">
import { onMounted, computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useZukanStore } from '@/stores/zukan'
import { useAuthStore } from '@/stores/auth'
import BottomNav from '@/components/common/BottomNav.vue'

const router = useRouter()
const zukan = useZukanStore()
const auth = useAuthStore()

const loaded = ref(false)

onMounted(async () => {
  try {
    await zukan.fetchAll()
  } catch (e) {
    console.error('[AdventureMap] fetchAll:', e)
  } finally {
    loaded.value = true
  }
})

interface MapNode {
  patternNo: string
  label: string
  labelJa: string
  stars: number
  layer0: boolean
  layer1: boolean
  layer2: boolean
  layer3: boolean
  locked: boolean
  isCurrent: boolean
  isGate: boolean
}

const nodes = computed<MapNode[]>(() => {
  const allPatterns = zukan.patterns
  if (!allPatterns.length) return []

  const result: MapNode[] = []
  let foundCurrent = false

  for (const p of allPatterns) {
    const prog = zukan.progress[p.pattern_no]
    const stars = prog?.mastery_level ?? 0
    const l0 = prog?.layer0_done ?? false
    const l1 = prog?.layer1_done ?? false
    const l2 = prog?.layer2_done ?? false
    const l3 = prog?.layer3_done ?? false

    // Unlock: first pattern always unlocked, rest need previous pattern at ★1+
    const idx = result.length
    const prevNode = idx > 0 ? result[idx - 1] : null
    const locked = idx > 0 && (prevNode!.stars < 1 && !prevNode!.layer2)

    const isCurrent = !foundCurrent && !locked && stars < 5
    if (isCurrent) foundCurrent = true

    // Gate nodes at P005, P010, P015, P020 (production gate every 5 patterns)
    const num = parseInt(p.pattern_no.replace('P', ''))
    const isGate = num % 5 === 0

    result.push({
      patternNo: p.pattern_no,
      label: p.pattern_text ?? p.pattern_no,
      labelJa: p.japanese ?? '',
      stars,
      layer0: l0,
      layer1: l1,
      layer2: l2,
      layer3: l3,
      locked,
      isCurrent,
      isGate,
    })
  }
  return result
})

const currentNode = computed(() => nodes.value.find(n => n.isCurrent))

function goToSession(node: MapNode) {
  if (node.locked) return
  router.push({ path: '/session', query: { pattern: node.patternNo } })
}

function layerProgress(node: MapNode): number {
  let count = 0
  if (node.layer0) count++
  if (node.layer1) count++
  if (node.layer2) count++
  if (node.layer3) count++
  return count
}

function starIcons(stars: number): string {
  return '★'.repeat(stars) + '☆'.repeat(Math.max(0, 5 - stars))
}
</script>

<template>
  <div class="min-h-screen bg-bg-dark pb-28 safe-pt relative overflow-hidden">
    <!-- Background -->
    <div class="absolute top-0 left-[-10%] w-[300px] h-[300px] rounded-full bg-brand-primary/5 blur-[80px]" />
    <div class="absolute bottom-[30%] right-[-15%] w-[250px] h-[250px] rounded-full bg-brand-secondary/5 blur-[80px]" />

    <!-- Header -->
    <header class="px-5 pt-4 pb-2 relative z-10">
      <div class="flex items-center justify-between">
        <button @click="router.back()" class="text-white/40 text-sm font-title">← もどる</button>
        <h1 class="text-white text-lg font-title font-bold">ぼうけんマップ</h1>
        <div class="w-12" />
      </div>
    </header>

    <!-- Loading -->
    <div v-if="!loaded" class="flex flex-col items-center justify-center mt-20 gap-4">
      <div class="w-16 h-16 mowi-orb glow-low animate-float" />
      <p class="text-white/40 text-sm font-title">マップをよみこみちゅう...</p>
    </div>

    <template v-else>
      <!-- Today's Adventure Card -->
      <div v-if="currentNode" class="px-5 mt-3 relative z-10">
        <div
          class="neo-card !py-5 !px-5 border border-brand-primary/20 bg-brand-primary/[0.04] cursor-pointer active:scale-[0.98] transition-all"
          @click="goToSession(currentNode)"
        >
          <div class="flex items-center gap-4">
            <div class="w-14 h-14 mowi-orb glow-mid animate-float shrink-0" />
            <div class="flex-1 min-w-0">
              <p class="text-brand-secondary text-[10px] font-title font-bold tracking-widest uppercase">きょうのぼうけん</p>
              <p class="text-white font-title font-bold text-base mt-0.5 truncate">{{ currentNode.labelJa }}</p>
              <p class="text-white/30 text-xs font-title mt-0.5 truncate">{{ currentNode.label }}</p>
            </div>
            <div class="shrink-0">
              <div class="w-12 h-12 rounded-2xl bg-neo-gradient flex items-center justify-center text-white font-title font-bold text-lg shadow-neo-sm">
                GO
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Map Path -->
      <div class="px-5 mt-6 relative z-10">
        <div class="relative">
          <!-- Vertical path line -->
          <div class="absolute left-7 top-0 bottom-0 w-0.5 bg-white/[0.06]" />

          <!-- Nodes -->
          <div
            v-for="(node, idx) in nodes"
            :key="node.patternNo"
            class="relative flex items-start gap-4 mb-6 last:mb-0"
            :class="{ 'opacity-40': node.locked }"
          >
            <!-- Node circle -->
            <div
              class="relative z-10 w-14 h-14 rounded-full flex items-center justify-center shrink-0 border-2 transition-all duration-300"
              :class="[
                node.isCurrent
                  ? 'bg-brand-primary/20 border-brand-primary shadow-[0_0_20px_rgba(108,92,231,0.3)] animate-glow-pulse'
                  : node.stars >= 5
                    ? 'bg-neon-yellow/20 border-neon-yellow/50'
                    : node.stars >= 1
                      ? 'bg-correct/10 border-correct/30'
                      : node.locked
                        ? 'bg-white/[0.03] border-white/10'
                        : 'bg-white/[0.06] border-white/15',
              ]"
              @click="goToSession(node)"
            >
              <!-- Gate icon -->
              <template v-if="node.isGate && node.locked">
                <span class="text-xl">🚪</span>
              </template>
              <!-- Locked -->
              <template v-else-if="node.locked">
                <span class="text-lg text-white/20">🔒</span>
              </template>
              <!-- Completed (★5) -->
              <template v-else-if="node.stars >= 5">
                <span class="text-lg">💎</span>
              </template>
              <!-- Current node (Mowi) -->
              <template v-else-if="node.isCurrent">
                <div class="w-10 h-10 mowi-orb glow-mid" />
              </template>
              <!-- In progress -->
              <template v-else-if="node.stars >= 1">
                <span class="text-white font-title font-bold text-sm">{{ node.stars }}</span>
              </template>
              <!-- Not started -->
              <template v-else>
                <span class="text-white/30 font-title text-sm">{{ idx + 1 }}</span>
              </template>
            </div>

            <!-- Node info -->
            <div
              class="flex-1 min-w-0 pt-1"
              :class="{ 'cursor-pointer': !node.locked }"
              @click="goToSession(node)"
            >
              <div class="flex items-center gap-2">
                <p class="text-white font-title font-semibold text-sm truncate" :class="{ 'text-white/30': node.locked }">
                  {{ node.labelJa }}
                </p>
                <span v-if="node.isCurrent" class="text-[10px] font-title font-bold text-brand-primary bg-brand-primary/15 px-2 py-0.5 rounded-full shrink-0">
                  つぎはここ！
                </span>
              </div>
              <p class="text-white/20 text-xs font-title truncate mt-0.5">{{ node.label }}</p>

              <!-- Stars + Layer progress -->
              <div v-if="!node.locked" class="flex items-center gap-3 mt-1.5">
                <span class="text-xs" :class="node.stars >= 5 ? 'text-neon-yellow' : node.stars >= 1 ? 'text-neon-yellow/60' : 'text-white/15'">
                  {{ starIcons(node.stars) }}
                </span>
                <!-- Layer dots -->
                <div class="flex gap-1">
                  <div
                    v-for="l in 4"
                    :key="l"
                    class="w-2 h-2 rounded-full"
                    :class="[
                      l === 1 && node.layer0 ? 'bg-correct' :
                      l === 2 && node.layer1 ? 'bg-correct' :
                      l === 3 && node.layer2 ? 'bg-neon-yellow' :
                      l === 4 && node.layer3 ? 'bg-neon-pink' :
                      'bg-white/10'
                    ]"
                  />
                </div>
              </div>

              <!-- Gate message -->
              <div v-if="node.isGate && !node.locked && node.stars < 4" class="mt-2 flex items-start gap-2">
                <div class="w-5 h-5 mowi-orb glow-low shrink-0 mt-0.5" />
                <p class="text-white/40 text-[11px] font-title leading-snug">
                  じぶんのことばで いえたら<br>つぎのとびらが ひらくよ！
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Empty state -->
      <div v-if="nodes.length === 0" class="px-5 mt-12 text-center relative z-10">
        <div class="w-16 h-16 mowi-orb glow-low mx-auto mb-4 animate-float" />
        <p class="text-white/40 text-sm font-title">パターンデータをよみこめませんでした</p>
      </div>
    </template>

    <BottomNav />
  </div>
</template>
