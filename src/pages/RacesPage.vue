<template>
  <div class="max-w-6xl mx-auto px-6 py-6 pb-24">
    <h1 class="font-display font-black tracking-tighter leading-none text-display-lg text-brand-text dark:text-brand-text-dark mb-1">
      Your <em class="signal">races</em>
    </h1>
    <p class="font-body text-[15px] leading-relaxed text-brand-secondary dark:text-brand-secondary-dark mb-6">All of your logged races, newest first.</p>

    <p v-if="loading" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">Loading…</p>
    <p v-else-if="error" class="text-sm text-red-500">{{ error }}</p>

    <div v-else>
      <!-- Controls row -->
      <div class="flex items-center justify-between mb-3 gap-4 flex-wrap">
        <div class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">
          {{ total }} race{{ total === 1 ? '' : 's' }}
        </div>
        <div class="flex items-center gap-2 text-sm font-body">
          <label class="text-brand-muted dark:text-brand-muted-dark">Per page</label>
          <select
            v-model="pageSize"
            class="border border-brand-border dark:border-brand-border-dark rounded px-2 py-1 bg-brand-bg dark:bg-brand-surface-dark text-sm"
            @change="currentPage = 1"
          >
            <option :value="25">25</option>
            <option :value="50">50</option>
            <option :value="100">100</option>
          </select>
        </div>
      </div>

      <p v-if="total === 0" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">No races logged yet.</p>

      <div v-else class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="text-left font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark border-b border-brand-border dark:border-brand-border-dark">
              <th class="px-4 py-2 font-medium">Date</th>
              <th class="px-4 py-2 font-medium">Track / Variation</th>
              <th class="px-4 py-2 font-medium">Vehicle</th>
              <th class="px-4 py-2 font-medium text-right">Place</th>
              <th class="px-4 py-2 font-medium text-right">Lap time</th>
              <th class="px-4 py-2 font-medium text-right">Total time</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-brand-border dark:divide-brand-border-dark">
            <tr
              v-for="race in pageRows"
              :key="race.id"
              class="hover:bg-brand-bg dark:hover:bg-brand-bg-dark/30"
            >
              <td class="px-4 py-2 whitespace-nowrap text-brand-muted dark:text-brand-muted-dark text-xs">
                {{ formatDate(race.datetime) }}
              </td>
              <td class="px-4 py-2">
                <router-link
                  v-if="race.trackSlug && race.variationSlug"
                  :to="`/track/${race.trackSlug}/${race.variationSlug}`"
                  class="text-brand-accent hover:underline"
                >
                  {{ race.trackName }}
                  <span class="text-brand-muted dark:text-brand-muted-dark font-normal">— {{ race.variationName }}</span>
                </router-link>
                <span v-else class="text-brand-muted dark:text-brand-muted-dark">—</span>
              </td>
              <td class="px-4 py-2 text-brand-secondary dark:text-brand-secondary-dark">
                {{ race.vehicleName }}
              </td>
              <td class="px-4 py-2 text-right tabular-nums">
                {{ race.place != null ? race.place : '—' }}
              </td>
              <td class="px-4 py-2 text-right font-mono tabular-nums">
                {{ race.lap_time_ms != null ? formatMs(race.lap_time_ms) : '—' }}
              </td>
              <td class="px-4 py-2 text-right font-mono tabular-nums text-brand-muted dark:text-brand-muted-dark">
                {{ race.total_time_ms != null ? formatMs(race.total_time_ms) : '—' }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Pagination -->
      <div v-if="totalPages > 1" class="flex items-center justify-center gap-6 mt-4 text-sm">
        <button
          :disabled="currentPage === 1"
          class="px-3 py-1 rounded border border-brand-border dark:border-brand-border-dark disabled:opacity-40 hover:bg-brand-surface dark:hover:bg-brand-surface-dark"
          @click="currentPage--"
        >
          ← Prev
        </button>
        <span class="text-brand-muted dark:text-brand-muted-dark">Page {{ currentPage }} of {{ totalPages }}</span>
        <button
          :disabled="currentPage === totalPages"
          class="px-3 py-1 rounded border border-brand-border dark:border-brand-border-dark disabled:opacity-40 hover:bg-brand-surface dark:hover:bg-brand-surface-dark"
          @click="currentPage++"
        >
          Next →
        </button>
      </div>
    </div>
  </div>
</template>

<script>
import { getAllRaces } from '../services/raceService.js'
import { getTracks } from '../services/trackService.js'
import { getVehicles } from '../services/vehicleService.js'
import { formatMsToTime } from '../utils/timeFormat.js'
import { pushToast } from '../stores/toastStore.js'

export default {
  name: 'RacesPage',
  data() {
    return {
      loading: true,
      error: null,
      rows: [],
      currentPage: 1,
      pageSize: 50
    }
  },
  computed: {
    total() {
      return this.rows.length
    },
    totalPages() {
      return Math.max(1, Math.ceil(this.total / this.pageSize))
    },
    pageRows() {
      const start = (this.currentPage - 1) * this.pageSize
      return this.rows.slice(start, start + this.pageSize)
    }
  },
  async mounted() {
    try {
      const [races, tracks, vehicles] = await Promise.all([
        getAllRaces(),
        getTracks(),
        getVehicles()
      ])

      const vehicleMap = Object.fromEntries(vehicles.map(v => [v.id, v.name]))

      const variationMap = {}
      for (const track of tracks) {
        for (const v of track.track_variations || []) {
          variationMap[v.id] = {
            trackName: track.name,
            trackSlug: track.slug,
            variationName: v.name,
            variationSlug: v.slug
          }
        }
      }

      this.rows = races.map(r => ({
        ...r,
        vehicleName: vehicleMap[r.vehicle_id] ?? '—',
        ...(variationMap[r.track_variation_id] ?? {
          trackName: '—',
          trackSlug: null,
          variationName: '—',
          variationSlug: null
        })
      }))
    } catch (err) {
      this.error = err.message || 'Failed to load races'
      pushToast(this.error, 'error')
    } finally {
      this.loading = false
    }
  },
  methods: {
    formatMs(ms) {
      return formatMsToTime(ms)
    },
    formatDate(iso) {
      return new Date(iso).toLocaleString(undefined, {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }
  }
}
</script>
