/**
 * MoWISE Layer 0 / Layer 1 型定義
 *
 * Layer 0: Sound Foundation（聞き比べ）
 *   - ゆっくり版 vs ナチュラル版の音を聞いて、正しい文を選ぶ
 *
 * Layer 1: Echo Drill（Sound Match）
 *   - 音声を聞いて、3つの選択肢から正しいテキストを選ぶ
 */

// ─────────────────────────────────────────────
// Layer 0: Sound Foundation
// ─────────────────────────────────────────────

export interface Layer0Question {
  id: string
  /** ゆっくり版テキスト（フル形: "I am tired."） */
  slowText: string
  /** ナチュラル版テキスト（短縮形: "I'm tired."） */
  naturalText: string
  /** 日本語の意味 */
  meaningJa: string
  /** ゆっくり版の音声ファイル名（Storageにあれば使う） */
  slowAudio?: string
  /** ナチュラル版の音声ファイル名 */
  naturalAudio?: string
  /** 聞き比べ後の確認クイズ: 「ナチュラルに聞こえるのはどっち？」 */
  quiz: {
    /** 選択肢 */
    options: Array<{ id: string; text: string; isNatural: boolean }>
    /** 解説 */
    explanation: string
  }
}

// ─────────────────────────────────────────────
// Layer 1: Echo Drill (Sound Match)
// ─────────────────────────────────────────────

export interface Layer1Choice {
  id: string
  text: string
  isCorrect: boolean
}

export interface Layer1Question {
  id: string
  /** 再生する英文（音声ファイルがなければ Web Speech API で読み上げ） */
  sentence: string
  /** 日本語ヒント（表示するかは設計次第） */
  hintJa?: string
  /** 音声ファイル名（Storageにあれば使う） */
  audio?: string
  /** 3択の選択肢 */
  choices: Layer1Choice[]
  /** 正解後の解説 */
  explanation?: string
}
