import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    // ──── Auth ────
    { path: '/auth/callback', name: 'AuthCallback', component: () => import('@/views/auth/AuthCallbackView.vue') },
    { path: '/login', name: 'Login', component: () => import('@/views/auth/LoginView.vue'), meta: { requiresGuest: true } },
    { path: '/signup', name: 'Signup', component: () => import('@/views/auth/SignupView.vue'), meta: { requiresGuest: true } },

    // ──── Student ────
    { path: '/', name: 'StudentHome', component: () => import('@/views/student/StudentHomeView.vue'), meta: { requiresAuth: true, requiresStudent: true } },
    { path: '/games', name: 'StudentGames', component: () => import('@/views/student/StudentGamesView.vue'), meta: { requiresAuth: true, requiresStudent: true } },
    { path: '/games/:gameId', name: 'StudentGamePlay', component: () => import('@/views/student/StudentGamePlayView.vue'), meta: { requiresAuth: true, hideBottomNav: true } },
    { path: '/ranking', name: 'StudentRanking', component: () => import('@/views/student/StudentRankingView.vue'), meta: { requiresAuth: true, requiresStudent: true } },
    { path: '/join', name: 'StudentJoinClass', component: () => import('@/views/student/StudentJoinClassView.vue'), meta: { requiresAuth: true } },

    // ──── Teacher ────
    { path: '/teacher', name: 'TeacherDashboard', component: () => import('@/views/teacher/TeacherDashboardView.vue'), meta: { requiresAuth: true, requiresTeacher: true } },
    { path: '/teacher/games', name: 'TeacherGames', component: () => import('@/views/teacher/TeacherGamesView.vue'), meta: { requiresAuth: true, requiresTeacher: true } },
    { path: '/teacher/subscription', name: 'TeacherSubscription', component: () => import('@/views/teacher/TeacherSubscriptionView.vue'), meta: { requiresAuth: true, requiresTeacher: true } },
    { path: '/teacher/:classId', name: 'TeacherClass', component: () => import('@/views/teacher/TeacherClassView.vue'), meta: { requiresAuth: true, requiresTeacher: true } },
    { path: '/teacher/:classId/student/:studentId', name: 'TeacherStudent', component: () => import('@/views/teacher/TeacherStudentView.vue'), meta: { requiresAuth: true, requiresTeacher: true } },

    // ──── Settings ────
    { path: '/settings', name: 'Settings', component: () => import('@/views/SettingsView.vue'), meta: { requiresAuth: true } },

    // ──── Fallback ────
    { path: '/:pathMatch(.*)*', redirect: '/login' },
  ],
})

router.beforeEach(async (to, _from, next) => {
  const auth = useAuthStore()
  if (auth.loading) await auth.initialize()

  if (to.meta.requiresAuth && !auth.isAuthenticated) return next({ name: 'Login' })
  if (to.meta.requiresGuest && auth.isAuthenticated) {
    return next(auth.isTeacher ? { name: 'TeacherDashboard' } : { name: 'StudentHome' })
  }
  if (to.meta.requiresTeacher && !auth.isTeacher) return next({ name: 'StudentHome' })
  if (to.meta.requiresStudent && auth.isTeacher) return next({ name: 'TeacherDashboard' })

  next()
})

export default router
