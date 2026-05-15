<template>
  <div
    v-if="ts.open"
    class="fixed inset-0 z-40 flex items-start sm:items-center justify-center bg-black/70 backdrop-blur-sm p-2 sm:p-4 overflow-hidden"
    @mousedown.self="onClose"
    @keydown.esc.stop="onClose"
  >
    <div
      class="bg-brand-bg dark:bg-brand-surface-dark rounded-lg shadow-xl w-full max-w-lg p-4 sm:p-6 max-h-[92svh] sm:max-h-[95vh] overflow-y-auto overscroll-contain border border-brand-border dark:border-brand-border-dark"
      role="dialog"
      aria-modal="true"
      aria-labelledby="track-search-title"
    >
      <div class="flex items-center justify-between mb-4">
        <h2 id="track-search-title" class="font-display font-black tracking-tighter leading-none text-display-sm text-brand-text dark:text-brand-text-dark">
          Go to <em class="signal">track</em>
        </h2>
        <button
          type="button"
          class="text-brand-muted dark:text-brand-muted-dark hover:text-brand-text dark:hover:text-brand-text-dark"
          aria-label="Close"
          @click="onClose"
        >
          ✕
        </button>
      </div>

      <p v-if="loadingTracks" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">Loading tracks…</p>
      <TrackVariationPicker v-else :tracks="tracks" @select="onTrackSelected" />
    </div>
  </div>
</template>

<script>
import TrackVariationPicker from './TrackVariationPicker.vue'
import { trackSearchStore, closeTrackSearch } from '../stores/trackSearchStore.js'
import { getTracks } from '../services/trackService.js'
import { pushToast } from '../stores/toastStore.js'

export default {
  name: 'TrackSearchModal',
  components: { TrackVariationPicker },
  data() {
    return {
      ts: trackSearchStore,
      tracks: [],
      loadingTracks: false
    }
  },
  watch: {
    'ts.open'(isOpen) {
      if (isOpen) {
        document.body.style.overflow = 'hidden'
        this.onOpened()
      } else {
        document.body.style.overflow = ''
      }
    }
  },
  unmounted() {
    document.body.style.overflow = ''
  },
  methods: {
    async onOpened() {
      if (this.tracks.length) return
      this.loadingTracks = true
      try {
        this.tracks = await getTracks()
      } catch (err) {
        pushToast(err.message || 'Failed to load tracks', 'error')
      } finally {
        this.loadingTracks = false
      }
    },
    onTrackSelected({ track, variation }) {
      closeTrackSearch()
      this.$router.push(`/track/${track.slug}/${variation.slug}`)
    },
    onClose() {
      closeTrackSearch()
    }
  }
}
</script>
