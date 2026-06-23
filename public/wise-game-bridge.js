/**
 * MoWISE Game Bridge - Embed in each game app
 * Usage: <script src="https://mowise.vercel.app/wise-game-bridge.js"></script>
 *
 * Then call:
 *   WiseGame.init({ gameId: 'eiken-game' })
 *   WiseGame.reportScore({ score: 100, accuracy: 85, timeSpent: 120 })
 *   WiseGame.reportComplete({ score: 100, accuracy: 85, xpEarned: 50 })
 *   WiseGame.exit()
 */
(function() {
  if (window.WiseGame) return;

  window.WiseGame = {
    gameId: null,
    _inIframe: window.parent !== window,

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
      if (this._inIframe) {
        window.parent.postMessage({
          type: type,
          payload: payload,
          source: 'mowise-game'
        }, '*');
      }
    }
  };

  // Listen for config from parent MoWISE app
  window.addEventListener('message', function(e) {
    if (e.data && e.data.source === 'mowise-parent') {
      if (e.data.type === 'INIT_GAME' && e.data.payload) {
        window.WiseGame.init(e.data.payload);
      }
    }
  });
})();
