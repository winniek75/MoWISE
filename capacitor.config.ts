import type { CapacitorConfig } from '@capacitor/cli'

const config: CapacitorConfig = {
  appId: 'com.wiseenglishclub.mowisse',
  appName: 'MoWISE',
  webDir: 'dist',
  server: {
    // 開発時のみ有効（本番では削除すること）
    // url: 'http://192.168.x.x:5173',
    // cleartext: true,
  },
  plugins: {
    StatusBar: {
      style: 'Dark',
      backgroundColor: '#0d0d1a',
    },
  },
  ios: {
    contentInset: 'always',
  },
  android: {
    backgroundColor: '#0d0d1a',
  },
}

export default config
