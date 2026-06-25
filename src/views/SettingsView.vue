<template>
  <div class="min-h-screen bg-bg-dark pb-28">
    <header class="neo-header flex items-center gap-3">
      <button @click="router.back()" class="text-white/30 text-sm font-title font-bold hover:text-white/50 transition-colors">← 戻る</button>
      <h1 class="text-lg font-title font-bold text-white">設定</h1>
    </header>

    <main class="px-5 py-5 space-y-5 max-w-lg mx-auto">

      <!-- Account -->
      <section>
        <p class="neo-section-title px-1">アカウント</p>
        <div class="neo-card !p-0 divide-y divide-white/[0.05]">
          <div class="px-4 py-3">
            <p class="text-[11px] text-white/25 font-title">名前</p>
            <p class="font-title font-bold text-white">{{ user?.display_name }}</p>
          </div>
          <div class="px-4 py-3">
            <p class="text-[11px] text-white/25 font-title">クラス</p>
            <p class="font-title font-bold text-white">{{ user?.class_name ?? '未参加' }}</p>
          </div>
        </div>
      </section>

      <!-- Notifications -->
      <section>
        <p class="neo-section-title px-1">通知</p>
        <div class="neo-card !p-0 divide-y divide-white/[0.05]">
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-white/60 font-title">朝チェックイン通知</p>
            <button
              @click="settings.notify_morning = !settings.notify_morning; save()"
              class="relative w-11 h-6 rounded-full transition-colors duration-200"
              :class="settings.notify_morning ? 'bg-brand-primary' : 'bg-white/10'"
            >
              <span
                class="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"
                :class="settings.notify_morning ? 'translate-x-5' : 'translate-x-0.5'"
              />
            </button>
          </div>
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-white/60 font-title">夕チェックイン通知</p>
            <button
              @click="settings.notify_evening = !settings.notify_evening; save()"
              class="relative w-11 h-6 rounded-full transition-colors duration-200"
              :class="settings.notify_evening ? 'bg-brand-primary' : 'bg-white/10'"
            >
              <span
                class="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"
                :class="settings.notify_evening ? 'translate-x-5' : 'translate-x-0.5'"
              />
            </button>
          </div>
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-white/60 font-title">練習リマインダー</p>
            <button
              @click="settings.notify_practice = !settings.notify_practice; save()"
              class="relative w-11 h-6 rounded-full transition-colors duration-200"
              :class="settings.notify_practice ? 'bg-brand-primary' : 'bg-white/10'"
            >
              <span
                class="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"
                :class="settings.notify_practice ? 'translate-x-5' : 'translate-x-0.5'"
              />
            </button>
          </div>
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-white/60 font-title">通知時刻（朝）</p>
            <input
              type="time" v-model="settings.notify_morning_time"
              @change="save"
              class="text-sm text-brand-secondary font-title font-bold bg-bg-card border border-white/[0.08] rounded-lg px-2 py-1"
            />
          </div>
          <div class="px-4 py-3 flex items-center justify-between">
            <p class="text-sm text-white/60 font-title">通知時刻（夕）</p>
            <input
              type="time" v-model="settings.notify_evening_time"
              @change="save"
              class="text-sm text-brand-secondary font-title font-bold bg-bg-card border border-white/[0.08] rounded-lg px-2 py-1"
            />
          </div>
        </div>
      </section>

      <!-- Practice mode -->
      <section>
        <p class="neo-section-title px-1">練習モード</p>
        <div class="neo-card">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-title font-bold text-white">ゲーム化ステージ</p>
              <p class="text-[11px] text-white/25 font-title mt-0.5">「つくる」SVO・「話す」Sprint を有効化</p>
            </div>
            <button
              @click="toggleGameMode"
              class="relative w-11 h-6 rounded-full transition-colors duration-200"
              :class="settings.game_mode_enabled ? 'bg-brand-primary' : 'bg-white/10'"
            >
              <span
                class="absolute top-0.5 w-5 h-5 bg-white rounded-full shadow transition-transform duration-200"
                :class="settings.game_mode_enabled ? 'translate-x-5' : 'translate-x-0.5'"
              />
            </button>
          </div>
        </div>
      </section>

      <!-- Roblox -->
      <section v-if="!isDemoMode">
        <p class="neo-section-title px-1">Roblox 連携</p>
        <button
          v-if="!linkLoading && !linkStatus.isLinked"
          @click="router.push({ name: 'RobloxLink' })"
          class="neo-card w-full flex items-center justify-between active:scale-[0.99] transition-transform"
        >
          <div class="text-left">
            <p class="text-sm font-title font-bold text-white">Roblox と連携する</p>
            <p class="text-[11px] text-white/25 font-title mt-0.5">Word Coins が 1.5 倍になる</p>
          </div>
          <span class="text-white/20">▶︎</span>
        </button>
        <div v-else-if="!linkLoading && linkStatus.isLinked" class="neo-card">
          <p class="text-sm font-title font-bold text-correct">Roblox 連携中</p>
          <p class="text-sm text-white/60 font-title mt-1">
            {{ linkStatus.robloxDisplayName ?? '(表示名未取得)' }}
            <span class="text-[11px] text-white/20 ml-1">（連携日：{{ formatDate(linkStatus.linkedAt) }}）</span>
          </p>
          <button
            @click="showUnlinkModal = true"
            class="mt-3 w-full py-2.5 text-sm font-title font-bold text-wrong border border-wrong/20 rounded-2xl active:bg-wrong/5 transition-colors"
          >
            連携を解除
          </button>
        </div>
        <div v-else class="neo-card">
          <p class="text-[11px] text-white/25 font-title">確認中...</p>
        </div>
      </section>

      <!-- Demo mode toggle -->
      <section v-if="isDemoMode">
        <p class="neo-section-title px-1">デモモード</p>
        <div class="neo-card">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-title font-bold text-white">ロール切替</p>
              <p class="text-[11px] text-white/25 font-title mt-0.5">
                現在: <span class="font-bold" :class="authStore.isTeacher ? 'text-neon-purple' : 'text-neon-cyan'">{{ authStore.isTeacher ? 'Teacher' : 'Student' }}</span>
              </p>
            </div>
            <button
              @click="authStore.toggleDemoRole()"
              class="neo-badge cursor-pointer active:scale-95 transition-transform"
              :class="authStore.isTeacher ? 'cyan' : ''"
            >
              {{ authStore.isTeacher ? 'Student に切替' : 'Teacher に切替' }}
            </button>
          </div>
        </div>
      </section>

      <!-- Logout -->
      <section>
        <div class="neo-card">
          <button @click="handleLogout" class="w-full text-left text-wrong font-title font-bold text-sm">
            ログアウト
          </button>
        </div>
      </section>
    </main>

    <!-- Unlink modal -->
    <div
      v-if="showUnlinkModal"
      class="neo-overlay"
      @click.self="showUnlinkModal = false"
    >
      <div class="neo-modal !max-w-sm">
        <h2 class="text-base font-title font-bold text-white">Roblox 連携を解除</h2>
        <p class="mt-3 text-sm text-white/50 leading-relaxed">
          解除すると Word Coins ブーストが無効になります。<br />
          Roblox 側のプレイデータは保持されます。
        </p>
        <div class="mt-5 flex gap-3">
          <button
            class="btn-ghost flex-1 py-2.5 border border-white/10 rounded-2xl"
            :disabled="unlinking"
            @click="showUnlinkModal = false"
          >
            キャンセル
          </button>
          <button
            class="flex-1 py-2.5 text-sm font-title font-bold text-white bg-wrong rounded-2xl active:scale-95 transition-transform disabled:opacity-50"
            :disabled="unlinking"
            @click="handleUnlink"
          >
            {{ unlinking ? '解除中...' : '解除する' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase, isOfflineMode } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'
import { useRobloxLink } from '@/composables/useRobloxLink'
import type { RobloxLinkStatus } from '@/composables/useRobloxLink'

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

const { fetchLinkStatus, unlink } = useRobloxLink()
const linkLoading = ref(true)
const linkStatus = ref<RobloxLinkStatus>({
  isLinked: false,
  robloxDisplayName: null,
  linkedAt: null,
  status: null,
})
const showUnlinkModal = ref(false)
const unlinking = ref(false)

async function loadLinkStatus() {
  if (isOfflineMode) {
    linkLoading.value = false
    return
  }
  linkLoading.value = true
  linkStatus.value = await fetchLinkStatus()
  linkLoading.value = false
}

async function handleUnlink() {
  if (unlinking.value) return
  unlinking.value = true
  const { error } = await unlink()
  unlinking.value = false
  if (error) {
    alert('連携解除に失敗しました。もう一度お試しください。')
    return
  }
  showUnlinkModal.value = false
  await loadLinkStatus()
}

function formatDate(iso: string | null): string {
  if (!iso) return '-'
  const d = new Date(iso)
  if (Number.isNaN(d.getTime())) return '-'
  const y = d.getFullYear()
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${y}-${m}-${day}`
}

onMounted(async () => {
  if (isOfflineMode) {
    user.value = authStore.userRow
    await loadLinkStatus()
    return
  }
  const { data: { user: u } } = await supabase.auth.getUser()
  const { data } = await supabase.from('users').select('*').eq('id', u!.id).single()
  user.value = data
  if (data) {
    settings.value.notify_morning      = (data as any).notify_morning      ?? true
    settings.value.notify_evening      = (data as any).notify_evening      ?? true
    settings.value.notify_practice     = (data as any).notify_practice     ?? true
    settings.value.notify_morning_time = (data as any).notify_morning_time ?? '07:30'
    settings.value.notify_evening_time = (data as any).notify_evening_time ?? '20:00'
    settings.value.game_mode_enabled   = (data as any).game_mode_enabled   ?? true
  }
  await loadLinkStatus()
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
