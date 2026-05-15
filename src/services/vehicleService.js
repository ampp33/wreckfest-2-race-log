import { supabase } from './supabase.js'

let _vehicles = null

export async function getVehicles() {
  if (_vehicles) return _vehicles
  const { data, error } = await supabase
    .from('vehicles')
    .select('id, name, class')
    .order('name', { ascending: true })
  if (error) throw error
  _vehicles = data || []
  return _vehicles
}
