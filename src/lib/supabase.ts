import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabaseUrl  = import.meta.env.VITE_SUPABASE_URL  as string | undefined
const supabaseAnon = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined

export const isOfflineMode = !supabaseUrl || !supabaseAnon

if (isOfflineMode) {
  console.warn(
    '[MoWISE] VITE_SUPABASE_URL / VITE_SUPABASE_ANON_KEY が未設定です。デモモードで起動します。'
  )
}

// Supabase未設定時はダミークライアントを生成（オフラインモード）
export const supabase = createClient<Database>(
  supabaseUrl  || 'https://placeholder.supabase.co',
  supabaseAnon || 'placeholder',
  {
  auth: {
    autoRefreshToken:  true,
    persistSession:    true,
    detectSessionInUrl: true,
  },
  realtime: {
    params: { eventsPerSecond: 10 },
  },
})

// ─────────────────────────────────────────
// 型エクスポート（ショートカット）
// ─────────────────────────────────────────
export type SupabaseClient = typeof supabase
