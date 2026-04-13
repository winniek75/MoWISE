// ============================================================
// MoWISE | Supabase Database 型定義
// スキーマ v1.0 準拠（2026-03-10）
// ============================================================

export type UserRole = 'student' | 'teacher' | 'admin'
export type UserPlan = 'free' | 'premium' | 'teacher_plan' | 'school'
export type MowiEmotion = 'idle' | 'joy' | 'cheer' | 'sad' | 'think' | 'grow' | 'sleep' | 'streak' | 'first_pattern'
export type CheckinType = 'morning' | 'evening'
export type MorningFeeling = 'morning_confident' | 'morning_okay' | 'morning_anxious' | 'morning_unsure'
export type EveningResult = 'evening_said_it' | 'evening_fun' | 'evening_hard' | 'evening_not_quite'
export type PatternLayer = 0 | 1 | 2 | 3 | 4
export type MasteryLevel = 0 | 1 | 2 | 3 | 4 | 5
export type BadgeStatus = 'pending' | 'approved' | 'rejected'
export type ClassMemberStatus = 'pending' | 'approved'
export type BattleType = 'daily' | 'class' | 'raid'
export type BattleStatus = 'waiting' | 'active' | 'completed' | 'cancelled'

// ─────────────────────────────────────────
// テーブル行の型
// ─────────────────────────────────────────

export interface UserRow {
  id: string
  email: string
  display_name: string
  avatar_url: string | null
  role: UserRole
  plan: UserPlan
  mowi_level: number   // 1〜30
  total_xp: number
  streak_days: number
  max_streak_days: number
  last_login_at: string | null
  last_practice_at: string | null
  notification_enabled: boolean
  language_ui: 'ja' | 'en' | 'ko'
  created_at: string
  updated_at: string
}

export interface MowiStateRow {
  id: string
  user_id: string
  happiness: number         // 0〜100
  growth_stage: number      // 0〜4
  current_emotion: MowiEmotion
  current_combo: number
  max_combo_today: number
  weekly_snapshot_happiness: number | null
  weekly_snapshot_at: string | null
  last_interaction_at: string
  created_at: string
  updated_at: string
}

export interface CheckinRow {
  id: string
  user_id: string
  type: CheckinType
  feeling: MorningFeeling | null
  result: EveningResult | null
  mowi_quote: string | null
  session_ref_id: string | null
  streak_at_checkin: number | null
  checkin_date: string
  created_at: string
}

export interface PatternRow {
  id: string
  pattern_no: string        // 'P001' 〜 'P100'
  pattern_text: string
  pattern_short: string | null
  japanese: string
  rarity: number            // 1〜5
  area: string
  evolution_of: string | null
  is_mvp: boolean
  is_free: boolean
  unlock_condition_pattern: string | null
  unlock_condition_stars: number | null
  sort_order: number
  created_at: string
  updated_at: string
}

export interface PatternContentRow {
  id: string
  pattern_no: string
  layer: PatternLayer
  question_order: number
  question_type: 'sound_compare' | 'sound_match' | 'slot_fill' | 'audio_predict' | 'tile_select' | 'keyboard_input' | 'scene_challenge'
  prompt_ja: string | null
  prompt_en: string | null
  display_text: string | null
  context_text: string | null
  audio_url_a: string | null      // Layer 0 ゆっくり版
  audio_url_b: string | null      // Layer 0 ナチュラル版
  audio_url_main: string | null   // Layer 1〜3 メイン音声
  choices: unknown | null          // JSONB
  correct_answer: string
  alternate_answers: string[] | null
  explanation_ja: string | null
  mowi_quote_correct: string | null
  mowi_quote_wrong: string | null
  time_limit_sec: number | null
  pass_threshold: number | null
  tts_text_a: string | null
  tts_text_b: string | null
  tts_speed_a: number | null
  tts_speed_b: number | null
  tts_voice: string | null
  created_at: string
  updated_at: string
}

export interface PatternProgressRow {
  id: string
  user_id: string
  pattern_id: string
  pattern_no: string
  mastery_level: MasteryLevel
  layer0_done: boolean
  layer1_done: boolean
  layer2_done: boolean
  layer3_done: boolean
  layer4_done: boolean
  correct_count: number
  incorrect_count: number
  correct_rate: number         // 0.00〜1.00
  current_combo: number
  max_combo: number
  ease_factor: number          // SM-2
  interval_days: number        // SM-2
  times_seen: number           // SM-2
  next_review_at: string | null
  last_practiced_at: string | null
  created_at: string
  updated_at: string
}

export interface ClassRow {
  id: string
  teacher_id: string
  class_name: string
  class_code: string           // 6桁英数字
  description: string | null
  current_pattern_range: string | null
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface ClassMemberRow {
  id: string
  class_id: string
  user_id: string
  status: ClassMemberStatus
  joined_at: string | null
  created_at: string
}

export interface ChartBadgeRow {
  id: string
  student_id: string
  class_id: string
  pattern_id: string | null
  area: string | null
  status: BadgeStatus
  teacher_note: string | null
  approved_at: string | null
  created_at: string
}

export interface BattleRow {
  id: string
  user_id: string
  class_id: string | null
  type: BattleType
  status: BattleStatus
  pattern_ids: string[]
  total_questions: number
  correct_count: number
  max_combo: number
  total_xp_earned: number
  duration_seconds: number | null
  class_battle_id: string | null
  raid_id: string | null
  started_at: string | null
  ended_at: string | null
  created_at: string
}

// ─────────────────────────────────────────
// Database 型（Supabase クライアント用）
// ─────────────────────────────────────────

export interface Database {
  public: {
    Tables: {
      users:            { Row: UserRow;           Insert: Partial<UserRow>;           Update: Partial<UserRow>           }
      mowi_state:       { Row: MowiStateRow;      Insert: Partial<MowiStateRow>;      Update: Partial<MowiStateRow>      }
      checkins:         { Row: CheckinRow;        Insert: Partial<CheckinRow>;        Update: Partial<CheckinRow>        }
      patterns:         { Row: PatternRow;        Insert: Partial<PatternRow>;        Update: Partial<PatternRow>        }
      pattern_content:  { Row: PatternContentRow; Insert: Partial<PatternContentRow>; Update: Partial<PatternContentRow> }
      pattern_progress: { Row: PatternProgressRow;Insert: Partial<PatternProgressRow>;Update: Partial<PatternProgressRow>}
      classes:          { Row: ClassRow;          Insert: Partial<ClassRow>;          Update: Partial<ClassRow>          }
      class_members:    { Row: ClassMemberRow;    Insert: Partial<ClassMemberRow>;    Update: Partial<ClassMemberRow>    }
      chart_badges:     { Row: ChartBadgeRow;     Insert: Partial<ChartBadgeRow>;     Update: Partial<ChartBadgeRow>     }
      battles:          { Row: BattleRow;         Insert: Partial<BattleRow>;         Update: Partial<BattleRow>         }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
  }
}
