import { createClient } from '@supabase/supabase-js'
import type { Database } from '@/types/database'

const supabaseUrl  = import.meta.env.VITE_SUPABASE_URL  as string
const supabaseAnon = import.meta.env.VITE_SUPABASE_ANON_KEY as string

if (!supabaseUrl || !supabaseAnon) {
  throw new Error(
    '[MoWISE] VITE_SUPABASE_URL と VITE_SUPABASE_ANON_KEY を .env に設定してください。'
  )
}

export const supabase = createClient<Database>(supabaseUrl, supabaseAnon, {
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
