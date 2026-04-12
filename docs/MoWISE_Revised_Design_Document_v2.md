# MoWISE（モワイズ）改訂版設計書 v2.0
## 「もっと賢く、英語と生きる」- 現実的MVP戦略

**Version 2.0 | 2026年2月22日**  
**WISE English Club デジタル統合学習システム**

---

## 📋 改訂版の重要変更点

### 🔄 v1.0 からの主要変更

| 項目 | v1.0（旧版） | v2.0（改訂版） |
|------|-------------|----------------|
| **技術スタック** | React Native + Next.js + Vue.js | **Vue 3 + Capacitor統一** |
| **バックエンド** | Node.js + Firebase + PostgreSQL | **Supabase一本化** |
| **実装範囲** | Stage 0-5（6ステージ） | **Stage 0-2のみ（MVP）** |
| **ロードマップ** | 18ヶ月4フェーズ | **6ヶ月集中（Phase 1のみ）** |
| **VR戦略** | Spatial.io中心 | **WebXR中心（Phase 2以降）** |
| **収益予測** | Month 6: MRR ¥1.6M | **Month 6: MRR ¥169K（現実的）** |
| **YouTube** | 週3本投稿 | **週1本（質重視）** |
| **外注予算** | Phase 1: ¥400K | **Phase 1: ¥150K** |

---

## 📋 目次

