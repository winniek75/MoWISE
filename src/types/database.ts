// ============================================================
// MoWISE | Supabase Database 型定義
// スキーマ v1.0 準拠（2026-03-10）
// ============================================================

export type UserRole = 'student' | 'teacher' | 'admin'
export type UserPlan = 'free' | 'premium' | 'teacher_plan' | 'school'
export type MowiEmotion = 'idle' | 'joy' | 'cheer' | 'sad' | 'think' | 'grow' | 'sleep' | 'streak' | 'first_pattern'
export type CheckinType = 'morning' | 'evening'
export type MorningFeeling = 'morning_great' | 'morning_doable' | 'morning_normal' | 'morning_heavy' | 'morning_nope'
export type EveningResult = 'evening_done' | 'evening_came_out' | 'evening_normal' | 'evening_drained' | 'evening_nope'
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
// 追加テーブル行の型（コード内で使用）
// ─────────────────────────────────────────

export interface FlashOutputLogRow {
  id: string
  user_id: string
  session_id: string | null
  pattern_id: string
  layer: number
  is_correct: boolean
  response_ms: number | null
  combo_at_time: number
  difficulty_level: number | null
  answered_at: string
  created_at: string
}

export interface RobloxLinkRow {
  id: string
  user_id: string
  roblox_user_id: string | null
  roblox_display_name: string | null
  status: string
  last_sync_at: string | null
  created_at: string
}

export interface RobloxSessionRow {
  id: string
  user_id: string
  started_at: string
  duration_seconds: number | null
  flash_output_total: number
  flash_output_correct: number
  max_combo: number
  word_coins_earned: number
  buildings_built: number
  created_at: string
}

export interface RobloxTownStateRow {
  id: string
  user_id: string
  word_coins: number
  total_buildings_built: number
  total_missions_completed: number
  total_play_time_seconds: number
  zones_unlocked: number
  created_at: string
  updated_at: string
}

export interface RobloxLinkCodeRow {
  id: string
  user_id: string
  code: string
  expires_at: string
  used: boolean
  created_at: string
}

export interface TeacherFeedbackRow {
  id: string
  teacher_id: string
  student_id: string
  class_id: string
  message: string
  context_type: 'general' | 'checkin' | 'badge' | 'pattern' | null
  context_ref: string | null
  is_read: boolean
  created_at: string
}

export interface StudentClassSummaryRow {
  class_id: string
  student_id: string
  display_name: string
  mowi_level: number
  streak_days: number
  avg_mastery_level: number | null
  patterns_mastered: number
  approved_badges: number
  latest_morning_mood: string | null
  anxious_days_last_3: number
}

// ─────────────────────────────────────────
// Database 型（Supabase クライアント用）
// Relationships を含めることで never 型を回避
// ─────────────────────────────────────────

type Table<R, I = Partial<R>, U = Partial<R>> = {
  Row: R; Insert: I; Update: U; Relationships: []
}

export interface Database {
  public: {
    Tables: {
      users:              Table<UserRow>
      mowi_state:         Table<MowiStateRow>
      checkins:           Table<CheckinRow>
      patterns:           Table<PatternRow>
      pattern_content:    Table<PatternContentRow>
      pattern_progress:   Table<PatternProgressRow>
      classes:            Table<ClassRow>
      class_members:      Table<ClassMemberRow>
      chart_badges:       Table<ChartBadgeRow>
      battles:            Table<BattleRow>
      flash_output_logs:  Table<FlashOutputLogRow>
      roblox_links:       Table<RobloxLinkRow>
      roblox_sessions:    Table<RobloxSessionRow>
      roblox_town_state:  Table<RobloxTownStateRow>
      roblox_link_codes:  Table<RobloxLinkCodeRow>
      teacher_feedback:   Table<TeacherFeedbackRow>
    }
    Views: {
      student_class_summary: {
        Row: StudentClassSummaryRow
        Relationships: []
      }
    }
    Functions: Record<string, never>
    Enums: Record<string, never>
  }
}
