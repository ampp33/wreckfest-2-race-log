<template>
  <div
    v-if="hasData"
    class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4 mb-6"
  >
    <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-text dark:text-brand-text-dark mb-2">
      Lap Times Over Time
    </div>
    <div class="relative h-64">
      <canvas ref="canvas"></canvas>
    </div>
  </div>
</template>

<script>
import {
  Chart,
  LineController,
  LineElement,
  PointElement,
  LinearScale,
  CategoryScale,
  Tooltip,
  Legend,
  Filler
} from 'chart.js'
import { markRaw } from 'vue'
import { prefsStore } from '../stores/prefsStore.js'

Chart.register(LineController, LineElement, PointElement, LinearScale, CategoryScale, Tooltip, Legend, Filler)

const PALETTE = [
  '#C41E1E', // brand accent
  '#3b82f6', // blue
  '#22c55e', // green
  '#f59e0b', // amber
  '#8b5cf6', // violet
  '#ec4899', // pink
  '#14b8a6', // teal
  '#f97316', // orange
]

function formatMs(ms) {
  if (ms == null) return ''
  const totalSec = ms / 1000
  const minutes = Math.floor(totalSec / 60)
  const secs = (totalSec % 60).toFixed(3).padStart(6, '0')
  return minutes > 0 ? `${minutes}:${secs}` : secs
}

export default {
  name: 'LapTimeChart',
  props: {
    races: { type: Array, default: () => [] },
    vehicles: { type: Array, default: () => [] }
  },
  data() {
    return { chart: null }
  },
  computed: {
    isDark() {
      return prefsStore.darkMode
    },
    chartData() {
      const byVehicle = {}
      for (const race of this.races) {
        if (!race.lap_time_ms || !race.vehicle_id) continue
        const day = race.datetime.substring(0, 10)
        if (!byVehicle[race.vehicle_id]) byVehicle[race.vehicle_id] = {}
        const cur = byVehicle[race.vehicle_id][day]
        if (cur == null || race.lap_time_ms < cur) {
          byVehicle[race.vehicle_id][day] = race.lap_time_ms
        }
      }

      const vehicleIds = Object.keys(byVehicle)
      if (!vehicleIds.length) return null

      const dateSet = new Set()
      for (const vid of vehicleIds) {
        for (const d of Object.keys(byVehicle[vid])) dateSet.add(d)
      }
      const sortedDates = [...dateSet].sort()
      const labels = sortedDates.map(d => {
        const [year, month, day] = d.split('-').map(Number)
        return new Date(year, month - 1, day).toLocaleDateString(undefined, {
          month: 'short',
          day: 'numeric'
        })
      })

      const vehicleById = Object.fromEntries(this.vehicles.map(v => [v.id, v]))
      const datasets = vehicleIds.map((vid, i) => {
        const color = PALETTE[i % PALETTE.length]
        return {
          label: vehicleById[vid]?.name ?? 'Unknown',
          data: sortedDates.map(d => byVehicle[vid][d] ?? null),
          borderColor: color,
          backgroundColor: color + '18',
          borderWidth: 2.5,
          pointRadius: 4,
          pointHoverRadius: 7,
          pointBackgroundColor: color,
          pointBorderColor: '#fff',
          pointBorderWidth: 2,
          tension: 0.35,
          fill: false,
          spanGaps: false
        }
      })

      return { labels, datasets }
    },
    hasData() {
      return this.chartData !== null
    }
  },
  watch: {
    chartData: {
      handler() {
        this.$nextTick(() => this.renderChart())
      }
    },
    isDark() {
      this.$nextTick(() => this.renderChart())
    }
  },
  mounted() {
    this.renderChart()
  },
  beforeUnmount() {
    this.destroyChart()
  },
  methods: {
    destroyChart() {
      if (this.chart) {
        this.chart.destroy()
        this.chart = null
      }
    },
    renderChart() {
      this.destroyChart()
      if (!this.chartData || !this.$refs.canvas) return

      const dark = this.isDark
      const gridColor = dark ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.06)'
      const tickColor = dark ? '#B4B2A9' : '#5F5E5A'
      const legendColor = dark ? '#F5F4F0' : '#444441'

      this.chart = markRaw(new Chart(this.$refs.canvas, {
        type: 'line',
        data: this.chartData,
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: 'index', intersect: false },
          plugins: {
            legend: {
              position: 'top',
              align: 'start',
              labels: {
                color: legendColor,
                boxWidth: 10,
                boxHeight: 10,
                borderRadius: 3,
                useBorderRadius: true,
                padding: 20,
                font: { size: 12, weight: '500' }
              }
            },
            tooltip: {
              backgroundColor: dark ? '#222220' : '#fff',
              borderColor: dark ? '#383836' : '#C8C6BF',
              borderWidth: 1,
              titleColor: dark ? '#F5F4F0' : '#1C1C1A',
              bodyColor: dark ? '#B4B2A9' : '#5F5E5A',
              padding: 10,
              cornerRadius: 8,
              callbacks: {
                label: ctx => {
                  const ms = ctx.parsed.y
                  if (ms == null) return ''
                  return `  ${ctx.dataset.label}: ${formatMs(ms)}`
                }
              }
            }
          },
          scales: {
            x: {
              grid: { color: gridColor, drawBorder: false },
              border: { display: false },
              ticks: { color: tickColor, font: { size: 11 }, maxRotation: 45 }
            },
            y: {
              grid: { color: gridColor, drawBorder: false },
              border: { display: false },
              ticks: {
                color: tickColor,
                font: { size: 11 },
                callback: ms => formatMs(ms)
              }
            }
          }
        }
      }))
    }
  }
}
</script>
