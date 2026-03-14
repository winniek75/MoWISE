<template>
  <div
    class="mowi-orb-wrapper"
    :class="[`size-${size}`, `state-${state}`]"
    :style="wrapperStyle"
  >
    <!-- 外側グロー -->
    <div class="mowi-glow" :style="glowStyle" />

    <!-- オーブ本体 -->
    <div class="mowi-orb" :style="orbStyle">

      <!-- 内部グラデーション層 -->
      <div class="orb-inner" />

      <!-- 目 -->
      <div class="mowi-eyes">
        <div class="eye left" :class="eyeClass" />
        <div class="eye right" :class="eyeClass" />
      </div>

      <!-- 感情ステート別オーバーレイ -->
      <Transition name="overlay-fade">
        <div v-if="state === 'joy'" class="state-overlay joy-overlay" />
        <div v-else-if="state === 'sad'" class="state-overlay sad-overlay" />
        <div v-else-if="state === 'grow'" class="state-overlay grow-overlay" />
      </Transition>
    </div>

    <!-- リング（grow/高brightnessのみ） -->
    <div v-if="showRings" class="mowi-rings">
      <div
        v-for="i in ringCount"
        :key="i"
        class="ring"
        :style="ringStyle(i)"
      />
    </div>

    <!-- 光のパーティクル（joy/growのみ） -->
    <div v-if="showParticles" class="particles">
      <div
        v-for="i in 6"
        :key="i"
        class="particle"
        :style="particleStyle(i)"
      />
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import type { MowiEmotionState } from '@/stores/mowi'

// ─── Props ────────────────────────────────────────────────────
interface Props {
  state?: MowiEmotionState
  brightness?: number          // 0-10
  size?: 'sm' | 'md' | 'lg'
  animated?: boolean
  grayscale?: number           // 0-100 (%)
}

const props = withDefaults(defineProps<Props>(), {
  state: 'idle',
  brightness: 5,
  size: 'md',
  animated: true,
  grayscale: 0,
})

// ─── Computed ─────────────────────────────────────────────────

/** brightness (0-10) をアルファ・サイズに変換 */
const b = computed(() => props.brightness / 10)

/** オーブの基本カラー（brightnessに応じてグラデーション変化）*/
const orbColor = computed(() => {
  const bright = props.brightness
  if (bright >= 10) return 'conic-gradient(from 0deg, #FF6B6B, #FFD93D, #6BCB77, #4D96FF, #C77DFF, #FF6B6B)'
  if (bright >= 7)  return 'radial-gradient(circle at 40% 35%, #FFB347 0%, #FF6B35 40%, #C2185B 100%)'
  if (bright >= 5)  return 'radial-gradient(circle at 40% 35%, #A78BFA 0%, #7C3AED 40%, #4C1D95 100%)'
  if (bright >= 3)  return 'radial-gradient(circle at 40% 35%, #60A5FA 0%, #2563EB 40%, #1E3A8A 100%)'
  return 'radial-gradient(circle at 40% 35%, #818CF8 0%, #4338CA 40%, #1e1b4b 100%)'
})

/** グロー色 */
const glowColor = computed(() => {
  const bright = props.brightness
  if (bright >= 10) return 'rgba(255, 220, 100, 0.6)'
  if (bright >= 7)  return 'rgba(255, 150, 50, 0.5)'
  if (bright >= 5)  return 'rgba(139, 92, 246, 0.5)'
  if (bright >= 3)  return 'rgba(96, 165, 250, 0.4)'
  return 'rgba(74, 122, 255, 0.3)'
})

// サイズ設定
const sizeMap = { sm: 48, md: 120, lg: 160 }
const orbPx = computed(() => sizeMap[props.size] ?? 120)

const wrapperStyle = computed(() => ({
  width: `${orbPx.value}px`,
  height: `${orbPx.value}px`,
  filter: props.grayscale > 0 ? `grayscale(${props.grayscale}%)` : undefined,
}))

const orbStyle = computed(() => ({
  background: orbColor.value,
  boxShadow: `0 0 ${orbPx.value * 0.3}px ${glowColor.value}`,
  animation: props.animated ? orbAnimation.value : 'none',
}))

const glowStyle = computed(() => ({
  background: `radial-gradient(circle, ${glowColor.value} 0%, transparent 70%)`,
  opacity: b.value,
  transform: `scale(${1 + b.value * 0.5})`,
}))

const eyeClass = computed(() => ({
  'eye-joy':   props.state === 'joy' || props.state === 'grow',
  'eye-sad':   props.state === 'sad',
  'eye-think': props.state === 'think' || props.state === 'sleep',
}))

const orbAnimation = computed(() => {
  switch (props.state) {
    case 'joy':   return 'mowi-bounce 0.6s cubic-bezier(0.36, 0.07, 0.19, 0.97) both'
    case 'sad':   return 'mowi-droop 0.8s ease both, mowi-float 4s ease-in-out 0.8s infinite'
    case 'grow':  return 'mowi-pulse 0.4s ease both, mowi-float 3s ease-in-out 0.4s infinite'
    case 'think': return 'mowi-tilt 2s ease-in-out infinite, mowi-float 4s ease-in-out infinite'
    case 'sleep': return 'mowi-float 6s ease-in-out infinite'
    default:      return 'mowi-float 4s ease-in-out infinite'
  }
})

const showRings = computed(() =>
  (props.state === 'grow' || props.brightness >= 7) && props.size !== 'sm'
)
const ringCount = computed(() => Math.min(Math.floor(props.brightness / 2) + 1, 4))

