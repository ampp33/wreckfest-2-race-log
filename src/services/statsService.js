import { getAllRaces } from './raceService.js'
import { getVehicles } from './vehicleService.js'
import { getTracks } from './trackService.js'
import { getAllGoals } from './goalService.js'

// Aggregate stats for the Stats page. We pull everything client-side because
// the dataset per user is small (hundreds of races at most) and avoids round
// trips for each metric.
export async function getStats() {
  const [races, vehicles, tracks, goals] = await Promise.all([
    getAllRaces(),
    getVehicles(),
    getTracks(),
    getAllGoals()
  ])

  return {
    mostUsedVehicle: computeMostUsedVehicle(races, vehicles),
    mostRacedVariation: computeMostRacedVariation(races, tracks),
    biggestImprovements: computeBiggestImprovements(races, tracks),
    totalRaces: races.length,
    goalProgress: computeGoalProgress(races, tracks, goals),
    raceCounts: computeRaceCounts(races),
    recentRaces: computeRecentRaces(races, tracks, vehicles)
  }
}

function computeMostUsedVehicle(races, vehicles) {
  const counts = countBy(races, r => r.vehicle_id)
  const winnerId = topKey(counts)
  if (!winnerId) return null
  const vehicle = vehicles.find(v => v.id === winnerId)
  return vehicle ? { name: vehicle.name, count: counts[winnerId] } : null
}

function computeMostRacedVariation(races, tracks) {
  const counts = countBy(races, r => r.track_variation_id)
  const winnerId = topKey(counts)
  if (!winnerId) return null
  const found = findVariationName(tracks, winnerId)
  if (!found) return null
  return { ...found, count: counts[winnerId] }
}

function computeBiggestImprovements(races, tracks) {
  const grouped = groupBy(races, r => r.track_variation_id)
  const improvements = []

  for (const variationId of Object.keys(grouped)) {
    const sorted = grouped[variationId]
      .filter(r => r.lap_time_ms != null)
      .sort((a, b) => new Date(a.datetime) - new Date(b.datetime))
    if (sorted.length < 2) continue

    const oldest = sorted[0].lap_time_ms
    const newest = sorted[sorted.length - 1].lap_time_ms
    const deltaMs = oldest - newest
    if (deltaMs <= 0) continue

    const found = findVariationName(tracks, variationId)
    if (!found) continue
    improvements.push({ ...found, deltaMs, oldest, newest })
  }

  improvements.sort((a, b) => b.deltaMs - a.deltaMs)
  return improvements.slice(0, 5)
}

function computeGoalProgress(races, tracks, goals) {
  const pbByVariation = {}
  for (const race of races) {
    if (race.lap_time_ms == null) continue
    const vid = race.track_variation_id
    if (pbByVariation[vid] == null || race.lap_time_ms < pbByVariation[vid]) {
      pbByVariation[vid] = race.lap_time_ms
    }
  }

  const result = []
  for (const goal of goals) {
    if (!goal.goal_lap_time_ms) continue
    const found = findVariationName(tracks, goal.track_variation_id)
    if (!found) continue
    const pb = pbByVariation[goal.track_variation_id] ?? null
    result.push({
      ...found,
      goalMs: goal.goal_lap_time_ms,
      pbMs: pb,
      deltaMs: pb != null ? pb - goal.goal_lap_time_ms : null
    })
  }

  // Beat goal (negative delta) first, then closest to goal, then no PB yet
  result.sort((a, b) => {
    if (a.deltaMs == null && b.deltaMs == null) return 0
    if (a.deltaMs == null) return 1
    if (b.deltaMs == null) return -1
    return a.deltaMs - b.deltaMs
  })

  return result
}

function computeRaceCounts(races) {
  const now = new Date()
  const todayStr = localDateStr(now)

  const hourlyCounts = new Array(24).fill(0)
  const dailyCounts = {}

  for (const race of races) {
    const d = new Date(race.datetime)
    const dateStr = localDateStr(d)
    dailyCounts[dateStr] = (dailyCounts[dateStr] || 0) + 1
    if (dateStr === todayStr) {
      hourlyCounts[d.getHours()]++
    }
  }

  return { hourlyCounts, dailyCounts }
}

function computeRecentRaces(races, tracks, vehicles) {
  const cutoff = Date.now() - 24 * 60 * 60 * 1000
  return races
    .filter(r => new Date(r.datetime).getTime() >= cutoff)
    .map(r => {
      const found = findVariationName(tracks, r.track_variation_id)
      const vehicle = vehicles.find(v => v.id === r.vehicle_id)
      return {
        id: r.id,
        datetime: r.datetime,
        trackName: found?.trackName ?? '—',
        trackSlug: found?.trackSlug ?? null,
        variationName: found?.variationName ?? '—',
        variationSlug: found?.variationSlug ?? null,
        vehicleName: vehicle?.name ?? '—',
        lapTimeMs: r.lap_time_ms,
        place: r.place
      }
    })
}

function localDateStr(date) {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

function countBy(items, keyFn) {
  const counts = {}
  for (const item of items) {
    const key = keyFn(item)
    if (key == null) continue
    counts[key] = (counts[key] || 0) + 1
  }
  return counts
}

function groupBy(items, keyFn) {
  const out = {}
  for (const item of items) {
    const key = keyFn(item)
    if (key == null) continue
    if (!out[key]) out[key] = []
    out[key].push(item)
  }
  return out
}

function topKey(counts) {
  let winner = null
  let best = -1
  for (const key of Object.keys(counts)) {
    if (counts[key] > best) {
      best = counts[key]
      winner = key
    }
  }
  return winner
}

function findVariationName(tracks, variationId) {
  for (const track of tracks) {
    const v = (track.track_variations || []).find(x => x.id === variationId)
    if (v) {
      return {
        trackName: track.name,
        trackSlug: track.slug,
        variationName: v.name,
        variationSlug: v.slug
      }
    }
  }
  return null
}
