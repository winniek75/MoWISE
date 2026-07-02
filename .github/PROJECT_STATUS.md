# MoWISE Project Status & Roadmap

**Last Updated:** 2026-07-02
**Project:** MoWISE for Teachers & Students
**Repo:** https://github.com/winniek75/MoWISE
**Live:** https://mowise.vercel.app
**Supabase:** yytxgxlhgotscwztlsqj (mowisse / wise org)
**Stack:** Vue 3 + Vite + Tailwind + Pinia + Supabase

---

## Current Architecture

### Platform Structure
- **MoWISE (Portal)**: Vue 3 SPA on Vercel — teacher/student dashboard
- **20 Game Apps**: Separate Vercel deployments, loaded via iframe in MoWISE
- **Supabase**: Auth, DB, RLS, Edge Functions
- **Communication**: postMessage bridge (WiseGame SDK) between iframe games and portal

### User Roles
- **Teacher**: Email/Google auth → create classes → manage students → assign games → view analytics
- **Student**: PIN login (no email required) → play games → earn XP/badges

---

## Changes Made (2026-07-02)

### 1. Game Catalog Reorganization
- **Category rename**: `vocabulary` → `eiken` (英検対策)
- **Grammar titles fixed** to match actual content:
  - 動詞活用バトル → to/ing判別バトル (infinitive vs gerund)
  - 文法ドリル → 関係詞・分詞ドリル (relative clauses & participles)
  - アレドクイズ → Are/Do判別クイズ (be-verb vs do-verb)
  - 英検文法 → 時制・受動態ドリル (tense & passive)
- **Eiken titles clarified**:
  - 英検クイズ → 英検ボキャブラリー (vocab quiz)
  - 英検チャレンジ → 英検模擬テスト (mock exam simulator)
  - 英検SNS → 英検トレーニング (grammar+vocab hybrid)
- All descriptions updated to accurately reflect content

### 2. Student PIN Login System
- **Teachers create student accounts** (name only) → 4-digit PIN auto-generated
- **Students login** with class code + PIN (no email required)
- **QR code support**: `mowise.vercel.app/student-login?c=CODE&p=PIN`
- Login page redesigned with student/teacher tab switcher
- Signup page now teacher-only
- Teacher class view: student creation UI + PIN display + printable cards
- **DB**: `student_pins` table + `create_student_account()` RPC function

### 3. Files Changed
- `src/stores/auth.ts` — signInAsStudent() added
- `src/stores/game.ts` — category labels updated
- `src/stores/teacher.ts` — createStudentAccount(), fetchClassPins() added
- `src/views/auth/LoginView.vue` — student/teacher tab login
- `src/views/auth/SignupView.vue` — teacher-only signup
- `src/views/student/StudentGamesView.vue` — eiken filter
- `src/views/teacher/TeacherClassView.vue` — student creation UI
- `src/components/game/GameIcon.vue` — category comment update
- `src/assets/styles/main.css` — .cat-eiken style
- `src/router/index.ts` — /student-login redirect
- `supabase/migrations/20260702_*` — DB migrations

---

## Game Catalog (18 active games)

### 英検対策 (eiken) — 6 games
| ID | Title | Content |
|---|---|---|
| eiken-game | 英検ボキャブラリー | 英検5-3級語彙アーケードクイズ |
| fallingwordbattle | 落下ワードバトル | 英検5-2級語彙の落下ゲーム |
| flashinput | フラッシュ入力 | 認知科学ベース語彙インプット(5段階) |
| beat-word-crush | ビートワードクラッシュ | リズムシンク型語彙パズル |
| eiken-sns-app | 英検トレーニング | 文法200問+語彙750問(SNS風) |
| eiken-challenge | 英検模擬テスト | 筆記+リスニング模擬試験 |

