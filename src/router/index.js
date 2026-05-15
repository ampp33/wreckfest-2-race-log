import { createRouter, createWebHashHistory } from 'vue-router'
import { authStore, initAuthStore } from '../stores/authStore.js'

import TrackListPage from '../pages/TrackListPage.vue'
import TrackDetailPage from '../pages/TrackDetailPage.vue'
import StatsPage from '../pages/StatsPage.vue'
import LoginPage from '../pages/LoginPage.vue'
import DiagnosticsPage from '../pages/DiagnosticsPage.vue'
import UserRolesPage from '../pages/UserRolesPage.vue'
import RacesPage from '../pages/RacesPage.vue'
import ApiKeysPage from '../pages/ApiKeysPage.vue'

const routes = [
  { path: '/login', name: 'login', component: LoginPage, meta: { public: true } },
  { path: '/', name: 'tracks', component: TrackListPage },
  {
    path: '/track/:trackSlug/:variationSlug',
    name: 'track-detail',
    component: TrackDetailPage
  },
  { path: '/races', name: 'races', component: RacesPage },
  { path: '/stats', name: 'stats', component: StatsPage },
  { path: '/settings/api-keys', name: 'api-keys', component: ApiKeysPage },
  { path: '/admin/diagnostics', name: 'admin-diagnostics', component: DiagnosticsPage, meta: { requiresAdmin: true } },
  { path: '/admin/users', name: 'admin-users', component: UserRolesPage, meta: { requiresAdmin: true } },
  { path: '/:pathMatch(.*)*', redirect: '/' }
]

// Hash history avoids needing a 404 fallback on GitHub Pages.
export const router = createRouter({
  history: createWebHashHistory(),
  routes
})

router.beforeEach(async to => {
  await initAuthStore()
  if (to.meta.public) return true
  if (!authStore.isAuthenticated) {
    return { name: 'login', query: { redirect: to.fullPath } }
  }
  if (to.meta.requiresAdmin && !authStore.isAdmin) {
    return { name: 'tracks' }
  }
  return true
})
