<template>
  <div class="max-w-6xl mx-auto px-6 py-6 pb-24">
    <p v-if="loading" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">Loading…</p>

    <div v-else-if="!track">
      <p class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">Track not found.</p>
      <router-link to="/" class="text-brand-accent text-sm hover:underline">← Back to tracks</router-link>
    </div>

    <div v-else>
      <!-- Hero banner -->
      <img
        v-if="track"
        :src="trackImage"
        :alt="track.name"
        class="w-full h-40 sm:h-56 object-cover rounded border border-brand-border dark:border-brand-border-dark mb-2 cursor-pointer hover:opacity-90 transition-opacity"
        @click="openImageModal"
      />

      <!-- Track header row -->
      <div class="flex flex-col sm:flex-row sm:items-start sm:justify-between gap-4 mb-4">
        <div class="min-w-0 flex-1">
          <h1 class="font-display font-black tracking-tighter leading-none text-display-lg text-brand-text dark:text-brand-text-dark">
            <em class="signal">{{ track.name }}</em>
          </h1>
          <!-- <p class="font-body text-[15px] text-brand-secondary dark:text-brand-secondary-dark mt-1">{{ currentVariation && currentVariation.name }}</p> -->
          <div class="flex flex-wrap gap-2 mt-3">
            <router-link
              v-for="v in track.track_variations"
              :key="v.id"
              :to="`/track/${track.slug}/${v.slug}`"
              class="flex items-center gap-2 pl-1 pr-3 py-1 text-xs rounded border"
              :class="v.id === currentVariation.id
                ? 'bg-brand-accent text-white border-brand-accent'
                : 'border-brand-border dark:border-brand-border-dark hover:border-brand-accent'"
            >
              <img
                :src="variationImageUrl(track.slug, v.slug)"
                alt=""
                aria-hidden="true"
                class="w-8 h-6 object-contain bg-black rounded"
                loading="lazy"
              />
              <span>{{ v.name }}</span>
            </router-link>
          </div>
        </div>

        <button
          type="button"
          class="w-full sm:w-auto sm:self-start font-display font-black uppercase tracking-widest bg-brand-accent text-white px-6 py-3 rounded-none hover:opacity-85 active:opacity-70 transition-opacity shrink-0"
          @click="onAddRow"
        >
          + Add Race
        </button>
      </div>

      <!-- Track Notes -->
      <div class="mb-4 bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-3">
        <div v-if="!notesEditMode" class="flex items-start gap-2">
          <div
            v-if="trackNotesHtml"
            class="flex-1 text-sm prose prose-sm dark:prose-invert max-w-none"
            v-html="trackNotesHtml"
          />
          <p
            v-else
            class="flex-1 font-body text-[15px] text-brand-muted dark:text-brand-muted-dark italic"
          >Add notes about this track…</p>
          <button
            type="button"
            class="text-brand-muted dark:text-brand-muted-dark hover:text-brand-accent shrink-0 mt-0.5"
            title="Edit notes"
            @click="startEditNotes"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
              <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"/>
            </svg>
          </button>
        </div>
        <div v-else class="flex flex-col gap-2">
          <textarea
            ref="notesTextarea"
            v-model="notesInput"
            rows="4"
            class="w-full text-sm rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-bg-dark text-brand-text dark:text-brand-text-dark px-2 py-1.5 resize-y focus:outline-none focus:ring-1 focus:ring-brand-accent"
            placeholder="Notes about this track…"
          />
          <div class="flex gap-2 justify-end">
            <button
              type="button"
              class="px-3 py-1 text-sm rounded border border-brand-border dark:border-brand-border-dark hover:border-brand-secondary dark:hover:border-brand-secondary-dark"
              @click="cancelEditNotes"
            >Cancel</button>
            <button
              type="button"
              class="font-display font-black uppercase tracking-widest bg-brand-accent text-white px-4 py-1 rounded-none hover:opacity-85 active:opacity-70 transition-opacity text-sm"
              @click="saveNotes"
            >Save</button>
          </div>
        </div>
      </div>

      <!-- Turn Annotations -->
      <VariationAnnotations
        v-if="currentVariation"
        :image-url="variationMapImage"
        :alt="currentVariation.name"
        :annotations="annotations"
        @save="onSaveAnnotations"
      />

      <div class="grid grid-cols-2 sm:grid-cols-3 gap-3 mb-6">
        <div class="col-span-2 sm:col-span-1 bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-3">
          <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark">Goal lap time</div>
          <div class="flex items-center gap-2 mt-1">
            <LapTimeInput v-model="goalInputMs" @blur="onSaveGoal" />
          </div>
        </div>
        <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-3">
          <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark">Personal best</div>
          <div class="font-display font-black tracking-tight text-2xl text-brand-text dark:text-brand-text-dark mt-1">{{ pbDisplay }}</div>
        </div>
        <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-3">
          <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark">Total races</div>
          <div class="font-display font-black tracking-tight text-2xl text-brand-text dark:text-brand-text-dark mt-1">{{ races.length }}</div>
        </div>
      </div>

      <LapTimeChart :races="races" :vehicles="vehicles" />

      <div class="overflow-x-auto bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark">
        <h2 class="font-display font-black tracking-tighter leading-none text-display-sm text-brand-text dark:text-brand-text-dark px-3 pt-3 pb-2">
          Logged <em class="signal">races</em>
        </h2>
        <table class="min-w-full text-sm">
          <thead class="bg-brand-bg dark:bg-brand-bg-dark text-left font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark">
            <tr>
              <th class="py-2 pl-3 pr-3">When</th>
              <th class="py-2 pr-3">Vehicle</th>
              <th class="py-2 pr-3 text-center">Tune</th>
              <th class="py-2 pr-3 text-center">Place</th>
              <th class="py-2 pr-3">Lap</th>
              <th class="py-2 pr-3">Δ goal</th>
              <th class="py-2 pr-3">Total</th>
              <th class="py-2 pr-3">Notes</th>
              <th class="py-2 pr-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            <RaceRow
              v-for="race in races"
              :key="race.id"
              :race="race"
              :vehicles="vehicles"
              :goal-lap-time-ms="goalLapTimeMs"
              :personal-best-ms="personalBestMs"
              @update="onUpdateRace"
              @delete="onDeleteRace"
            />
            <tr v-if="!races.length">
              <td colspan="9" class="py-6 text-center font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">
                No races yet — click <span class="font-semibold">+ Add Race</span> to log one.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>

  <!-- Hero image modal -->
  <Teleport to="body">
    <div
      v-if="showImageModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/70 backdrop-blur-sm"
      @click.self="closeImageModal"
    >
      <div class="relative max-w-4xl w-full mx-4">
        <button
          type="button"
          class="absolute -top-8 right-0 text-white/80 hover:text-white"
          aria-label="Close"
          @click="closeImageModal"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="w-6 h-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
        <img
          :src="trackImage"
          :alt="track && track.name"
          class="w-full max-h-[85vh] object-contain rounded"
        />
      </div>
    </div>
  </Teleport>
