<template>
  <tr class="border-b border-brand-border dark:border-brand-border-dark">
    <template v-if="!editing">
      <td class="py-2 pl-3 pr-3 whitespace-nowrap text-brand-muted dark:text-brand-muted-dark">
        {{ formattedDate }}
      </td>
      <td class="py-2 pr-3 text-brand-secondary dark:text-brand-secondary-dark">{{ vehicleName }}</td>
      <td class="py-2 pr-3 text-center text-brand-secondary dark:text-brand-secondary-dark">{{ race.tuning ?? '—' }}</td>
      <td class="py-2 pr-3 text-center text-brand-secondary dark:text-brand-secondary-dark">{{ race.place || '—' }}</td>
      <td class="py-2 pr-3 font-mono text-brand-text dark:text-brand-text-dark">{{ formatLap }}</td>
      <td class="py-2 pr-3 font-mono" :class="deltaColor">{{ deltaLabel }}</td>
      <td class="py-2 pr-3 font-mono text-brand-secondary dark:text-brand-secondary-dark">{{ formatTotal }}</td>
      <td class="py-2 pr-3 text-brand-muted dark:text-brand-muted-dark truncate max-w-[18ch]" :title="race.notes || ''">
        {{ race.notes || '' }}
      </td>
      <td class="py-2 pr-3 text-right whitespace-nowrap">
        <div class="inline-flex items-center gap-1">
          <button
            class="p-1 rounded text-brand-muted dark:text-brand-muted-dark hover:text-brand-accent hover:bg-brand-surface dark:hover:bg-brand-surface-dark"
            title="Edit"
            @click="editing = true"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z" />
            </svg>
          </button>
          <button
            class="p-1 rounded text-brand-muted dark:text-brand-muted-dark hover:text-red-600 hover:bg-brand-surface dark:hover:bg-brand-surface-dark"
            title="Delete"
            @click="onDelete"
          >
            <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M9 2a1 1 0 00-.894.553L7.382 4H4a1 1 0 000 2v10a2 2 0 002 2h8a2 2 0 002-2V6a1 1 0 100-2h-3.382l-.724-1.447A1 1 0 0011 2H9zM7 8a1 1 0 012 0v6a1 1 0 11-2 0V8zm5-1a1 1 0 00-1 1v6a1 1 0 102 0V8a1 1 0 00-1-1z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
      </td>
    </template>

    <td v-else colspan="9" class="p-5 bg-brand-surface dark:bg-brand-surface-dark">
      <RaceForm
        :vehicles="vehicles"
        :defaults="editDefaults"
        :saving="saving"
        :autofocus="false"
        @submit="onSave"
        @cancel="editing = false"
      />
    </td>
  </tr>
</template>

<script>
import RaceForm from './RaceForm.vue'
import { formatMsToTime, formatDelta } from '../utils/timeFormat.js'

function toLocalIsoMinute(isoString) {
  const d = new Date(isoString)
  const tzOffset = d.getTimezoneOffset() * 60_000
  return new Date(d.getTime() - tzOffset).toISOString().slice(0, 16)
}

export default {
  name: 'RaceRow',
  components: { RaceForm },
  props: {
    race: { type: Object, required: true },
    vehicles: { type: Array, required: true },
    goalLapTimeMs: { type: Number, default: null },
    personalBestMs: { type: Number, default: null }
  },
  emits: ['update', 'delete'],
  data() {
    return {
      editing: false,
      saving: false
    }
  },
  computed: {
    vehicleName() {
      const v = this.vehicles.find(x => x.id === this.race.vehicle_id)
      return v ? v.name : '—'
    },
    formattedDate() {
      const d = new Date(this.race.datetime)
      return d.toLocaleString(undefined, {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    },
    formatLap() {
      if (this.race.lap_time_ms == null) return '—'
      const isPb = this.personalBestMs != null && this.race.lap_time_ms === this.personalBestMs
      return isPb ? `★ ${formatMsToTime(this.race.lap_time_ms)}` : formatMsToTime(this.race.lap_time_ms)
    },
    formatTotal() {
      return this.race.total_time_ms != null
        ? formatMsToTime(this.race.total_time_ms)
        : '—'
    },
    deltaLabel() {
      if (this.race.lap_time_ms == null || this.goalLapTimeMs == null) return ''
      return formatDelta(this.race.lap_time_ms - this.goalLapTimeMs)
    },
    deltaColor() {
      if (!this.deltaLabel) return ''
      const diff = this.race.lap_time_ms - this.goalLapTimeMs
      if (diff < 0) return 'text-green-600'
      if (diff > 0) return 'text-red-500'
      return 'text-brand-muted dark:text-brand-muted-dark'
    },
    editDefaults() {
      return {
        datetime: toLocalIsoMinute(this.race.datetime),
        vehicleId: this.race.vehicle_id,
        tuning: this.race.tuning,
        place: this.race.place || '',
        lapTime: this.race.lap_time_ms != null ? formatMsToTime(this.race.lap_time_ms) : '',
        totalTime: this.race.total_time_ms != null ? formatMsToTime(this.race.total_time_ms) : '',
        notes: this.race.notes || ''
      }
    }
  },
  methods: {
    async onSave(payload) {
      this.saving = true
      try {
        await this.$emit('update', { id: this.race.id, patch: payload })
        this.editing = false
      } finally {
        this.saving = false
      }
    },
    onDelete() {
      if (!window.confirm('Delete this race?')) return
      this.$emit('delete', this.race.id)
    }
  }
}
</script>
