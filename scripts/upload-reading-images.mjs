#!/usr/bin/env node
/**
 * Reading Book Image Uploader
 *
 * Usage:
 *   1. Put images in reading-images/ folder:
 *      reading-images/B001/cover.png
 *      reading-images/B001/p1.png
 *      reading-images/B001/p2.png
 *      ...
 *
 *   2. Run:  node scripts/upload-reading-images.mjs
 *
 *   Supports: .png .jpg .jpeg .webp
 */
import { createClient } from '@supabase/supabase-js'
import fs from 'fs'
import path from 'path'

const SUPABASE_URL = 'https://nrkhfkxzfaycehaxfdek.supabase.co'
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY

if (!SUPABASE_SERVICE_KEY) {
  console.log(`
  Service Role Key is required.

  1. Go to: https://supabase.com/dashboard/project/nrkhfkxzfaycehaxfdek/settings/api
  2. Copy "service_role" key (NOT anon key)
  3. Run:

     SUPABASE_SERVICE_KEY="your-key-here" node scripts/upload-reading-images.mjs
  `)
  process.exit(1)
}

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_KEY)
const BUCKET = 'reading'
const BASE_DIR = path.resolve(process.cwd(), 'reading-images')
const PUBLIC_BASE = `${SUPABASE_URL}/storage/v1/object/public/${BUCKET}`

const MIME = {
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.webp': 'image/webp',
}

async function main() {
  if (!fs.existsSync(BASE_DIR)) {
    console.log(`\n  Folder not found: ${BASE_DIR}`)
    console.log(`  Create it and add images like:`)
    console.log(`    reading-images/B001/cover.png`)
    console.log(`    reading-images/B001/p1.png\n`)
    process.exit(1)
  }

  const bookDirs = fs.readdirSync(BASE_DIR).filter(d =>
    d.match(/^B\d{3}$/) && fs.statSync(path.join(BASE_DIR, d)).isDirectory()
  ).sort()

  if (bookDirs.length === 0) {
    console.log('No B00X folders found in reading-images/')
    process.exit(1)
  }

  console.log(`\nFound ${bookDirs.length} book folder(s): ${bookDirs.join(', ')}\n`)

  let uploaded = 0
  let skipped = 0
  let errors = 0

  for (const bookNo of bookDirs) {
    const dir = path.join(BASE_DIR, bookNo)
    const files = fs.readdirSync(dir).filter(f => {
      const ext = path.extname(f).toLowerCase()
      return MIME[ext]
    }).sort()

    console.log(`--- ${bookNo} (${files.length} files) ---`)

    for (const file of files) {
      const ext = path.extname(file).toLowerCase()
      const filePath = path.join(dir, file)
      const storagePath = `${bookNo}/${file}`
      const fileData = fs.readFileSync(filePath)

      // Upload (upsert)
      const { error } = await supabase.storage
        .from(BUCKET)
        .upload(storagePath, fileData, {
          contentType: MIME[ext],
          upsert: true,
        })

      if (error) {
        console.log(`  FAIL  ${storagePath}: ${error.message}`)
        errors++
      } else {
        console.log(`  OK    ${storagePath}`)
        uploaded++
      }
    }
  }

  // --- Update DB ---
  console.log(`\nUpdating database...`)

  // Update cover URLs
  const { error: coverErr } = await supabase.rpc('exec_sql', { sql: '' }).catch(() => ({}))
  // Use direct queries instead
  for (const bookNo of bookDirs) {
    const dir = path.join(BASE_DIR, bookNo)
    const files = fs.readdirSync(dir).map(f => f.toLowerCase())

    // Find cover file
    const coverFile = files.find(f => f.startsWith('cover'))
    if (coverFile) {
      const coverUrl = `${PUBLIC_BASE}/${bookNo}/${coverFile}`
      const { error } = await supabase
        .from('reading_books')
        .update({ cover_url: coverUrl })
        .eq('book_no', bookNo)
      if (error) console.log(`  DB cover FAIL ${bookNo}: ${error.message}`)
      else console.log(`  DB cover OK   ${bookNo}`)
    }

    // Find page images (p1.png, p2.jpg, etc.)
    const pageFiles = files.filter(f => f.match(/^p\d+\./)).sort()
    for (const pf of pageFiles) {
      const pageNo = parseInt(pf.match(/^p(\d+)\./)[1])
      const imageUrl = `${PUBLIC_BASE}/${bookNo}/${pf}`

      // Get book id first
      const { data: book } = await supabase
        .from('reading_books')
        .select('id')
        .eq('book_no', bookNo)
        .single()

      if (book) {
        const { error } = await supabase
          .from('reading_pages')
          .update({ image_url: imageUrl })
          .eq('book_id', book.id)
          .eq('page_no', pageNo)
        if (error) console.log(`  DB page FAIL  ${bookNo}/p${pageNo}: ${error.message}`)
        else console.log(`  DB page OK    ${bookNo}/p${pageNo}`)
      }
    }
  }

  console.log(`
Done!
  Uploaded: ${uploaded}
  Skipped:  ${skipped}
  Errors:   ${errors}
  `)
}

main().catch(e => { console.error(e); process.exit(1) })
