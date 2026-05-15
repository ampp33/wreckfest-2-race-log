<template>
  <div class="fixed top-4 right-4 z-50 space-y-2 pointer-events-none">
    <div
      v-for="t in toasts.items"
      :key="t.id"
      class="pointer-events-auto px-4 py-2 rounded shadow font-body text-sm text-white"
      :class="toastClass(t.type)"
      role="status"
    >
      {{ t.message }}
    </div>
  </div>
</template>

<script>
import { toastStore } from '../stores/toastStore.js'

export default {
  name: 'ToastContainer',
  data() {
    return { toasts: toastStore }
  },
  methods: {
    toastClass(type) {
      if (type === 'error') return 'bg-brand-accent'
      if (type === 'success') return 'bg-green-600'
      return 'bg-brand-secondary dark:bg-brand-secondary-dark'
    }
  }
}
</script>
