import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/lib/supabase'

export const useTeacherStore = defineStore('teacher', () => {
  const classes        = ref<any[]>([])
  const students       = ref<any[]>([])
  const pendingMembers = ref<any[]>([])
  const pendingBadges  = ref<any[]>([])
  const loading        = ref(false)
  const error          = ref<string | null>(null)

  // ─── クラス一覧取得 ───────────────────────────────────────────
  async function fetchMyClasses() {
    loading.value = true
    const { data, error: err } = await supabase
      .from('classes')
      .select('*')
      .order('created_at', { ascending: false })
    if (err) error.value = err.message
    else classes.value = data ?? []
    loading.value = false
  }

  // ─── クラス作成 ───────────────────────────────────────────────
  async function createClass(payload: { class_name: string; description?: string }) {
    const { data: { user } } = await supabase.auth.getUser()
    const classCode = generateClassCode()
    const { data, error: err } = await supabase
      .from('classes')
      .insert({
        teacher_id:  user!.id,
        class_name:  payload.class_name,
        description: payload.description ?? null,
        class_code:  classCode,
      })
      .select()
      .single()
    if (err) { error.value = err.message; return null }
    classes.value.unshift(data)
    return data
  }

  // ─── 生徒進捗一覧（student_class_summary ビュー） ─────────────
  async function fetchClassStudents(classId: string) {
    loading.value = true
    const { data, error: err } = await supabase
      .from('student_class_summary')
      .select('*')
      .eq('class_id', classId)
      .order('display_name')
    if (err) error.value = err.message
    else students.value = data ?? []
    loading.value = false
  }

  // ─── 承認待ち生徒一覧 ─────────────────────────────────────────
  async function fetchPendingMembers(classId: string) {
    const { data, error: err } = await supabase
      .from('class_members')
      .select('id, joined_at, users(display_name, email)')
      .eq('class_id', classId)
      .eq('status', 'pending')
      .order('joined_at')
    if (err) error.value = err.message
    else pendingMembers.value = data ?? []
  }

  // ─── 生徒承認 ─────────────────────────────────────────────────
  async function approveMember(memberId: string) {
    const { data: { user } } = await supabase.auth.getUser()
    const { error: err } = await supabase
      .from('class_members')
      .update({
        status:      'approved',
        approved_by: user!.id,
        approved_at: new Date().toISOString(),
      })
      .eq('id', memberId)
    if (err) { error.value = err.message; return false }
    pendingMembers.value = pendingMembers.value.filter(m => m.id !== memberId)
    return true
  }

  // ─── 生徒削除 ─────────────────────────────────────────────────
  async function removeMember(memberId: string) {
    const { error: err } = await supabase
      .from('class_members')
      .update({ status: 'removed' })
      .eq('id', memberId)
    if (err) { error.value = err.message; return false }
    pendingMembers.value = pendingMembers.value.filter(m => m.id !== memberId)
    return true
  }

  // ─── バッジ承認待ち一覧 ───────────────────────────────────────
  async function fetchPendingBadges(classId: string) {
    const { data, error: err } = await supabase
      .from('chart_badges')
      .select('id, area, badge_name, applied_at, mastery_avg_at_apply, users!student_id(display_name)')
      .eq('class_id', classId)
      .eq('status', 'pending')
      .order('applied_at')
    if (err) error.value = err.message
    else pendingBadges.value = data ?? []
  }

  // ─── バッジ承認 ───────────────────────────────────────────────
  async function approveBadge(badgeId: string) {
    const { data: { user } } = await supabase.auth.getUser()
    const { error: err } = await supabase
      .from('chart_badges')
      .update({
        status:      'approved',
        approved_by: user!.id,
        approved_at: new Date().toISOString(),
      })
      .eq('id', badgeId)
    if (err) { error.value = err.message; return false }
    pendingBadges.value = pendingBadges.value.filter(b => b.id !== badgeId)
    return true
  }

  // ─── バッジ却下 ───────────────────────────────────────────────
  async function rejectBadge(badgeId: string, reason: string) {
    const { error: err } = await supabase
      .from('chart_badges')
      .update({ status: 'rejected', rejection_reason: reason })
      .eq('id', badgeId)
    if (err) { error.value = err.message; return false }
    pendingBadges.value = pendingBadges.value.filter(b => b.id !== badgeId)
    return true
  }

  // ─── ユーティリティ ───────────────────────────────────────────
  function generateClassCode(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
    return Array.from({ length: 6 }, () =>
      chars[Math.floor(Math.random() * chars.length)]
    ).join('')
  }

  return {
    classes, students, pendingMembers, pendingBadges, loading, error,
    fetchMyClasses, createClass,
    fetchClassStudents, fetchPendingMembers, approveMember, removeMember,
    fetchPendingBadges, approveBadge, rejectBadge,
  }
})
