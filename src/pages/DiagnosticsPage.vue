<template>
  <div class="max-w-4xl mx-auto px-6 py-6 pb-24">
    <h1 class="font-display font-black tracking-tighter leading-none text-display-lg text-brand-text dark:text-brand-text-dark mb-1">
      <em class="signal">Diagnostics</em>
    </h1>
    <p class="font-body text-[15px] leading-relaxed text-brand-secondary dark:text-brand-secondary-dark mb-6">Site-wide activity overview.</p>

    <p v-if="loading" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">Loading…</p>

    <p v-else-if="error" class="text-sm text-red-500">{{ error }}</p>

    <div v-else class="space-y-6">
      <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4 inline-block">
        <div class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark">Registered users</div>
        <div class="mt-1 font-display font-black tracking-tight text-3xl text-brand-text dark:text-brand-text-dark">{{ data.total_users }}</div>
      </div>

      <!-- User growth chart -->
      <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4">
        <h2 class="font-display font-black tracking-tighter leading-none text-display-sm text-brand-text dark:text-brand-text-dark mb-3">
          User <em class="signal">growth</em> — last 30 days
        </h2>
        <div class="relative h-56">
          <canvas ref="growthCanvas"></canvas>
        </div>
      </div>

      <!-- Top users table -->
      <div class="bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark p-4">
        <h2 class="font-display font-black tracking-tighter leading-none text-display-sm text-brand-text dark:text-brand-text-dark mb-3">
          Top 5 users by <em class="signal">activity</em>
        </h2>
        <p v-if="!data.top_users || !data.top_users.length" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark">
          No activity yet.
        </p>
        <div v-else class="overflow-x-auto">
        <table class="w-full text-sm">
          <thead>
            <tr class="text-left font-body font-medium uppercase tracking-widest text-[11px] text-brand-muted dark:text-brand-muted-dark border-b border-brand-border dark:border-brand-border-dark">
              <th class="pb-2 font-medium">User</th>
              <th class="pb-2 font-medium">Signed up</th>
              <th class="pb-2 font-medium text-right">Races</th>
              <th class="pb-2 font-medium text-right">Goals</th>
              <th class="pb-2 font-medium text-right">Annotations</th>
              <th class="pb-2 font-medium text-right">Total</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-brand-border dark:divide-brand-border-dark">
            <tr v-for="(user, i) in data.top_users" :key="user.email" class="hover:bg-brand-bg dark:hover:bg-brand-bg-dark/30">
              <td class="py-2 pr-4">
                <span class="text-brand-muted dark:text-brand-muted-dark mr-2">{{ i + 1 }}.</span>
                {{ user.email }}
              </td>
              <td class="py-2 pr-4 text-brand-muted dark:text-brand-muted-dark text-xs whitespace-nowrap">{{ formatDate(user.created_at) }}</td>
              <td class="py-2 text-right tabular-nums">{{ user.race_count }}</td>
              <td class="py-2 text-right tabular-nums">{{ user.goal_count }}</td>
              <td class="py-2 text-right tabular-nums">{{ user.annotation_count }}</td>
              <td class="py-2 text-right tabular-nums font-semibold">{{ user.total_activity }}</td>
            </tr>
          </tbody>
        </table>
        </div>
      </div>
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
  Filler
} from 'chart.js'
import { markRaw } from 'vue'
import { prefsStore } from '../stores/prefsStore.js'
import { getDiagnostics, getUserGrowth } from '../services/adminService.js'

Chart.register(LineController, LineElement, PointElement, LinearScale, CategoryScale, Tooltip, Filler)

export default {
  name: 'DiagnosticsPage',
  data() {
    return {
      loading: true,
      error: null,
      data: { total_users: 0, top_users: [] },
      growthData: [],
      chart: null
    }
  },
  computed: {
    isDark() {
      return prefsStore.darkMode
    }
  },
  watch: {
    isDark() {
      this.$nextTick(() => this.renderChart())
    }
  },
  async created() {
    try {
      ;[this.data, this.growthData] = await Promise.all([getDiagnostics(), getUserGrowth()])
    } catch (err) {
      this.error = err.message || 'Failed to load diagnostics'
    } finally {
      this.loading = false
    }
  },
  mounted() {
    if (!this.loading) this.renderChart()
  },
  updated() {
    if (!this.loading && !this.chart) this.renderChart()
  },
  beforeUnmount() {
    this.chart?.destroy()
  },
  methods: {
    formatDate(iso) {
      if (!iso) return '—'
      return new Date(iso).toLocaleString(undefined, { year: 'numeric', month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' })
    },
    renderChart() {
      if (!this.$refs.growthCanvas || !this.growthData.length) return
      this.chart?.destroy()

      const dark = this.isDark
      const color = '#0ea5e9'
      const gridColor = dark ? 'rgba(255,255,255,0.07)' : 'rgba(0,0,0,0.06)'
      const tickColor = dark ? '#B4B2A9' : '#5F5E5A'

      const labels = this.growthData.map(row =>
        new Date(row.day).toLocaleDateString(undefined, { month: 'short', day: 'numeric' })
      )
      const counts = this.growthData.map(row => Number(row.user_count))

      this.chart = markRaw(new Chart(this.$refs.growthCanvas, {
        type: 'line',
        data: {
          labels,
          datasets: [{
            label: 'Total users',
            data: counts,
            borderColor: color,
            backgroundColor: color + '22',
            borderWidth: 2.5,
            pointRadius: 3,
            pointHoverRadius: 6,
            pointBackgroundColor: color,
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            tension: 0.35,
            fill: true
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: 'index', intersect: false },
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
                label: ctx => `  ${ctx.parsed.y} users`
              }
            }
          },
          scales: {
            x: {
              grid: { color: gridColor },
              border: { display: false },
              ticks: { color: tickColor, font: { size: 11 }, maxRotation: 45, maxTicksLimit: 10 }
            },
            y: {
              grid: { color: gridColor },
              border: { display: false },
              beginAtZero: true,
              ticks: {
                color: tickColor,
                font: { size: 11 },
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
