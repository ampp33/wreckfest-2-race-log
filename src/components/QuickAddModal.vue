<template>
  <div
    v-if="qa.open"
    class="fixed inset-0 z-40 flex items-start sm:items-center justify-center bg-black/70 backdrop-blur-sm p-2 sm:p-4 overflow-hidden"
    @mousedown.self="onClose"
    @keydown.esc.stop="onClose"
  >
    <div
      class="bg-brand-bg dark:bg-brand-surface-dark rounded-lg shadow-xl w-full max-w-lg p-4 sm:p-6 max-h-[92svh] sm:max-h-[95vh] overflow-y-auto overscroll-contain border border-brand-border dark:border-brand-border-dark"
      role="dialog"
      aria-modal="true"
      aria-labelledby="quick-add-title"
    >
      <div class="flex items-center justify-between mb-4">
        <h2 id="quick-add-title" class="font-display font-black tracking-tighter leading-none text-display-sm text-brand-text dark:text-brand-text-dark">
          Quick add <em class="signal">race</em>
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

      <div v-else-if="!chosen">
        <TrackVariationPicker :tracks="tracks" @select="onTrackSelected" />
      </div>

      <div v-else>
        <div class="mb-4 flex items-center justify-between gap-3 text-sm">
          <div class="flex items-center gap-3 min-w-0">
            <img
              :src="variationImageUrl(chosen.track.slug, chosen.variation.slug)"
              :alt="chosen.variation.name"
              class="w-16 h-12 object-contain bg-black rounded shrink-0"
              loading="lazy"
            />
            <div class="min-w-0">
              <div class="font-semibold truncate text-brand-text dark:text-brand-text-dark">{{ chosen.track.name }}</div>
              <div class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark truncate">{{ chosen.variation.name }}</div>
            </div>
          </div>
          <button
            type="button"
            class="text-xs text-brand-accent hover:underline shrink-0"
            @click="resetChoice"
          >
            Change track
          </button>
        </div>

        <RaceForm
          :vehicles="vehicles"
          :defaults="formDefaults"
          :last-race="lastRace"
          :saving="saving"
          @submit="onSaveRace"
          @cancel="onClose"
        />
      </div>
    </div>
  </div>
</template>

<script>
import TrackVariationPicker from './TrackVariationPicker.vue'
import RaceForm from './RaceForm.vue'
import { variationImageUrl } from '../utils/imageUrl.js'
import { quickAddStore, closeQuickAdd, notifyRaceSaved } from '../stores/quickAddStore.js'
import { prefsStore } from '../stores/prefsStore.js'
import { authStore } from '../stores/authStore.js'
import { getTracks } from '../services/trackService.js'
import { getVehicles } from '../services/vehicleService.js'
import { createRace, getRacesByVariation } from '../services/raceService.js'
import { pushToast } from '../stores/toastStore.js'

export default {
  name: 'QuickAddModal',
  components: { TrackVariationPicker, RaceForm },
  data() {
    return {
      qa: quickAddStore,
      tracks: [],
      vehicles: [],
      loadingTracks: false,
      saving: false,
      chosen: null,
      lastRace: null
    }
  },
  computed: {
    formDefaults() {
      return {
        vehicleId: prefsStore.lastVehicleId,
        tuning: prefsStore.lastTuning
      }
    }
  },
  watch: {
    'qa.open'(isOpen) {
      if (isOpen) {
        document.body.style.overflow = 'hidden'
        this.onOpened()
      } else {
        document.body.style.overflow = ''
        this.resetState()
      }
    }
  },
  unmounted() {
    document.body.style.overflow = ''
  },
  methods: {
    variationImageUrl,
    async onOpened() {
      this.loadingTracks = true
      try {
        const [tracks, vehicles] = await Promise.all([getTracks(), getVehicles()])
        this.tracks = tracks
        this.vehicles = vehicles
        if (this.qa.prefillVariationId) {
          this.preselectVariation(this.qa.prefillVariationId)
        }
      } catch (err) {
        pushToast(err.message || 'Failed to load tracks', 'error')
      } finally {
        this.loadingTracks = false
      }
    },
    preselectVariation(variationId) {
      for (const track of this.tracks) {
        const variation = (track.track_variations || []).find(v => v.id === variationId)
        if (variation) {
          this.onTrackSelected({ track, variation })
          return
        }
      }
    },
    async onTrackSelected({ track, variation }) {
      this.chosen = { track, variation }
      try {
        const races = await getRacesByVariation(variation.id)
        this.lastRace = races[0] || null
      } catch {
        this.lastRace = null
      }
    },
    resetChoice() {
      this.chosen = null
      this.lastRace = null
    },
    resetState() {
      this.chosen = null
      this.lastRace = null
      this.saving = false
    },
    async onSaveRace(racePayload) {
      if (!this.chosen) return
      const userId = authStore.user && authStore.user.id
      if (!userId) {
        pushToast('Not signed in', 'error')
        return
      }

      this.saving = true
      try {
        const created = await createRace(
          { ...racePayload, track_variation_id: this.chosen.variation.id },
          userId
        )
        prefsStore.lastVehicleId = created.vehicle_id
        prefsStore.lastTuning = created.tuning
        prefsStore.lastTrackVariationId = created.track_variation_id
        pushToast('Race saved', 'success', 2000)
        notifyRaceSaved(this.chosen.variation.id)
        closeQuickAdd()
      } catch (err) {
        pushToast(err.message || 'Failed to save race', 'error')
      } finally {
        this.saving = false
      }
    },
    onClose() {
      closeQuickAdd()
    }
  }
}
</script>
