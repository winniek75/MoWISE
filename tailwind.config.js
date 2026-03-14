/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{vue,js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        brand: {
          primary:   '#4A7AFF',
          secondary: '#9B5CF6',
        },
        bg: {
          dark:    '#0d0d1a',
          surface: '#141428',
          card:    '#1e1e3a',
        },
        correct: '#4CAF50',
        wrong:   '#F44336',
        star:    '#FFD700',
        // Mowi コンボカラー
        combo: {
          low:    '#64B5F6',  // 3-4
          mid:    '#9C27B0',  // 5-6
          high:   '#FF9800',  // 7-9
          // 10+ はアニメで虹色
        },
      },
      fontFamily: {
        sans:  ['Noto Sans JP', 'sans-serif'],
        title: ['Outfit', 'sans-serif'],
      },
      fontSize: {
        pattern: ['22px', { fontWeight: '700' }],
        mowi:    ['16px', { fontWeight: '400' }],
      },
      animation: {
        'mowi-pulse':   'mowiPulse 2s ease-in-out infinite',
        'mowi-glow':    'mowiGlow 1.5s ease-in-out infinite',
        'combo-burst':  'comboBurst 0.4s cubic-bezier(0.36, 0.07, 0.19, 0.97)',
        'tile-enter':   'tileEnter 0.25s ease-out',
        'checkin-fade': 'checkinFade 0.5s ease-out',
      },
      keyframes: {
        mowiPulse: {
          '0%, 100%': { transform: 'scale(1)',    opacity: '1'    },
          '50%':      { transform: 'scale(1.04)', opacity: '0.9'  },
        },
        mowiGlow: {
          '0%, 100%': { filter: 'brightness(1)   drop-shadow(0 0 8px  #9B5CF6)' },
          '50%':      { filter: 'brightness(1.2) drop-shadow(0 0 24px #4A7AFF)' },
        },
        comboBurst: {
          '0%':   { transform: 'scale(1)'    },
          '40%':  { transform: 'scale(1.15)' },
          '100%': { transform: 'scale(1)'    },
        },
        tileEnter: {
          from: { transform: 'scale(0.8)', opacity: '0' },
          to:   { transform: 'scale(1)',   opacity: '1' },
        },
        checkinFade: {
          from: { opacity: '0', transform: 'translateY(12px)' },
          to:   { opacity: '1', transform: 'translateY(0)'    },
        },
      },
      backgroundImage: {
        'mowi-rainbow': 'conic-gradient(from 0deg, #FF0080, #FF8C00, #FFD700, #00FF88, #00BFFF, #8B5CF6, #FF0080)',
      },
    },
  },
  plugins: [],
}
