import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useCheckinStore } from '@/stores/checkin'
import { useSessionStore } from '@/stores/session'
import { isOfflineMode } from '@/lib/supabase'


const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/auth/callback', name: 'AuthCallback', component: () => import('@/views/auth/AuthCallbackView.vue') },
    {
      path: '/onboarding',
      name: 'Onboarding',
      component: () => import('@/views/onboarding/OnboardingView.vue'),
      children: [
        { path: '1', name: 'Onboarding1', component: () => import('@/views/onboarding/Onboarding1Splash.vue'), meta: { requiresGuest: true } },
        { path: '2', name: 'Onboarding2', component: () => import('@/views/onboarding/Onboarding2Account.vue'), meta: { requiresGuest: true } },
        { path: '3', name: 'Onboarding3', component: () => import('@/views/onboarding/Onboarding3ClassCode.vue') },
        { path: '4', name: 'Onboarding4', component: () => import('@/views/onboarding/Onboarding4MowiMeet.vue') },
        { path: '5', name: 'Onboarding5', component: () => import('@/views/onboarding/Onboarding5FirstQuestion.vue') },
      ],
    },
    { path: '/', name: 'Home', component: () => import('@/views/home/HomeView.vue'), meta: { requiresAuth: true } },
    { path: '/checkin/morning', name: 'CheckinMorning', component: () => import('@/views/checkin/CheckinMorningView.vue'), meta: { requiresAuth: true } },
    { path: '/checkin/evening', name: 'CheckinEvening', component: () => import('@/views/checkin/CheckinEveningView.vue'), meta: { requiresAuth: true } },
    { path: '/session/start', name: 'session-start', component: () => import('@/views/session/SessionStartView.vue'), meta: { requiresAuth: true } },
    { path: '/session/layer0', name: 'session-layer0', component: () => import('@/views/session/Layer0View.vue'), meta: { requiresAuth: true, hideBottomNav: true } },
    { path: '/session/layer1', name: 'session-layer1', component: () => import('@/views/session/Layer1View.vue'), meta: { requiresAuth: true, hideBottomNav: true } },
    { path: '/session/layer2', name: 'session-layer2', component: () => import('@/views/session/Layer2View.vue'), meta: { requiresAuth: true } },
    { path: '/session/layer3', name: 'session-layer3', component: () => import('@/views/session/Layer3View.vue'), meta: { requiresAuth: true } },
    { path: '/session/end', name: 'session-end', component: () => import('@/views/session/SessionEndView.vue'), meta: { requiresAuth: true } },
    { path: '/session/pattern-master', name: 'pattern-master', component: () => import('@/views/session/PatternMasterView.vue'), meta: { requiresAuth: true, hideBottomNav: true } },
    { path: '/session/pattern-unlock', name: 'pattern-unlock', component: () => import('@/views/session/PatternUnlockView.vue'), meta: { requiresAuth: true, hideBottomNav: true } },
    { path: '/checkin/night', name: 'checkin-night', component: () => import('@/views/checkin/CheckinNightView.vue'), meta: { requiresAuth: true } },
    { path: '/checkin/diff',  name: 'checkin-diff',  component: () => import('@/views/checkin/DiffFeedbackView.vue'),  meta: { requiresAuth: true } },
    { path: '/teacher', name: 'TeacherDashboard', component: () => import('@/views/teacher/TeacherDashboardView.vue'), meta: { requiresAuth: true, requiresTeacher: true, hideBottomNav: true } },
    { path: '/teacher/:classId', name: 'TeacherClass', component: () => import('@/views/teacher/TeacherClassView.vue'), meta: { requiresAuth: true, requiresTeacher: true, hideBottomNav: true } },
    // ──── 図鑑 ────
    { path: '/zukan', name: 'Zukan', component: () => import('@/views/zukan/ZukanView.vue'), meta: { requiresAuth: true } },
    { path: '/zukan/:id', name: 'ZukanDetail', component: () => import('@/views/zukan/ZukanDetailView.vue'), meta: { requiresAuth: true }, props: true },
    // ──── 記録 ────
    { path: '/log/weekly', name: 'LogWeekly', component: () => import('@/views/log/LogWeeklyView.vue'), meta: { requiresAuth: true } },
    // ──── 設定 ────
    { path: '/settings', name: 'Settings', component: () => import('@/views/SettingsView.vue'), meta: { requiresAuth: true } },
    // ──── ゲーム化Layer ────
    { path: '/session/layer/2/svo', name: 'Layer2SVO', component: () => import('@/views/session/Layer2SVOView.vue'), meta: { requiresAuth: true, hideBottomNav: true } },
    { path: '/session/layer/3/sprint', name: 'Layer3Sprint', component: () => import('@/views/session/Layer3SprintView.vue'), meta: { requiresAuth: true, hideBottomNav: true } },
    { path: '/:pathMatch(.*)*', redirect: '/onboarding/1' },
  ],
})

router.beforeEach(async (to, _from, next) => {
  const auth = useAuthStore()
  if (auth.loading) await auth.initialize()
  if (to.meta.requiresAuth && !auth.isAuthenticated) return next({ name: 'Onboarding1' })
  if (to.meta.requiresGuest && auth.isAuthenticated) return next({ name: 'Home' })
  if (to.meta.requiresTeacher && !auth.isTeacher) return next({ name: 'Home' })

  // セッション中断ガード：セッションが未開始なのにlayer2以降へ直接アクセスされた場合
  const sessionStore = useSessionStore()
  const sessionGuardRoutes = ['session-layer0', 'session-layer1', 'session-layer2', 'session-layer3', 'session-end', 'Layer2SVO', 'Layer3Sprint', 'pattern-master', 'pattern-unlock']
  if (sessionGuardRoutes.includes(to.name as string) && !sessionStore.isActive) {
    return next({ name: 'session-start' })
  }

  // ホーム到達時：朝の時間帯（04:00〜13:59）かつ朝チェックイン未完了なら朝チェックインへ
  // ※ 初回ログイン（練習履歴なし）の場合はスキップ
  if (to.name === 'Home' && auth.isAuthenticated && !isOfflineMode) {
    try {
      const checkin = useCheckinStore()
      await checkin.fetchTodayCheckins()
      const hour = new Date().getHours()
      const hasEverPracticed = !!auth.userRow?.last_practice_at
      if (hour >= 4 && hour < 14 && !checkin.hasMorningCheckin && hasEverPracticed) {
        return next({ name: 'CheckinMorning' })
      }
    } catch (e) {
      console.warn('[router] checkin fetch failed, skipping:', e)
    }
  }

  next()
})

export default router
