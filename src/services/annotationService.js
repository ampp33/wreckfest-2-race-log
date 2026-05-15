import { supabase } from './supabase.js'

export async function getAnnotationsForVariation(variationId) {
  const { data, error } = await supabase
    .from('variation_annotations')
    .select('id, x, y, number, note')
    .eq('track_variation_id', variationId)
    .order('created_at')
  if (error) throw error
  return data || []
}

export async function saveAnnotations({ variationId, annotations, userId }) {
  const { error: deleteError } = await supabase
    .from('variation_annotations')
    .delete()
    .eq('track_variation_id', variationId)
    .eq('user_id', userId)
  if (deleteError) throw deleteError

  if (!annotations.length) return []

  const rows = annotations.map(ann => ({
    user_id: userId,
    track_variation_id: variationId,
    x: ann.x,
    y: ann.y,
    number: ann.number,
    note: ann.note || null,
  }))

  const { data, error } = await supabase
    .from('variation_annotations')
    .insert(rows)
    .select('id, x, y, number, note')
  if (error) throw error
  return data || []
}
