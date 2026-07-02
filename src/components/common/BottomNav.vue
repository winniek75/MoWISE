<script setup lang="ts">
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const studentTabs = [
  { name: 'StudentHome', icon: 'home', label: 'ホーム' },
  { name: 'StudentGames', icon: 'games', label: 'ゲーム' },
  { name: 'MonsterGallery', icon: 'monster', label: 'モンスター' },
  { name: 'Settings', icon: 'settings', label: '設定' },
]

const teacherTabs = [
  { name: 'TeacherDashboard', icon: 'dashboard', label: 'ダッシュボード' },
  { name: 'TeacherGames', icon: 'games', label: 'ゲーム' },
  { name: 'TeacherSubscription', icon: 'plan', label: 'プラン' },
  { name: 'Settings', icon: 'settings', label: '設定' },
]

const tabs = auth.isTeacher ? teacherTabs : studentTabs

const iconPaths: Record<string, string> = {
  home: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-4 0a1 1 0 01-1-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 01-1 1',
  games: 'M14.828 14.828a4 4 0 01-5.656 0M9 10h.01M15 10h.01M12 2C6.477 2 2 6.477 2 12s4.477 10 10 10 10-4.477 10-10S17.523 2 12 2z',
  ranking: 'M9 12l2 2 4-4M7.835 4.697a3.42 3.42 0 001.946-.806 3.42 3.42 0 014.438 0 3.42 3.42 0 001.946.806 3.42 3.42 0 013.138 3.138 3.42 3.42 0 00.806 1.946 3.42 3.42 0 010 4.438 3.42 3.42 0 00-.806 1.946 3.42 3.42 0 01-3.138 3.138 3.42 3.42 0 00-1.946.806 3.42 3.42 0 01-4.438 0 3.42 3.42 0 00-1.946-.806 3.42 3.42 0 01-3.138-3.138 3.42 3.42 0 00-.806-1.946 3.42 3.42 0 010-4.438 3.42 3.42 0 00.806-1.946 3.42 3.42 0 013.138-3.138z',
  dashboard: 'M4 5a1 1 0 011-1h14a1 1 0 011 1v2a1 1 0 01-1 1H5a1 1 0 01-1-1V5zm0 8a1 1 0 011-1h6a1 1 0 011 1v6a1 1 0 01-1 1H5a1 1 0 01-1-1v-6zm12 0a1 1 0 011-1h2a1 1 0 011 1v6a1 1 0 01-1 1h-2a1 1 0 01-1-1v-6z',
  plan: 'M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z',
  monster: 'M12 3c-4.97 0-9 3.582-9 8 0 2.2 1.01 4.19 2.64 5.63.17.15.36.4.36.75v1.62c0 .55.45 1 1 1h10c.55 0 1-.45 1-1v-1.62c0-.35.19-.6.36-.75C19.99 15.19 21 13.2 21 11c0-4.418-4.03-8-9-8zm-2 14h4m-3-3h2',
  settings: 'M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.066 2.573c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.573 1.066c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.066-2.573c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.573-1.066z M15 12a3 3 0 11-6 0 3 3 0 016 0z',
}
</script>

<template>
  <nav class="fixed bottom-0 inset-x-0 z-40 safe-pb">
    <div class="mx-3 mb-2 rounded-2xl border border-white/[0.06] overflow-hidden"
         style="background: linear-gradient(180deg, rgba(18,18,43,0.95) 0%, rgba(11,11,26,0.98) 100%); backdrop-filter: blur(20px);">
      <div class="flex justify-around px-2 pt-3 pb-2">
        <button
          v-for="tab in tabs"
          :key="tab.name"
          class="flex flex-col items-center gap-1 py-1 px-3 transition-all duration-200 min-w-[56px] relative"
          :class="route.name === tab.name ? 'text-brand-secondary' : 'text-white/30 hover:text-white/50'"
          @click="router.push({ name: tab.name })"
        >
          <!-- Active indicator dot -->
          <div
            v-if="route.name === tab.name"
            class="absolute -top-1 w-1 h-1 rounded-full bg-brand-secondary"
            style="box-shadow: 0 0 8px rgba(0,206,206,0.6)"
          />
          <svg class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="1.8">
            <path stroke-linecap="round" stroke-linejoin="round" :d="iconPaths[tab.icon]" />
          </svg>
          <span class="text-[10px] font-title font-medium">{{ tab.label }}</span>
        </button>
      </div>
    </div>
  </nav>
</template>
