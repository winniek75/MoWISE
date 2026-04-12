# MoWISE｜B バトルシステム再設計書
**バージョン：v1.0（完全版）**
**策定日：2026年2月23日**
**ステータス：設計確定・エンジニア引き渡し用**
**対象範囲：デイリーバトル・クラスバトル・レイドバトル（MVP + Phase 2）**

---

## 設計の根幹思想

> **「バトルは、英語を使う理由。Mowi（=自分の英語力）で戦う。」**

- Mowi はユーザーの英語力そのもの。だからバトルでは「自分の英語力を持ち込んで戦う」
- 「勝ち負け」ではなく「今日の自分の英語力がどこまで届いたか」
- AI対戦の相手は**3日前の自分**。自分に勝つことが成長の証明
- クラスバトルのランキングは比較ではなく「クラス全員の英語力MAP」として可視化
- レイドバトルは競争ではなく「チームの英語力が合わさってボスを倒す」協力体験
- チェックイン日記の朝の状態がバトルに影響する。生活と英語が地続き

---

## 目次

1. [システム全体像・3つのバトル型](#1-システム全体像3つのバトル型)
2. [チェックイン日記との連動設計](#2-チェックイン日記との連動設計)
3. [勝ち負けの設計哲学](#3-勝ち負けの設計哲学)
4. [デイリーバトル（AI対戦）詳細設計](#4-デイリーバトルai対戦詳細設計)
5. [クラスバトル（生徒間非同期対戦）詳細設計](#5-クラスバトル生徒間非同期対戦詳細設計)
6. [レイドバトル（クラス全員協力イベント）詳細設計](#6-レイドバトルクラス全員協力イベント詳細設計)
7. [AI対戦相手の強さ設定ロジック](#7-ai対戦相手の強さ設定ロジック)
8. [バトルスコア計算式](#8-バトルスコア計算式)
9. [画面フロー詳細（デイリー・クラス・レイド）](#9-画面フロー詳細デイリークラスレイド)
10. [Supabase テーブル定義](#10-supabase-テーブル定義)
11. [フロントエンド実装スニペット（Vue 3）](#11-フロントエンド実装スニペットvue-3)
12. [実装優先順位](#12-実装優先順位)

---

## 1. システム全体像・3つのバトル型

### 1.1 バトル型の比較

| 項目 | デイリーバトル | クラスバトル | レイドバトル |
|------|--------------|------------|------------|
| **頻度** | 毎日（0時リセット） | 週1〜先生設定 | 週1・先生設定 |
| **対戦相手** | AI（3日前の自分）| クラスメイト（非同期） | ボスパターン（全員で倒す） |
| **参加人数** | 1人 | クラス全員（個別） | クラス全員（協力） |
| **競争形式** | 自分 vs 自分（成長確認） | スコアランキング | チーム合計HP削り |
| **チェックイン連動** | ✅ 朝の状態で難易度・ボーナス変化 | ✅ 朝の状態でスタートボーナス | ✅ チーム全員の状態が合算 |
| **報酬** | XP・Mowi輝き | XP・ランキングバッジ | クラス全員に特別バッジ + XP |
| **MVP必須** | ✅ | Phase 2 | Phase 2 |

### 1.2 「Mowi = 自分の英語力」とバトルの整合性

```
【従来のバトルイメージ（採用しない）】
  自分のキャラ（HP付き）が相手キャラを攻撃する
  → MowiはHPを持たない。Mowiは英語力のビジュアライズ

【MoWISEのバトルイメージ（採用）】
  英語パターンの問題に答える
  → 正解の速さ・コンボ・習熟度★ がスコアになる
  → スコアが高いほどMowiが輝く
  → 「今日の自分の英語力がここまで届いた」という体験
```

---

## 2. チェックイン日記との連動設計

### 2.1 朝チェックイン → バトルへの影響

朝チェックインの4択選択が、当日のバトル全体に影響する。

| 朝の選択 | バトルへの影響 | UIでの表現 |
|---------|--------------|-----------|
| **自信ある** | 制限時間 +20%（余裕を持って答えられる）+ コンボボーナス1.2倍 | バトル開始前「今日のMowiは輝いている」表示 |
| **まあまあ** | 通常設定 | 通常 |
| **不安** | AI難易度を1段階下げる・ヒント利用回数 +1 | バトル開始前「今日は無理しなくていい」Mowiセリフ |
| **わからない** | AI難易度を通常 → ヒント利用回数 +1 | 通常 |

### 2.2 夜チェックイン → 翌日バトルへの影響

| 夜の選択 | 翌日への影響 |
|---------|------------|
| **できた・話せた** | 翌日デイリーバトルのAI難易度を+1段階 |
| **まあまあだった** | 通常 |
| **うまくいかなかった** | 翌日AIが「昨日失点したパターン」を優先出題 |
| **疲れた** | 翌日デイリーバトルの問題数を7問→5問に短縮 |

### 2.3 連動ロジック（疑似コード）

```javascript
// バトル開始時の状態取得
async function getBattleModifiers(userId) {
  const today = new Date().toISOString().split('T')[0];

  // 今日の朝チェックイン取得
  const { data: morningCheckin } = await supabase
    .from('checkins')
    .select('morning_mood')
    .eq('user_id', userId)
    .eq('checkin_date', today)
    .single();

  // 昨日の夜チェックイン取得
  const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
  const { data: eveningCheckin } = await supabase
    .from('checkins')
    .select('evening_mood')
    .eq('user_id', userId)
    .eq('checkin_date', yesterday)
    .single();

  return computeModifiers(morningCheckin?.morning_mood, eveningCheckin?.evening_mood);
}

function computeModifiers(morningMood, eveningMood) {
  const modifiers = {
    timeLimitMultiplier: 1.0,   // 制限時間倍率
    comboBonusMultiplier: 1.0,  // コンボボーナス倍率
    aiDifficultyDelta: 0,        // AI難易度調整（-1〜+1）
    hintBonus: 0,                // 追加ヒント回数
    questionCountDelta: 0,       // 問題数増減
    mowiMessage: null,           // バトル開始前のMowiセリフID
  };

  // 朝チェックインの影響
  switch (morningMood) {
    case 'confident':  // 自信ある
      modifiers.timeLimitMultiplier  = 1.2;
      modifiers.comboBonusMultiplier = 1.2;
      modifiers.mowiMessage = 'BATTLE_START_CONFIDENT';
      break;
    case 'anxious':    // 不安
      modifiers.aiDifficultyDelta = -1;
      modifiers.hintBonus = 1;
      modifiers.mowiMessage = 'BATTLE_START_ANXIOUS';
      break;
    case 'unsure':     // わからない
      modifiers.hintBonus = 1;
      break;
    // 'okay': デフォルトのまま
  }

  // 夜チェックインの影響（昨日分）
  switch (eveningMood) {
    case 'great':
      modifiers.aiDifficultyDelta += 1;
      break;
    case 'struggled':
      // 弱点パターン優先出題フラグはbattle_configで制御
      modifiers.weakPatternPriority = true;
      break;
    case 'tired':
      modifiers.questionCountDelta = -2;
      break;
  }

  return modifiers;
}
```

---

## 3. 勝ち負けの設計哲学

### 3.1 「外部競争 vs 内発的動機」の両立方針

MoWISEのバトルは「勝ち負け」ではなく「届いたかどうか」を設計の軸にする。

```
【避けるべき設計（Duolingo化）】
  他のプレイヤーに勝って上位ランクに入ることが目的
  → ゲームに慣れた人だけが有利
  → 英語力の成長と切り離された競争

【MoWISEが採用する設計】
  バトル型別の「勝ち」の定義を変える
  ├─ デイリーバトル：3日前の自分のスコアを超えたか（自分 vs 自分）
  ├─ クラスバトル：今週の自分のベストスコアを出したか（個人記録更新）
  └─ レイドバトル：クラス全員でボスのHPを0にできたか（チーム協力）
```

### 3.2 勝ち負けの定義

| バトル型 | 「勝ち」の定義 | 「負け」の定義 | UIでの表現 |
|---------|--------------|--------------|-----------|
| **デイリー** | 今日スコア > 3日前スコア | 今日スコア ≤ 3日前スコア | 「Mowiが前の自分を超えた」/ 「まだ3日前の自分の方が速い」 |
| **クラス** | 今週の自分のベスト更新 | 更新なし | 個人ランキング + 「今週のベスト」バッジ |
| **レイド** | クラス合計ダメージ ≥ ボスHP | 合計ダメージ不足 | 「チームの英語力が届いた！」/ 「もう少しだった」 |

### 3.3 ランキング表示の哲学（クラスバトル）

```
【採用しない表現】
  1位：田中 1200pt
  2位：鈴木  980pt
  3位：佐藤  850pt  ← 最下位が見えてしまう

【採用する表現】
  📊 今週の英語力MAP
  
  ██████████  田中（P001〜P015 全解放）
  ████████    鈴木（P001〜P012 全解放）
  ██████      佐藤（P001〜P010 全解放）
  
  「クラスみんなの英語力が、ここまで来た。」
  ← スコアは非表示。習熟パターン範囲で表示
```

---

## 4. デイリーバトル（AI対戦）詳細設計

### 4.1 ゲームプレイ概要

```
バトル内容：
  ・★1以上のパターンからAIが問題を出題
  ・Layer 3（Flash Output タイル式）相当の問題
  ・制限時間：1問8秒（チェックイン修正あり）
  ・問題数：7問（チェックイン修正あり）
  ・コンボシステム：通常練習と同じ
  
バトル相手：
  ・「3日前の自分のスコア」をAIがシミュレート
  ・初回（記録なし）は標準難易度のデフォルトAI
  
報酬：
  ・勝利：XP × 150、コインボーナス × 1.5
  ・敗北：XP × 50（完走ボーナス）
  ・コンボ3以上で追加XP
```

### 4.2 バトル中のMowii挙動

| 状況 | Mowi状態 | セリフ（内なる声） |
|------|---------|----------------|
| バトル開始 | Cheer（前のめり） | 「3日前の私が、ここにいる。」 |
| 正解・コンボ継続 | Joy → 輝き増加 | （セリフなし。輝きで表現） |
| コンボ3達成 | Glow（強い輝き） | 「また、速くなってる。」 |
| 不正解 | Sad → 輝き減少 | 「…まだここが、弱い。」 |
| 最後の1問 | Focus（集中） | 「最後まで、届かせて。」 |
| 勝利 | Grow（最大輝き） | 「3日前の私を、超えた。」 |
| 敗北 | Dim（暗め） | 「まだ、3日前の方が速かった。」 |
| チェックイン：不安 + 開始 | Comfort（穏やか） | 「今日は、できる範囲でいい。」 |

---

## 5. クラスバトル（生徒間非同期対戦）詳細設計

### 5.1 ゲームプレイ概要

```
バトル設定（先生が行う）：
  ・出題パターン範囲：P001〜P020 など指定
  ・実施期間：月〜金 など
  ・問題数：10〜20問（先生が設定）
  
バトル内容：
  ・指定パターンのLayer 3（Flash Output）問題
  ・全生徒が同じ問題セットに回答（非同期）
  ・制限時間：1問8秒
  ・各自がベストスコアを目指す（何度でも再チャレンジ可）
  
スコア算出：
  ・正解率 × 速度ボーナス × コンボ倍率（後述 §8）
  
結果表示：
  ・クラス「英語力MAP」（スコア数値非表示・パターン習熟帯で表現）
  ・個人の今週ベストスコア更新確認
  ・先生ダッシュボードでクラス全体俯瞰
```

### 5.2 非同期対戦の設計意図

- 対戦相手の都合に縛られない（塾の時間以外でも参加可）
- 「全員が同じ課題に向かう体験」をクラスで共有できる
- 週次リセットで「今週のクラス記録」として区切りを作る

---

## 6. レイドバトル（クラス全員協力イベント）詳細設計

### 6.1 ゲームプレイ概要

```
レイド設定（先生が行う）：
  ・ボスパターン：1〜3パターン指定（難易度高め）
  ・ボスHP：クラス人数 × 50（デフォルト。調整可）
  ・実施期間：例「金〜日の3日間」
  
バトル内容：
  ・生徒は1人30問まで参加可（1日10問 × 3日）
  ・全員の正解数合計 = ボスへの総ダメージ
  ・ダメージ計算：正解1問 = 1ダメージ（コンボ5以上は2ダメージ）
  ・ボスHP 0で全員クリア
  
報酬：
  ・クリア：全員に「レイドバッジ」+ XP × 200
  ・参加のみ：XP × 50
  ・個人トップダメージ：「MVP」アイコン表示（翌週まで）
```

### 6.2 レイドのチェックイン連動

```
チーム全員の朝チェックイン「自信ある」の人数 ≥ クラスの50%
→ その日のレイドでコンボダメージが 1.5倍に

全員のチェックインデータを先生ダッシュボードで可視化
→ 「今日のクラスの状態を先生が把握してから授業開始」が可能
```

---

## 7. AI対戦相手の強さ設定ロジック

### 7.1 基本設計思想

> **AIの相手 = 「3日前のあなたの英語力」**

外部の固定AIではなく、ユーザー自身の過去スコアをベースにした動的な対戦相手。これにより：
- 始めたばかりの生徒も上級生徒も同じ難易度体験
- 「3日前より速くなった」という成長実感
- 常に少し頑張れば届く難易度（フロー状態を維持）

### 7.2 AI難易度テーブル

| 難易度 | 制限時間 | 問題構成 | 使用条件 |
|--------|---------|---------|---------|
| **Lv.0（初回専用）** | 10秒 | ★1パターンのみ・最多出現パターン | 初回バトル（過去記録なし） |
| **Lv.1（やさしい）** | 10秒 | ★1〜2 パターン中心 | 朝チェックイン「不安」 or aiDifficultyDelta = -1 |
| **Lv.2（標準）** | 8秒 | ★1〜3 パターン・弱点パターン混入 | デフォルト |
| **Lv.3（強め）** | 7秒 | ★1〜4 パターン・高速応答要求 | 朝チェックイン「自信ある」 or aiDifficultyDelta = +1 |
| **Lv.4（激辛）** | 6秒 | ★3〜5 パターン・最高難度問題 | 夜チェックイン「できた」翌日 + aiDifficultyDelta = +1 |

### 7.3 AI強さの動的計算ロジック

```javascript
// AI難易度を決定する関数
async function computeAiLevel(userId, modifiers) {
  // ① 3日前のスコアを取得
  const threeDaysAgo = new Date(Date.now() - 3 * 86400000).toISOString().split('T')[0];
  const { data: pastBattle } = await supabase
    .from('battles')
    .select('score, accuracy_rate, avg_response_ms')
    .eq('user_id', userId)
    .eq('battle_type', 'daily')
    .gte('battle_date', threeDaysAgo)
    .order('battle_date', { ascending: false })
    .limit(1)
    .single();

  // ② 基本難易度を決定
  let baseDifficulty = 2; // デフォルト Lv.2
  if (!pastBattle) baseDifficulty = 0; // 初回
  else if (pastBattle.accuracy_rate >= 0.85) baseDifficulty = 3;
  else if (pastBattle.accuracy_rate < 0.50) baseDifficulty = 1;

  // ③ チェックイン修正を適用
  const finalDifficulty = Math.max(0, Math.min(4,
    baseDifficulty + (modifiers.aiDifficultyDelta || 0)
  ));

  // ④ AIのターゲットスコアを算出（3日前比 +5%）
  const targetScore = pastBattle
    ? Math.round(pastBattle.score * 1.05)
    : 100; // 初回デフォルト

  return {
    level: finalDifficulty,
    targetScore,
    timeLimitSeconds: [10, 10, 8, 7, 6][finalDifficulty],
    pastScore: pastBattle?.score ?? null,
  };
}
```

### 7.4 出題パターンの選定ロジック

```javascript
// バトル用問題セットを生成する関数
async function generateBattleQuestions(userId, aiConfig, questionCount = 7) {
  // ① ユーザーの習得済みパターン（★1以上）を取得
  const { data: progress } = await supabase
    .from('pattern_progress')
    .select('pattern_id, star_level, correct_attempts, total_attempts')
    .eq('user_id', userId)
    .gte('star_level', 1)
    .order('star_level', { ascending: false });

  // ② 問題配分ロジック
  // 40%：弱点パターン（正解率 < 60% かつ ★1〜2）
  // 40%：標準パターン（正解率 60〜80%）
  // 20%：得意パターン（正解率 > 80%）＝ 達成感のため
  const weak    = progress.filter(p => p.total_attempts > 0 && (p.correct_attempts / p.total_attempts) < 0.6);
  const medium  = progress.filter(p => p.total_attempts > 0 && (p.correct_attempts / p.total_attempts) >= 0.6 && (p.correct_attempts / p.total_attempts) < 0.8);
  const strong  = progress.filter(p => p.total_attempts > 0 && (p.correct_attempts / p.total_attempts) >= 0.8);

  const weakCount   = Math.floor(questionCount * 0.4);
  const mediumCount = Math.floor(questionCount * 0.4);
  const strongCount = questionCount - weakCount - mediumCount;

  const selected = [
    ...shuffleAndTake(weak, weakCount),
    ...shuffleAndTake(medium, mediumCount),
    ...shuffleAndTake(strong, strongCount),
  ];

  // ③ 弱点パターン優先フラグ（夜チェックイン「うまくいかなかった」翌日）
  if (modifiers?.weakPatternPriority) {
    selected.sort((a, b) => {
      const rateA = a.correct_attempts / (a.total_attempts || 1);
      const rateB = b.correct_attempts / (b.total_attempts || 1);
      return rateA - rateB; // 正解率が低い順
    });
  }

  return selected.map(p => p.pattern_id);
}

function shuffleAndTake(arr, n) {
  return arr.sort(() => Math.random() - 0.5).slice(0, n);
}
```

---

## 8. バトルスコア計算式

### 8.1 デイリー・クラスバトル共通スコア式

```
最終スコア = 正解数 × 基本点 × スピードボーナス × コンボ倍率 × チェックイン倍率

基本点：
  正解 1問 = 100pt

スピードボーナス：
  制限時間残り率 = (制限時間 - 回答時間) / 制限時間
  スピードボーナス = 1.0 + (残り率 × 0.5)
  例：8秒制限 → 2秒で回答 = 残り率75% → ×1.375

コンボ倍率：
  コンボ 1〜2 = ×1.0
  コンボ 3〜4 = ×1.1
  コンボ 5〜6 = ×1.2
  コンボ 7〜9 = ×1.3
  コンボ 10+  = ×1.5

チェックイン倍率：
  朝「自信ある」 = ×1.2
  その他        = ×1.0
```

```javascript
function calculateScore(answers, modifiers) {
  let totalScore = 0;
  let currentCombo = 0;

  answers.forEach(answer => {
    if (!answer.isCorrect) {
      currentCombo = 0;
      return;
    }

    const timeLimit = modifiers.timeLimitSeconds * 1000; // ms
    const speedRate = Math.max(0, (timeLimit - answer.responseTimeMs) / timeLimit);
    const speedBonus = 1.0 + (speedRate * 0.5);

    currentCombo++;
    const comboMultiplier =
      currentCombo >= 10 ? 1.5 :
      currentCombo >= 7  ? 1.3 :
      currentCombo >= 5  ? 1.2 :
      currentCombo >= 3  ? 1.1 : 1.0;

    const checkinMultiplier = modifiers.comboBonusMultiplier ?? 1.0;

    totalScore += Math.round(100 * speedBonus * comboMultiplier * checkinMultiplier);
  });

  return totalScore;
}
```

### 8.2 レイドバトルのダメージ計算

```
ダメージ = 正解1問 = 1 ダメージ
コンボ5以上の正解 = 2 ダメージ
チームチェックイン50%以上「自信ある」 = 全員のダメージ × 1.5（当日限定）
```

---

## 9. 画面フロー詳細（デイリー・クラス・レイド）

### 9.1 デイリーバトル 画面フロー

```
【ホーム画面】
    │
    └─ [デイリーバトル] ボタンタップ
            ↓
【バトル準備画面】
    ・Mowiが「3日前の私が、ここにいる。」
    ・朝チェックイン状態に応じたMowiの輝き・セリフ
    ・本日の難易度表示（自動設定・変更不可）
    ・「バトル開始」ボタン
            ↓
【バトル問題画面】（7問 × 8秒）
    ・Layer 3 Flash Output形式（タイル並べ替え）
    ・ヘッダー：問題番号 / コンボ数 / 制限時間バー
    ・Mowiエリア：コンボ連動で輝き変化
    ・AI対戦相手の「3日前スコア」プログレスバー（右上）
    ・問題ごとに正誤判定 → 次問へ
            ↓
【バトル結果画面】
    ├─ 勝利（今日スコア > 3日前スコア）
    │       ・Grow MAX アニメーション
    │       ・「3日前の私を、超えた。」Mowiセリフ
    │       ・今日スコア vs 3日前スコア並列表示
    │       ・獲得XP・コイン表示
    │       ・「もう一度バトル」（1日1回制限内なら）
    │
    └─ 敗北（今日スコア ≤ 3日前スコア）
            ・Dim → 徐々に通常Mowii
            ・「まだ、3日前の方が速かった。」
            ・今日スコア vs 3日前スコア並列表示
            ・「どのパターンが足を引っ張ったか」1件表示
            ・獲得XP（参加ボーナス）
```

### 9.2 デイリーバトル ワイヤーフレーム（問題画面）

```
┌─────────────────────────────────────────┐
│  ← 終了    バトル中   [3/7問]  🔥コンボ:4│
│─────────────────────────────────────────│
│                                         │
│  ████████████████░░░░  8秒              │  ← 制限時間バー（赤くなる）
│                                         │
│  [Mowi・Joy（コンボ4で輝き強め）]         │  ← 上1/3
│                                         │
│─────────────────────────────────────────│
│                                         │
│  🇯🇵 「コーヒーをお願いします」           │
│                                         │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  │  ← タイル（Flash Output形式）
│  │ I'd  │ │ like │ │  a   │ │coffee│  │
│  └──────┘ └──────┘ └──────┘ └──────┘  │
│                                         │
│  ┌──────────────────────────────────┐   │  ← 回答欄（タイルをここに置く）
│  │                                  │   │
│  └──────────────────────────────────┘   │
│                                         │
│  ─────────────────────── 3日前AI: 420pt │  ← AIスコア進捗
│  自分の現在スコア:    ███░░ 360pt        │
└─────────────────────────────────────────┘
```

### 9.3 クラスバトル 画面フロー

```
【ホーム画面 or 先生からのプッシュ通知】
    │
    └─ [クラスバトル] バナータップ
            ↓
【クラスバトル告知画面】
    ・先生が設定したパターン範囲表示
    ・期間表示（例：月〜金）
    ・クラスの参加状況（○人/○人参加済み）
    ・「バトルに参加する」ボタン
            ↓
【バトル準備画面】
    ・使用パターン一覧（先生設定のもの）
    ・朝チェックインボーナス表示
    ・「スタート」ボタン
            ↓
【バトル問題画面】（先生設定の問題数）
    ・デイリーバトルと同形式
    ・AIスコアバー → 自分の「今週ベストスコア」比較表示
            ↓
【バトル結果画面（個人）】
    ・今回スコア vs 今週ベスト比較
    ・「ベスト更新！」or「あとXptでベスト更新」
    ・再チャレンジボタン（期間中は何度でも可）
            ↓
【クラス英語力MAP画面】
    ・クラス全員の習熟パターン帯をバー表示（スコア数値非表示）
    ・Mowiセリフ「クラスみんなの英語力が、ここまで来た。」
    ・先生へのシェアボタン
```

### 9.4 レイドバトル 画面フロー

```
【先生がレイドを設定 → 全生徒にプッシュ通知】
    │
    └─ 通知 or ホームのバナーからタップ
            ↓
【レイド告知・ボス紹介画面】
    ・ボスパターン名「The Shadow of が構文」など演出名
    ・ボスHP バー（全体量）
    ・クラス全員の参加状況
    ・「参加する」ボタン
            ↓
【レイド準備画面】
    ・今日の残り参加可能問題数（上限10問/日）
    ・チームのチェックイン状況表示（50%以上自信あり → ダメージ1.5倍バナー）
    ・「攻撃する」ボタン
            ↓
【レイド問題画面】（1回最大10問）
    ・ボスHP バー（全体と自分の貢献量）
    ・コンボ5以上でダメージ×2演出
    ・クラスメイトのリアルタイム参加通知（例：「田中がコンボ5！+2ダメージ」）
            ↓
【個人ターン結果画面】
    ・今回の貢献ダメージ量
    ・クラス全体のボス現在HP
    ・「残りボスHP: ○○ 明日もう一度攻撃しよう」
            ↓
（レイド期間終了後）
【最終結果画面】
    ├─ 討伐成功
    │       ・Mowi全員が輝くクラス演出
    │       ・「チームの英語力が、届いた。」
    │       ・全員にレイドバッジ付与
    │       ・MVP（最高ダメージ生徒）表示
    │
    └─ 討伐失敗
            ・「あとXダメージ足りなかった」
            ・「次のレイドで届かせよう」Mowiセリフ
            ・参加ボーナスXPのみ付与
```

### 9.5 レイドバトル ワイヤーフレーム（ボス討伐画面）

```
┌─────────────────────────────────────────┐
│  クラスレイド！                          │
│─────────────────────────────────────────│
│                                         │
│  👾「The Shadow of が構文」             │
│                                         │
│  ████████████████░░░░░░░░  72%          │  ← ボスHP
│  残りHP: 360 / クラス合計ダメージ: 140  │
│                                         │
│  ─────────────────────────────          │
│                                         │
│  [Mowi アニメーション]                  │
│                                         │
│  「田中が 🔥コンボ5！ +2ダメージ！」    │  ← リアルタイム通知
│                                         │
│─────────────────────────────────────────│
│                                         │
│  🇯🇵 「〜している間に」                 │
│                                         │
│  ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  │
│  │while │ │  I   │ │  am  │ │doing │  │
│  └──────┘ └──────┘ └──────┘ └──────┘  │
│                                         │
│  ┌──────────────────────────────────┐   │
│  │                                  │   │
│  └──────────────────────────────────┘   │
│                                         │
│  自分の貢献ダメージ: 12 / 今日残り: 3問 │
└─────────────────────────────────────────┘
```

---

## 10. Supabase テーブル定義

### 10.1 `battles` テーブル

```sql
-- =====================================================
-- テーブル名: battles
-- 用途: バトルセッション全体の記録
-- =====================================================
CREATE TABLE battles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- バトル種別
    battle_type         TEXT NOT NULL CHECK (battle_type IN ('daily', 'class', 'raid')),
    battle_date         DATE NOT NULL,

    -- 紐付け（クラスバトル・レイドに使用）
    class_battle_id     UUID REFERENCES class_battles(id) ON DELETE SET NULL,
    raid_id             UUID REFERENCES raids(id) ON DELETE SET NULL,

    -- バトル設定（開始時に確定・変更不可）
    ai_level            INTEGER CHECK (ai_level BETWEEN 0 AND 4),  -- デイリーのみ
    question_count      INTEGER NOT NULL DEFAULT 7,
    time_limit_seconds  INTEGER NOT NULL DEFAULT 8,
    combo_multiplier    NUMERIC(4,2) NOT NULL DEFAULT 1.0,  -- チェックイン影響
    time_multiplier     NUMERIC(4,2) NOT NULL DEFAULT 1.0,

    -- チェックイン状態（バトル開始時スナップショット）
    morning_mood        TEXT CHECK (morning_mood IN ('confident', 'okay', 'anxious', 'unsure')),
    checkin_score_bonus NUMERIC(4,2) NOT NULL DEFAULT 1.0,

    -- バトル結果
    score               INTEGER NOT NULL DEFAULT 0,
    accuracy_rate       NUMERIC(4,3) NOT NULL DEFAULT 0,  -- 0.000〜1.000
    avg_response_ms     INTEGER,
    max_combo           INTEGER NOT NULL DEFAULT 0,
    correct_count       INTEGER NOT NULL DEFAULT 0,
    total_questions     INTEGER NOT NULL DEFAULT 0,

    -- デイリー専用：AI対戦結果
    ai_target_score     INTEGER,   -- AIの目標スコア（3日前スコアの105%）
    battle_won          BOOLEAN,   -- デイリーのみ意味を持つ

    -- ステータス
    status              TEXT NOT NULL DEFAULT 'in_progress'
                        CHECK (status IN ('in_progress', 'completed', 'abandoned')),

    started_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at            TIMESTAMPTZ,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX battles_user_type_date_idx ON battles(user_id, battle_type, battle_date DESC);
CREATE INDEX battles_class_battle_idx   ON battles(class_battle_id) WHERE class_battle_id IS NOT NULL;
CREATE INDEX battles_raid_idx           ON battles(raid_id) WHERE raid_id IS NOT NULL;

-- RLS
ALTER TABLE battles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own battles"
    ON battles FOR ALL
    USING (auth.uid() = user_id);

CREATE POLICY "Teachers can view class battles"
    ON battles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members cm
            JOIN teachers t ON cm.class_id = t.class_id
            WHERE cm.user_id = battles.user_id
              AND t.user_id = auth.uid()
        )
    );
```

### 10.2 `battle_logs` テーブル

```sql
-- =====================================================
-- テーブル名: battle_logs
-- 用途: バトル中の1問ごとの回答ログ
-- =====================================================
CREATE TABLE battle_logs (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    battle_id           UUID NOT NULL REFERENCES battles(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- 問題情報
    pattern_id          TEXT NOT NULL,  -- 'P001' 〜 'P100'
    layer               INTEGER NOT NULL DEFAULT 3 CHECK (layer BETWEEN 0 AND 4),
    question_order      INTEGER NOT NULL,  -- バトル内の出題順（1〜N）

    -- 回答情報
    is_correct          BOOLEAN NOT NULL,
    response_time_ms    INTEGER NOT NULL,  -- 回答までのミリ秒
    was_timeout         BOOLEAN NOT NULL DEFAULT FALSE,
    hint_used           BOOLEAN NOT NULL DEFAULT FALSE,

    -- スコア計算の中間値（デバッグ・分析用）
    base_score          INTEGER NOT NULL DEFAULT 0,
    speed_bonus         NUMERIC(4,2) NOT NULL DEFAULT 1.0,
    combo_at_time       INTEGER NOT NULL DEFAULT 0,
    combo_multiplier    NUMERIC(4,2) NOT NULL DEFAULT 1.0,
    question_score      INTEGER NOT NULL DEFAULT 0,  -- この問題の最終得点

    answered_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX battle_logs_battle_idx ON battle_logs(battle_id, question_order);
CREATE INDEX battle_logs_user_pattern_idx ON battle_logs(user_id, pattern_id, answered_at DESC);

-- RLS
ALTER TABLE battle_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage own battle_logs"
    ON battle_logs FOR ALL
    USING (auth.uid() = user_id);
```

### 10.3 `class_battles` テーブル（クラスバトルのイベント定義）

```sql
-- =====================================================
-- テーブル名: class_battles
-- 用途: 先生が設定するクラスバトルイベント
-- =====================================================
CREATE TABLE class_battles (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id            UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id          UUID NOT NULL REFERENCES auth.users(id),

    title               TEXT NOT NULL,
    pattern_ids         TEXT[] NOT NULL DEFAULT '{}',  -- 出題パターン範囲
    question_count      INTEGER NOT NULL DEFAULT 15,
    time_limit_seconds  INTEGER NOT NULL DEFAULT 8,

    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,

    status              TEXT NOT NULL DEFAULT 'scheduled'
                        CHECK (status IN ('scheduled', 'active', 'finished')),

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX class_battles_class_status_idx ON class_battles(class_id, status, end_date DESC);

-- RLS
ALTER TABLE class_battles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teachers manage class_battles"
    ON class_battles FOR ALL
    USING (auth.uid() = teacher_id);

CREATE POLICY "Students can view their class battles"
    ON class_battles FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members
            WHERE class_id = class_battles.class_id
              AND user_id = auth.uid()
        )
    );
```

### 10.4 `raids` テーブル（レイドバトルのイベント定義）

```sql
-- =====================================================
-- テーブル名: raids
-- 用途: 先生が設定するレイドイベント
-- =====================================================
CREATE TABLE raids (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    class_id            UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
    teacher_id          UUID NOT NULL REFERENCES auth.users(id),

    title               TEXT NOT NULL,
    boss_name           TEXT NOT NULL,  -- 例：「The Shadow of が構文」
    pattern_ids         TEXT[] NOT NULL DEFAULT '{}',
    boss_hp             INTEGER NOT NULL,  -- 例：クラス人数 × 50

    -- ダメージ設定
    normal_damage       INTEGER NOT NULL DEFAULT 1,   -- 通常正解ダメージ
    combo_damage        INTEGER NOT NULL DEFAULT 2,   -- コンボ5以上ダメージ
    daily_question_limit INTEGER NOT NULL DEFAULT 10, -- 1人1日の上限

    start_date          DATE NOT NULL,
    end_date            DATE NOT NULL,

    -- 集計（リアルタイム更新）
    current_hp          INTEGER NOT NULL,  -- 残りHP
    total_damage_dealt  INTEGER NOT NULL DEFAULT 0,

    status              TEXT NOT NULL DEFAULT 'scheduled'
                        CHECK (status IN ('scheduled', 'active', 'finished')),
    result              TEXT CHECK (result IN ('victory', 'defeat', NULL)),
    finished_at         TIMESTAMPTZ,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- インデックス
CREATE INDEX raids_class_status_idx ON raids(class_id, status, end_date DESC);

-- RLS
ALTER TABLE raids ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Teachers manage raids"
    ON raids FOR ALL
    USING (auth.uid() = teacher_id);

CREATE POLICY "Students can view their class raids"
    ON raids FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM class_members
            WHERE class_id = raids.class_id
              AND user_id = auth.uid()
        )
    );
```

### 10.5 テーブル間リレーション図

```
auth.users
    │
    ├── battles (user_id FK)
    │       │
    │       ├── battle_logs (battle_id FK)
    │       │
    │       ├── class_battles (class_battle_id FK)  ← クラスバトル参照
    │       │
    │       └── raids (raid_id FK)                  ← レイド参照
    │
    ├── class_battles (teacher_id FK)
    │       │
    │       └── classes (class_id FK)
    │
    ├── raids (teacher_id FK)
    │       │
    │       └── classes (class_id FK)
    │
    └── checkins (user_id FK)
            │
            └── [battles の morning_mood に参照・コピー]
```

### 10.6 レイドHP更新用 Supabase Function

```sql
-- レイドのHP更新関数（バトル完了時にトリガー）
CREATE OR REPLACE FUNCTION update_raid_hp()
RETURNS TRIGGER AS $$
BEGIN
  -- バトルがレイド型で完了した場合のみ処理
  IF NEW.battle_type = 'raid' AND NEW.status = 'completed' AND NEW.raid_id IS NOT NULL THEN
    -- ダメージ計算（このバトルのコンボ5以上正解ログを集計）
    UPDATE raids
    SET
      current_hp        = GREATEST(0, current_hp - (
        SELECT
          SUM(CASE WHEN bl.combo_at_time >= 5 THEN 2 ELSE 1 END)
        FROM battle_logs bl
        WHERE bl.battle_id = NEW.id
          AND bl.is_correct = TRUE
      )),
      total_damage_dealt = total_damage_dealt + (
        SELECT
          SUM(CASE WHEN bl.combo_at_time >= 5 THEN 2 ELSE 1 END)
        FROM battle_logs bl
        WHERE bl.battle_id = NEW.id
          AND bl.is_correct = TRUE
      ),
      updated_at        = now()
    WHERE id = NEW.raid_id;

    -- ボスHPが0になったら討伐完了処理
    UPDATE raids
    SET
      status      = 'finished',
      result      = 'victory',
      finished_at = now()
    WHERE id = NEW.raid_id
      AND current_hp <= 0
      AND status = 'active';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- トリガー登録
CREATE TRIGGER on_battle_complete_update_raid
  AFTER UPDATE ON battles
  FOR EACH ROW
  WHEN (OLD.status = 'in_progress' AND NEW.status = 'completed')
  EXECUTE FUNCTION update_raid_hp();
```

---

## 11. フロントエンド実装スニペット（Vue 3）

### 11.1 バトル開始コンポーザブル

```javascript
// composables/useBattle.js
import { ref, computed } from 'vue';
import { supabase } from '@/lib/supabase';

export function useBattle(battleType) {
  const battle        = ref(null);
  const currentQuestion = ref(null);
  const questionIndex = ref(0);
  const score         = ref(0);
  const combo         = ref(0);
  const logs          = ref([]);
  const isLoading     = ref(false);
  const modifiers     = ref(null);

  // バトル初期化
  async function initBattle(options = {}) {
    isLoading.value = true;

    try {
      // ① チェックイン状態取得
      const mods = await getBattleModifiers(supabase.auth.user().id);
      modifiers.value = mods;

      // ② AI設定計算（デイリーのみ）
      const aiConfig = battleType === 'daily'
        ? await computeAiLevel(supabase.auth.user().id, mods)
        : null;

      // ③ 問題セット生成
      const patternIds = options.patternIds
        ?? await generateBattleQuestions(supabase.auth.user().id, aiConfig, mods.questionCountDelta);

      // ④ バトルレコード作成
      const { data } = await supabase.from('battles').insert({
        user_id:             supabase.auth.user().id,
        battle_type:         battleType,
        battle_date:         new Date().toISOString().split('T')[0],
        ai_level:            aiConfig?.level ?? null,
        ai_target_score:     aiConfig?.targetScore ?? null,
        question_count:      patternIds.length,
        time_limit_seconds:  (aiConfig?.timeLimitSeconds ?? 8) * mods.timeLimitMultiplier,
        combo_multiplier:    mods.comboBonusMultiplier,
        morning_mood:        mods.morningMood,
        checkin_score_bonus: mods.comboBonusMultiplier,
        class_battle_id:     options.classBattleId ?? null,
        raid_id:             options.raidId ?? null,
      }).select().single();

      battle.value = data;
      return { battle: data, modifiers: mods, patternIds };

    } finally {
      isLoading.value = false;
    }
  }

  // 1問回答の記録
  async function recordAnswer({ patternId, isCorrect, responseTimeMs, hintUsed }) {
    const timeLimit  = (battle.value.time_limit_seconds * 1000);
    const speedRate  = Math.max(0, (timeLimit - responseTimeMs) / timeLimit);
    const speedBonus = 1.0 + speedRate * 0.5;

    if (isCorrect) combo.value++;
    else           combo.value = 0;

    const comboMultiplier =
      combo.value >= 10 ? 1.5 :
      combo.value >= 7  ? 1.3 :
      combo.value >= 5  ? 1.2 :
      combo.value >= 3  ? 1.1 : 1.0;

    const checkinMultiplier = modifiers.value.comboBonusMultiplier ?? 1.0;
    const questionScore = isCorrect
      ? Math.round(100 * speedBonus * comboMultiplier * checkinMultiplier)
      : 0;

    score.value += questionScore;

    const log = {
      battle_id:       battle.value.id,
      user_id:         supabase.auth.user().id,
      pattern_id:      patternId,
      layer:           3,
      question_order:  questionIndex.value + 1,
      is_correct:      isCorrect,
      response_time_ms: responseTimeMs,
      was_timeout:     responseTimeMs >= timeLimit,
      hint_used:       hintUsed,
      base_score:      isCorrect ? 100 : 0,
      speed_bonus:     speedBonus,
      combo_at_time:   combo.value,
      combo_multiplier: comboMultiplier,
      question_score:  questionScore,
    };

    logs.value.push(log);
    await supabase.from('battle_logs').insert(log);

    questionIndex.value++;
  }

  // バトル完了処理
  async function completeBattle() {
    const correctCount = logs.value.filter(l => l.is_correct).length;
    const avgResponse  = Math.round(logs.value.reduce((s, l) => s + l.response_time_ms, 0) / logs.value.length);
    const maxCombo     = Math.max(...logs.value.map((_, i) => {
      let c = 0, max = 0;
      for (let j = 0; j <= i; j++) {
        if (logs.value[j].is_correct) { c++; max = Math.max(max, c); }
        else c = 0;
      }
      return max;
    }));

    const won = battleType === 'daily'
      ? score.value > (battle.value.ai_target_score ?? 0)
      : null;

    const { data } = await supabase
      .from('battles')
      .update({
        score,
        accuracy_rate:   correctCount / logs.value.length,
        avg_response_ms: avgResponse,
        max_combo:       maxCombo,
        correct_count:   correctCount,
        total_questions: logs.value.length,
        battle_won:      won,
        status:          'completed',
        ended_at:        new Date().toISOString(),
      })
      .eq('id', battle.value.id)
      .select()
      .single();

    return data;
  }

  return { battle, score, combo, isLoading, modifiers, initBattle, recordAnswer, completeBattle };
}
```

### 11.2 レイドHP リアルタイム購読

```javascript
// composables/useRaidRealtime.js
import { ref, onUnmounted } from 'vue';
import { supabase } from '@/lib/supabase';

export function useRaidRealtime(raidId) {
  const raidHp          = ref(null);
  const recentDamages   = ref([]);  // リアルタイム通知用

  const channel = supabase
    .channel(`raid:${raidId}`)
    .on('postgres_changes', {
      event:  'UPDATE',
      schema: 'public',
      table:  'raids',
      filter: `id=eq.${raidId}`,
    }, (payload) => {
      const prev = raidHp.value;
      raidHp.value = payload.new.current_hp;
      if (prev !== null) {
        recentDamages.value.unshift({
          damage: prev - payload.new.current_hp,
          at: new Date(),
        });
        // 最大10件保持
        if (recentDamages.value.length > 10) recentDamages.value.pop();
      }
    })
    .subscribe();

  onUnmounted(() => supabase.removeChannel(channel));

  return { raidHp, recentDamages };
}
```

---

## 12. 実装優先順位

| 優先度 | 機能 | 実装コスト | MVP必須 |
|--------|------|-----------|---------|
| 🔴 最優先 | デイリーバトル（AI対戦）問題画面 | 中 | ✅ |
| 🔴 最優先 | `battles` + `battle_logs` テーブル作成 | 低 | ✅ |
| 🔴 最優先 | チェックイン連動（難易度・倍率取得）| 中 | ✅ |
| 🔴 最優先 | AI難易度計算（3日前スコア参照）| 中 | ✅ |
| 🔴 最優先 | バトル結果画面（勝敗判定・Mowi演出）| 中 | ✅ |
| 🟡 次フェーズ | `class_battles` テーブル + 先生設定UI | 中〜高 | Phase 2 |
| 🟡 次フェーズ | クラスバトル問題画面 + ランキング表示 | 中〜高 | Phase 2 |
| 🟡 次フェーズ | `raids` テーブル + レイド告知画面 | 高 | Phase 2 |
| 🟡 次フェーズ | レイドバトル問題画面 + リアルタイムHP | 高 | Phase 2 |
| 🟡 次フェーズ | チームチェックイン集計（レイドダメージ倍率）| 中 | Phase 2 |
| 🟢 Phase 3 | レイドバッジ自動付与フロー | 中 | Phase 3 |
| 🟢 Phase 3 | クラス英語力MAP画面 | 中 | Phase 3 |

### MVP最短実装パス

```
1. battles・battle_logs テーブル作成（SQL流し込み）
        ↓
2. getBattleModifiers（チェックインDB参照）
        ↓
3. computeAiLevel（3日前スコア計算）
        ↓
4. generateBattleQuestions（pattern_progress から選定）
        ↓
5. デイリーバトル問題画面（Flash Output形式・既存コンポーネント流用）
        ↓
6. recordAnswer + calculateScore
        ↓
7. completeBattle + バトル結果画面（勝敗表示・Mowi演出）
```

---

## 付録：Mowiバトルセリフ一覧（バトル専用トリガー）

| トリガーID | 使用シーン | セリフ（日本語・内なる声） |
|-----------|----------|------------------------|
| `BATTLE_START_NORMAL` | デイリーバトル開始 | 「3日前の私が、ここにいる。」 |
| `BATTLE_START_CONFIDENT` | 朝チェックイン「自信ある」＋開始 | 「今日は、届く気がする。」 |
| `BATTLE_START_ANXIOUS` | 朝チェックイン「不安」＋開始 | 「今日は、できる範囲でいい。」 |
| `BATTLE_COMBO_5` | コンボ5達成 | 「また、速くなってる。」 |
| `BATTLE_COMBO_10` | コンボ10達成 | 「止まらない。全部、体にある。」 |
| `BATTLE_TIMEOUT` | タイムアウト | 「…まだ、反射になっていない。」 |
| `BATTLE_WIN` | デイリーバトル勝利 | 「3日前の私を、超えた。」 |
| `BATTLE_LOSE` | デイリーバトル敗北 | 「まだ、3日前の方が速かった。」 |
| `BATTLE_PERSONAL_BEST` | クラスバトルでベスト更新 | 「今週、一番速い自分だった。」 |
| `RAID_JOIN` | レイド参加時 | 「みんなの英語力が、合わさる。」 |
| `RAID_BOSS_HALF` | ボスHP50%以下 | 「もう半分まで、届いた。」 |
| `RAID_VICTORY` | レイド討伐成功 | 「チームの英語力が、届いた。」 |
| `RAID_DEFEAT` | レイド討伐失敗 | 「あと少し。次は、届かせよう。」 |

---

*MoWISE B バトルシステム再設計書 v1.0*
*策定日：2026年2月23日*
*次回更新：デイリーバトルUXテスト後・クラスバトル実装前*
