/**
 * MoWISE 共通音声再生ユーティリティ
 *
 * 優先順位:
 *   1. Supabase Storage に音声ファイルがあればそれを再生（高品質）
 *   2. なければ Web Speech API で即時読み上げ（フォールバック）
 *
 * 後から音声ファイルを Storage にアップロードすれば自動的に高品質版に切り替わる。
 */

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL as string | undefined
const AUDIO_BUCKET = 'mowise-audio'

/** 現在再生中の Audio / SpeechSynthesisUtterance を追跡（多重再生防止） */
let currentAudio: HTMLAudioElement | null = null
let currentUtterance: SpeechSynthesisUtterance | null = null

/**
 * Supabase Storage のファイルURLを組み立てる
 */
function buildStorageUrl(filename: string): string | null {
  if (!SUPABASE_URL) return null
  // P001_L0_normal_1.mp3 → patterns/P001/L0/P001_L0_normal_1.mp3
  const match = filename.match(/^(P\d+)_L(\d)_/)
  if (!match) return null
  const [, patternNo, layer] = match
  return `${SUPABASE_URL}/storage/v1/object/public/${AUDIO_BUCKET}/patterns/${patternNo}/L${layer}/${filename}`
}

/**
 * Storage から音声を再生。成功したら true を返す。
 */
function tryPlayFromStorage(filename: string): Promise<boolean> {
  const url = buildStorageUrl(filename)
  if (!url) return Promise.resolve(false)

  return new Promise((resolve) => {
    const audio = new Audio(url)
    audio.addEventListener('canplaythrough', () => {
      stopCurrent()
      currentAudio = audio
      audio.play().then(() => resolve(true)).catch(() => resolve(false))
    }, { once: true })
    audio.addEventListener('error', () => resolve(false), { once: true })
    // タイムアウト: 2秒で読み込めなければフォールバック
    setTimeout(() => resolve(false), 2000)
  })
}

/**
 * Web Speech API で読み上げ
 */
function speakWithWebSpeech(
  text: string,
  options: { rate?: number; pitch?: number; lang?: string } = {},
): void {
  if (!('speechSynthesis' in window)) return
  stopCurrent()

  const utterance = new SpeechSynthesisUtterance(text)
  utterance.lang = options.lang ?? 'en-US'
  utterance.rate = options.rate ?? 1.0
  utterance.pitch = options.pitch ?? 1.0
  currentUtterance = utterance
  window.speechSynthesis.speak(utterance)
}

/**
 * 再生中の音声を停止
 */
export function stopCurrent(): void {
  if (currentAudio) {
    currentAudio.pause()
    currentAudio.currentTime = 0
    currentAudio = null
  }
  if (currentUtterance) {
    window.speechSynthesis.cancel()
    currentUtterance = null
  }
}

// ─────────────────────────────────────────────
// 公開API
// ─────────────────────────────────────────────

/**
 * 音声ファイルを再生（Storage優先 → Web Speech APIフォールバック）
 *
 * @param filename  Supabase Storage 上のファイル名 (e.g. "P001_L0_normal_1.mp3")
 * @param text      フォールバック用の英文テキスト
 * @param options   Web Speech API 用オプション（rate, pitch, lang）
 */
export async function playAudio(
  filename: string | undefined,
  text: string,
  options: { rate?: number; pitch?: number } = {},
): Promise<void> {
  // 1. ファイル名がある場合、Storageを試す
  if (filename) {
    const played = await tryPlayFromStorage(filename)
    if (played) return
  }
  // 2. フォールバック: Web Speech API
  speakWithWebSpeech(text, options)
}

/**
 * Layer 0 専用: ゆっくり版を再生
 */
export async function playSlowAudio(
  filename: string | undefined,
  text: string,
): Promise<void> {
  return playAudio(filename, text, { rate: 0.75 })
}

/**
 * Layer 0 専用: ナチュラルスピード版を再生
 */
export async function playNaturalAudio(
  filename: string | undefined,
  text: string,
): Promise<void> {
  return playAudio(filename, text, { rate: 1.0 })
}

/**
 * 不正解時の「不自然な音」を再生（v3.1 不正解UX原則準拠）
 * Storage にファイルがあればそれを使い、なければ pitch を下げた Web Speech API で代替
 */
export async function playWrongAudio(
  filename: string | undefined,
  text: string,
): Promise<void> {
  return playAudio(filename, text, { rate: 0.9, pitch: 0.7 })
}
