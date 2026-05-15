import { createApp } from 'vue'
import App from './App.vue'
import { router } from './router/index.js'
import { initAuthStore } from './stores/authStore.js'
import './style.css'

async function bootstrap() {
  // Resolve the session before mounting so the first paint already reflects
  // the user's auth state and we don't flash "Loading session...".
  await initAuthStore()
  const app = createApp(App)
  app.use(router)
  app.mount('#app')
}

bootstrap()
