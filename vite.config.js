import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// `base` lets the app be hosted under a GitHub Pages project path
// (e.g. https://user.github.io/wreckfest-2-race-log/). It is set via
// VITE_BASE_PATH at build time so local dev still serves at /.
export default defineConfig({
  plugins: [vue()],
  base: process.env.VITE_BASE_PATH || '/',
  server: {
    port: 5173
  }
})
