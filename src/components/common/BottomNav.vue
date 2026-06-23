<script setup lang="ts">
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const studentTabs = [
  { name: 'StudentHome', icon: '🏠', label: 'ホーム' },
  { name: 'StudentGames', icon: '🎮', label: 'ゲーム' },
  { name: 'StudentRanking', icon: '🏆', label: 'ランキング' },
  { name: 'Settings', icon: '⚙️', label: '設定' },
]

const teacherTabs = [
  { name: 'TeacherDashboard', icon: '📊', label: 'ダッシュボード' },
  { name: 'TeacherGames', icon: '🎮', label: 'ゲーム' },
  { name: 'TeacherSubscription', icon: '💳', label: 'プラン' },
  { name: 'Settings', icon: '⚙️', label: '設定' },
]

const tabs = auth.isTeacher ? teacherTabs : studentTabs
</script>

<template>
  <nav class="fixed bottom-0 inset-x-0 bg-bg-surface border-t border-white/5 safe-pb z-40">
    <div class="flex justify-around px-2 pt-2 pb-1">
      <button
        v-for="tab in tabs"
        :key="tab.name"
        class="flex flex-col items-center gap-0.5 py-1 px-3 transition-colors min-w-[60px]"
        :class="route.name === tab.name ? 'text-brand-primary' : 'text-white/40 hover:text-white/70'"
        @click="router.push({ name: tab.name })"
      >
        <span class="text-xl">{{ tab.icon }}</span>
        <span class="text-[10px] font-title">{{ tab.label }}</span>
      </button>
    </div>
  </nav>
</template>
