import { computed } from 'vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

export interface RobloxLinkStatus {
  isLinked: boolean
  robloxDisplayName: string | null
  linkedAt: string | null
  status: 'active' | 'inactive' | null
}

export interface LinkVerifyResponse {
  linked: boolean
  roblox_display_name: string
  link_token: string
  boosts: {
    coin_multiplier: number
    premium_materials: boolean
  }
}

export type LinkVerifyErrorCode =
  | 'CODE_NOT_FOUND'
  | 'CODE_EXPIRED'
  | 'ALREADY_LINKED'
  | 'INVALID_FORMAT'
  | 'AUTH_REQUIRED'
  | 'UNKNOWN'

export interface LinkVerifyError {
  code: LinkVerifyErrorCode
  message: string
}

export function useRobloxLink() {
  const authStore = useAuthStore()
  const userId = computed(() => authStore.userId)

  async function fetchLinkStatus(): Promise<RobloxLinkStatus> {
    const uid = userId.value
    if (!uid) {
      return { isLinked: false, robloxDisplayName: null, linkedAt: null, status: null }
    }

    const { data, error } = await supabase
      .from('roblox_links')
      .select('roblox_display_name, status, created_at')
      .eq('user_id', uid)
      .eq('status', 'active')
      .maybeSingle()

    if (error) {
      console.error('[useRobloxLink] fetchLinkStatus error:', error)
      return { isLinked: false, robloxDisplayName: null, linkedAt: null, status: null }
    }

    if (!data) {
      return { isLinked: false, robloxDisplayName: null, linkedAt: null, status: null }
    }

    return {
      isLinked: data.status === 'active',
      robloxDisplayName: data.roblox_display_name ?? null,
      linkedAt: data.created_at ?? null,
      status: (data.status as 'active' | 'inactive') ?? null,
    }
  }

  async function verifyLinkCode(
    code: string
  ): Promise<{ data: LinkVerifyResponse | null; error: LinkVerifyError | null }> {
    const normalized = code.trim().toUpperCase()
    if (!/^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{6}$/.test(normalized)) {
      return {
        data: null,
        error: { code: 'INVALID_FORMAT', message: 'コードの形式が違う。6 文字すべてを入力してください。' },
      }
    }

    const { data, error } = await supabase.functions.invoke<LinkVerifyResponse>(
      'roblox-link-verify',
      { body: { code: normalized } }
    )

    if (data && (data as LinkVerifyResponse).linked) {
      return { data: data as LinkVerifyResponse, error: null }
    }

    const ctx = (error as { context?: { status?: number } } | null)?.context
    const status = ctx?.status

    let code_: LinkVerifyErrorCode = 'UNKNOWN'
    let message = '連携に失敗。少し時間をおいてもう一度試してください。'

    if (status === 401) {
      code_ = 'AUTH_REQUIRED'
      message = 'ログインが必要です。'
    } else if (status === 404) {
      code_ = 'CODE_NOT_FOUND'
      message = 'このコードは見つからない。Roblox 側で正しく表示されていますか？'
    } else if (status === 410) {
      code_ = 'CODE_EXPIRED'
      message = 'このコードは時間切れ。Roblox 側で新しいコードを発行してください。'
    } else if (status === 409) {
      code_ = 'ALREADY_LINKED'
      message = 'この Roblox アカウントは既に別の MoWISE アカウントと連携済み。'
    } else if (status === 400) {
      code_ = 'INVALID_FORMAT'
      message = 'コードの形式が違う。'
    }

    return { data: null, error: { code: code_, message } }
  }

  async function unlink(): Promise<{ error: Error | null }> {
    const uid = userId.value
    if (!uid) {
      return { error: new Error('未ログイン状態のため連携解除できません。') }
    }

    const { error } = await supabase
      .from('roblox_links')
      .update({
        status: 'inactive',
        updated_at: new Date().toISOString(),
      } as never)
      .eq('user_id', uid)
      .eq('status', 'active')

    if (error) {
      console.error('[useRobloxLink] unlink error:', error)
      return { error: error as unknown as Error }
    }

    return { error: null }
  }

  return { fetchLinkStatus, verifyLinkCode, unlink }
}
