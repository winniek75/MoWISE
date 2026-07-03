/**
 * seed_reading.ts — seeds/reading/*.json を Supabase に投入する
 *
 * 使い方:
 *   SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... npx tsx scripts/seed_reading.ts
 *
 * - 同じ book_no が既に存在する場合はスキップ（上書きしない）
 * - JSON形式は docs/mowise_reading_spec_v1.md §7 を参照
 * - 画像・音声URLは投入時に reading バケットの公開URLへ自動変換
 */
import { createClient } from '@supabase/supabase-js'
import { readdirSync, readFileSync } from 'node:fs'
import { join } from 'node:path'

const url = process.env.SUPABASE_URL
const key = process.env.SUPABASE_SERVICE_ROLE_KEY
if (!url || !key) {
  console.error('SUPABASE_URL と SUPABASE_SERVICE_ROLE_KEY を環境変数で指定してください')
  process.exit(1)
}
const supabase = createClient(url, key)
const SEED_DIR = join(process.cwd(), 'seeds', 'reading')
const publicUrl = (bookNo: string, file: string) =>
  `${url}/storage/v1/object/public/reading/${bookNo}/${file}`

async function main() {
  const files = readdirSync(SEED_DIR).filter(f => f.endsWith('.json'))
  console.log(`${files.length} 件のseedファイルを処理します`)

  for (const file of files) {
    const book = JSON.parse(readFileSync(join(SEED_DIR, file), 'utf-8'))

    const { data: existing } = await supabase
      .from('reading_books').select('id').eq('book_no', book.book_no).maybeSingle()
    if (existing) { console.log(`⏭  ${book.book_no} は既に存在 → スキップ`); continue }

    const { data: inserted, error } = await supabase
      .from('reading_books')
      .insert({
        book_no: book.book_no,
        level: book.level,
        level_code: book.level_code,
        title: book.title,
        title_ja: book.title_ja ?? '',
        genre: book.genre ?? 'story',
        word_count: book.word_count ?? 0,
        cover_url: publicUrl(book.book_no, 'cover.png'),
        is_free: book.is_free ?? false,
        sort_order: book.sort_order ?? 0,
        is_published: book.is_published ?? true,
      })
      .select('id').single()
    if (error || !inserted) { console.error(`❌ ${book.book_no} books insert失敗`, error); continue }

    const { error: pErr } = await supabase.from('reading_pages').insert(
      book.pages.map((p: any) => ({
        book_id: inserted.id,
        page_no: p.page_no,
        body: p.body,
        image_url: p.image ? publicUrl(book.book_no, p.image) : null,
        audio_url: p.audio ? publicUrl(book.book_no, p.audio) : null,
      })),
    )
    if (pErr) { console.error(`❌ ${book.book_no} pages insert失敗`, pErr); continue }

    const { error: qErr } = await supabase.from('reading_quizzes').insert(
      book.quizzes.map((q: any) => ({
        book_id: inserted.id,
        question_no: q.question_no,
        format: q.format,
        question: q.question,
        choices: q.choices,
        answer_index: q.answer_index,
        explanation_ja: q.explanation_ja ?? '',
      })),
    )
    if (qErr) { console.error(`❌ ${book.book_no} quizzes insert失敗`, qErr); continue }

    console.log(`✅ ${book.book_no} 「${book.title}」 投入完了（${book.pages.length}ページ・${book.quizzes.length}問）`)
  }
}

main()
