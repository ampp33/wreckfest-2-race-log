<template>
  <div class="max-w-4xl mx-auto px-6 py-6 pb-24">
    <h1 class="font-display font-black tracking-tighter leading-none text-display-lg text-brand-text dark:text-brand-text-dark mb-1">
      API <em class="signal">Keys</em>
    </h1>
    <p class="font-body text-[15px] leading-relaxed text-brand-secondary dark:text-brand-secondary-dark mb-6">
      Generate keys for the Wreckfest sidecar app so it can auto-submit race results on your behalf.
    </p>

    <!-- New key reveal banner -->
    <div
      v-if="newKeyValue"
      class="mb-6 bg-yellow-50 dark:bg-yellow-900/20 border border-yellow-300 dark:border-yellow-700 rounded p-4"
    >
      <p class="font-body font-semibold text-[14px] text-yellow-800 dark:text-yellow-300 mb-1">
        Copy your new API key — it won't be shown again.
      </p>
      <div class="flex items-center gap-2 mt-2">
        <input
          readonly
          :value="newKeyValue"
          class="flex-1 font-mono text-xs bg-white dark:bg-brand-bg-dark border border-yellow-300 dark:border-yellow-700 rounded px-3 py-2 text-brand-text dark:text-brand-text-dark select-all"
          @click="$event.target.select()"
        />
        <button
          type="button"
          class="shrink-0 px-3 py-2 text-xs font-body font-medium bg-yellow-100 dark:bg-yellow-800/40 border border-yellow-300 dark:border-yellow-700 rounded hover:bg-yellow-200 dark:hover:bg-yellow-700/40 text-yellow-800 dark:text-yellow-300"
          @click="copyNewKey"
        >
          {{ copied ? 'Copied!' : 'Copy' }}
        </button>
        <button
          type="button"
          class="shrink-0 text-yellow-600 dark:text-yellow-500 hover:text-yellow-800 dark:hover:text-yellow-300 text-lg leading-none"
          aria-label="Dismiss"
          @click="newKeyValue = null; copied = false"
        >
          ×
        </button>
      </div>
    </div>

    <!-- Create new key form -->
    <form class="mb-6 flex items-end gap-3" @submit.prevent="onCreate">
      <div class="flex-1">
        <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
          Key name
        </label>
        <input
          v-model="newName"
          type="text"
          placeholder="e.g. My PC"
          maxlength="80"
          required
          class="w-full font-body text-[15px] bg-brand-bg dark:bg-brand-bg-dark border border-brand-border dark:border-brand-border-dark rounded px-3 py-2 text-brand-text dark:text-brand-text-dark placeholder:text-brand-muted dark:placeholder:text-brand-muted-dark focus:outline-none focus:border-brand-accent"
        />
      </div>
      <button
        type="submit"
        :disabled="creating"
        class="shrink-0 px-4 py-2 font-body font-semibold text-sm bg-brand-accent text-white rounded hover:opacity-90 disabled:opacity-50"
      >
        {{ creating ? 'Generating…' : 'Generate key' }}
      </button>
    </form>

    <p v-if="loadError" class="text-sm text-red-500 mb-4">{{ loadError }}</p>

    <p v-if="loading" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">Loading…</p>

    <div v-else-if="!keys.length" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">
      No API keys yet. Generate one above to get started.
    </div>

    <div v-else class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark overflow-x-auto">
      <table class="min-w-full text-sm">
        <thead>
          <tr class="text-left font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark border-b border-brand-border dark:border-brand-border-dark">
            <th class="px-4 py-2 font-medium">Name</th>
            <th class="px-4 py-2 font-medium whitespace-nowrap">Created</th>
            <th class="px-4 py-2 font-medium whitespace-nowrap">Last used</th>
            <th class="px-4 py-2 font-medium text-right">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-brand-border dark:divide-brand-border-dark">
          <tr
            v-for="key in keys"
            :key="key.id"
            class="hover:bg-brand-bg dark:hover:bg-brand-bg-dark/30"
          >
            <td class="px-4 py-2 font-body text-brand-text dark:text-brand-text-dark">{{ key.name }}</td>
            <td class="px-4 py-2 text-brand-muted dark:text-brand-muted-dark whitespace-nowrap">{{ formatDate(key.created_at) }}</td>
            <td class="px-4 py-2 text-brand-muted dark:text-brand-muted-dark whitespace-nowrap">
              {{ key.last_used_at ? formatDate(key.last_used_at) : 'Never' }}
            </td>
            <td class="px-4 py-2 text-right">
              <button
                v-if="confirmDeleteId !== key.id"
                type="button"
                class="text-xs text-red-500 hover:underline"
                @click="confirmDeleteId = key.id"
              >
                Delete
              </button>
              <span v-else class="inline-flex items-center gap-2">
                <span class="text-xs text-brand-muted dark:text-brand-muted-dark">Sure?</span>
                <button
                  type="button"
                  class="text-xs text-red-500 font-semibold hover:underline"
                  @click="onDelete(key.id)"
                >
                  Yes
                </button>
                <button
                  type="button"
                  class="text-xs text-brand-muted dark:text-brand-muted-dark hover:underline"
                  @click="confirmDeleteId = null"
                >
                  Cancel
                </button>
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import { getApiKeys, createApiKey, deleteApiKey } from '../services/apiKeyService.js'
import { pushToast } from '../stores/toastStore.js'

export default {
  name: 'ApiKeysPage',
  data() {
    return {
      keys: [],
      loading: true,
      loadError: null,
      newName: '',
      creating: false,
      newKeyValue: null,
      copied: false,
      confirmDeleteId: null
    }
  },
  async mounted() {
    await this.loadKeys()
  },
  methods: {
    async loadKeys() {
      this.loading = true
      this.loadError = null
      try {
        this.keys = await getApiKeys()
      } catch (err) {
        this.loadError = err.message || 'Failed to load API keys'
      } finally {
        this.loading = false
      }
    },
    async onCreate() {
      if (!this.newName.trim()) return
      this.creating = true
      this.newKeyValue = null
      this.copied = false
      try {
        const rawKey = await createApiKey(this.newName.trim())
        this.newKeyValue = rawKey
        this.newName = ''
        await this.loadKeys()
      } catch (err) {
        pushToast(err.message || 'Failed to create key', 'error')
      } finally {
        this.creating = false
      }
    },
    async onDelete(id) {
      this.confirmDeleteId = null
      try {
        await deleteApiKey(id)
        this.keys = this.keys.filter(k => k.id !== id)
        pushToast('API key deleted', 'success')
      } catch (err) {
        pushToast(err.message || 'Failed to delete key', 'error')
      }
    },
    async copyNewKey() {
      try {
        await navigator.clipboard.writeText(this.newKeyValue)
        this.copied = true
        setTimeout(() => { this.copied = false }, 2000)
      } catch {
        // fallback: the input is already selectable
      }
    },
    formatDate(iso) {
      return new Date(iso).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' })
    }
  }
}
</script>