</template>

<script>
import RaceRow from '../components/RaceRow.vue'
import LapTimeChart from '../components/LapTimeChart.vue'
import VariationAnnotations from '../components/VariationAnnotations.vue'
import { getTrackBySlug, findVariation } from '../services/trackService.js'
import { getVehicles } from '../services/vehicleService.js'
import { getRacesByVariation, updateRace, deleteRace } from '../services/raceService.js'
import { getGoalForVariation, upsertGoal } from '../services/goalService.js'
import { getAnnotationsForVariation, saveAnnotations } from '../services/annotationService.js'
import { marked } from 'marked'
import DOMPurify from 'dompurify'
import { authStore } from '../stores/authStore.js'
import { pushToast } from '../stores/toastStore.js'
import { quickAddStore, setOnRaceSaved, clearOnRaceSaved, openQuickAdd } from '../stores/quickAddStore.js'
import { formatMsToTime } from '../utils/timeFormat.js'
import LapTimeInput from '../components/LapTimeInput.vue'
import { trackImageUrl, variationImageUrl } from '../utils/imageUrl.js'

export default {
  name: 'TrackDetailPage',
  components: { RaceRow, LapTimeChart, LapTimeInput, VariationAnnotations },
  data() {
    return {
      loading: true,
      track: null,
      currentVariation: null,
      vehicles: [],
      races: [],
      goal: null,
      goalInputMs: null,
      annotations: [],
      quickAddStore,
      showImageModal: false,
      notesEditMode: false,
      notesInput: ''
    }
  },
  computed: {
    trackImage() {
      return this.track ? trackImageUrl(this.track.slug) : ''
    },
    goalLapTimeMs() {
      return this.goal ? this.goal.goal_lap_time_ms : null
    },
    personalBestMs() {
      const valid = this.races
        .map(r => r.lap_time_ms)
        .filter(v => v != null)
      if (!valid.length) return null
      return Math.min(...valid)
    },
    pbDisplay() {
      return this.personalBestMs != null ? formatMsToTime(this.personalBestMs) : '—'
    },
    trackNotes() {
      return this.goal ? (this.goal.notes || '') : ''
    },
    trackNotesHtml() {
      if (!this.trackNotes) return ''
      return DOMPurify.sanitize(marked.parse(this.trackNotes))
    },
    variationMapImage() {
      return this.track && this.currentVariation
        ? variationImageUrl(this.track.slug, this.currentVariation.slug)
        : ''
    }
  },
  watch: {
    '$route.params': {
      handler() {
        this.loadAll()
      },
      immediate: false
    },
    'quickAddStore.open'(isOpen) {
      if (!isOpen && this._quickAddOpenedHere) {
        this._quickAddOpenedHere = false
        this.loadRaces()
      }
    }
  },
  async mounted() {
    setOnRaceSaved((variationId) => {
      if (variationId === this.currentVariation?.id) this.loadRaces()
    })
    await this.loadAll()
    this._escHandler = (e) => { if (e.key === 'Escape') this.closeImageModal() }
    document.addEventListener('keydown', this._escHandler)
  },
  beforeUnmount() {
    document.removeEventListener('keydown', this._escHandler)
  },
  unmounted() {
    quickAddStore.currentPageVariationId = null
    clearOnRaceSaved()
  },
  methods: {
    variationImageUrl,
    async loadAll() {
      this.loading = true
      const slug = this.$route.params.trackSlug
      const variationSlug = this.$route.params.variationSlug
      try {
        const [track, vehicles] = await Promise.all([
          getTrackBySlug(slug),
          getVehicles()
        ])
        this.track = track
        this.vehicles = vehicles
        this.currentVariation = findVariation(track, variationSlug)
        if (!this.currentVariation) {
          pushToast('Variation not found', 'error')
          return
        }
        quickAddStore.currentPageVariationId = this.currentVariation.id
        await Promise.all([this.loadRaces(), this.loadGoal(), this.loadAnnotations()])
      } catch (err) {
        pushToast(err.message || 'Failed to load track', 'error')
      } finally {
        this.loading = false
      }
    },
    async loadRaces() {
      this.races = await getRacesByVariation(this.currentVariation.id)
    },
    async loadGoal() {
      this.goal = await getGoalForVariation(this.currentVariation.id)
      this.goalInputMs = this.goal ? this.goal.goal_lap_time_ms : null
    },
    async loadAnnotations() {
      this.annotations = await getAnnotationsForVariation(this.currentVariation.id)
    },
    openImageModal() {
      this.showImageModal = true
    },
    closeImageModal() {
      this.showImageModal = false
    },
    startEditNotes() {
      this.notesInput = this.trackNotes
      this.notesEditMode = true
      this.$nextTick(() => this.$refs.notesTextarea?.focus())
    },
    cancelEditNotes() {
      this.notesEditMode = false
    },
    async saveNotes() {
      try {
        const userId = authStore.user && authStore.user.id
        this.goal = await upsertGoal({
          variationId: this.currentVariation.id,
          goalLapTimeMs: this.goalLapTimeMs,
          notes: this.notesInput,
          userId
        })
        this.notesEditMode = false
        pushToast('Notes saved', 'success', 1500)
      } catch (err) {
        pushToast(err.message || 'Failed to save notes', 'error')
      }
    },
    async onSaveAnnotations(annotations) {
      try {
        const userId = authStore.user && authStore.user.id
        this.annotations = await saveAnnotations({
          variationId: this.currentVariation.id,
          annotations,
          userId
        })
        pushToast('Annotations saved', 'success', 1500)
      } catch (err) {
        pushToast(err.message || 'Failed to save annotations', 'error')
      }
    },
    onAddRow() {
      this._quickAddOpenedHere = true
      openQuickAdd(this.currentVariation.id)
    },
    async onUpdateRace({ id, patch }) {
      try {
        const updated = await updateRace(id, patch)
        const idx = this.races.findIndex(r => r.id === id)
        if (idx !== -1) this.races.splice(idx, 1, updated)
        pushToast('Race updated', 'success', 1500)
      } catch (err) {
        pushToast(err.message || 'Failed to update race', 'error')
      }
    },
    async onDeleteRace(id) {
      try {
        await deleteRace(id)
        this.races = this.races.filter(r => r.id !== id)
        pushToast('Race deleted', 'success', 1500)
      } catch (err) {
        pushToast(err.message || 'Failed to delete race', 'error')
      }
    },
    async onSaveGoal() {
      const ms = this.goalInputMs
      if (!ms) return
      if (this.goal && this.goal.goal_lap_time_ms === ms) return
      try {
        const userId = authStore.user && authStore.user.id
        this.goal = await upsertGoal({
          variationId: this.currentVariation.id,
          goalLapTimeMs: ms,
          notes: this.trackNotes,
          userId
        })
        pushToast('Goal saved', 'success', 1500)
      } catch (err) {
        pushToast(err.message || 'Failed to save goal', 'error')
      }
    }
  }
}
</script>
