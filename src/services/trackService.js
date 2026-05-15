import { supabase } from './supabase.js'

let _tracks = null

export async function getTracks() {
  if (_tracks) return _tracks
  const { data, error } = await supabase
    .from('tracks')
    .select('id, name, slug, track_variations(id, name, slug)')
    .order('name', { ascending: true })
  if (error) throw error
  _tracks = data || []
  return _tracks
}

export async function getTrackBySlug(slug) {
  const tracks = await getTracks()
  return tracks.find(t => t.slug === slug) ?? null
}

export function findVariation(track, variationSlug) {
  if (!track || !track.track_variations) return null
  return track.track_variations.find(v => v.slug === variationSlug) || null
}
