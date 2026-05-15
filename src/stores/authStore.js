import { reactive } from 'vue'
import { getSession, onAuthChange } from '../services/authService.js'
import { supabase } from '../services/supabase.js'

export const authStore = reactive({
  session: null,
  ready: false,
  userRoles: [],

  get user() {
    return this.session ? this.session.user : null
  },

  get isAuthenticated() {
    return Boolean(this.session)
  },

  get isAdmin() {
    return this.userRoles.some(ur => ur.roles?.name === 'admin')
  }
})

async function fetchUserRoles() {
  if (!authStore.user) {
    authStore.userRoles = []
    return
  }
  const { data } = await supabase
    .from('user_roles')
    .select('role_id, roles(name)')
    .eq('user_id', authStore.user.id)
  authStore.userRoles = data ?? []
}

let initialized = false

export async function initAuthStore() {
  if (initialized) return
  initialized = true

  try {
    authStore.session = await getSession()
    await fetchUserRoles()
  } catch (err) {
    console.error('Failed to load session', err)
    authStore.session = null
  } finally {
    authStore.ready = true
  }

  onAuthChange(async session => {
    authStore.session = session
    await fetchUserRoles()
  })
}
