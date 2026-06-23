// ============================================================
// MoWISE Game SDK - postMessage bridge for iframe games
// ============================================================

export interface GameScorePayload {
  gameId: string
  score: number
  maxScore?: number
  accuracy?: number
  timeSpent?: number
  xpEarned?: number
  coinsEarned?: number
  completed?: boolean
  metadata?: Record<string, unknown>
}

export interface GameReadyPayload {
  gameId: string
  version?: string
}

type GameEventType = 'GAME_READY' | 'GAME_SCORE' | 'GAME_COMPLETE' | 'GAME_EXIT'

interface GameMessage {
  type: GameEventType
  payload: GameScorePayload | GameReadyPayload
  source: 'mowise-game'
}

type GameEventHandler = (payload: GameScorePayload) => void

const handlers: Map<GameEventType, GameEventHandler[]> = new Map()

function isGameMessage(data: unknown): data is GameMessage {
  return (
    typeof data === 'object' &&
    data !== null &&
    'type' in data &&
    'source' in data &&
    (data as GameMessage).source === 'mowise-game'
  )
}

export function onGameEvent(type: GameEventType, handler: GameEventHandler) {
  const list = handlers.get(type) ?? []
  list.push(handler)
  handlers.set(type, list)
}

export function offGameEvent(type: GameEventType, handler: GameEventHandler) {
  const list = handlers.get(type) ?? []
  handlers.set(type, list.filter(h => h !== handler))
}

export function initGameListener() {
  window.addEventListener('message', (event: MessageEvent) => {
    if (!isGameMessage(event.data)) return
    const { type, payload } = event.data
    const list = handlers.get(type) ?? []
    for (const handler of list) {
      handler(payload as GameScorePayload)
    }
  })
}

export function sendToGame(iframe: HTMLIFrameElement, type: string, payload: Record<string, unknown>) {
  iframe.contentWindow?.postMessage({ type, payload, source: 'mowise-parent' }, '*')
}

// ============================================================
// wise-game-bridge.js - embed in each game app (separate file)
// This is the game-side SDK that reports scores to the parent
// ============================================================
export const GAME_BRIDGE_SCRIPT = `
(function() {
  if (window.WiseGame) return;

  var parentOrigin = '*';

  window.WiseGame = {
    gameId: null,

    init: function(config) {
      this.gameId = config.gameId;
      this._send('GAME_READY', { gameId: this.gameId, version: config.version || '1.0' });
    },

    reportScore: function(data) {
      this._send('GAME_SCORE', Object.assign({ gameId: this.gameId }, data));
    },

    reportComplete: function(data) {
      this._send('GAME_COMPLETE', Object.assign({ gameId: this.gameId, completed: true }, data));
    },

    exit: function() {
      this._send('GAME_EXIT', { gameId: this.gameId });
    },

    _send: function(type, payload) {
      if (window.parent !== window) {
        window.parent.postMessage({ type: type, payload: payload, source: 'mowise-game' }, parentOrigin);
      }
    }
  };

  // Listen for config from parent
  window.addEventListener('message', function(e) {
    if (e.data && e.data.source === 'mowise-parent') {
      if (e.data.type === 'INIT_GAME') {
        window.WiseGame.init(e.data.payload);
      }
    }
  });
})();
`