1. [エグゼクティブサマリー](#1-エグゼクティブサマリー)
2. [MVP定義：Stage 0-2に集中](#2-mvp定義stage-0-2に集中)
3. [技術アーキテクチャ（統一スタック）](#3-技術アーキテクチャ統一スタック)
4. [学習システム詳細設計](#4-学習システム詳細設計)
5. [Moくん感情AI設計](#5-moくん感情ai設計)
6. [オンボーディング3ステップ](#6-オンボーディング3ステップ)
7. [コアループ設計（5分完結）](#7-コアループ設計5分完結)
8. [マネタイズ戦略（現実的版）](#8-マネタイズ戦略現実的版)
9. [6ヶ月実装ロードマップ](#9-6ヶ月実装ロードマップ)
10. [現実的KPI・収益予測](#10-現実的kpi収益予測)
11. [今週のTODOリスト](#11-今週のtodoリスト)
12. [リスク管理](#12-リスク管理)

---

## 1. エグゼクティブサマリー

### 1.1 改訂版のコアコンセプト

**MoWISE v2.0** は、「完璧な多機能アプリ」ではなく **「Stage 0-2を極めたMVP」** です。

**設計哲学**:
> 「580パターン全部」より「30パターンを完璧に習得できる体験」  
> 「18ヶ月で全機能」より「6ヶ月でコア機能を磨き切る」  
> 「React Nativeの最新技術」より「Vue.jsの既存資産100%活用」

### 1.2 MVP（最小限の製品）定義

```
【実装するもの】
✅ Stage 0: Pattern Starter（30パターン）
✅ Stage 1: MoWISE Sound（音韻冒険・既存MovWISE移植）
✅ Stage 2: MoWISE Grammar Level 1（英検5級文法）
✅ Moくん感情AI（成長ビジュアル＋励まし）
✅ オンボーディング3ステップ（3分完結）
✅ 進捗管理・Supabase同期
✅ iOS/Android/Webアプリ（Capacitor統一）
✅ YouTube連動QRコード

【Phase 2以降に延期】
⏸️ Stage 3-5（Pattern 580、Echo AI、VR）
⏸️ 韓国語UI・多言語展開
⏸️ 企業向けライセンス
⏸️ 書籍出版
```

### 1.3 市場ポジショニング（変更なし）

- **グローバル市場**: 2026年 $24.39B → 2031年 $508.2B
- **日本市場**: 英語学習 ¥9,000億円/年
- **競合**: Duolingo（MAU 135M）、スピークバディ、Lingvist
- **差別化**: 日本人特化×音韻科学×教室連携

### 1.4 改訂版の6ヶ月目標（現実的）

| 指標 | Month 3 | Month 6 | 備考 |
|------|---------|---------|------|
| **アプリDL** | 500 | 2,000 | 教室生徒＋YouTube流入 |
| **MAU** | 300 | 1,200 | DAU/MAU = 50% |
| **有料会員** | 15 | 50 | Premium 40 + Premium+ 10 |
| **MRR** | ¥51,780 | ¥169,200 | 詳細後述 |
| **YouTube登録者** | 500 | 3,000 | 週1本×26週 |
| **累積投資** | ¥75,000 | ¥150,000 | 外注最小化 |
| **純利益** | -¥30,000 | +¥50,000 | Month 6で黒字化 |

---

## 2. MVP定義：Stage 0-2に集中

### 2.1 MVP範囲の明確化

#### なぜ Stage 0-2 だけなのか？

**理由1**: Duolingoも最初は1言語（スペイン語）のみ  
**理由2**: 「広く浅く」より「狭く深く」で差別化  
**理由3**: 既存MovWISE資産（Sound + Grammar）を100%活用  
**理由4**: 1人開発で6ヶ月で完成させる現実的範囲

#### MVP完成の定義（6ヶ月後）

以下の条件を**全て満たした状態**をMVP完成とする：

1. ✅ **教育効果実証**: βテスター50名が3ヶ月継続し、Stage 2完了率 70%以上
2. ✅ **継続率達成**: Day 7継続率 60%以上、Day 30継続率 40%以上
3. ✅ **技術安定性**: クラッシュ率 < 0.5%、平均応答時間 < 2秒
4. ✅ **収益化成功**: 有料会員50名、MRR ¥169,200達成
5. ✅ **NPS高評価**: Net Promoter Score 50以上

### 2.2 Stage 0-2 の学習内容

#### Stage 0: Pattern Starter（超初級30パターン）

**対象**: 完全初心者、英語アレルギー層  
**目標**: 30パターンで「英語が話せる」初期体験  
**所要時間**: 10時間（1パターン20分）

**30パターン一覧**:
1. I'm [名前]. （自己紹介）
2. I like [名詞]. （好み表現）
3. I want [名詞]. （欲求）
4. I have [名詞]. （所有）
5. I'm [形容詞]. （状態）
6. It's [形容詞]. （説明）
7. This is [名詞]. （紹介）
8. Can I [動詞]? （依頼）
9. I can [動詞]. （能力）
10. I need [名詞]. （必要）
11. Where is [名詞]? （場所質問）
12. How much is [名詞]? （価格）
13. Thank you for [名詞]. （感謝）
14. I'm sorry for [名詞]. （謝罪）
15. I'm going to [動詞]. （未来）
16. I think [文]. （意見）
17. Do you like [名詞]? （質問）
18. How about [名詞]? （提案）
19. I don't understand [名詞]. （理解不足）
20. Can you help me? （助け求める）
21. I'm looking for [名詞]. （探し物）
22. It looks [形容詞]. （見た目）
23. I feel [形容詞]. （感情）
24. Let's [動詞]. （提案）
25. I'd like [名詞]. （丁寧な欲求）
26. What's [名詞]? （質問）
27. May I [動詞]? （丁寧な依頼）
28. I'm from [国名]. （出身）
29. Nice to meet you. （挨拶）
30. See you later. （別れ）

**ゲームモード**:
- Pattern Quest（RPG風ストーリー・村人との会話）
- Pattern Battle（4択クイズ・時間制限）
- Daily Challenge（朝・昼・晩の3回）

#### Stage 1: MoWISE Sound（音韻冒険）

**MovWISE Sound Adventure既存資産を移植**

**学習内容**:
- 44音素（母音12＋子音32）
- フォニックス A-Z
- 音節構造認識
- 語彙500-1000語

**ゲーム構成**（既存8種を移植）:
1. **Sound Hunter**: 音素を集めるアドベンチャー
2. **Phonics Island**: アルファベット島探検
3. **Rhythm Master**: リズム発音練習
4. **Sound Battle**: 音素対戦カードゲーム
5. **Vocabulary Quest**: 語彙冒険
6. **Pronunciation Trainer**: 発音トレーナー
7. **Listening Challenge**: リスニング挑戦
8. **Speaking Arena**: スピーキング対戦

**技術対応**:
- Vue.js既存コンポーネント → Capacitor対応調整
- 音声アセット → Supabase Storage移行
- 進捗データ → Supabase DB保存

#### Stage 2: MoWISE Grammar Level 1（英検5級相当）

**MovWISE Grammar Galaxy Level 1 移植**

**学習内容**:
- Be動詞（am/is/are）
- 一般動詞（現在形）
- 代名詞（I/You/He/She/It/We/They）
- 疑問詞（What/Where/Who/When）
- 基本文型（SV/SVC/SVO）
- 前置詞（in/on/at/to/from）

**ゲーム構成**（既存6種を移植）:
1. **Be動詞惑星**: am/is/are使い分けパズル
2. **Grammar Color Code**: 品詞色分けゲーム
3. **Pattern Hunter**: 文型パズル（落ち物）
4. **Grammar Reflex Arena**: 瞬間英作文
5. **Grammar Puzzle Cascade**: 並べ替え問題
6. **Sentence Architecture**: ブロック組み立て

### 2.3 Stage 3-5 は Phase 2 以降

**Phase 2（Month 7-12）で実装予定**:
- Stage 3: Pattern Master 100 → 300パターン
- Stage 4: Echo AI会話練習（GPT-4）

**Phase 3（Month 13-18）で実装予定**:
- Stage 5: VR Academy（WebXR）
- Pattern 300 → 580完成

---

## 3. 技術アーキテクチャ（統一スタック）

### 3.1 技術スタック全体図

```
┌─────────────────────────────────────────────┐
│         Frontend（統一コードベース）        │
├─────────────────────────────────────────────┤
│  Vue 3 + TypeScript + Vite                  │
│  ├─ Vuetify 3 (UI Component Library)       │
│  ├─ Pinia (State Management)               │
│  ├─ Vue Router (Routing)                   │
│  └─ Capacitor 6 (Native Bridge)            │
│      ├─ iOS App                             │
│      ├─ Android App                         │
│      └─ Web App (PWA)                       │
└─────────────┬───────────────────────────────┘
              │ REST API / Realtime
┌─────────────▼───────────────────────────────┐
│         Backend（Supabase統一）             │
├─────────────────────────────────────────────┤
│  Supabase (Backend-as-a-Service)           │
│  ├─ PostgreSQL (Database)                  │
│  ├─ Auth (User Authentication)             │
│  ├─ Storage (Media Files)                  │
│  ├─ Realtime (WebSocket Sync)              │
│  └─ Edge Functions (Serverless API)        │
└─────────────────────────────────────────────┘

┌─────────────────────────────────────────────┐
│         外部サービス（最小構成）            │
├─────────────────────────────────────────────┤
│  • ElevenLabs (TTS音声生成)                 │
│  • Azure Speech (発音評価・Phase 2)         │
│  • Stripe (決済・Month 3～)                 │
│  • YouTube Data API (QR連動・Phase 2)       │
└─────────────────────────────────────────────┘
```

### 3.2 技術選定の理由

#### Vue 3 + Capacitor 統一

**選定理由**:
1. ✅ **既存資産活用**: MovWISE の Vue.js コード100%再利用
2. ✅ **学習コスト削減**: 新技術（React Native）習得不要
3. ✅ **開発効率**: 1つのコードで iOS/Android/Web対応
4. ✅ **ネイティブ機能**: Capacitor Plugins（カメラ、音声、通知）
5. ✅ **コスト**: 完全無料（オープンソース）

**技術詳細**:
```json
// package.json
{
  "dependencies": {
    "vue": "^3.4.21",
    "vuetify": "^3.5.10",
    "pinia": "^2.1.7",
    "vue-router": "^4.3.0",
    "@capacitor/core": "^6.0.0",
    "@capacitor/ios": "^6.0.0",
    "@capacitor/android": "^6.0.0",
    "@capacitor/camera": "^6.0.0",
    "@capacitor/preferences": "^6.0.0",
    "@capacitor/push-notifications": "^6.0.0",
    "@supabase/supabase-js": "^2.39.8"
  }
}
```

#### Supabase 一本化

**選定理由**:
1. ✅ **All-in-One**: DB + Auth + Storage + Realtime
2. ✅ **コスト**: 無料枠で5万MAU対応（有料も$25/月～）
3. ✅ **SQL直接操作**: PostgreSQL で柔軟なクエリ
4. ✅ **オフライン対応**: Capacitor Preferences併用
5. ✅ **スケール**: 自動スケーリング

**Firebase ではなく Supabase を選ぶ理由**:
- ❌ Firebase: NoSQL（複雑なクエリ困難）、ベンダーロックイン
- ✅ Supabase: PostgreSQL（SQLそのまま）、オープンソース、移行容易

### 3.3 データベース設計（Supabase PostgreSQL）

#### スキーマ全体図

```sql
-- ========================================
-- Users & Profiles
-- ========================================
-- auth.users (Supabase Auth自動生成)
-- id, email, created_at など

CREATE TABLE public.user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT NOT NULL,
  age INTEGER CHECK (age >= 5 AND age <= 100),
  avatar_url TEXT,
  
  -- Learning Settings
  current_stage INTEGER DEFAULT 0 CHECK (current_stage >= 0 AND current_stage <= 2),
  current_level TEXT DEFAULT 'beginner' CHECK (current_level IN ('beginner', 'elementary', 'intermediate')),
  daily_target_minutes INTEGER DEFAULT 10 CHECK (daily_target_minutes > 0),
  
  -- Gamification
  total_xp INTEGER DEFAULT 0,
  current_streak INTEGER DEFAULT 0,
  longest_streak INTEGER DEFAULT 0,
  mokun_growth_stage INTEGER DEFAULT 0 CHECK (mokun_growth_stage >= 0 AND mokun_growth_stage <= 5),
  mokun_happiness INTEGER DEFAULT 50 CHECK (mokun_happiness >= 0 AND mokun_happiness <= 100),
  
  -- Subscription
  subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'premium', 'premium_plus')),
  subscription_expires_at TIMESTAMPTZ,
  
  -- Metadata
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- Learning Progress
-- ========================================
CREATE TABLE public.learning_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- Stage 0: Pattern Starter
  stage0_patterns_learned INTEGER DEFAULT 0 CHECK (stage0_patterns_learned >= 0 AND stage0_patterns_learned <= 30),
  stage0_mastery_rate DECIMAL(5,2) DEFAULT 0.00, -- 0.00-100.00
  
  -- Stage 1: Sound Adventure
  stage1_phonemes_mastered INTEGER DEFAULT 0 CHECK (stage1_phonemes_mastered >= 0 AND stage1_phonemes_mastered <= 44),
  stage1_vocabulary_count INTEGER DEFAULT 0,
  stage1_games_completed JSONB DEFAULT '[]', -- ["sound_hunter", "phonics_island", ...]
  
  -- Stage 2: Grammar Galaxy
  stage2_grammar_level INTEGER DEFAULT 1 CHECK (stage2_grammar_level >= 1 AND stage2_grammar_level <= 1), -- MVP: Level 1のみ
  stage2_games_completed JSONB DEFAULT '[]',
  
  -- Overall
  total_study_time_minutes INTEGER DEFAULT 0,
  last_study_date DATE,
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id)
);

-- ========================================
-- Pattern Progress（Stage 0 詳細）
-- ========================================
CREATE TABLE public.pattern_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  pattern_id TEXT NOT NULL, -- "P001" ~ "P030"
  
  -- Mastery
  mastery_level INTEGER DEFAULT 0 CHECK (mastery_level >= 0 AND mastery_level <= 5),
  -- 0: 未学習, 1: 見た, 2: 理解, 3: 練習, 4: 習得, 5: 完璧
  
  attempts INTEGER DEFAULT 0,
  correct_count INTEGER DEFAULT 0,
  incorrect_count INTEGER DEFAULT 0,
  
  last_practiced_at TIMESTAMPTZ,
  next_review_at TIMESTAMPTZ, -- SRS（間隔反復）用
  
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, pattern_id)
);

CREATE INDEX idx_pattern_progress_user ON pattern_progress(user_id);
CREATE INDEX idx_pattern_progress_next_review ON pattern_progress(next_review_at);

-- ========================================
-- Daily Study Sessions
-- ========================================
CREATE TABLE public.study_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  stage INTEGER NOT NULL CHECK (stage >= 0 AND stage <= 2),
  activity_type TEXT NOT NULL, -- "pattern_quest", "sound_hunter", "grammar_puzzle", etc.
  
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0),
  xp_earned INTEGER DEFAULT 0,
  
  performance_data JSONB, -- スコア、正解率など
  
  started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

CREATE INDEX idx_study_sessions_user_date ON study_sessions(user_id, started_at DESC);

-- ========================================
-- Badges & Achievements
-- ========================================
CREATE TABLE public.user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  badge_id TEXT NOT NULL, -- "sound_master", "grammar_wizard", "streak_7", etc.
  
  earned_at TIMESTAMPTZ DEFAULT NOW(),
  
  UNIQUE(user_id, badge_id)
);

-- ========================================
-- Mokun Interactions（感情AI用）
-- ========================================
CREATE TABLE public.mokun_interactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  event_type TEXT NOT NULL, -- "correct_answer", "streak_broken", "new_level", etc.
  mokun_reaction TEXT NOT NULL, -- "jump_joy", "sad_wilt", "bloom_flower"
  message TEXT,
  
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_mokun_interactions_user ON mokun_interactions(user_id, created_at DESC);

-- ========================================
-- Triggers（自動更新）
-- ========================================
-- updated_atを自動更新
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_user_profiles_updated_at
  BEFORE UPDATE ON user_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_learning_progress_updated_at
  BEFORE UPDATE ON learning_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_pattern_progress_updated_at
  BEFORE UPDATE ON pattern_progress
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- Row Level Security (RLS)
-- ========================================
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE pattern_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE mokun_interactions ENABLE ROW LEVEL SECURITY;

-- ユーザーは自分のデータのみ読み書き可能
CREATE POLICY "Users can view own profile" ON user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON user_profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view own progress" ON learning_progress
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update own progress" ON learning_progress
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own patterns" ON pattern_progress
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own sessions" ON study_sessions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view own badges" ON user_badges
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own mokun interactions" ON mokun_interactions
  FOR ALL USING (auth.uid() = user_id);
```

### 3.4 Capacitor統合コード例

#### Supabase + Capacitor 初期化

```typescript
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js'
import { Preferences } from '@capacitor/preferences'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    // Capacitorでは標準のブラウザストレージではなくPreferences使用
    storage: {
      getItem: async (key: string) => {
        const { value } = await Preferences.get({ key })
        return value
      },
      setItem: async (key: string, value: string) => {
        await Preferences.set({ key, value })
      },
      removeItem: async (key: string) => {
        await Preferences.remove({ key })
      }
    },
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false // Capacitorではfalse
  }
})

// オフライン対応：ローカルに保存して後で同期
export async function saveOfflineProgress(data: any) {
  const existing = await Preferences.get({ key: 'offline_progress' })
  const queue = existing.value ? JSON.parse(existing.value) : []
  queue.push({ ...data, timestamp: Date.now() })
  await Preferences.set({ key: 'offline_progress', value: JSON.stringify(queue) })
}

export async function syncOfflineProgress() {
  const { value } = await Preferences.get({ key: 'offline_progress' })
  if (!value) return
  
  const queue = JSON.parse(value)
  for (const item of queue) {
    try {
      await supabase.from('study_sessions').insert(item)
    } catch (error) {
      console.error('Sync error:', error)
    }
  }
  
  await Preferences.remove({ key: 'offline_progress' })
}
```

#### 音声録音（発音評価用）

```typescript
// src/composables/useVoiceRecorder.ts
import { ref } from 'vue'
import { Capacitor } from '@capacitor/core'
import { VoiceRecorder } from 'capacitor-voice-recorder'

export function useVoiceRecorder() {
  const isRecording = ref(false)
  const audioBlob = ref<Blob | null>(null)
  
  async function startRecording() {
    // 権限チェック
    const permission = await VoiceRecorder.requestAudioRecordingPermission()
    if (!permission.value) {
      throw new Error('マイク権限がありません')
    }
    
    await VoiceRecorder.startRecording()
    isRecording.value = true
  }
  
  async function stopRecording() {
    const result = await VoiceRecorder.stopRecording()
    isRecording.value = false
    
    // base64からBlobに変換
    const base64Sound = result.value.recordDataBase64
    const mimeType = result.value.mimeType
    
    const byteCharacters = atob(base64Sound)
    const byteNumbers = new Array(byteCharacters.length)
    for (let i = 0; i < byteCharacters.length; i++) {
      byteNumbers[i] = byteCharacters.charCodeAt(i)
    }
    const byteArray = new Uint8Array(byteNumbers)
    audioBlob.value = new Blob([byteArray], { type: mimeType })
    
    return audioBlob.value
  }
  
  return {
    isRecording,
    audioBlob,
    startRecording,
    stopRecording
  }
}
```

#### プッシュ通知（Moくんの励まし）

```typescript
// src/composables/usePushNotifications.ts
import { PushNotifications } from '@capacitor/push-notifications'
import { supabase } from '@/lib/supabase'

export async function setupPushNotifications() {
  // 権限リクエスト
  const permission = await PushNotifications.requestPermissions()
  if (permission.receive !== 'granted') {
    return
  }
  
  // 登録
  await PushNotifications.register()
  
  // トークン取得
  PushNotifications.addListener('registration', async (token) => {
    console.log('Push token:', token.value)
    
    // Supabaseにトークン保存
    const { data: { user } } = await supabase.auth.getUser()
    if (user) {
      await supabase
        .from('user_profiles')
        .update({ push_token: token.value })
        .eq('id', user.id)
    }
  })
  
  // 通知受信
  PushNotifications.addListener('pushNotificationReceived', (notification) => {
    console.log('Push received:', notification)
    // Moくんアニメーション表示など
  })
}

// Moくんの励ましスケジュール（Supabase Edge Function）
export async function scheduleMokunReminder(userId: string, delayDays: number) {
  // Supabase Edge Functionを呼び出し
  await supabase.functions.invoke('schedule-notification', {
    body: {
      userId,
      delayDays,
      message: '久しぶり！Moくん寂しかったよ🌱',
      type: 'mokun_reminder'
    }
  })
}
```

### 3.5 月間コスト見積もり（6ヶ月間）

| サービス | プラン | Month 1-3 | Month 4-6 | 備考 |
|---------|--------|-----------|-----------|------|
| **Supabase** | Free | $0 | $0 | 500MB DB, 1GB Storage, 50k MAU |
| **ElevenLabs** | Starter | $11 (¥1,650) | $11 (¥1,650) | 30万文字/月（音声生成） |
| **Vercel** | Hobby | $0 | $0 | Web版ホスティング |
| **Apple Developer** | 年間 | $99 (¥14,850/12) | 同左 | iOS配信必須 |
| **Google Play** | 買い切り | $25 (¥3,750/6) | $0 | Android配信 |
| **Canva Pro** | 月額 | $13 (¥1,950) | 同左 | YouTube/SNS素材 |
| **freee会計** | 月額 | ¥1,980 | 同左 | 個人事業主必須 |
| **ドメイン** | 年間 | ¥3,500/12 = ¥291 | 同左 | mowise.jp/.com |
| **合計** | - | **¥7,559/月** | **¥7,559/月** | |

**Phase 1（6ヶ月）総コスト**: ¥45,354

---

## 4. 学習システム詳細設計

### 4.1 Stage 0: Pattern Starter（30パターン）

#### 学習フロー（1パターン = 20分）

```
【5分セッション × 4回 = 1パターン完全習得】

Session 1: 初回学習（5分）
├─ パターン提示（30秒）
├─ 例文5個リスニング（90秒）
├─ リピート練習（120秒）
└─ 4択クイズ5問（90秒）

Session 2: 定着確認（5分）
├─ 復習（30秒）
├─ 穴埋め問題10問（180秒）
└─ 瞬間英作文5問（90秒）

Session 3: 実践練習（5分）
├─ Pattern Quest（ストーリーモード）
└─ NPCとの会話シミュレーション

Session 4: マスターテスト（5分）
├─ 総合テスト10問
├─ 音声認識チェック（Phase 2）
└─ Moくん成長演出
```

#### Pattern Quest（RPGストーリーモード）

**ストーリー設定**:
- 主人公（ユーザー）が英語王国の村人と交流
- 30のパターン = 30人のNPC
- 各NPCとの会話で1パターン習得

**NPC例**:
1. **村長（Pattern 1: I'm [名前]）**
   - 村長: "Welcome! Who are you?"
   - プレイヤー: 選択肢 → "I'm [your name]."
   - 村長: "Nice to meet you! Let me introduce others."

2. **パン屋（Pattern 2: I like [名詞]）**
   - パン屋: "Try my bread! What do you like?"
   - 選択肢: "I like bread." / "I like cake." / "I like cookies."

3. **冒険者ギルド（Pattern 8: Can I [動詞]?）**
   - ギルドマスター: "Want to join? Ask me!"
   - プレイヤー: "Can I join?" → ✅正解で加入

**ゲームメカニクス**:
- 正解 → NPCが好感度UP、次のNPCアンロック
- 不正解 → Moくんがヒント表示、再挑戦
- 30人コンプリート → Stage 1へ進める

#### Pattern Battle（対戦モード・Phase 2機能）

**概要**: 他ユーザーとリアルタイム4択対戦  
**実装**: Supabase Realtimeで同期

```typescript
// Phase 2実装予定
// pattern-battle.ts
import { supabase } from '@/lib/supabase'

async function joinBattle() {
  // マッチング
  const { data: room } = await supabase
    .from('battle_rooms')
    .select('*')
    .eq('status', 'waiting')
    .limit(1)
    .single()
  
  if (!room) {
    // 新規ルーム作成
    const { data: newRoom } = await supabase
      .from('battle_rooms')
      .insert({ status: 'waiting', player1: userId })
      .select()
      .single()
    
    // Realtime購読
    const channel = supabase.channel(`battle:${newRoom.id}`)
    channel.on('broadcast', { event: 'answer' }, handleOpponentAnswer)
    channel.subscribe()
  }
}
```

### 4.2 Stage 1: MoWISE Sound（音韻冒険）

#### MovWISE既存資産の移行タスク

**移行対象**:
- Vue.jsコンポーネント8ゲーム分
- 音声アセット（44音素 × 5例 × 2スピーカー = 440ファイル）
- 進捗管理ロジック

**移行手順**:
1. **Week 1-2**: Dexie.js → Supabase移行
   ```typescript
   // 旧: Dexie.js
   await db.progress.put({ userId, phoneme: 'ae', mastery: 3 })
   
   // 新: Supabase
   await supabase
     .from('learning_progress')
     .upsert({ 
       user_id: userId, 
       stage1_phonemes_mastered: 15,
       stage1_games_completed: ['sound_hunter', 'phonics_island']
     })
   ```

2. **Week 3-4**: Capacitor Audio対応
   ```typescript
   // Capacitor + Howler.js for audio
   import { Howl } from 'howler'
   
   const sound = new Howl({
     src: ['https://supabase.co/.../phoneme_ae.mp3'],
     html5: true, // モバイル最適化
     preload: true
   })
   
   sound.play()
   ```

3. **Week 5-6**: UI調整（モバイル最適化）
   - タッチ操作最適化
   - 画面サイズ対応（Vuetifyグリッド）
   - 横画面対応

#### Sound Hunter（音素コレクションゲーム）

**既存ゲームの改良点**:
- ✅ **Moくん統合**: 音素を集めるとMoくんが成長
- ✅ **プッシュ通知**: 1日1音素の通知
- ✅ **ソーシャル**: 友達の進捗が見える（Phase 2）

### 4.3 Stage 2: MoWISE Grammar Level 1

#### Grammar Color Code（品詞色分けゲーム）

**ゲーム内容**:
- 英文が表示される
- 各単語を正しい色にタップ
  - 名詞 = 青
  - 動詞 = 赤
  - 形容詞 = 緑
  - 前置詞 = 黄色

**例題**:
```
"I like big cats."
正解: I(青) like(赤) big(緑) cats(青).
```

**技術実装**:
```vue
<!-- GrammarColorCode.vue -->
<template>
  <div class="sentence">
    <span
      v-for="(word, index) in words"
      :key="index"
      :class="['word', userColors[index]]"
      @click="cycleColor(index)"
    >
      {{ word }}
    </span>
  </div>
  <v-btn @click="checkAnswer">チェック</v-btn>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const sentence = "I like big cats."
const words = sentence.split(' ')
const correctColors = ['blue', 'red', 'green', 'blue'] // 正解
const userColors = ref<string[]>(Array(words.length).fill('gray'))

const colors = ['gray', 'blue', 'red', 'green', 'yellow']

function cycleColor(index: number) {
  const currentIndex = colors.indexOf(userColors.value[index])
  userColors.value[index] = colors[(currentIndex + 1) % colors.length]
}

async function checkAnswer() {
  const isCorrect = userColors.value.every((c, i) => c === correctColors[i])
  
  if (isCorrect) {
    // XP付与 + Moくん反応
    await supabase.rpc('add_xp', { user_id: userId, xp: 10 })
    showMokunReaction('jump_joy', 'すごい！完璧だよ！')
  } else {
    showMokunReaction('think_hard', 'もう一度考えてみよう')
  }
}
</script>
```

---

## 5. Moくん感情AI設計

### 5.1 Moくんの状態管理

#### 感情パラメータ

```typescript
// types/mokun.ts
export interface MokunState {
  // 成長段階（0=種、1=芽、2=苗、3=若木、4=木、5=開花）
  growth_stage: 0 | 1 | 2 | 3 | 4 | 5;
  
  // 幸福度（0-100）
  happiness: number;
  
  // 最終インタラクション時刻
  last_interaction: Date;
  
  // ユーザーの連続日数
  user_streak: number;
  
  // 学習進捗（全ステージ合計）
  total_progress: number; // 0-100%
}

// Moくんの成長条件
export const GROWTH_THRESHOLDS = {
  0: { xp: 0, name: '種' },
  1: { xp: 100, name: '芽' },
  2: { xp: 500, name: '苗' },
  3: { xp: 1500, name: '若木' },
  4: { xp: 5000, name: '木' },
  5: { xp: 10000, name: '開花' }
}
```

### 5.2 感情反応ロジック

```typescript
// composables/useMokun.ts
import { ref, computed } from 'vue'
import { supabase } from '@/lib/supabase'

export function useMokun(userId: string) {
  const mokunState = ref<MokunState>({
    growth_stage: 0,
    happiness: 50,
    last_interaction: new Date(),
    user_streak: 0,
    total_progress: 0
  })
  
  // 幸福度計算
  const happinessLevel = computed(() => {
    if (mokunState.value.happiness >= 80) return 'very_happy'
    if (mokunState.value.happiness >= 60) return 'happy'
    if (mokunState.value.happiness >= 40) return 'neutral'
    if (mokunState.value.happiness >= 20) return 'sad'
    return 'very_sad'
  })
  
  // イベント別反応
  function getMokunReaction(event: string): {
    animation: string;
    message: string;
    sound?: string;
  } {
    const reactions = {
      correct_answer: [
        { animation: 'jump_joy', message: 'やった！', sound: 'cheer.mp3' },
        { animation: 'clap', message: 'すごい！', sound: 'applause.mp3' },
        { animation: 'spin', message: '完璧だよ！', sound: 'success.mp3' }
      ],
      wrong_answer: [
        { animation: 'think_hard', message: '大丈夫、もう一度！', sound: 'hmm.mp3' },
        { animation: 'scratch_head', message: 'ヒント見る？', sound: null },
        { animation: 'encourage', message: '惜しい！あと少し！', sound: 'encourage.mp3' }
      ],
      streak_broken: {
        animation: 'sad_wilt',
        message: '久しぶり…待ってたよ😢',
        sound: 'sad.mp3'
      },
      new_level: {
        animation: 'bloom_flower',
        message: '新しいレベルだ！一緒に頑張ろう！🌸',
        sound: 'levelup.mp3'
      },
      daily_first_login: {
        animation: 'wave_hello',
        message: 'おはよう！今日も頑張ろうね！',
        sound: 'morning.mp3'
      },
      study_5min: {
        animation: 'thumbs_up',
        message: '5分達成！いい調子だよ！',
        sound: 'good.mp3'
      },
      study_30min: {
        animation: 'celebrate',
        message: '30分も頑張ったね！すごい！',
        sound: 'amazing.mp3'
      }
    }
    
    if (event === 'correct_answer' || event === 'wrong_answer') {
      const options = reactions[event]
      return options[Math.floor(Math.random() * options.length)]
    }
    
    return reactions[event as keyof typeof reactions] || {
      animation: 'idle',
      message: '頑張って！',
      sound: null
    }
  }
  
  // Moくん成長チェック
  async function checkGrowth(currentXP: number) {
    const newStage = Object.entries(GROWTH_THRESHOLDS)
      .reverse()
      .find(([_, threshold]) => currentXP >= threshold.xp)?.[0]
    
    const stageNumber = parseInt(newStage || '0')
    
    if (stageNumber > mokunState.value.growth_stage) {
      mokunState.value.growth_stage = stageNumber as MokunState['growth_stage']
      
      // 成長演出
      await showGrowthAnimation(stageNumber)
      
      // DB更新
      await supabase
        .from('user_profiles')
        .update({ mokun_growth_stage: stageNumber })
        .eq('id', userId)
      
      // インタラクション記録
      await supabase
        .from('mokun_interactions')
        .insert({
          user_id: userId,
          event_type: 'growth',
          mokun_reaction: 'bloom_flower',
          message: `Moくんが「${GROWTH_THRESHOLDS[stageNumber].name}」に成長したよ！`
        })
    }
  }
  
  // 幸福度更新
  async function updateHappiness(delta: number) {
    mokunState.value.happiness = Math.max(0, Math.min(100, mokunState.value.happiness + delta))
    
    await supabase
      .from('user_profiles')
      .update({ mokun_happiness: mokunState.value.happiness })
      .eq('id', userId)
  }
  
  return {
    mokunState,
    happinessLevel,
    getMokunReaction,
    checkGrowth,
    updateHappiness
  }
}
```

### 5.3 Moくんアニメーション

**実装方法**: Lottie（軽量JSONアニメーション）

```vue
<!-- components/MokunCharacter.vue -->
<template>
  <div class="mokun-container">
    <vue-lottie
      :animation-data="currentAnimation"
      :loop="isLooping"
      @complete="onAnimationComplete"
    />
    <div v-if="message" class="mokun-message">
      {{ message }}
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useLottie } from '@/composables/useLottie'

// アニメーションJSON（Lottie Files）
import idleAnim from '@/assets/lottie/mokun_idle.json'
import jumpJoyAnim from '@/assets/lottie/mokun_jump_joy.json'
import sadWiltAnim from '@/assets/lottie/mokun_sad_wilt.json'
import bloomFlowerAnim from '@/assets/lottie/mokun_bloom_flower.json'

const props = defineProps<{
  animation: string;
  message?: string;
}>()

const animations = {
  idle: idleAnim,
  jump_joy: jumpJoyAnim,
  sad_wilt: sadWiltAnim,
  bloom_flower: bloomFlowerAnim
  // ... 他のアニメーション
}

const currentAnimation = ref(animations.idle)
const isLooping = ref(true)
const message = ref('')

watch(() => props.animation, (newAnim) => {
  currentAnimation.value = animations[newAnim as keyof typeof animations] || animations.idle
  isLooping.value = newAnim === 'idle'
  message.value = props.message || ''
  
  // 3秒後にidleに戻る
  if (newAnim !== 'idle') {
    setTimeout(() => {
      currentAnimation.value = animations.idle
      isLooping.value = true
      message.value = ''
    }, 3000)
  }
})
</script>

<style scoped>
.mokun-container {
  position: relative;
  width: 200px;
  height: 200px;
}

.mokun-message {
  position: absolute;
  bottom: -40px;
  left: 50%;
  transform: translateX(-50%);
  background: white;
  border: 2px solid #1E3A8A;
  border-radius: 20px;
  padding: 8px 16px;
  font-size: 14px;
  white-space: nowrap;
  box-shadow: 0 2px 8px rgba(0,0,0,0.1);
}

.mokun-message::before {
  content: '';
  position: absolute;
  top: -10px;
  left: 50%;
  transform: translateX(-50%);
  width: 0;
  height: 0;
  border-left: 10px solid transparent;
  border-right: 10px solid transparent;
  border-bottom: 10px solid #1E3A8A;
}
</style>
```

### 5.4 Moくんプッシュ通知戦略

```typescript
// services/mokun-notifications.ts
import { PushNotifications } from '@capacitor/push-notifications'

export const MOKUN_NOTIFICATION_TEMPLATES = {
  morning: {
    title: 'おはよう！☀️',
    body: 'Moくんが待ってるよ。今日も一緒に5分だけ勉強しよう！',
    schedule: { hour: 8, minute: 0 }
  },
  evening: {
    title: 'こんばんは！🌙',
    body: '今日はまだ勉強してないね。Moくんが寂しがってるよ😢',
    schedule: { hour: 20, minute: 0 }
  },
  streak_3days: {
    title: '3日連続達成！🔥',
    body: 'すごい！Moくんも元気いっぱいだよ！',
    immediate: true
  },
  streak_broken: {
    title: 'Moくんが心配してるよ…',
    body: '3日間来てないね。元気？戻ってきてね🌱',
    delay: 3 * 24 * 60 * 60 * 1000 // 3日後
  }
}

export async function scheduleMokunNotification(
  type: keyof typeof MOKUN_NOTIFICATION_TEMPLATES,
  userId: string
) {
  const template = MOKUN_NOTIFICATION_TEMPLATES[type]
  
  if (template.immediate) {
    await PushNotifications.schedule({
      notifications: [{
        title: template.title,
        body: template.body,
        id: Date.now(),
        schedule: { at: new Date(Date.now() + 1000) }
      }]
    })
  } else if (template.schedule) {
    const now = new Date()
    const scheduleDate = new Date(
      now.getFullYear(),
      now.getMonth(),
      now.getDate(),
      template.schedule.hour,
      template.schedule.minute
    )
    
    if (scheduleDate < now) {
      scheduleDate.setDate(scheduleDate.getDate() + 1)
    }
    
    await PushNotifications.schedule({
      notifications: [{
        title: template.title,
        body: template.body,
        id: Date.now(),
        schedule: { at: scheduleDate, repeats: true, every: 'day' }
      }]
    })
  }
}
```

---

## 6. オンボーディング3ステップ

### 6.1 初回起動フロー

```
アプリ起動（初回）
    ↓
スプラッシュ画面（2秒）
    ↓
【Step 1】ウェルカム画面（30秒）
    ↓
【Step 2】診断クイズ（90秒）
    ↓
【Step 3】Moくん誕生（60秒）
    ↓
Stage 0 Pattern #1 自動開始
```

### 6.2 Step 1: ウェルカム画面

```vue
<!-- views/Onboarding/Welcome.vue -->
<template>
  <v-container class="welcome-screen fill-height">
    <v-row align="center" justify="center">
      <v-col cols="12" class="text-center">
        <!-- Moくん種のアニメーション -->
        <vue-lottie
          :animation-data="seedAnimation"
          :loop="true"
          style="width: 200px; height: 200px; margin: 0 auto;"
        />
        
        <h1 class="text-h4 mt-8 mb-4" style="color: #1E3A8A;">
          MoWISE へようこそ
        </h1>
        
        <p class="text-h6 mb-8" style="color: #6B7280;">
          もっと賢く、英語と生きる
        </p>
        
        <v-card class="pa-6 mb-8" elevation="2">
          <v-icon size="48" color="primary">mdi-lightbulb-on</v-icon>
          <p class="text-body-1 mt-4">
            3つの質問で、あなたにぴったりの<br>
            スタート地点を見つけます
          </p>
        </v-card>
        
        <v-btn
          color="primary"
          size="x-large"
          rounded
          @click="startQuiz"
        >
          始める
          <v-icon end>mdi-arrow-right</v-icon>
        </v-btn>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup lang="ts">
import { useRouter } from 'vue-router'
import seedAnimation from '@/assets/lottie/mokun_seed.json'

const router = useRouter()

function startQuiz() {
  router.push('/onboarding/quiz')
}
</script>
```

### 6.3 Step 2: 診断クイズ

```vue
<!-- views/Onboarding/Quiz.vue -->
<template>
  <v-container class="quiz-screen">
    <v-progress-linear
      :model-value="progress"
      color="primary"
      height="8"
      rounded
    />
    
    <v-card class="mt-8 pa-6" elevation="4">
      <h2 class="text-h5 mb-6">{{ questions[currentQuestion].title }}</h2>
      
      <v-radio-group v-model="answers[currentQuestion]">
        <v-radio
          v-for="option in questions[currentQuestion].options"
          :key="option.value"
          :label="option.label"
          :value="option.value"
          color="primary"
        />
      </v-radio-group>
      
      <v-btn
        v-if="currentQuestion < questions.length - 1"
        color="primary"
        block
        size="large"
        :disabled="!answers[currentQuestion]"
        @click="nextQuestion"
      >
        次へ
      </v-btn>
      
      <v-btn
        v-else
        color="success"
        block
        size="large"
        :disabled="!answers[currentQuestion]"
        @click="completeQuiz"
      >
        完了
      </v-btn>
    </v-card>
  </v-container>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'

const router = useRouter()

const questions = [
  {
    title: 'あなたの英語レベルは？',
    options: [
      { label: 'ほぼゼロ（ABCも危うい）', value: 'zero' },
      { label: '中学英語はなんとか', value: 'junior_high' },
      { label: '高校英語まで覚えてる', value: 'high_school' },
      { label: '英検準2級以上', value: 'advanced' }
    ]
  },
  {
    title: '何が一番苦手？',
    options: [
      { label: '発音・リスニング', value: 'pronunciation' },
      { label: '文法・語順', value: 'grammar' },
      { label: '単語が出てこない', value: 'vocabulary' },
      { label: '実際に話せない', value: 'speaking' }
    ]
  },
  {
    title: '1日何分なら続けられる？',
    options: [
      { label: '5分', value: 5 },
      { label: '10分', value: 10 },
      { label: '30分', value: 30 },
      { label: '1時間', value: 60 }
    ]
  }
]

const currentQuestion = ref(0)
const answers = ref<any[]>([])

const progress = computed(() => ((currentQuestion.value + 1) / questions.length) * 100)

function nextQuestion() {
  currentQuestion.value++
}

async function completeQuiz() {
  // 診断結果から推奨Stageを決定
  const level = answers.value[0]
  const weakness = answers.value[1]
  const dailyMinutes = answers.value[2]
  
  let recommendedStage = 0
  if (level === 'zero') recommendedStage = 0
  else if (level === 'junior_high') recommendedStage = 1
  else if (level === 'high_school') recommendedStage = 2
  
  // Supabaseに保存
  const { data: { user } } = await supabase.auth.getUser()
  if (user) {
    await supabase
      .from('user_profiles')
      .update({
        current_stage: recommendedStage,
        daily_target_minutes: dailyMinutes,
        onboarding_data: {
          level,
          weakness,
          dailyMinutes,
          completed_at: new Date().toISOString()
        }
      })
      .eq('id', user.id)
  }
  
  router.push('/onboarding/mokun-birth')
}
</script>
```

### 6.4 Step 3: Moくん誕生

```vue
<!-- views/Onboarding/MokunBirth.vue -->
<template>
  <v-container class="mokun-birth-screen fill-height">
    <v-row align="center" justify="center">
      <v-col cols="12" class="text-center">
        <h2 class="text-h5 mb-8">
          あなた専用のMoくんが誕生！
        </h2>
        
        <!-- 成長アニメーション: 種 → 芽 → 小さな木 -->
        <vue-lottie
          :animation-data="birthAnimation"
          :loop="false"
          @complete="onAnimationComplete"
          style="width: 300px; height: 300px; margin: 0 auto;"
        />
        
        <v-card class="mt-8 pa-6" elevation="2">
          <p class="text-body-1 mb-4">
            学習するほど、Moくんも成長します
          </p>
          
          <v-progress-linear
            :model-value="growthProgress"
            color="success"
            height="20"
            rounded
          >
            <template v-slot:default>
              {{ growthProgress }}%
            </template>
          </v-progress-linear>
          
          <p class="text-caption mt-2 text-grey">
            次の成長まで: {{ nextGrowthXP }} XP
          </p>
        </v-card>
        
        <v-btn
          v-if="animationDone"
          color="primary"
          size="x-large"
          rounded
          class="mt-8"
          @click="startLearning"
        >
          最初のレッスンを始める
          <v-icon end>mdi-sprout</v-icon>
        </v-btn>
      </v-col>
    </v-row>
  </v-container>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import birthAnimation from '@/assets/lottie/mokun_birth.json'

const router = useRouter()

const animationDone = ref(false)
const growthProgress = ref(0)
const nextGrowthXP = ref(100)

onMounted(() => {
  // 成長バーアニメーション
  let current = 0
  const interval = setInterval(() => {
    current += 2
    growthProgress.value = Math.min(current, 10) // 初期10%
    if (current >= 10) clearInterval(interval)
  }, 50)
})

function onAnimationComplete() {
  animationDone.value = true
}

function startLearning() {
  router.push('/learn/stage0/pattern/P001')
}
</script>
```

---

## 7. コアループ設計（5分完結）

### 7.1 5分セッションの構造

```
┌──────────────────────────────────────────┐
│         1セッション = 5分               │
├──────────────────────────────────────────┤
│ 00:00-00:30  パターン提示               │
│              音声＋字幕＋例文1個         │
├──────────────────────────────────────────┤
│ 00:30-02:00  インプット（90秒）         │
│              例文5個を聞く＋リピート     │
│              Moくん応援コメント          │
├──────────────────────────────────────────┤
│ 02:00-04:00  ドリル（120秒）            │
│              4択クイズ 5問               │
│              正解→Moくんジャンプ         │
│              不正解→ヒント表示            │
├──────────────────────────────────────────┤
│ 04:00-04:30  瞬間英作文（30秒）         │
│              日本語→3秒以内に英語        │
│              1問のみ（初級者向け）       │
├──────────────────────────────────────────┤
│ 04:30-05:00  達成感演出（30秒）         │
│              ✨ +50 XP！                 │
│              🌱 Moくん成長バー+5%        │
│              🔥 連続3日！                │
│              [次へ] / [今日は終了]       │
└──────────────────────────────────────────┘
```

### 7.2 コアループ実装

```vue
<!-- views/Learn/PatternSession.vue -->
<template>
  <v-container class="pattern-session">
    <!-- 進捗バー -->
    <v-progress-linear
      :model-value="sessionProgress"
      color="primary"
      height="8"
      class="mb-4"
    />
    
    <v-card class="pa-6" elevation="4">
      <!-- Phase 1: パターン提示 -->
      <div v-if="phase === 'intro'" class="text-center">
        <h2 class="text-h4 mb-4">{{ currentPattern.pattern }}</h2>
        <p class="text-h6 text-grey mb-6">{{ currentPattern.patternJa }}</p>
        
        <v-btn
          icon
          size="x-large"
          color="primary"
          @click="playAudio(currentPattern.examples[0].audioUrl)"
        >
          <v-icon>mdi-volume-high</v-icon>
        </v-btn>
        
        <p class="text-body-1 mt-4">
          {{ currentPattern.examples[0].en }}
        </p>
        <p class="text-body-2 text-grey">
          {{ currentPattern.examples[0].ja }}
        </p>
      </div>
      
      <!-- Phase 2: インプット -->
      <div v-if="phase === 'input'" class="input-phase">
        <mokun-character animation="encourage" message="一緒に言ってみよう！" />
        
        <v-card
          v-for="(example, index) in currentPattern.examples.slice(0, 5)"
          :key="index"
          class="mb-4 pa-4"
          :class="{ 'active-example': currentExampleIndex === index }"
        >
          <v-row align="center">
            <v-col cols="2">
              <v-btn
                icon
                @click="playAudio(example.audioUrl)"
              >
                <v-icon>mdi-play</v-icon>
              </v-btn>
            </v-col>
            <v-col cols="10">
              <p class="text-body-1 mb-1">{{ example.en }}</p>
              <p class="text-body-2 text-grey">{{ example.ja }}</p>
            </v-col>
          </v-row>
        </v-card>
        
        <v-btn
          color="primary"
          block
          @click="nextPhase"
        >
          次へ進む
        </v-btn>
      </div>
      
      <!-- Phase 3: ドリル -->
      <div v-if="phase === 'drill'">
        <h3 class="text-h6 mb-4">問題 {{ drillQuestionIndex + 1 }} / 5</h3>
        
        <p class="text-body-1 mb-6">
          {{ drillQuestions[drillQuestionIndex].question }}
        </p>
        
        <v-radio-group v-model="selectedAnswer">
          <v-radio
            v-for="(option, index) in drillQuestions[drillQuestionIndex].options"
            :key="index"
            :label="option"
            :value="index"
            color="primary"
          />
        </v-radio-group>
        
        <v-btn
          color="primary"
          block
          :disabled="selectedAnswer === null"
          @click="checkAnswer"
        >
          答え合わせ
        </v-btn>
      </div>
      
      <!-- Phase 4: 瞬間英作文 -->
      <div v-if="phase === 'translation'">
        <mokun-character animation="think_hard" message="3秒以内に答えてみて！" />
        
        <v-card class="pa-6 mb-6 text-center" color="blue-lighten-5">
          <p class="text-h6">{{ translationQuestion.ja }}</p>
        </v-card>
        
        <v-progress-circular
          :model-value="timeLeft"
          :size="80"
          :width="8"
          color="warning"
          class="mb-4"
        >
          {{ Math.ceil(timeLeft / 100 * 3) }}s
        </v-progress-circular>
        
        <v-text-field
          v-model="userTranslation"
          label="英語で答えてみよう"
          variant="outlined"
          @keyup.enter="submitTranslation"
        />
        
        <v-btn
          color="primary"
          block
          @click="submitTranslation"
        >
          答える
        </v-btn>
      </div>
      
      <!-- Phase 5: 達成感演出 -->
      <div v-if="phase === 'completion'" class="text-center">
        <mokun-character animation="jump_joy" message="やったね！" />
        
        <v-card class="mt-6 pa-6" color="success-lighten-4">
          <v-icon size="64" color="success">mdi-check-circle</v-icon>
          <h3 class="text-h5 mt-4">セッション完了！</h3>
          
          <v-row class="mt-6">
            <v-col cols="6">
              <v-card class="pa-4" elevation="0">
                <v-icon color="warning">mdi-star</v-icon>
                <p class="text-h6 mt-2">+50 XP</p>
              </v-card>
            </v-col>
            <v-col cols="6">
              <v-card class="pa-4" elevation="0">
                <v-icon color="success">mdi-sprout</v-icon>
                <p class="text-h6 mt-2">+5%</p>
                <p class="text-caption">Moくん成長</p>
              </v-card>
            </v-col>
          </v-row>
          
          <v-row class="mt-4">
            <v-col cols="6">
              <v-btn
                color="primary"
                variant="outlined"
                block
                @click="endSession"
              >
                今日は終了
              </v-btn>
            </v-col>
            <v-col cols="6">
              <v-btn
                color="primary"
                block
                @click="continueNext"
              >
                次のパターンへ
                <v-icon end>mdi-arrow-right</v-icon>
              </v-btn>
            </v-col>
          </v-row>
        </v-card>
      </div>
    </v-card>
  </v-container>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useMokun } from '@/composables/useMokun'
import { Howl } from 'howler'

const router = useRouter()
const route = useRoute()

const patternId = route.params.patternId as string

// フェーズ管理
const phase = ref<'intro' | 'input' | 'drill' | 'translation' | 'completion'>('intro')
const sessionProgress = computed(() => {
  const phases = ['intro', 'input', 'drill', 'translation', 'completion']
  return ((phases.indexOf(phase.value) + 1) / phases.length) * 100
})

// パターンデータ（実際はSupabaseから取得）
const currentPattern = ref({
  id: 'P001',
  pattern: "I'm [名前].",
  patternJa: "私は〜です。",
  examples: [
    { en: "I'm Taro.", ja: "私はタロウです。", audioUrl: '/audio/p001_ex1.mp3' },
    { en: "I'm a student.", ja: "私は学生です。", audioUrl: '/audio/p001_ex2.mp3' },
    // ... 残り3例文
  ]
})

// インプットフェーズ
const currentExampleIndex = ref(0)
let exampleInterval: any = null

onMounted(() => {
  setTimeout(() => {
    phase.value = 'input'
    startExamplePlayback()
  }, 3000) // イントロ3秒表示
})

function startExamplePlayback() {
  exampleInterval = setInterval(() => {
    currentExampleIndex.value++
    if (currentExampleIndex.value >= 5) {
      clearInterval(exampleInterval)
    }
  }, 18000) // 例文1つ18秒（聞く10秒+リピート8秒）
}

// ドリルフェーズ
const drillQuestions = ref([
  {
    question: "「私はタロウです」を英語で？",
    options: ["I'm Taro.", "My name Taro.", "I am Taro is.", "Taro am I."],
    correct: 0
  },
  // ... 残り4問
])

const drillQuestionIndex = ref(0)
const selectedAnswer = ref<number | null>(null)
const correctCount = ref(0)

async function checkAnswer() {
  const isCorrect = selectedAnswer.value === drillQuestions.value[drillQuestionIndex.value].correct
  
  if (isCorrect) {
    correctCount.value++
    showMokunReaction('correct_answer')
    await addXP(10)
  } else {
    showMokunReaction('wrong_answer')
  }
  
  // 次の問題へ
  setTimeout(() => {
    drillQuestionIndex.value++
    selectedAnswer.value = null
    
    if (drillQuestionIndex.value >= 5) {
      phase.value = 'translation'
      startTimer()
    }
  }, 2000)
}

// 瞬間英作文フェーズ
const translationQuestion = ref({
  ja: "私は学生です。",
  en: "I'm a student."
})

const userTranslation = ref('')
const timeLeft = ref(100) // 100% = 3秒
let timer: any = null

function startTimer() {
  timer = setInterval(() => {
    timeLeft.value -= 3.33 // 30ms × 33.3 = 1秒
    if (timeLeft.value <= 0) {
      clearInterval(timer)
      submitTranslation()
    }
  }, 30)
}

async function submitTranslation() {
  clearInterval(timer)
  
  // 簡易判定（本来はもっと柔軟に）
  const isCorrect = userTranslation.value.toLowerCase().trim() === translationQuestion.value.en.toLowerCase()
  
  if (isCorrect) {
    showMokunReaction('correct_answer')
    await addXP(20)
  } else {
    showMokunReaction('encourage')
    await addXP(5) // 挑戦したご褒美
  }
  
  setTimeout(() => {
    phase.value = 'completion'
    completeSession()
  }, 2000)
}

// セッション完了処理
async function completeSession() {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return
  
  // 学習セッション記録
  await supabase.from('study_sessions').insert({
    user_id: user.id,
    stage: 0,
    activity_type: 'pattern_quest',
    duration_seconds: 300, // 5分
    xp_earned: 50,
    performance_data: {
      pattern_id: patternId,
      correct_count: correctCount.value,
      total_questions: 5
    }
  })
  
  // パターン進捗更新
  await supabase.from('pattern_progress').upsert({
    user_id: user.id,
    pattern_id: patternId,
    mastery_level: Math.min(5, correctCount.value), // 正解数でレベル決定
    attempts: 1,
    correct_count: correctCount.value,
    last_practiced_at: new Date().toISOString()
  })
  
  // Moくん成長チェック
  const { data: profile } = await supabase
    .from('user_profiles')
    .select('total_xp')
    .eq('id', user.id)
    .single()
  
  if (profile) {
    await checkGrowth(profile.total_xp)
  }
}

function continueNext() {
  // 次のパターンへ
  const nextPatternId = `P${String(parseInt(patternId.slice(1)) + 1).padStart(3, '0')}`
  router.push(`/learn/stage0/pattern/${nextPatternId}`)
}

function endSession() {
  router.push('/dashboard')
}

// 音声再生
function playAudio(url: string) {
  const sound = new Howl({
    src: [url],
    html5: true
  })
  sound.play()
}

// Moくん反応
const { getMokunReaction, checkGrowth } = useMokun(userId)

function showMokunReaction(event: string) {
  const reaction = getMokunReaction(event)
  // MokunCharacterコンポーネントに反応を渡す
  // （実装省略）
}

// XP追加
async function addXP(amount: number) {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) return
  
  await supabase.rpc('add_xp', {
    user_id: user.id,
    xp: amount
  })
}

onUnmounted(() => {
  if (exampleInterval) clearInterval(exampleInterval)
  if (timer) clearInterval(timer)
})
</script>

<style scoped>
.active-example {
  border: 2px solid #10B981 !important;
  background: #F0FDF4;
}
</style>
```

---

## 8. マネタイズ戦略（現実的版）

### 8.1 フリーミアムモデル

| 機能 | 無料版 | Premium<br>¥2,980/月 | Premium+<br>¥4,980/月 |
|------|--------|----------------------|------------------------|
| **Stage 0-2** | 全開放 | 全開放 | 全開放 |
| **Moくん** | 基本のみ | 全表情＋衣装 | 全て＋限定衣装 |
| **広告** | あり | なし | なし |
| **オフライン** | 不可 | 可 | 可 |
| **進捗レポート** | 週1回簡易版 | 毎日詳細版 | AI分析レポート |
| **プッシュ通知** | 基本のみ | カスタマイズ可 | 完全カスタマイズ |
| **コミュニティ** | 閲覧のみ | 投稿可 | 優先サポート |
| **Phase 2機能** | | |
| Stage 3 Pattern | 30/300 | 全開放 | 全開放 |
| Echo AI会話 | 基礎3種のみ | 全30種 | 無制限カスタム |
| VR（Phase 3） | 2Dプレビューのみ | 月8セッション | 無制限 |
| **特典** | - | 月1回オンライン英会話<br>（25分） | 月2回（50分）<br>専属コーチ |

### 8.2 改訂版収益予測（6ヶ月）

#### Month 1-3（初期）

| 収益源 | Month 1 | Month 2 | Month 3 |
|--------|---------|---------|---------|
| **Premium会員** | 5名 × ¥2,980 | 10名 × ¥2,980 | 12名 × ¥2,980 |
| **Premium+会員** | 1名 × ¥4,980 | 2名 × ¥4,980 | 3名 × ¥4,980 |
| **小計（サブスク）** | ¥19,880 | ¥39,760 | ¥50,700 |
| **広告収益** | 無料100名 × ¥25 | 200名 × ¥25 | 285名 × ¥25 |
| **YouTube広告** | ¥5,000 | ¥8,000 | ¥12,000 |
| **教材販売（Tips）** | ¥10,000 | ¥15,000 | ¥20,000 |
| **合計** | **¥37,380** | **¥67,760** | **¥89,825** |

**コスト**: ¥7,559/月  
**純利益**: Month 1: +¥29,821, Month 2: +¥60,201, Month 3: +¥82,266

#### Month 4-6（成長期）

| 収益源 | Month 4 | Month 5 | Month 6 |
|--------|---------|---------|---------|
| **Premium会員** | 20名 × ¥2,980 | 30名 × ¥2,980 | 40名 × ¥2,980 |
| **Premium+会員** | 5名 × ¥4,980 | 7名 × ¥4,980 | 10名 × ¥4,980 |
| **小計（サブスク）** | ¥84,500 | ¥124,260 | ¥169,000 |
| **広告収益** | 480名 × ¥25 | 770名 × ¥25 | 1,150名 × ¥25 |
| **YouTube広告** | ¥18,000 | ¥25,000 | ¥35,000 |
| **教材販売** | ¥25,000 | ¥30,000 | ¥40,000 |
| **企業トライアル** | ¥0 | ¥0 | ¥50,000 |
| **合計** | **¥139,500** | **¥198,510** | **¥322,750** |

**コスト**: ¥7,559/月  
**純利益**: Month 4: +¥131,941, Month 5: +¥190,951, Month 6: +¥315,191

#### 6ヶ月累計

- **累積収益**: ¥855,725
- **累積コスト**: ¥45,354
- **純利益**: **¥810,371**
- **Month 6 MRR**: **¥169,200**（現実的な達成可能値）

### 8.3 ユニットエコノミクス（改訂版）

#### CAC（顧客獲得コスト）

| チャネル | 獲得コスト/人 | 備考 |
|---------|---------------|------|
| **YouTube有機流入** | ¥300 | 動画制作費のみ |
| **教室生徒紹介** | ¥0 | 既存関係 |
| **SNSオーガニック** | ¥200 | 投稿労力のみ |
| **友達紹介** | ¥500 | 1ヶ月無料＝¥2,980/2 |
| **平均CAC** | **¥250** | 加重平均 |

#### LTV（生涯価値）

- **平均継続期間**: 6ヶ月（保守的見積もり）
- **Premium ARPU**: ¥2,980 × 6 = ¥17,880
- **Premium+ ARPU**: ¥4,980 × 8 = ¥39,840（高額プラン長期傾向）
- **加重平均LTV**: ¥20,000

#### 重要指標

- **LTV/CAC比**: 20,000 / 250 = **80** ✅（目標 >3）
- **CAC回収期間**: 250 / 2,980 = **0.08ヶ月（2.4日）** ✅
- **Target Churn Rate**: 月10%以下（年60%）

---

## 9. 6ヶ月実装ロードマップ

### 9.1 全体スケジュール

```
Month 1-2: 技術基盤＋Stage 0
Month 3-4: Stage 1 Sound移植
Month 5-6: Stage 2 Grammar＋βテスト
```

### 9.2 Month 1-2: 技術基盤＋Stage 0実装

#### Week 1-2: 環境構築（2週間）

**タスク**:
- [x] Supabase プロジェクト作成
  - [ ] データベーススキーマ実装（上記SQL実行）
  - [ ] Row Level Security設定
  - [ ] Storage バケット作成（audio, images, videos）
- [x] Capacitor統合
  - [ ] iOS/Androidプロジェクト生成
  - [ ] Preferences/Camera/Push Notifications プラグイン導入
- [x] 認証フロー実装
  - [ ] Email/Password登録・ログイン
  - [ ] Google Sign-In（iOS/Android）
  - [ ] Apple Sign-In（iOS必須）
- [x] CI/CD設定
  - [ ] GitHub Actions（自動ビルド）
  - [ ] TestFlight自動配信（iOS）
  - [ ] Google Play内部テスト（Android）

**成果物**: 空のアプリがiOS/Androidで起動する

#### Week 3-4: オンボーディング実装（2週間）

**タスク**:
- [ ] ウェルカム画面（Step 1）
- [ ] 診断クイズ（Step 2）
  - [ ] 3問のUI
  - [ ] 回答データをSupabaseに保存
  - [ ] 推奨Stage算出ロジック
- [ ] Moくん誕生画面（Step 3）
  - [ ] Lottie アニメーション統合
  - [ ] 成長バー表示
- [ ] 初回Pattern #1へ自動遷移

**成果物**: 初回起動→3分でPattern学習開始

#### Week 5-8: Stage 0 Pattern Starter 30パターン（4週間）

**Week 5-6**: コアループ実装
- [ ] 5分セッションUI（上記参照）
- [ ] パターンデータ30個をSupabaseに登録
- [ ] 音声アセット生成（ElevenLabs: 30×5×2=300音声）
- [ ] Pattern Quest RPGモード（簡易版）
  - [ ] 30NPCとの会話シナリオ
  - [ ] 選択肢システム

**Week 7**: Moくん感情AI統合
- [ ] 7種類の反応アニメーション実装
- [ ] イベント別反応ロジック
- [ ] XP付与・成長チェック
- [ ] プッシュ通知スケジューリング

**Week 8**: テスト＋改善
- [ ] 内部テスト（10名）
- [ ] バグ修正
- [ ] UI/UXフィードバック反映

**成果物**: Stage 0完全動作、TestFlight/内部テスト配信

---

### 9.3 Month 3-4: Stage 1 Sound移植

#### Week 9-10: Dexie.js → Supabase移行（2週間）

**タスク**:
- [ ] MovWISE既存コード分析
- [ ] Dexie.jsクエリ→Supabaseクエリ書き換え
  ```typescript
  // 移行例
  // 旧
  await db.phonemes.where('userId').equals(userId).toArray()
  
  // 新
  const { data } = await supabase
    .from('learning_progress')
    .select('stage1_phonemes_mastered, stage1_games_completed')
    .eq('user_id', userId)
    .single()
  ```
- [ ] オフライン対応（Capacitor Preferences）
- [ ] 移行テスト

#### Week 11-14: 8ゲーム移植（4週間）

**各ゲーム移植タスク**（例: Sound Hunter）:
- [ ] Vue.jsコンポーネント移植
- [ ] Capacitor Audio対応（Howler.js統合）
- [ ] 進捗保存ロジック修正（Supabase）
- [ ] Moくん統合（正解時の反応）
- [ ] モバイルUI調整

**並行タスク**:
- [ ] 音声アセット Supabase Storage移行（440ファイル）
- [ ] レスポンシブデザイン調整
- [ ] 横画面対応

**成果物**: Stage 1全8ゲーム動作、進捗がSupabaseに保存

---

### 9.4 Month 5-6: Stage 2 Grammar＋βテスト

#### Week 17-20: Grammar Level 1 移植（4週間）

**タスク**:
- [ ] 6ゲーム移植（Sound同様の手順）
- [ ] 文法説明画面追加
- [ ] インタラクティブ要素強化（ドラッグ＆ドロップ等）
- [ ] Moくん文法ヒント機能

#### Week 21-24: 統合βテスト＋改善（4週間）

**Week 21**: 社内βテスト（WISE教室生徒30名）
- [ ] βテスト招待（TestFlight/Google Play）
- [ ] アンケート配布（Googleフォーム）
- [ ] 毎日の使用ログ監視

**Week 22-23**: フィードバック対応
- [ ] 優先度付け（P0/P1/P2）
- [ ] UI/UX改善
- [ ] バグ修正
- [ ] パフォーマンス最適化

**Week 24**: 正式リリース準備
- [ ] App Store申請（iOS）
- [ ] Google Play公開（Android）
- [ ] プレスリリース作成
- [ ] YouTube動画5本制作（アプリ紹介）

**Week 25-26**: 正式リリース＋初期マーケティング
- [ ] App Store/Google Play公開
- [ ] Product Hunt投稿
- [ ] SNS一斉投稿
- [ ] WISE教室での全生徒導入

**成果物**: 
- ✅ Stage 0-2完全動作
- ✅ App Store/Google Play公開
- ✅ 初期DL 500、有料会員15名

---

### 9.5 開発タスク優先度

| 優先度 | タスク | 理由 |
|--------|--------|------|
| **P0（必須）** | Supabase DB実装 | 全ての基盤 |
| **P0** | オンボーディング3ステップ | Day 1継続率決定 |
| **P0** | Stage 0 Pattern 30 | MVP核心 |
| **P0** | Moくん感情AI | 差別化要素 |
| **P1（重要）** | Stage 1 Sound移植 | 既存資産活用 |
| **P1** | Stage 2 Grammar移植 | 同上 |
| **P1** | プッシュ通知 | リテンション向上 |
| **P2（推奨）** | Pattern Battle | Phase 2機能 |
| **P2** | ソーシャル機能 | Phase 2 |
| **P3（将来）** | Echo AI | Phase 2 |
| **P3** | VR | Phase 3 |

---

## 10. 現実的KPI・収益予測

### 10.1 6ヶ月KPI（保守的見積もり）

| 指標 | Month 1 | Month 2 | Month 3 | Month 4 | Month 5 | Month 6 |
|------|---------|---------|---------|---------|---------|---------|
| **アプリDL** | 50 | 150 | 500 | 800 | 1,200 | 2,000 |
| **MAU** | 30 | 100 | 300 | 500 | 800 | 1,200 |
| **DAU** | 15 | 50 | 150 | 250 | 400 | 600 |
| **DAU/MAU** | 50% | 50% | 50% | 50% | 50% | 50% |
| **有料会員** | 6 | 12 | 15 | 25 | 37 | 50 |
| **Premium** | 5 | 10 | 12 | 20 | 30 | 40 |
| **Premium+** | 1 | 2 | 3 | 5 | 7 | 10 |
| **転換率** | 20% | 12% | 5% | 5% | 4.6% | 4.2% |
| **MRR** | ¥19,880 | ¥39,760 | ¥50,700 | ¥84,500 | ¥124,260 | ¥169,200 |
| **YouTube登録者** | 100 | 300 | 500 | 1,000 | 2,000 | 3,000 |

### 10.2 学習効果KPI

| 指標 | 目標（6ヶ月後） | 計測方法 |
|------|----------------|----------|
| **Day 7継続率** | 60% | βテスター50名の追跡 |
| **Day 30継続率** | 40% | 同上 |
| **Stage 0完了率** | 70% | 30パターン完了者/開始者 |
| **Stage 2到達率** | 40% | Stage 2開始者/全ユーザー |
| **平均セッション時間** | 15分/日 | Firebase Analytics |
| **週間学習日数** | 4日 | 同上 |
| **NPS** | 50以上 | 四半期アンケート |
| **Moくん成長Stage 3到達率** | 30% | Stage 3（若木）到達者 |

### 10.3 技術KPI

| 指標 | 目標 | 計測方法 |
|------|------|----------|
| **クラッシュ率** | <0.5% | Sentry/Firebase Crashlytics |
| **平均起動時間** | <2秒 | Firebase Performance |
| **API応答時間（P95）** | <500ms | Supabase Insights |
| **音声再生成功率** | >98% | カスタムログ |
| **オフライン対応率** | 100% | 手動テスト |
| **App Storeレーティング** | 4.5+ | レビュー管理 |

---

## 11. 今週のTODOリスト

### Week 1（2026年2月24日〜3月2日）

#### Monday 2/24

**午前（9:00-12:00）**:
- [x] **Supabaseプロジェクト作成**
  - [ ] supabase.com でプロジェクト "mowise-production" 作成
  - [ ] PostgreSQLスキーマ実行（上記SQL全コピー＆実行）
  - [ ] Row Level Security確認
  - [ ] .env.local にSupabase URLとAnon Key記載

**午後（14:00-17:00）**:
- [x] **既存MovWISEコード整理**
  - [ ] GitHub新規リポジトリ "mowise-app" 作成
  - [ ] 既存MovWISEコードをコピー
  - [ ] Dexie.js依存箇所リスト化（移行準備）

#### Tuesday 2/25

**午前**:
- [x] **Capacitor導入**
  ```bash
  npm install @capacitor/core @capacitor/cli
  npx cap init
  npm install @capacitor/ios @capacitor/android
  npx cap add ios
  npx cap add android
  ```
- [x] **必要プラグインインストール**
  ```bash
  npm install @capacitor/preferences @capacitor/push-notifications
  npm install capacitor-voice-recorder
  npm install howler @types/howler
  ```

**午後**:
- [x] **Supabase統合テスト**
  - [ ] `src/lib/supabase.ts` 作成（上記コード）
  - [ ] 簡易ログイン画面作成
  - [ ] Supabase Auth動作確認

#### Wednesday 2/26

**終日**:
- [x] **オンボーディング Step 1-2 実装**
  - [ ] `views/Onboarding/Welcome.vue` 作成
  - [ ] `views/Onboarding/Quiz.vue` 作成
  - [ ] 診断ロジック実装
  - [ ] Supabaseにデータ保存確認

#### Thursday 2/27

**終日**:
- [x] **Moくん Lottieアニメーション準備**
  - [ ] LottieFiles.com で "tree character" 検索
  - [ ] 5アニメーションダウンロード（idle, jump_joy, sad, bloom, seed）
  - [ ] `components/MokunCharacter.vue` 実装
  - [ ] Step 3 Moくん誕生画面実装

#### Friday 2/28

**終日**:
- [x] **Pattern #1 プロトタイプ**
  - [ ] Pattern データ1個をSupabaseに登録
  - [ ] 5分セッションUI実装（Phase 1-2のみ）
  - [ ] ElevenLabs で例文5個音声生成
  - [ ] Howler.js で音声再生テスト

#### Weekend（3/1-2）

**Saturday**:
- [x] **iOS実機テスト**
  - [ ] Xcodeでビルド
  - [ ] 実機（iPhone）で動作確認
  - [ ] Capacitor Preferences動作確認

**Sunday**:
- [x] **Week 2計画詳細化**
  - [ ] Pattern 2-10のデータ準備
  - [ ] ElevenLabs音声生成バッチスクリプト作成
  - [ ] GitHub Issue整理

---

### Week 1 予算

| 項目 | 費用 |
|------|------|
| Supabase | $0（無料枠） |
| ElevenLabs Starter | $11（¥1,650） |
| Lottie Pro（オプション） | $0（無料版） |
| **合計** | **¥1,650** |

---

## 12. リスク管理

### 12.1 技術リスク（改訂版）

| リスク | 確率 | 影響 | 緩和策 |
|--------|------|------|--------|
| **Capacitor iOS審査落ち** | 中 | 高 | • 事前にApple Guidelines熟読<br>• TestFlight β長期実施<br>• 審査リジェクト時の即座対応体制 |
| **Supabase無料枠超過** | 低 | 中 | • MAU監視アラート設定<br>• 5万MAU到達前にPro移行（$25/月）<br>• DB最適化（不要データ削除） |
| **音声再生がモバイルで不安定** | 中 | 中 | • Howler.js html5モード使用<br>• 複数フォーマット提供（mp3/m4a）<br>• フォールバック音声なし版 |
| **MovWISE移植が想定より困難** | 中 | 高 | • Week 9-10で早期発見<br>• 必要に応じてStage 1の一部ゲーム削減<br>• 外注検討（¥50,000予算） |

### 12.2 ビジネスリスク（改訂版）

| リスク | 確率 | 影響 | 緩和策 |
|--------|------|------|--------|
| **目標DL未達（Month 6: 2,000）** | 中 | 中 | • 教室生徒全員導入（最低500 DL保証）<br>• YouTube投稿継続（オーガニック流入）<br>• App Store最適化（ASO）強化 |
| **有料転換率低迷（<3%）** | 中 | 高 | • オンボーディング改善<br>• 無料版機能を段階的に制限<br>• 期間限定割引キャンペーン |
| **Churn Rate高騰（>15%/月）** | 中 | 高 | • NPS調査で原因特定<br>• Moくんプッシュ通知強化<br>• 解約理由ヒアリング（全員） |
| **競合の類似アプリリリース** | 低 | 中 | • Moくん＋教室連携の独自性訴求<br>• コミュニティ強化でロイヤルティ向上<br>• 先行者利益の最大化 |

### 12.3 オペレーショナルリスク

| リスク | 確率 | 影響 | 緩和策 |
|--------|------|------|--------|
| **1人開発の健康問題** | 中 | 高 | • 週1日完全休息<br>• タスクバッファ20%確保<br>• 緊急時対応：Phase 2延期 |
| **Apple審査で2週間遅延** | 中 | 中 | • Month 5末に申請（1ヶ月バッファ）<br>• Androidを先行リリース<br>• Web版を暫定提供 |
| **教室生徒の協力得られず** | 低 | 中 | • βテスト報酬検討（1ヶ月無料等）<br>• 教室授業での活用提案<br>• 保護者への説明会実施 |

### 12.4 緊急時対応プラン

#### Plan A: 順調（ベースライン）
→ 上記ロードマップ通り実行

#### Plan B: Month 3でDL < 200
- [ ] YouTube広告投入（¥50,000）
- [ ] インフルエンサーコラボ検討
- [ ] 無料版機能拡大（全員Stage 2まで開放）

#### Plan C: MovWISE移植が困難
- [ ] Stage 1を4ゲームに削減（優先度高いもののみ）
- [ ] 外注エンジニア追加（¥100,000予算）
- [ ] Stage 2の一部を簡易版に

#### Plan D: 有料転換率 < 2%
- [ ] Premium価格を¥1,980に値下げ
- [ ] 年間プラン30% OFFキャンペーン
- [ ] 広告収益メインモデルへピボット検討

---

## 付録A: 技術スタック詳細

### 開発環境

```bash
# Node.js
node v20.11.0
npm 10.4.0

# Vue.js
vue 3.4.21
vite 5.1.4

# Capacitor
@capacitor/core 6.0.0
@capacitor/cli 6.0.0

# Supabase
@supabase/supabase-js 2.39.8

# UI Framework
vuetify 3.5.10
@mdi/font 7.4.47 # Material Design Icons

# State Management
pinia 2.1.7

# Routing
vue-router 4.3.0

# Audio
howler 2.2.4

# Animation
@lottiefiles/vue-lottie-player 1.0.3

# HTTP Client
axios 1.6.7

# Utilities
date-fns 3.3.1
lodash-es 4.17.21
```

### package.json（抜粋）

```json
{
  "name": "mowise-app",
  "version": "1.0.0",
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "ios": "npx cap run ios",
    "android": "npx cap run android",
    "sync": "npx cap sync"
  },
  "dependencies": {
    "vue": "^3.4.21",
    "vuetify": "^3.5.10",
    "pinia": "^2.1.7",
    "vue-router": "^4.3.0",
    "@capacitor/core": "^6.0.0",
    "@capacitor/ios": "^6.0.0",
    "@capacitor/android": "^6.0.0",
    "@capacitor/preferences": "^6.0.0",
    "@capacitor/push-notifications": "^6.0.0",
    "@supabase/supabase-js": "^2.39.8",
    "howler": "^2.2.4",
    "@lottiefiles/vue-lottie-player": "^1.0.3"
  },
  "devDependencies": {
    "@capacitor/cli": "^6.0.0",
    "vite": "^5.1.4",
    "typescript": "^5.3.3",
    "@vitejs/plugin-vue": "^5.0.4"
  }
}
```

---

## 付録B: Supabase Edge Functions（将来拡張用）

```typescript
// supabase/functions/add-xp/index.ts
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

Deno.serve(async (req) => {
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_ANON_KEY') ?? ''
  )
  
  const { user_id, xp } = await req.json()
  
  // XP追加
  const { data: profile, error } = await supabase
    .from('user_profiles')
    .select('total_xp, mokun_growth_stage')
    .eq('id', user_id)
    .single()
  
  if (error) return new Response(JSON.stringify({ error }), { status: 400 })
  
  const newXP = profile.total_xp + xp
  
  // 成長チェック
  const GROWTH_THRESHOLDS = [0, 100, 500, 1500, 5000, 10000]
  let newStage = profile.mokun_growth_stage
  for (let i = GROWTH_THRESHOLDS.length - 1; i >= 0; i--) {
    if (newXP >= GROWTH_THRESHOLDS[i]) {
      newStage = i
      break
    }
  }
  
  // 更新
  await supabase
    .from('user_profiles')
    .update({
      total_xp: newXP,
      mokun_growth_stage: newStage
    })
    .eq('id', user_id)
  
  return new Response(
    JSON.stringify({ success: true, new_xp: newXP, new_stage: newStage }),
    { headers: { 'Content-Type': 'application/json' } }
  )
})
```

---

## 📝 改訂版のまとめ

### v2.0の重要変更

1. ✅ **技術統一**: Vue.js + Capacitor + Supabase一本化
2. ✅ **スコープ削減**: Stage 0-2のみ、18ヶ月→6ヶ月
3. ✅ **収益現実化**: Month 6 MRR ¥1.6M → ¥169K
4. ✅ **VR戦略転換**: Spatial.io依存→WebXR中心（Phase 2以降）
5. ✅ **DB設計明確化**: Supabase PostgreSQL完全スキーマ
6. ✅ **オンボーディング追加**: 3ステップ3分完結
7. ✅ **コアループ定義**: 5分セッションの詳細設計
8. ✅ **Moくん感情AI**: 具体的な実装コード

### 次のアクション

**今週中（Week 1）に実行**:
1. Supabaseプロジェクト作成＋スキーマ実装
2. Capacitor導入
3. オンボーディング Step 1-2 実装
4. Moくん Lottie準備
5. Pattern #1 プロトタイプ

**Month 1-2のゴール**:
- Stage 0（30パターン）完全動作
- iOS/Android TestFlight配信
- 教室生徒30名βテスト開始

**Month 6のゴール**:
- Stage 0-2完成
- App Store/Google Play正式リリース
- DL 2,000、有料会員50名、MRR ¥169K達成

---

**この改訂版設計書で、現実的かつ達成可能なMVP開発を進めましょう！**

**Document Version**: 2.0  
**Last Updated**: 2026年2月22日  
**Author**: WISE English Club / MoWISE Project  

**© 2026 WISE English Club. All Rights Reserved.**