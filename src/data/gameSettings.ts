import { GameMode } from '../types/models';

/**
 * ゲーム設定のインターフェース
 */
export interface GameSettings {
  /** 難易度調整設定 */
  difficulty: {
    /** 基本難易度 (1-5) */
    baseLevel: number;
    /** 動的難易度調整を有効にするか */
    dynamicAdjustment: boolean;
    /** スコアに基づく難易度上昇閾値 */
    levelUpThreshold: number;
    /** 連続ミスによる難易度低下閾値 */
    levelDownThreshold: number;
  };
  
  /** タイマー設定 */
  timer: {
    /** 制限時間（秒）*/
    defaultTime: number;
    /** レベルごとの時間調整（秒） */
    levelTimeAdjustment: number;
    /** タイムボーナスの有効化 */
    enableTimeBonus: boolean;
    /** タイムボーナスの計算係数 */
    timeBonusFactor: number;
  };
  
  /** スコア設定 */
  scoring: {
    /** 基本点数 */
    basePoints: number;
    /** コンボボーナスの有効化 */
    enableComboBonus: boolean;
    /** コンボボーナスの計算係数 */
    comboBonusFactor: number;
    /** 素早さボーナスの有効化 */
    enableSpeedBonus: boolean;
    /** 正確性ボーナスの有効化 */
    enableAccuracyBonus: boolean;
    /** ミスによる減点 */
    mistakePenalty: number;
  };
  
  /** ヒント設定 */
  hints: {
    /** 利用可能なヒント回数 */
    maxHints: number;
    /** ヒント使用時のペナルティ */
    hintPenalty: number;
    /** ヒントの自動提案を有効にするか */
    autoSuggest: boolean;
    /** ヒントの自動提案までのミス回数 */
    autoSuggestAfterMistakes: number;
  };
  
  /** フィードバック設定 */
  feedback: {
    /** 視覚的フィードバックの有効化 */
    visualFeedback: boolean;
    /** 聴覚的フィードバックの有効化 */
    audioFeedback: boolean;
    /** フィードバック表示時間（ミリ秒） */
    displayDuration: number;
    /** 正解時のフィードバックメッセージ */
    correctMessages: string[];
    /** 不正解時のフィードバックメッセージ */
    incorrectMessages: string[];
  };
  
  /** アニメーション設定 */
  animation: {
    /** アニメーションの有効化 */
    enabled: boolean;
    /** アニメーション速度（0.5-2.0） */
    speed: number;
    /** パーティクルエフェクトの強度（0-2） */
    particleIntensity: number;
    /** アクセシビリティモード（アニメーション削減） */
    reducedMotion: boolean;
  };
  
  /** ゲームモード設定 */
  gameMode: {
    /** 現在のゲームモード */
    currentMode: GameMode;
    /** チャレンジモードのロック解除レベル */
    challengeModeUnlockLevel: number;
    /** テストモードの制限時間（秒） */
    testModeTimeLimit: number;
    /** マルチプレイヤーの最大プレイヤー数 */
    multiplayerMaxPlayers: number;
  };
  
  /** 学習進捗設定 */
  progress: {
    /** レベルアップに必要な経験値 */
    xpPerLevel: number;
    /** アクティビティ完了のスコア閾値（％） */
    completionThreshold: number;
    /** 習得と見なすためのスコア閾値（％） */
    masteryThreshold: number;
    /** 復習間隔（日数） */
    reviewInterval: number;
  };
}

/**
 * ゲーム設定のデフォルト値
 */
export const defaultGameSettings: GameSettings = {
  difficulty: {
    baseLevel: 1,
    dynamicAdjustment: true,
    levelUpThreshold: 100,
    levelDownThreshold: 3
  },
  
  timer: {
    defaultTime: 60,
    levelTimeAdjustment: 10,
    enableTimeBonus: true,
    timeBonusFactor: 0.5
  },
  
  scoring: {
    basePoints: 10,
    enableComboBonus: true,
    comboBonusFactor: 0.1,
    enableSpeedBonus: true,
    enableAccuracyBonus: true,
    mistakePenalty: 0
  },
  
  hints: {
    maxHints: 3,
    hintPenalty: 5,
    autoSuggest: true,
    autoSuggestAfterMistakes: 3
  },
  
  feedback: {
    visualFeedback: true,
    audioFeedback: true,
    displayDuration: 1500,
    correctMessages: [
      '出た。ちゃんと出た。',
      '体に入った。',
      '自然に出た。',
      '口が、覚えてる。',
      '迷わなかった。',
    ],
    incorrectMessages: [
      'あと少し、だった。',
      'まだ体になじんでない。',
      'もう一回。今度は出る。',
      '…なんか変。',
      '次はできるよ！'
    ]
  },
  
  animation: {
    enabled: true,
    speed: 1.0,
    particleIntensity: 1.0,
    reducedMotion: false
  },
  
  gameMode: {
    currentMode: GameMode.PRACTICE,
    challengeModeUnlockLevel: 3,
    testModeTimeLimit: 300,
    multiplayerMaxPlayers: 4
  },
  
  progress: {
    xpPerLevel: 100,
    completionThreshold: 70,
    masteryThreshold: 90,
    reviewInterval: 7
  }
};

