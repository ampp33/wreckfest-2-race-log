<template>
  <div class="max-w-4xl mx-auto px-6 py-6 pb-24">
    <h1 class="font-display font-black tracking-tighter leading-none text-display-lg text-brand-text dark:text-brand-text-dark mb-1">
      Your <em class="signal">stats</em>
    </h1>
    <p class="font-body text-[15px] leading-relaxed text-brand-secondary dark:text-brand-secondary-dark mb-6">
      Aggregated from all of your saved races.
    </p>

    <p v-if="loading" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">Loading…</p>

    <div v-else class="space-y-6">
      <div class="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4">
          <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark">Most used vehicle</div>
          <div class="mt-1 font-display font-black tracking-tight text-2xl text-brand-text dark:text-brand-text-dark">
            {{ stats.mostUsedVehicle ? stats.mostUsedVehicle.name : '—' }}
          </div>
          <div v-if="stats.mostUsedVehicle" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">
            {{ stats.mostUsedVehicle.count }} races
          </div>
        </div>

        <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4">
          <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark">Most raced variation</div>
          <router-link
            v-if="stats.mostRacedVariation"
            :to="`/track/${stats.mostRacedVariation.trackSlug}/${stats.mostRacedVariation.variationSlug}`"
            class="block mt-1 font-display font-black tracking-tight text-2xl text-brand-accent hover:underline"
          >
            {{ stats.mostRacedVariation.trackName }}
            <span class="font-body font-normal text-base text-brand-muted dark:text-brand-muted-dark">
              — {{ stats.mostRacedVariation.variationName }}
            </span>
          </router-link>
          <div v-else class="mt-1 font-display font-black tracking-tight text-2xl text-brand-text dark:text-brand-text-dark">—</div>
          <div v-if="stats.mostRacedVariation" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">
            {{ stats.mostRacedVariation.count }} races
          </div>
        </div>

        <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4">
          <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark">Total races</div>
          <div class="mt-1 font-display font-black tracking-tight text-2xl text-brand-text dark:text-brand-text-dark">{{ stats.totalRaces }}</div>
        </div>
      </div>

      <RaceActivityChart
        :hourly-counts="stats.raceCounts.hourlyCounts"
        :daily-counts="stats.raceCounts.dailyCounts"
      />

      <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4">
        <h2 class="font-display font-black tracking-tighter leading-none text-display-sm text-brand-text dark:text-brand-text-dark mb-3">
          Goal <em class="signal">progress</em>
        </h2>
        <p v-if="!stats.goalProgress.length" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">
          No goals set — open a track and set a goal lap time to track your progress here.
        </p>
        <ul v-else class="divide-y divide-brand-border dark:divide-brand-border-dark">
          <li
            v-for="row in stats.goalProgress"
            :key="row.trackSlug + row.variationSlug"
            class="flex items-center justify-between py-2.5 text-sm"
          >
            <router-link
              :to="`/track/${row.trackSlug}/${row.variationSlug}`"
              class="text-brand-accent hover:underline font-body"
            >
              {{ row.trackName }}
              <span class="text-brand-muted dark:text-brand-muted-dark font-normal">— {{ row.variationName }}</span>
            </router-link>
            <div class="flex items-center gap-4 shrink-0 ml-4">
              <div class="text-right">
                <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark leading-none mb-0.5">goal</div>
                <div class="font-mono text-sm">{{ format(row.goalMs) }}</div>
              </div>
              <div class="text-right">
                <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark leading-none mb-0.5">best</div>
                <div class="font-mono text-sm">{{ row.pbMs != null ? format(row.pbMs) : '—' }}</div>
              </div>
              <div class="text-right min-w-[3.5rem]">
                <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark leading-none mb-0.5">delta</div>
                <div
                  v-if="row.deltaMs != null"
                  class="font-mono text-sm font-semibold"
                  :class="row.deltaMs <= 0 ? 'text-green-600' : 'text-red-500'"
                >
                  {{ row.deltaMs <= 0 ? '-' : '+' }}{{ format(Math.abs(row.deltaMs)) }}
                </div>
                <div v-else class="font-mono text-sm text-brand-muted dark:text-brand-muted-dark">—</div>
              </div>
            </div>
          </li>
        </ul>
      </div>

      <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4">
        <h2 class="font-display font-black tracking-tighter leading-none text-display-sm text-brand-text dark:text-brand-text-dark mb-3">
          Biggest <em class="signal">improvements</em> (oldest → newest lap)
        </h2>
        <p v-if="!stats.biggestImprovements.length" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">
          No improvement data yet — log more laps on the same variation.
        </p>
        <ul v-else class="space-y-2 text-sm">
          <li
            v-for="row in stats.biggestImprovements"
            :key="row.variationSlug + row.trackSlug"
            class="flex items-center justify-between"
          >
            <router-link
              :to="`/track/${row.trackSlug}/${row.variationSlug}`"
              class="text-brand-accent hover:underline font-body"
            >
              {{ row.trackName }} — {{ row.variationName }}
            </router-link>
            <span class="font-mono text-green-600">
              -{{ format(row.deltaMs) }}
            </span>
          </li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script>
import { getStats } from '../services/statsService.js'
import { formatMsToTime } from '../utils/timeFormat.js'
import { pushToast } from '../stores/toastStore.js'
import RaceActivityChart from '../components/RaceActivityChart.vue'

export default {
  name: 'StatsPage',
  components: { RaceActivityChart },
  data() {
    return {
      loading: true,
      stats: {
        mostUsedVehicle: null,
        mostRacedVariation: null,
        biggestImprovements: [],
        totalRaces: 0,
        goalProgress: [],
        raceCounts: { hourlyCounts: new Array(24).fill(0), dailyCounts: {} },
        recentRaces: []
      }
    }
  },
  async mounted() {
    try {
      this.stats = await getStats()
    } catch (err) {
      pushToast(err.message || 'Failed to load stats', 'error')
    } finally {
      this.loading = false
    }
  },
  methods: {
    format(ms) {
      return formatMsToTime(ms)
    },
    formatDate(isoString) {
      const d = new Date(isoString)
      return d.toLocaleString(undefined, {
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      })
    }
  }
}
</script>
