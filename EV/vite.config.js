// vite.config.js
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

const API_URL =
  process.env.VITE_API_URL || 'https://ev-charging-backend-5yw3.onrender.com'

// .vue / .js 소스 안의 'http://localhost:8080' 리터럴을 빌드 시 API_URL 로 치환
// → .vue 파일을 직접 수정하지 않고도 prod 에서 올바른 백엔드를 호출
const apiUrlReplacer = {
  name: 'replace-localhost-api-url',
  enforce: 'pre',
  transform(code, id) {
    if (/\.(vue|js|ts|mjs)$/.test(id) && code.includes('http://localhost:8080')) {
      return {
        code: code.split('http://localhost:8080').join(API_URL),
        map: null,
      }
    }
    return null
  },
}

export default defineConfig({
  plugins: [vue(), apiUrlReplacer],
  server: {
    proxy: {
      '/api': {
        target: API_URL,   // dev 모드에서도 /api/* 를 백엔드로 프록시
        changeOrigin: true,
      },
    },
  },
})
