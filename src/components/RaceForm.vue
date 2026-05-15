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
        <select
          ref="vehicleInput"
          v-model="form.vehicleId"
          class="w-full h-10 rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-surface-dark px-3 py-2"
        >
          <option :value="null">— none —</option>
          <option v-for="v in vehicles" :key="v.id" :value="v.id">
            {{ v.name }}
          </option>
        </select>
      </div>

      <div>
        <label class="block font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark mb-1">
          Tuning
        </label>
        <input
          v-model.number="form.tuning"
          type="number"
          min="0"
          inputmode="numeric"
          class="w-full h-10 rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-surface-dark px-3 py-2"
        />
      </div>

      <div class="col-span-2 rounded bg-brand-surface dark:bg-brand-bg-dark px-3 py-1 space-y-1">
        <div v-for="(cfg, i) in tuningSliderConfig" :key="i">
          <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-text dark:text-brand-text-dark mb-0 mt-3">{{ cfg.label }}</div>
          <div class="relative flex items-center">
            <div class="absolute inset-x-0 h-px bg-brand-border dark:bg-brand-border-dark" />
            <div class="relative flex justify-between w-full">
              <div
                v-for="pos in 5"
                :key="pos"
                role="button"
                tabindex="0"
                class="group flex items-center justify-center w-14 h-14 cursor-pointer"
                @click="setSlider(i, pos)"
                @keydown.enter.prevent="setSlider(i, pos)"
                @keydown.space.prevent="setSlider(i, pos)"
              >
                <span
                  class="w-5 h-5 rounded-full border-2 transition-colors pointer-events-none"
                  :class="sliders[i] === pos
                    ? 'bg-brand-text border-brand-text dark:bg-brand-text-dark dark:border-brand-text-dark'
                    : 'bg-brand-border border-brand-border dark:bg-brand-surface-dark dark:border-brand-border-dark group-hover:border-brand-secondary group-hover:bg-brand-muted dark:group-hover:border-brand-muted-dark dark:group-hover:bg-brand-secondary-dark'"
                />
              </div>
            </div>
          </div>
          <div class="flex justify-between font-body text-[11px] text-brand-muted dark:text-brand-muted-dark mt-0 px-7">
            <span class="block -translate-x-1/2">{{ cfg.left }}</span>
            <span>{{ cfg.center }}</span>
            <span class="block translate-x-1/2">{{ cfg.right }}</span>
          </div>
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
          Lap time
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

const TUNING_SLIDER_CONFIG = [
  { label: 'Suspension',    left: 'SOFT',  center: 'STANDARD', right: 'STIFF'  },
  { label: 'Gear Ratio',    left: 'SHORT', center: 'STANDARD', right: 'LONG'   },
  { label: 'Differential',  left: 'OPEN',  center: 'LIMITED',  right: 'LOCKED' },
  { label: 'Brake Balance', left: 'REAR',  center: 'MIDDLE',   right: 'FRONT'  },
]

function parseSliders(tuning) {
  if (tuning == null) return [1, 1, 1, 1]
  const s = String(Math.round(tuning))
  if (s.length !== 4) return [1, 1, 1, 1]
  const digits = s.split('').map(d => parseInt(d))
  if (digits.some(n => n < 1 || n > 5)) return [1, 1, 1, 1]
  return digits
}

function slidersToTuning(sliders) {
  return sliders[0] * 1000 + sliders[1] * 100 + sliders[2] * 10 + sliders[3]
}

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
    tuning: null,
    place: '',
    lapTimeMs: null,
    totalTimeMs: null,
    notes: ''
  }
}

export default {
  name: 'RaceForm',
  components: { LapTimeInput },
  props: {
    vehicles: { type: Array, required: true },
    defaults: { type: Object, default: () => ({}) },
    lastRace: { type: Object, default: null },
    saving: { type: Boolean, default: false },
    autofocus: { type: Boolean, default: true }
  },
  emits: ['submit', 'cancel'],
  data() {
    return {
      form: { ...emptyForm(), ...this.defaults },
      errorMessage: '',
      sliders: parseSliders(this.defaults.tuning),
      tuningSliderConfig: TUNING_SLIDER_CONFIG
    }
  },
  watch: {
    'form.tuning'(val) {
      if (val !== slidersToTuning(this.sliders)) {
        const parsed = parseSliders(val)
        parsed.forEach((v, i) => this.sliders.splice(i, 1, v))
      }
    }
  },
  computed: {
    canDuplicateLast() {
      return Boolean(this.lastRace)
    }
  },
  mounted() {
    if (this.autofocus) {
      this.$nextTick(() => this.$refs.vehicleInput && this.$refs.vehicleInput.focus())
    }
    this.autoExpand()
  },
  methods: {
    setSlider(i, pos) {
      this.sliders.splice(i, 1, pos)
      this.form.tuning = slidersToTuning(this.sliders)
    },
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
      this.form.tuning = this.lastRace.tuning ?? null
      this.form.place = this.lastRace.place || ''
      this.form.lapTimeMs = this.lastRace.lap_time_ms || null
      this.form.totalTimeMs = this.lastRace.total_time_ms || null
      this.form.notes = this.lastRace.notes || ''
    },
    onSubmit() {
      this.errorMessage = ''
      const payload = {
        datetime: new Date(this.form.datetime).toISOString(),
        vehicle_id: this.form.vehicleId || null,
        tuning: this.form.tuning ?? null,
        place: this.form.place || null,
        lap_time_ms: this.form.lapTimeMs,
        total_time_ms: this.form.totalTimeMs,
        notes: this.form.notes || null
      }
      this.$emit('submit', payload)
    }
  }
}
</script>
