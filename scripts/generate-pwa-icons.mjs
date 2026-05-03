/**
 * PWA アイコン一括生成スクリプト
 *
 * 入力 : public/mowi-icon.svg
 * 出力 : public/icons/icon-192.png
 *        public/icons/icon-512.png
 *        public/icons/icon-512-maskable.png
 *        public/icons/apple-touch-icon-180.png
 *
 * 実行: node scripts/generate-pwa-icons.mjs
 *
 * maskable 版は中央 80% に主要視覚要素が収まるよう padding を入れて生成する。
 * 背景色は manifest.background_color と一致させる (#0d0d1a)。
 */

import sharp from 'sharp'
import { readFileSync, mkdirSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = dirname(fileURLToPath(import.meta.url))
const ROOT = resolve(__dirname, '..')
const SRC_SVG = resolve(ROOT, 'public/mowi-icon.svg')
const OUT_DIR = resolve(ROOT, 'public/icons')
const BG = '#0d0d1a'

mkdirSync(OUT_DIR, { recursive: true })

const svgBuffer = readFileSync(SRC_SVG)

async function renderSquare(size, outName, { padding = 0 } = {}) {
  const inner = Math.round(size * (1 - padding * 2))
  const innerPng = await sharp(svgBuffer, { density: 384 })
    .resize(inner, inner, { fit: 'contain', background: BG })
    .png()
    .toBuffer()

  const offset = Math.round((size - inner) / 2)
  await sharp({
    create: {
      width: size,
      height: size,
      channels: 4,
      background: BG,
    },
  })
    .composite([{ input: innerPng, top: offset, left: offset }])
    .png()
    .toFile(resolve(OUT_DIR, outName))

  console.log(`  ✓ ${outName} (${size}x${size}${padding ? `, pad=${padding}` : ''})`)
}

console.log('Generating PWA icons...')
await renderSquare(192, 'icon-192.png')
await renderSquare(512, 'icon-512.png')
await renderSquare(512, 'icon-512-maskable.png', { padding: 0.1 })
await renderSquare(180, 'apple-touch-icon-180.png')
console.log('Done.')
