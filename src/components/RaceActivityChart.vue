<template>
  <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4">
    <div class="flex items-center justify-between mb-4">
      <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-text dark:text-brand-text-dark">Race Activity</div>
      <div class="flex gap-1">
        <button
          v-for="tab in tabs"
          :key="tab.key"
          type="button"
          class="px-2.5 py-1 text-xs rounded font-medium transition-colors"
          :class="activeTab === tab.key
            ? 'bg-brand-accent text-white'
            : 'text-brand-muted dark:text-brand-muted-dark hover:text-brand-text dark:hover:text-brand-text-dark'"
          @click="activeTab = tab.key"
        >{{ tab.label }}</button>
      </div>
    </div>
    <div class="relative h-48">
      <canvas ref="canvas"></canvas>
    </div>
  </div>
</template>

<script>
import {
  Chart,
  BarController,
  BarElement,
  LinearScale,
  CategoryScale,
  Tooltip
} from 'chart.js'
import { markRaw } from 'vue'
import { prefsStore } from '../stores/prefsStore.js'

Chart.register(BarController, BarElement, LinearScale, CategoryScale, Tooltip)

function localDateStr(date) {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

function addDays(date, n) {
  const d = new Date(date)
  d.setDate(d.getDate() + n)
  return d
}

export default {
  name: 'RaceActivityChart',
  props: {
    hourlyCounts: { type: Array, default: () => new Array(24).fill(0) },
    dailyCounts: { type: Object, default: () => ({}) }
  },
  data() {
    return {
      chart: null,
      activeTab: 'week',
      tabs: [
        { key: 'day', label: 'Day' },
        { key: 'week', label: 'Week' },
        { key: 'month', label: 'Month' },
        { key: 'year', label: 'Year' }
      ]
    }
  },
  computed: {
    isDark() {
      return prefsStore.darkMode
    },
    chartData() {
      const now = new Date()
      if (this.activeTab === 'day') {
        const labels = Array.from({ length: 24 }, (_, h) => {
          const ampm = h < 12 ? 'am' : 'pm'
          const hour = h % 12 || 12
          return `${hour}${ampm}`
        })
        return { labels, data: [...this.hourlyCounts] }
      }

      if (this.activeTab === 'week') {
        const days = Array.from({ length: 7 }, (_, i) => addDays(now, i - 6))
        const labels = days.map(d => d.toLocaleDateString(undefined, { weekday: 'short', month: 'numeric', day: 'numeric' }))
        const data = days.map(d => this.dailyCounts[localDateStr(d)] || 0)
        return { labels, data }
      }

      if (this.activeTab === 'month') {
        const days = Array.from({ length: 30 }, (_, i) => addDays(now, i - 29))
        const labels = days.map(d => d.toLocaleDateString(undefined, { month: 'numeric', day: 'numeric' }))
        const data = days.map(d => this.dailyCounts[localDateStr(d)] || 0)
        return { labels, data }
      }

      // year: past 12 months
      const months = []
      for (let i = 11; i >= 0; i--) {
        const d = new Date(now.getFullYear(), now.getMonth() - i, 1)
        months.push(d)
      }
      const labels = months.map(d => d.toLocaleDateString(undefined, { month: 'short' }))
      const data = months.map(d => {
        const y = d.getFullYear()
        const m = d.getMonth()
        let total = 0
        for (const [dateStr, count] of Object.entries(this.dailyCounts)) {
          const pd = new Date(dateStr + 'T00:00:00')
          if (pd.getFullYear() === y && pd.getMonth() === m) total += count
        }
        return total
      })
      return { labels, data }
    }
  },
  watch: {
    chartData() {
      this.$nextTick(() => {
        if (this.chart) {
          const { labels, data } = this.chartData
          this.chart.data.labels = labels
          this.chart.data.datasets[0].data = data
          this.chart.update()
        } else {
          this.renderChart()
        }
      })
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
        this.chart.stop()
        this.chart.destroy()
        this.chart = null
      }
    },
    renderChart() {
      this.destroyChart()
      if (!this.$refs.canvas) return

      const dark = this.isDark
      const gridColor = dark ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.06)'
      const tickColor = dark ? '#B4B2A9' : '#5F5E5A'
      const barColor = '#C41E1E'

      const { labels, data } = this.chartData

      this.chart = markRaw(new Chart(this.$refs.canvas, {
        type: 'bar',
        data: {
          labels,
          datasets: [{
            data,
            backgroundColor: barColor + 'cc',
            borderColor: barColor,
            borderWidth: 1,
            borderRadius: 3
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          animation: { duration: 400, easing: 'easeInOutQuart' },
          plugins: {
            legend: { display: false },
            tooltip: {
              backgroundColor: dark ? '#222220' : '#fff',
              borderColor: dark ? '#383836' : '#C8C6BF',
              borderWidth: 1,
              titleColor: dark ? '#F5F4F0' : '#1C1C1A',
              bodyColor: dark ? '#B4B2A9' : '#5F5E5A',
              padding: 10,
              cornerRadius: 8,
              callbacks: {
                label: ctx => `  ${ctx.parsed.y} race${ctx.parsed.y !== 1 ? 's' : ''}`
              }
            }
          },
          scales: {
            x: {
              grid: { display: false },
              border: { display: false },
              ticks: {
                color: tickColor,
                font: { size: 10 },
                maxRotation: 45,
                autoSkip: true,
                maxTicksLimit: this.activeTab === 'month' ? 10 : 24
              }
            },
            y: {
              grid: { color: gridColor, drawBorder: false },
              border: { display: false },
              beginAtZero: true,
              ticks: {
                color: tickColor,
                font: { size: 11 },
                stepSize: 1,
                precision: 0
              }
            }
          }
        }
      }))
    }
  }
}
</script>
