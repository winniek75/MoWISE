/**
 * チェックイン自動誘導用 composable（B-4-2）
 *
 * 時間帯（朝 04:00〜13:59 / 夜 14:00〜03:59）に応じた自動誘導と、
 * 「あとでやる」dismiss を localStorage で1日単位に管理する。
 *
 * 日付ロールは 04:00 起点（depth: stores/checkin.ts の todayDateStr と整合）。
 */

export type CheckinSession = 'morning' | 'evening'

const DISMISS_KEY_PREFIX = 'checkin_dismissed_'

/** 04:00 起点の「今日」キー（YYYY-MM-DD） */
function getTodayKey(): string {
  const now = new Date()
  if (now.getHours() < 4) {
    now.setDate(now.getDate() - 1)
  }
  return now.toISOString().split('T')[0]
}

/** 現在時刻から該当セッションを判定 */
export function getCurrentCheckinSession(): CheckinSession {
  const hour = new Date().getHours()
  // 04:00〜13:59 → morning / それ以外（14:00〜03:59）→ evening
  if (hour >= 4 && hour < 14) return 'morning'
  return 'evening'
}

/** dismiss 済みか */
export function isCheckinDismissed(session: CheckinSession): boolean {
  try {
    const key = `${DISMISS_KEY_PREFIX}${getTodayKey()}_${session}`
    return localStorage.getItem(key) === 'true'
  } catch {
    return false
  }
}

/** dismiss を記録 */
export function setCheckinDismissed(session: CheckinSession): void {
  try {
    const key = `${DISMISS_KEY_PREFIX}${getTodayKey()}_${session}`
    localStorage.setItem(key, 'true')
  } catch {
    // localStorage 不可（プライベートモード等）→ 黙って失敗（次回も誘導される）
  }
}

/** 当日以外の dismiss キーをクリーンアップ（古いキーの蓄積防止） */
export function cleanupOldDismissKeys(): void {
  try {
    const today = getTodayKey()
    const toRemove: string[] = []
    for (let i = 0; i < localStorage.length; i++) {
      const k = localStorage.key(i)
      if (k && k.startsWith(DISMISS_KEY_PREFIX) && !k.includes(today)) {
        toRemove.push(k)
      }
    }
    toRemove.forEach(k => localStorage.removeItem(k))
  } catch {
    // noop
  }
}
