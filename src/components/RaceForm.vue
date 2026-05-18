<template>
  <form @submit.prevent="onSubmit" @keydown="onFormKeydown">
    <div class="grid grid-cols-2 gap-3">
      <div class="col-span-2 min-w-0 overflow-hidden">
        <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
          Date / time
        </label>
        <input
          ref="datetimeInput"
          v-model="form.datetime"
          type="datetime-local"
          class="w-full min-w-0 max-w-full rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-surface-dark px-3 py-2"
        />
      </div>

      <div>
        <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
          Vehicle
        </label>
        <div class="relative">
          <select
            ref="vehicleInput"
            v-model="form.vehicleId"
            class="w-full h-10 appearance-none rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-surface-dark pl-3 pr-8 py-2"
          >
            <option :value="null">— none —</option>
            <option v-for="v in vehicles" :key="v.id" :value="v.id">
              {{ v.name }}
            </option>
          </select>
          <div class="pointer-events-none absolute inset-y-0 right-0 flex items-center px-2 text-brand-muted dark:text-brand-muted-dark">
            <svg class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"/>
            </svg>
          </div>
        </div>
      </div>

      <div>
        <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
          Performance Index (PI)
        </label>
        <div class="flex gap-2">
          <div
            class="w-10 h-10 shrink-0 flex items-center justify-center rounded font-display font-black text-white text-base"
            :style="{ backgroundColor: piColor }"
          >{{ piClass }}</div>
          <input
            :value="form.performanceIndex"
            type="text"
            inputmode="numeric"
            class="w-full rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-surface-dark px-3 py-2"
            placeholder="0"
            @input="form.performanceIndex = $event.target.value.replace(/[^0-9]/g, '')"
          />
        </div>
      </div>

      <div>
        <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
          Place
        </label>
        <input
          :value="form.place"
          type="text"
          inputmode="numeric"
          class="w-full rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-surface-dark px-3 py-2"
          placeholder="1"
          @input="form.place = $event.target.value.replace(/[^0-9]/g, '')"
        />
      </div>

      <div>
        <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
          Lap time<template v-if="goalLapTimeMs"> (🎯 {{ formatMsToTime(goalLapTimeMs) }})</template>
        </label>
        <LapTimeInput v-model="form.lapTimeMs" />
      </div>

      <div class="col-span-2">
        <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
          Total time (optional)
        </label>
        <LapTimeInput v-model="form.totalTimeMs" />
      </div>

      <div class="col-span-2">
        <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
          Notes (Ctrl+Enter to save)
        </label>
        <textarea
          ref="notesInput"
          v-model="form.notes"
          rows="2"
          class="w-full rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-surface-dark px-3 py-2 resize-none"
          @input="autoExpand"
        />
      </div>

    </div>

    <p v-if="errorMessage" class="mt-3 text-sm text-red-600">{{ errorMessage }}</p>

    <div class="mt-4 flex items-center justify-between gap-3">
      <button
        type="button"
        class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark hover:text-brand-text dark:hover:text-brand-text-dark"
        @click="$emit('cancel')"
      >
        Cancel (Esc)
      </button>
      <div class="flex items-center gap-2">
        <button
          type="submit"
          :disabled="saving"
          class="font-display font-black uppercase tracking-widest bg-brand-accent text-white px-6 py-3 rounded-none hover:opacity-85 active:opacity-70 transition-opacity disabled:opacity-60"
        >
          {{ saving ? 'Saving...' : 'Save (Enter)' }}
        </button>
      </div>
    </div>
  </form>
</template>

<script>
import LapTimeInput from './LapTimeInput.vue'
import { formatMsToTime } from '../utils/timeFormat.js'
import { piInfo } from '../utils/piInfo.js'

function nowLocalIsoMinute() {
  const d = new Date()
  d.setSeconds(0, 0)
  const tzOffset = d.getTimezoneOffset() * 60_000
  return new Date(d.getTime() - tzOffset).toISOString().slice(0, 16)
}

function emptyForm() {
  return {
    datetime: nowLocalIsoMinute(),
    vehicleId: null,
    place: '',
    lapTimeMs: null,
    totalTimeMs: null,
    performanceIndex: '0',
    notes: ''
  }
}

export default {
  name: 'RaceForm',
  components: { LapTimeInput },
  props: {
    vehicles: { type: Array, required: true },
    vehiclePiMap: { type: Object, default: () => ({}) },
    defaults: { type: Object, default: () => ({}) },
    lastRace: { type: Object, default: null },
    goalLapTimeMs: { type: Number, default: null },
    saving: { type: Boolean, default: false },
    autofocus: { type: Boolean, default: true }
  },
  emits: ['submit', 'cancel'],
  data() {
    return {
      form: { ...emptyForm(), ...this.defaults },
      errorMessage: ''
    }
  },
  computed: {
    canDuplicateLast() {
      return Boolean(this.lastRace)
    },
    piClass() {
      return piInfo(this.form.performanceIndex).cls
    },
    piColor() {
      return piInfo(this.form.performanceIndex).color
    }
  },
  watch: {
    'form.vehicleId': {
      handler(vehicleId) {
        if (!vehicleId) return
        const pi = this.vehiclePiMap[vehicleId]
        if (pi != null) this.form.performanceIndex = String(pi)
      },
      immediate: true
    }
  },
  mounted() {
    if (this.autofocus) {
      this.$nextTick(() => this.$refs.vehicleInput && this.$refs.vehicleInput.focus())
    }
    this.autoExpand()
  },
  methods: {
    formatMsToTime,
    onFormKeydown(event) {
      if (event.key === 'Escape') {
        event.preventDefault()
        this.$emit('cancel')
        return
      }
      // Enter submits form unless we're inside the textarea (use Ctrl+Enter
      // there). This matches the spec's "fast input" rule.
      if (event.key === 'Enter') {
        const inTextarea = event.target && event.target.tagName === 'TEXTAREA'
        if (inTextarea && !event.ctrlKey && !event.metaKey) return
        event.preventDefault()
        this.onSubmit()
      }
    },
    autoExpand() {
      const el = this.$refs.notesInput
      if (!el) return
      el.style.height = 'auto'
      el.style.height = `${Math.min(el.scrollHeight, 200)}px`
    },
    onDuplicateLast() {
      if (!this.lastRace) return
      this.form.vehicleId = this.lastRace.vehicle_id || null
      this.form.place = this.lastRace.place || ''
      this.form.lapTimeMs = this.lastRace.lap_time_ms || null
      this.form.totalTimeMs = this.lastRace.total_time_ms || null
      this.form.performanceIndex = this.lastRace.performance_index != null ? String(this.lastRace.performance_index) : '0'
      this.form.notes = this.lastRace.notes || ''
    },
    onSubmit() {
      this.errorMessage = ''
      const pi = parseInt(this.form.performanceIndex, 10)
      const payload = {
        datetime: new Date(this.form.datetime).toISOString(),
        vehicle_id: this.form.vehicleId || null,
        place: this.form.place || null,
        lap_time_ms: this.form.lapTimeMs,
        total_time_ms: this.form.totalTimeMs,
        performance_index: isNaN(pi) ? null : pi,
        notes: this.form.notes || null
      }
      this.$emit('submit', payload)
    }
  }
}
</script>