/**
 * アクティビティ別の特殊設定
 */
export const activitySpecificSettings: Record<string, Partial<GameSettings>> = {
  // サウンドキャッチャーの設定
  'sound-catcher': {
    timer: {
      defaultTime: 60,
      levelTimeAdjustment: 5
    },
    scoring: {
      basePoints: 10,
      comboBonusFactor: 0.2
    },
    hints: {
      maxHints: 5
    }
  },
  
  // ワードスタッカーの設定
  'word-stacker': {
    timer: {
      defaultTime: 90,
      levelTimeAdjustment: 10
    },
    scoring: {
      basePoints: 20,
      enableSpeedBonus: true
    },
    hints: {
      maxHints: 3
    }
  },
  
  // アクションマッチの設定
  'action-match': {
    timer: {
      defaultTime: 120,
      levelTimeAdjustment: 15
    },
    scoring: {
      basePoints: 15,
      comboBonusFactor: 0.15
    },
    hints: {
      maxHints: 2
    }
  }
};

/**
 * 年齢グループ別の設定調整
 */
export const ageGroupSettings: Record<string, Partial<GameSettings>> = {
  // 子供向け設定
  'kids': {
    difficulty: {
      dynamicAdjustment: true,
      levelUpThreshold: 120
    },
    timer: {
      defaultTime: 75 // より長い時間
    },
    hints: {
      maxHints: 5, // より多くのヒント
      autoSuggest: true,
      autoSuggestAfterMistakes: 2
    },
    animation: {
      particleIntensity: 1.5 // より派手なエフェクト
    },
    feedback: {
      displayDuration: 2000 // より長いフィードバック表示
    }
  },
  
  // ティーン向け設定
  'teens': {
    // ほぼデフォルト設定
    scoring: {
      mistakePenalty: 2 // 小さなペナルティ
    }
  },
  
  // 大人向け設定
  'adults': {
    difficulty: {
      dynamicAdjustment: false // 固定難易度
    },
    timer: {
      defaultTime: 45 // より短い時間
    },
    hints: {
      maxHints: 2, // より少ないヒント
      autoSuggest: false
    },
    animation: {
      particleIntensity: 0.7 // 控えめなエフェクト
    }
  }
};

/**
 * 特定ユーザー向けの設定を取得
 */
export const getSettingsForUser = (
  userId: string,
  ageGroup: string,
  activityId: string
): GameSettings => {
  // 基本設定を取得
  const baseSettings = { ...defaultGameSettings };
  
  // 年齢グループによる調整を適用
  if (ageGroupSettings[ageGroup]) {
    applySettingsOverride(baseSettings, ageGroupSettings[ageGroup]);
  }
  
  // アクティビティ別の設定を適用
  if (activitySpecificSettings[activityId]) {
    applySettingsOverride(baseSettings, activitySpecificSettings[activityId]);
  }
  
  // TODO: ユーザー固有の設定を適用（これは将来的にデータベースから取得するなどの実装が必要）
  
  return baseSettings;
};

/**
 * 設定のオーバーライドを適用
 */
function applySettingsOverride<T>(
  baseSettings: T,
  overrideSettings: Partial<T>
): T {
  for (const key in overrideSettings) {
    if (
      typeof overrideSettings[key] === 'object' && 
      overrideSettings[key] !== null &&
      baseSettings[key]
    ) {
      // 再帰的に適用
      baseSettings[key] = applySettingsOverride(
        baseSettings[key], 
        overrideSettings[key] as any
      );
    } else {
      // プリミティブ値のオーバーライド
      baseSettings[key] = overrideSettings[key] as any;
    }
  }
  
  return baseSettings;
}