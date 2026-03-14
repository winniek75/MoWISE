/**
 * MoWISE Router 追記 — Step M-2（練習セッション）
 * 
 * src/router/index.ts の routes 配列に追加してください。
 * 既存ルートの下に追記する形で問題ありません。
 */

// ─────────────────────────────────────────────
// 追加ルート定義
// ─────────────────────────────────────────────

const sessionRoutes = [
  {
    path: '/session',
    name: 'session-start',
    component: () => import('@/views/session/SessionStartView.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/session/layer2',
    name: 'session-layer2',
    component: () => import('@/views/session/Layer2View.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/session/layer3',
    name: 'session-layer3',
    component: () => import('@/views/session/Layer3View.vue'),
    meta: { requiresAuth: true },
  },
  {
    path: '/session/end',
    name: 'session-end',
    component: () => import('@/views/session/SessionEndView.vue'),
    meta: { requiresAuth: true },
  },
]

export default sessionRoutes

// ─────────────────────────────────────────────
// Navigation Guard 追記
// ─────────────────────────────────────────────

/**
 * router.beforeEach に追記する内容。
 * Layer2/3 直アクセス防止（セッション未開始時はセッション開始画面へ）
 *
 * router.beforeEach((to, from) => {
 *   const sessionStore = useSessionStore()
 *   const sessionRequiredRoutes = ['session-layer2', 'session-layer3', 'session-end']
 *
 *   if (sessionRequiredRoutes.includes(to.name as string) && !sessionStore.isActive) {
 *     return { name: 'session-start' }
 *   }
 * })
 */