function ringStyle(i: number) {
  const delay = (i - 1) * 0.3
  return {
    animation: `ring-expand 1.5s ease-out ${delay}s infinite`,
    '--ring-scale': 1 + i * 0.35,
    borderColor: glowColor.value,
  }
}

const showParticles = computed(() =>
  (props.state === 'joy' || props.state === 'grow') && props.size !== 'sm'
)

function particleStyle(i: number) {
  return {
    '--angle': `${(i - 1) * 60}deg`,
    animation: `particle-fly 1.2s ease-out ${(i - 1) * 0.1}s both`,
  }
}
</script>

<style scoped>
.mowi-orb-wrapper {
  position: relative;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.mowi-glow {
  position: absolute;
  inset: -40%;
  border-radius: 50%;
  pointer-events: none;
  transition: opacity 0.8s ease, transform 0.8s ease;
}

.mowi-orb {
  width: 100%;
  height: 100%;
  border-radius: 50%;
  position: relative;
  overflow: hidden;
  transition: box-shadow 0.8s ease;
}

.orb-inner {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  background: radial-gradient(
    circle at 30% 25%,
    rgba(255, 255, 255, 0.35) 0%,
    transparent 55%
  );
}

.mowi-eyes {
  position: absolute;
  top: 42%;
  left: 50%;
  transform: translate(-50%, -50%);
  display: flex;
  gap: 28%;
  width: 55%;
}

.eye {
  width: 22%;
  aspect-ratio: 1;
  border-radius: 50%;
  background: #0d0d1a;
  transition: all 0.3s ease;
  position: relative;
}

.eye::after {
  content: '';
  position: absolute;
  top: 15%;
  left: 20%;
  width: 35%;
  height: 35%;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.6);
}

.eye.eye-joy {
  background: #0d0d1a;
  box-shadow: 0 0 4px rgba(255, 220, 100, 0.8);
}

.eye.eye-sad {
  transform: scaleY(0.5) translateY(30%);
  background: #1a0d1a;
}

.eye.eye-think {
  background: #0d0d24;
  animation: eye-think-blink 3s ease-in-out infinite;
}

.state-overlay {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  pointer-events: none;
}

.joy-overlay {
  background: radial-gradient(circle at 50% 50%, rgba(255, 215, 0, 0.2) 0%, transparent 70%);
  animation: joy-pulse 0.6s ease both;
}

.sad-overlay {
  background: linear-gradient(to bottom, transparent 0%, rgba(0, 0, 30, 0.3) 100%);
}

.grow-overlay {
  background: conic-gradient(from 0deg, transparent, rgba(255, 255, 255, 0.15), transparent);
  animation: grow-spin 2s linear infinite;
}

.mowi-rings {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.ring {
  position: absolute;
  inset: 0;
  border-radius: 50%;
  border: 1px solid transparent;
  animation: ring-expand 1.5s ease-out infinite;
}

.particles {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.particle {
  position: absolute;
  top: 50%;
  left: 50%;
  width: 4px;
  height: 4px;
  border-radius: 50%;
  background: rgba(255, 220, 100, 0.9);
  transform-origin: 0 0;
}

@keyframes mowi-float {
  0%, 100% { transform: translateY(0px); }
  50%       { transform: translateY(-6px); }
}

@keyframes mowi-bounce {
  0%   { transform: scale(1); }
  30%  { transform: scale(1.15) translateY(-8px); }
  60%  { transform: scale(0.95) translateY(0px); }
  80%  { transform: scale(1.05) translateY(-3px); }
  100% { transform: scale(1) translateY(0px); }
}

@keyframes mowi-droop {
  0%   { transform: translateY(0px) scale(1); }
  40%  { transform: translateY(4px) scale(0.97, 1.03); }
  100% { transform: translateY(0px) scale(1); }
}

@keyframes mowi-pulse {
  0%   { transform: scale(1); box-shadow: 0 0 0 0 rgba(255, 215, 0, 0.4); }
  50%  { transform: scale(1.08); box-shadow: 0 0 0 20px rgba(255, 215, 0, 0); }
  100% { transform: scale(1); }
}

@keyframes mowi-tilt {
  0%, 100% { transform: rotate(0deg); }
  25%       { transform: rotate(-5deg); }
  75%       { transform: rotate(5deg); }
}

@keyframes ring-expand {
  0%   { transform: scale(1);    opacity: 0.8; }
  100% { transform: scale(var(--ring-scale, 2)); opacity: 0; }
}

@keyframes particle-fly {
  0%   { transform: rotate(var(--angle)) translateX(0) scale(1); opacity: 1; }
  100% { transform: rotate(var(--angle)) translateX(40px) scale(0); opacity: 0; }
}

@keyframes joy-pulse {
  0%   { opacity: 0; transform: scale(0.8); }
  50%  { opacity: 1; }
  100% { opacity: 0.6; transform: scale(1); }
}

@keyframes grow-spin {
  from { transform: rotate(0deg); }
  to   { transform: rotate(360deg); }
}

@keyframes eye-think-blink {
  0%, 90%, 100% { transform: scaleY(1); }
  95%            { transform: scaleY(0.1); }
}

.overlay-fade-enter-active,
.overlay-fade-leave-active {
  transition: opacity 0.4s ease;
}
.overlay-fade-enter-from,
.overlay-fade-leave-to {
  opacity: 0;
}
</style>
