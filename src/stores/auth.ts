// ============================================================
// stores/auth.ts — 認証状態管理
// ============================================================
import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'
import type { UserRow, UserRole } from '@/types/database'
import type { User, Session } from '@supabase/supabase-js'

export const useAuthStore = defineStore('auth', () => {
  // ─── State ───────────────────────────────────────────────
  const session   = ref<Session | null>(null)
  const authUser  = ref<User | null>(null)
  const userRow   = ref<UserRow | null>(null)
  const loading   = ref(true)
  const error     = ref<string | null>(null)
  let _initialized = false

  // ─── Computed ────────────────────────────────────────────
  const isAuthenticated = computed(() => !!session.value)
  const isTeacher       = computed(() => userRow.value?.role === 'teacher')
  const isStudent       = computed(() => userRow.value?.role === 'student')
  const userId          = computed(() => authUser.value?.id ?? null)
  const displayName     = computed(() => userRow.value?.display_name ?? '')

  // ─── Actions ─────────────────────────────────────────────

  /** アプリ起動時：セッション復元（二重初期化防止済み） */
  async function initialize() {
    if (_initialized) return
    _initialized = true
    loading.value = true
    try {
      const { data } = await supabase.auth.getSession()
      session.value  = data.session
      authUser.value = data.session?.user ?? null
      if (authUser.value) await fetchUserRow(authUser.value.id)
    } catch (e) {
      console.error('[auth] initialize error:', e)
    } finally {
      loading.value = false
    }

    // セッション変更を購読
    supabase.auth.onAuthStateChange(async (_event, newSession) => {
      session.value  = newSession
      authUser.value = newSession?.user ?? null
      if (authUser.value) {
        await fetchUserRow(authUser.value.id)
      } else {
        userRow.value = null
      }
    })
  }

  /** usersテーブルからプロフィール取得 */
  async function fetchUserRow(uid: string) {
    const { data, error: err } = await supabase
      .from('users')
      .select('*')
      .eq('id', uid)
      .single()
    if (err) { console.error('[auth] fetchUserRow:', err); return }
    userRow.value = data
  }

  /** メール＋パスワード 新規登録 */
  async function signUpWithEmail(
    email: string,
    password: string,
    displayName: string,
    role: UserRole = 'student',
  ) {
    loading.value = true
    error.value   = null
    try {
      const { data, error: err } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { display_name: displayName, role },
        },
      })
      if (err) throw err
      if (data.session) {
        // メール認証OFF：セッションが即座に返る
        session.value  = data.session
        authUser.value = data.user
        if (data.user) await fetchUserRow(data.user.id)
      } else if (data.user && !data.session) {
        // identities が空 = 既にそのメールで登録済み（メール認証OFF時のSupabase仕様）
        const isExisting = (data.user.identities?.length ?? 0) === 0
        if (isExisting) {
          throw new Error('このメールアドレスは既に登録済みです。「ログイン」を選択してください。')
        }
        // identities がある = メール認証ONで確認メールが送信された
        throw new Error('確認メールを送信しました。受信トレイを確認してからログインしてください。')
      }
      return data
    } catch (e: unknown) {
      error.value = (e as Error).message
      throw e
    } finally {
      loading.value = false
    }
  }

  /** メール＋パスワード ログイン */
  async function signInWithEmail(email: string, password: string) {
    loading.value = true
    error.value   = null
    try {
      const { data, error: err } = await supabase.auth.signInWithPassword({ email, password })
      if (err) throw err
      // onAuthStateChange より先にセッションを同期的に更新（ルーターガードのレースコンディション防止）
      session.value  = data.session
      authUser.value = data.user
      if (data.user) await fetchUserRow(data.user.id)
      return data
    } catch (e: unknown) {
      error.value = (e as Error).message
      throw e
    } finally {
      loading.value = false
    }
  }

  /** Google SSO ログイン */
  async function signInWithGoogle() {
    const { error: err } = await supabase.auth.signInWithOAuth({
      provider: 'google',
      options: { redirectTo: window.location.origin + '/auth/callback' },
    })
    if (err) throw err
  }

  /** ログアウト */
  async function signOut() {
    await supabase.auth.signOut()
    userRow.value = null
  }

  /** プロフィール更新 */
  async function updateProfile(updates: Partial<Pick<UserRow, 'display_name' | 'avatar_url' | 'notification_enabled'>>) {
    if (!userId.value) return
    // Database 型に Relationships が未定義のため builder を any キャスト
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const builder = supabase.from('users') as any
    const { data, error: err } = await builder
      .update({ ...updates, updated_at: new Date().toISOString() })
      .eq('id', userId.value)
      .select()
      .single()
    if (err) throw err
    userRow.value = data as UserRow
  }

  return {
    session, authUser, userRow, loading, error,
    isAuthenticated, isTeacher, isStudent, userId, displayName,
    // 新ストア（checkin.ts / mowi.ts）が authStore.user でアクセスできるようエイリアス
    user: authUser,
    initialize, fetchUserRow, signUpWithEmail, signInWithEmail, signInWithGoogle, signOut, updateProfile,
  }
})
