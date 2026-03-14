<template>
  <div class="min-h-screen bg-gray-50 pb-24">
    <header class="bg-white border-b border-gray-200 px-4 py-3">
      <h1 class="text-lg font-bold text-gray-900">⚙ 設定</h1>
    </header>

    <main class="px-4 py-5 space-y-6">

      <!-- アカウント -->
      <section>
        <p class="text-xs font-bold text-gray-400 mb-2 px-1">アカウント</p>
        <div class="bg-white rounded-2xl divide-y divide-gray-100 shadow-sm">
          <div class="px-4 py-3">
            <p class="text-xs text-gray-400">名前</p>
            <p class="font-bold text-gray-900">{{ user?.display_name }}</p>
          </div>
          <div class="px-4 py-3">
            <p class="text-xs text-gray-400">クラス</p>
            <p class="font-bold text-gray-900">{{ user?.class_name ?? '未参加' }}</p>
          </div>
        </div>
      </section>

      <!-- 通知設定 -->
      <section>
        <p class="text-xs font-bold text-gray-400 mb-2 px-1">通知</p>
        <div class="bg-white rounded-2xl divide-y divide-gray-100 shadow-sm">
          <!-- 朝チェックイン通知 -->
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-gray-700">朝チェックイン通知</p>
            <button
              @click="settings.notify_morning = !settings.notify_morning; save()"
              class="relative w-12 h-6 rounded-full transition-colors duration-200"
              :class="settings.notify_morning ? 'bg-indigo-500' : 'bg-gray-300'"
            >
              <span
                class="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"
                :class="settings.notify_morning ? 'translate-x-6' : 'translate-x-0.5'"
              ></span>
            </button>
          </div>
          <!-- 夕チェックイン通知 -->
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-gray-700">夕チェックイン通知</p>
            <button
              @click="settings.notify_evening = !settings.notify_evening; save()"
              class="relative w-12 h-6 rounded-full transition-colors duration-200"
              :class="settings.notify_evening ? 'bg-indigo-500' : 'bg-gray-300'"
            >
              <span
                class="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"
                :class="settings.notify_evening ? 'translate-x-6' : 'translate-x-0.5'"
              ></span>
            </button>
          </div>
          <!-- 練習リマインダー -->
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-gray-700">練習リマインダー</p>
            <button
              @click="settings.notify_practice = !settings.notify_practice; save()"
              class="relative w-12 h-6 rounded-full transition-colors duration-200"
              :class="settings.notify_practice ? 'bg-indigo-500' : 'bg-gray-300'"
            >
              <span
                class="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"
                :class="settings.notify_practice ? 'translate-x-6' : 'translate-x-0.5'"
              ></span>
            </button>
          </div>
          <!-- 通知時刻（朝） -->
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-gray-700">通知時刻（朝）</p>
            <input
              type="time" v-model="settings.notify_morning_time"
              @change="save"
              class="text-sm text-indigo-600 font-bold border border-gray-200 rounded-lg px-2 py-1"
            />
          </div>
          <!-- 通知時刻（夕） -->
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-gray-700">通知時刻（夕）</p>
            <input
              type="time" v-model="settings.notify_evening_time"
              @change="save"
              class="text-sm text-indigo-600 font-bold border border-gray-200 rounded-lg px-2 py-1"
            />
          </div>
        </div>
      </section>

      <!-- 練習モード -->
      <section>
        <p class="text-xs font-bold text-gray-400 mb-2 px-1">練習モード</p>
        <div class="bg-white rounded-2xl shadow-sm">
          <div class="px-4 py-3">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-bold text-gray-900">ゲーム化Layer</p>
                <p class="text-xs text-gray-400">Layer2 SVO・Layer3 Sprint を有効化</p>
              </div>
              <button
                @click="toggleGameMode"
                class="relative w-12 h-6 rounded-full transition-colors duration-200"
                :class="settings.game_mode_enabled ? 'bg-indigo-500' : 'bg-gray-300'"
              >
                <span
                  class="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"
                  :class="settings.game_mode_enabled ? 'translate-x-6' : 'translate-x-0.5'"
                ></span>
              </button>
            </div>
          </div>
        </div>
      </section>

      <!-- デモモード切替（オフライン時のみ） -->
      <section v-if="isDemoMode">
        <p class="text-xs font-bold text-gray-400 mb-2 px-1">デモモード</p>
        <div class="bg-white rounded-2xl shadow-sm">
          <div class="px-4 py-3 flex items-center justify-between">
            <div>
              <p class="text-sm font-bold text-gray-900">ロール切替</p>
              <p class="text-xs text-gray-400">現在: <span class="font-bold" :class="authStore.isTeacher ? 'text-purple-600' : 'text-blue-600'">{{ authStore.isTeacher ? 'Teacher' : 'Student' }}</span></p>
            </div>
            <button
              @click="authStore.toggleDemoRole()"
              class="px-4 py-2 rounded-full text-sm font-bold transition-colors"
              :class="authStore.isTeacher ? 'bg-blue-100 text-blue-700' : 'bg-purple-100 text-purple-700'"
            >
              {{ authStore.isTeacher ? 'Student に切替' : 'Teacher に切替' }}
            </button>
          </div>
        </div>
      </section>

      <!-- ログアウト -->
      <section>
        <div class="bg-white rounded-2xl shadow-sm">
          <button @click="handleLogout" class="w-full px-4 py-4 text-left text-red-500 font-bold text-sm">
            ログアウト
          </button>
        </div>
      </section>

    </main>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase, isOfflineMode } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

const router    = useRouter()
const authStore = useAuthStore()
const isDemoMode = isOfflineMode
const user     = ref<any>(null)
const settings = ref({
  notify_morning:      true,
  notify_evening:      true,
  notify_practice:     true,
  notify_morning_time: '07:30',
  notify_evening_time: '20:00',
  game_mode_enabled:   true,
})

onMounted(async () => {
  if (isOfflineMode) {
    user.value = authStore.userRow
    return
  }
  const { data: { user: u } } = await supabase.auth.getUser()
  const { data } = await supabase.from('users').select('*').eq('id', u!.id).single()
  user.value = data
  if (data) {
    settings.value.notify_morning      = data.notify_morning      ?? true
    settings.value.notify_evening      = data.notify_evening      ?? true
    settings.value.notify_practice     = data.notify_practice     ?? true
    settings.value.notify_morning_time = data.notify_morning_time ?? '07:30'
    settings.value.notify_evening_time = data.notify_evening_time ?? '20:00'
    settings.value.game_mode_enabled   = data.game_mode_enabled   ?? true
  }
})

async function save() {
  if (isOfflineMode) return
  const { data: { user: u } } = await supabase.auth.getUser()
  await supabase.from('users').update(settings.value).eq('id', u!.id)
}

async function toggleGameMode() {
  settings.value.game_mode_enabled = !settings.value.game_mode_enabled
  await save()
}

async function handleLogout() {
  if (!confirm('ログアウトしますか？')) return
  await supabase.auth.signOut()
  router.push('/')
}
</script>
