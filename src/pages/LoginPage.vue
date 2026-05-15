<template>
  <div class="min-h-screen flex items-center justify-center px-6">
    <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-6 sm:p-8 w-full max-w-md">
      <h1 class="font-display font-black tracking-tighter leading-none text-display-lg text-brand-text dark:text-brand-text-dark mb-3">
        🏁 Wreckfest Race <em class="signal">Log</em>
      </h1>
      <p class="font-body text-[15px] leading-relaxed text-brand-secondary dark:text-brand-secondary-dark mb-6">
        {{ mode === 'signin' ? 'Sign in to log your races.' : 'Create an account to start logging races.' }}
      </p>

      <form @submit.prevent="onSubmit" class="space-y-3">
        <div>
          <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
            Email
          </label>
          <input
            v-model="email"
            type="email"
            required
            autocomplete="email"
            class="w-full rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-surface-dark px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-accent"
            placeholder="you@example.com"
          />
        </div>

        <div>
          <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
            Password
          </label>
          <input
            v-model="password"
            type="password"
            required
            minlength="6"
            :autocomplete="mode === 'signin' ? 'current-password' : 'new-password'"
            class="w-full rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-surface-dark px-3 py-2 focus:outline-none focus:ring-2 focus:ring-brand-accent"
            placeholder="••••••••"
          />
        </div>

        <button
          type="submit"
          :disabled="submitting"
          class="w-full font-display font-black uppercase tracking-widest bg-brand-accent text-white px-6 py-3 rounded-none hover:opacity-85 active:opacity-70 transition-opacity disabled:opacity-60"
        >
          {{ submitButtonLabel }}
        </button>
      </form>

      <p class="mt-4 font-body text-[15px] text-brand-secondary dark:text-brand-secondary-dark text-center">
        {{ mode === 'signin' ? "Don't have an account?" : 'Already have an account?' }}
        <button
          type="button"
          class="text-brand-accent hover:underline ml-1"
          @click="toggleMode"
        >
          {{ mode === 'signin' ? 'Create one' : 'Sign in' }}
        </button>
      </p>

      <p v-if="message" class="mt-4 text-sm text-green-600">{{ message }}</p>
      <p v-if="errorMessage" class="mt-4 text-sm text-red-600">{{ errorMessage }}</p>
    </div>
  </div>
</template>

<script>
import { signInWithPassword, signUpWithPassword } from '../services/authService.js'

export default {
  name: 'LoginPage',
  data() {
    return {
      mode: 'signin',
      email: '',
      password: '',
      submitting: false,
      message: '',
      errorMessage: ''
    }
  },
  computed: {
    submitButtonLabel() {
      if (this.submitting) return this.mode === 'signin' ? 'Signing in...' : 'Creating account...'
      return this.mode === 'signin' ? 'Sign in' : 'Create account'
    },
    redirectPath() {
      const target = this.$route.query.redirect
      if (typeof target === 'string' && target.startsWith('/') && !target.startsWith('//')) {
        return target
      }
      return '/'
    }
  },
  methods: {
    toggleMode() {
      this.mode = this.mode === 'signin' ? 'signup' : 'signin'
      this.message = ''
      this.errorMessage = ''
    },
    async onSubmit() {
      this.message = ''
      this.errorMessage = ''
      this.submitting = true
      try {
        if (this.mode === 'signin') {
          await signInWithPassword(this.email.trim(), this.password)
          this.$router.replace(this.redirectPath)
        } else {
          const { session } = await signUpWithPassword(this.email.trim(), this.password)
          if (session) {
            this.$router.replace(this.redirectPath)
          } else {
            // Project has "Confirm email" enabled — the user has to click the
            // verification link before we can sign them in.
            this.message = 'Account created. Check your inbox to confirm your email, then sign in.'
            this.mode = 'signin'
          }
        }
      } catch (err) {
        this.errorMessage = err.message || 'Authentication failed.'
      } finally {
        this.submitting = false
      }
    }
  }
}
</script>
