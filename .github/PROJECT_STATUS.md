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

## Completed Phases

### Phase 1: Coins/Tickets + Teacher Analytics (COMPLETE)
- `coins` & `gacha_tickets` columns added to `users` table
- Coins/tickets awarded on game score save
- Teacher analytics: game-level reports, assignment completion tracking
- Weekly progress views, weakness detection

### Phase 2: Monster System (COMPLETE)
- **DB Tables**: `monster_species`, `user_monsters`
- Monster definitions: 20-30 species, 3 evolution stages, 4 rarities (common/uncommon/rare/legendary)
- User monster collection with buddy system
- Monster gallery UI + buddy display on home screen
- **Frontend**: MonsterGallery.vue, MonsterBuddy.vue, FeedingView.vue implemented
- **DB Functions**: `feed_monster()` — EXP gain → level up → stage evolution

### Phase 3: Gacha & Daily Missions (COMPLETE - DB Layer)

#### DB Tables Created
| Table | Purpose |
|-------|---------|
| `mission_definitions` | 16 mission templates (3 difficulty levels) |
| `user_daily_missions` | Per-user daily mission assignments & progress |
| `gacha_history` | Pull records with rarity/species/duplicate tracking |
| `login_streaks` | Consecutive login tracking with reward milestones |

#### Mission Definitions (16 total)
| Difficulty | Examples | Reward |
|------------|----------|--------|
| 1 (Easy) | Play 1 game, Clear 1 game, Feed monster, 70%+ accuracy | 10-20 coins or 1 food |
| 2 (Normal) | Play 5 games, 80%+ accuracy, Category challenges, Pull gacha | 25-30 coins |
| 3 (Hard) | Play 10 games, Clear 5 games, 90%+ accuracy, Play 15min | 1 gacha ticket |

#### DB Functions Created
| Function | Description |
|----------|-------------|
| `assign_daily_missions(user_id)` | Assigns 3 daily missions (1 per difficulty level), idempotent |
| `update_mission_progress(user_id, condition_type, increment, category)` | Updates matching mission progress, returns newly completed |
| `claim_mission_reward(user_id, mission_id)` | Claims reward (coins/tickets/food), prevents double-claim |
| `pull_gacha(user_id)` | Full gacha flow: ticket deduction → rarity roll → species pick → new/duplicate handling |
| `feed_monster(user_id, monster_id, exp_gain)` | Feed monster → EXP → level up → evolution check |
| `update_login_streak(user_id)` | Streak tracking + milestone rewards (3/7/14/30 day bonuses) |

#### Gacha Rarity Rates
| Rarity | Rate | Duplicate Compensation |
|--------|------|----------------------|
| Common | 50% | 10 coins |
| Uncommon | 30% | 20 coins |
| Rare | 15% | 50 coins |
| Legendary | 5% | 100 coins |

#### Login Streak Rewards
| Streak | Coins | Tickets |
|--------|-------|---------|
| Daily | 5 | 0 |
| 3 days | 15 | 0 |
| 7 days | 30 | 1 |
| 14 days | 50 | 2 |
| 30 days | 100 | 3 |
| Every 7 days | 20 | 1 |

#### RLS Policies Applied
- `mission_definitions` — public read
- `user_daily_missions` — user reads/updates own only
- `login_streaks` — user reads own only
- `gacha_history` — user reads own only

---

## Next Phases (TODO)

### Phase 3b: Frontend — Gacha & Mission UI
- [ ] **Daily Mission Panel** on student home screen (3 cards with progress bars)
- [ ] **Mission reward claim UI** with coin/ticket animation
- [ ] **Gacha Page** with egg-hatching / capsule animation
- [ ] **Gacha result modal** (new monster reveal vs duplicate coins)
- [ ] **Login streak popup** on daily first login (streak fire + reward display)
- [ ] **Integration**: Call `update_mission_progress()` from `gameStore.saveScore()`
- [ ] **Integration**: Call `assign_daily_missions()` on student login
- [ ] **Integration**: Call `update_login_streak()` on auth session start

### Phase 4: Migration & Cleanup
- [ ] Remove Mowi mascot system (`stores/mowi.ts`, `MowiOrb.vue`, checkin views)
- [ ] Remove morning/evening checkin
- [ ] Monster level = new progress indicator for teachers
- [ ] Clean up unused Mowi-related styles and components

### Phase 5: monster_species Seed Data
- [ ] Owner provides original monster illustrations (stage 1/2/3)
- [ ] Seed 20-30 monster species into `monster_species` table
- [ ] Assign category-linked monsters (eiken/grammar/phonics themed)

### Phase 6: Polish & Launch Prep
- [ ] Battle Pass / Season system
- [ ] League / Division leaderboards
- [ ] Boss Battles
- [ ] CSV/PDF analytics export for teachers
- [ ] Parent sharing link

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

## Full DB Schema (public tables)

| Table | Purpose |
|-------|---------|
| `users` | All users (teachers + students), coins, tickets, XP |
| `classes` | Teacher-created classes |
| `class_members` | Student-class membership |
| `student_pins` | PIN login for students |
| `game_catalog` | 18 game definitions |
| `game_scores` | All game play records |
| `assignments` | Teacher-assigned games |
| `badge_definitions` | Badge templates |
| `user_badges` | Earned badges |
| `subscriptions` | Plan management |
| `monster_species` | 20-30 monster definitions (4 rarities, 3 stages) |
| `user_monsters` | Player's monster collection |
| `gacha_history` | Gacha pull records |
| `mission_definitions` | 16 daily mission templates |
| `user_daily_missions` | Per-user daily mission state |
| `login_streaks` | Login streak tracking |
| `mowi_state` | (Legacy) Mowi mascot state — to be removed in Phase 4 |
| `checkins` | (Legacy) Morning/evening checkin — to be removed in Phase 4 |
| `teacher_feedback` | Teacher feedback on students |

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
