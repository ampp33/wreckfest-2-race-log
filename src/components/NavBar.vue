<template>
  <nav class="bg-brand-bg dark:bg-brand-surface-dark border-b border-brand-border dark:border-brand-border-dark">
    <div class="max-w-6xl mx-auto px-4 py-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 sm:gap-4">
      <router-link
        to="/"
        class="font-display font-black tracking-tighter leading-none text-brand-text dark:text-brand-text-dark text-xl"
      >
        Wreckfest <em class="signal">2</em> Race <em class="signal">Log</em>
      </router-link>

      <div class="flex flex-wrap items-center gap-2 sm:gap-4 text-sm font-body">
        <router-link
          to="/"
          class="hover:text-brand-accent"
          active-class="text-brand-accent font-semibold"
          :class="{ 'text-brand-accent font-semibold': isTrackListRoute }"
        >
          Tracks
        </router-link>
        <router-link
          to="/races"
          class="hover:text-brand-accent"
          active-class="text-brand-accent font-semibold"
        >
          Races
        </router-link>
        <router-link
          to="/stats"
          class="hover:text-brand-accent"
          active-class="text-brand-accent font-semibold"
        >
          Stats
        </router-link>
        <!-- <router-link
          to="/settings/api-keys"
          class="hover:text-brand-accent"
          active-class="text-brand-accent font-semibold"
        >
          API Keys
        </router-link> -->

        <div v-if="auth.isAdmin" class="relative group">
          <button
            type="button"
            class="flex items-center gap-1 hover:text-brand-accent"
            :class="{ 'text-brand-accent font-semibold': isAdminRoute }"
          >
            Admin
            <svg xmlns="http://www.w3.org/2000/svg" class="w-3 h-3 mt-px" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z" clip-rule="evenodd" />
            </svg>
          </button>
          <div class="absolute right-0 top-full pt-1 hidden group-hover:block z-50">
            <div class="w-40 bg-brand-bg dark:bg-brand-surface-dark border border-brand-border dark:border-brand-border-dark rounded shadow-lg py-1">
              <router-link
                to="/admin/diagnostics"
                class="block px-4 py-2 text-sm hover:bg-brand-surface dark:hover:bg-brand-surface-dark/70"
                active-class="text-brand-accent font-semibold"
              >
                Diagnostics
              </router-link>
              <router-link
                to="/admin/users"
                class="block px-4 py-2 text-sm hover:bg-brand-surface dark:hover:bg-brand-surface-dark/70"
                active-class="text-brand-accent font-semibold"
              >
                Users
              </router-link>
            </div>
          </div>
        </div>

        <button
          type="button"
          class="h-7 px-2 flex items-center justify-center leading-none rounded border border-brand-border dark:border-brand-border-dark hover:bg-brand-surface dark:hover:bg-brand-surface-dark"
          @click="onToggleDark"
          :aria-label="prefs.darkMode ? 'Switch to light mode' : 'Switch to dark mode'"
        >
          {{ prefs.darkMode ? '☀' : '🌙' }}
        </button>

        <button
          type="button"
          class="h-7 px-2 flex items-center justify-center rounded border border-brand-border dark:border-brand-border-dark hover:bg-brand-surface dark:hover:bg-brand-surface-dark"
          aria-label="feedback"
          @click="onOpenFeedback"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4" aria-hidden="true">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 20.25c4.97 0 9-3.694 9-8.25s-4.03-8.25-9-8.25S3 7.444 3 12c0 2.104.859 4.023 2.273 5.48.432.447.74 1.04.586 1.641a4.483 4.483 0 0 1-.923 1.785A5.969 5.969 0 0 0 6 21c1.282 0 2.47-.402 3.445-1.087.81.22 1.668.337 2.555.337Z" />
          </svg>
        </button>

        <button
          v-if="auth.isAuthenticated"
          type="button"
          class="ml-2 text-brand-muted dark:text-brand-muted-dark hover:text-brand-accent text-xs"
          @click="onSignOut"
        >
          Sign out
        </button>
      </div>
    </div>
  </nav>
</template>

<script>
import { authStore } from '../stores/authStore.js'
import { prefsStore } from '../stores/prefsStore.js'
import { signOut } from '../services/authService.js'
import { pushToast } from '../stores/toastStore.js'
import { openFeedback } from '../stores/feedbackStore.js'

export default {
  name: 'NavBar',
  data() {
    return {
      auth: authStore,
      prefs: prefsStore
    }
  },
  computed: {
    isTrackListRoute() {
      return this.$route.path === '/'
    },
    isAdminRoute() {
      return this.$route.path.startsWith('/admin')
    }
  },
  methods: {
    onToggleDark() {
      this.prefs.darkMode = !this.prefs.darkMode
    },
    onOpenFeedback() {
      openFeedback()
    },
    async onSignOut() {
      try {
        await signOut()
        this.$router.push('/login')
      } catch (err) {
        pushToast(err.message || 'Sign out failed', 'error')
      }
    }
  }
}
</script>
