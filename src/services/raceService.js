import { supabase } from './supabase.js'

const RACE_COLUMNS =
  'id, datetime, track_variation_id, vehicle_id, place, lap_time_ms, total_time_ms, performance_index, notes, created_at'

export async function getRacesByVariation(variationId) {
  const { data, error } = await supabase
    .from('races')
    .select(RACE_COLUMNS)
    .eq('track_variation_id', variationId)
    .order('datetime', { ascending: false })
  if (error) throw error
  return data || []
}

export async function getAllRaces() {
  const { data, error } = await supabase
    .from('races')
    .select(RACE_COLUMNS + ', track_variation_id')
    .order('datetime', { ascending: false })
  if (error) throw error
  return data || []
}

export async function createRace(race, userId) {
  const payload = { ...race, user_id: userId }
  const { data, error } = await supabase
    .from('races')
    .insert(payload)
    .select(RACE_COLUMNS)
    .single()
  if (error) throw error
  return data
}

export async function updateRace(id, patch) {
  const { data, error } = await supabase
    .from('races')
    .update(patch)
    .eq('id', id)
    .select(RACE_COLUMNS)
    .single()
  if (error) throw error
  return data
}

export async function deleteRace(id) {
  const { error } = await supabase.from('races').delete().eq('id', id)
  if (error) throw error
}

export async function getVehiclePiMap() {
  const { data, error } = await supabase
    .from('races')
    .select('vehicle_id, performance_index')
    .not('vehicle_id', 'is', null)
    .not('performance_index', 'is', null)
    .order('datetime', { ascending: false })
  if (error) throw error
  const map = {}
  for (const { vehicle_id, performance_index } of data || []) {
    if (!(vehicle_id in map)) map[vehicle_id] = performance_index
  }
  return map
}

export async function bulkInsertRaces(races, userId) {
  const payload = races.map(r => ({ ...r, user_id: userId }))
  const { data, error } = await supabase
    .from('races')
    .insert(payload)
    .select(RACE_COLUMNS)
  if (error) throw error
  return data || []
}