### 文法 (grammar) — 6 games
| ID | Title | Content |
|---|---|---|
| verbform-battle | to/ing判別バトル | to不定詞 vs 動名詞(94問) |
| grammar-drill | 関係詞・分詞ドリル | 関係代名詞/副詞/分詞(108問) |
| grammar-app | 文法クラスルーム | 中学文法300問(ライブレッスン用) |
| eiken-grammar-game | 時制・受動態ドリル | 現在完了/過去形/受動態 |
| aredo-game | Are/Do判別クイズ | be動詞 vs 一般動詞(100問) |
| wh-questiongame | WH質問ゲーム | 疑問詞13種類 |

### フォニックス (phonics) — 4 games
### ライティング (writing) — 2 games
### ミックス (mixed) — 1 game

---

## Roadmap: Monster x Gacha System

### Decision: Replace Mowi mascot + checkin system with Monster Raising + Gacha

**Why:**
- Morning/evening checkin = obligation, not fun
- Mowi orb is too abstract for kids
- Kids engage with: visible growth, collection, competition, instant rewards

### Core Loop
```
Game Clear → Coins + EXP → Feed Monster → Growth & Evolution
          → Gacha Tickets → New Monster from Gacha
```

### Phase 1: Foundation (coins/tickets + teacher analytics)
- Add coins & gacha_tickets to users
- Award coins/tickets on game score save
- Teacher analytics: game-level reports, assignment completion tracking
- Weekly progress views, weakness detection

### Phase 2: Monster System
- Monster definitions DB (20-30 species, 3 evolution stages each)
- User monster collection (user_monsters table)
- Feeding/EXP/evolution logic
- Monster gallery UI + buddy display
- **Design: Owner provides original monster illustrations**

### Phase 3: Gacha & Daily Missions
- Gacha UI with egg-hatching animation
- Rarity system: ★1 Normal(60%) / ★2 Rare(25%) / ★3 SR(12%) / ★4 Legend(3%)
- Daily missions replacing checkin (e.g., "Clear 1 game today" → 3 food)
- Streak bonuses (3-day → ticket, 7-day → ★2+ guaranteed ticket)

### Phase 4: Migration & Cleanup
- Remove Mowi mascot system (stores/mowi.ts, MowiOrb.vue, checkin views)
- Remove morning/evening checkin
- Monster level = new progress indicator for teachers

### Game Integration Strategy: Hybrid
- **SDK (iframe)**: All games start here. Proper WiseGame SDK integration.
- **Vue integrated**: High-priority games migrated into MoWISE as components.
- **Migration path**: SDK → Vue component, one game at a time. Same saveScore() pipeline.
- **No breaking changes**: game_scores table is the same regardless of rendering method.

---

## Teacher Analytics Roadmap

| Priority | Feature | Status |
|---|---|---|
| HIGH | Game-level score reports (per game, per student) | Phase 1 |
| HIGH | Weekly/monthly progress charts | Phase 1 |
| HIGH | Assignment completion tracking | Phase 1 |
| MED | Auto weakness detection by category/grade | Phase 1 |
| MED | Parent sharing link (read-only) | Phase 2+ |
| MED | Cross-class comparison dashboard | Phase 2+ |
| LOW | CSV/PDF report export | Partial (CSV exists) |
| LOW | Inactivity alerts (3+ days) | Phase 2+ |

---

## Environment & Credentials

### Supabase
- Project: mowisse (yytxgxlhgotscwztlsqj)
- Region: ap-northeast-1 (Tokyo)
- Old project (INACTIVE): nrkhfkxzfaycehaxfdek

### Vercel
- Team: winniek75s-projects (team_TKGb96EGEQmtpfqNSUXhgZQE)
- Project: mowise (prj_BrOWx3U4I5yJt3PNh1124RArAkpd)
- Env vars: VITE_SUPABASE_URL + VITE_SUPABASE_ANON_KEY

### Game App URLs
All games at: `https://{game-id}-winniek75s-projects.vercel.app`
