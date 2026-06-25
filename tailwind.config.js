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
          primary:   '#6C5CE7',
          secondary: '#00CECE',
          accent:    '#FF6B9D',
          glow:      '#A78BFA',
        },
        bg: {
          dark:    '#0B0B1A',
          surface: '#12122B',
          card:    '#1A1A3E',
          elevated:'#222255',
        },
        neon: {
          purple: '#A78BFA',
          cyan:   '#22D3EE',
          pink:   '#F472B6',
          green:  '#34D399',
          orange: '#FB923C',
          yellow: '#FACC15',
        },
        correct: '#34D399',
        wrong:   '#F87171',
        star:    '#FACC15',
        combo: {
          low:    '#22D3EE',
          mid:    '#A78BFA',
          high:   '#FB923C',
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
        'float':        'float 3s ease-in-out infinite',
        'glow-pulse':   'glowPulse 2s ease-in-out infinite',
        'slide-up':     'slideUp 0.3s ease-out',
        'pop-in':       'popIn 0.3s cubic-bezier(0.34, 1.56, 0.64, 1)',
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
        float: {
          '0%, 100%': { transform: 'translateY(0)' },
          '50%':      { transform: 'translateY(-6px)' },
        },
        glowPulse: {
          '0%, 100%': { opacity: '0.6' },
          '50%':      { opacity: '1' },
        },
        slideUp: {
          from: { opacity: '0', transform: 'translateY(16px)' },
          to:   { opacity: '1', transform: 'translateY(0)' },
        },
        popIn: {
          from: { opacity: '0', transform: 'scale(0.8)' },
          to:   { opacity: '1', transform: 'scale(1)' },
        },
      },
      backgroundImage: {
        'mowi-rainbow': 'conic-gradient(from 0deg, #FF0080, #FF8C00, #FFD700, #00FF88, #00BFFF, #8B5CF6, #FF0080)',
        'neo-gradient':  'linear-gradient(135deg, #6C5CE7 0%, #00CECE 100%)',
        'neo-card':      'linear-gradient(145deg, #1A1A3E 0%, #222255 100%)',
        'neo-hero':      'linear-gradient(180deg, #12122B 0%, #1A1A3E 50%, #0B0B1A 100%)',
      },
      boxShadow: {
        'neo-sm':    '0 0 12px rgba(108, 92, 231, 0.15)',
        'neo-md':    '0 0 24px rgba(108, 92, 231, 0.2)',
        'neo-lg':    '0 4px 40px rgba(108, 92, 231, 0.3)',
        'neo-cyan':  '0 0 20px rgba(0, 206, 206, 0.25)',
        'neo-pink':  '0 0 20px rgba(244, 114, 182, 0.25)',
        'neo-glow':  '0 0 30px rgba(167, 139, 250, 0.4)',
      },
      borderRadius: {
        '3xl': '1.5rem',
        '4xl': '2rem',
      },
    },
  },
  plugins: [],
}
