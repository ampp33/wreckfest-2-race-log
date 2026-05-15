import { supabase } from './supabase.js'

async function sha256Hex(text) {
  const encoder = new TextEncoder()
  const data = encoder.encode(text)
  const hashBuffer = await crypto.subtle.digest('SHA-256', data)
  return Array.from(new Uint8Array(hashBuffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')
}

function generateRawKey() {
  const bytes = new Uint8Array(32)
  crypto.getRandomValues(bytes)
  return Array.from(bytes)
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')
}

export async function getApiKeys() {
  const { data, error } = await supabase
    .from('api_keys')
    .select('id, name, created_at, last_used_at')
    .order('created_at', { ascending: false })
  if (error) throw error
  return data || []
}

export async function createApiKey(name) {
  const { data: { user } } = await supabase.auth.getUser()
  if (!user) throw new Error('Not authenticated')

  const rawKey = generateRawKey()
  const keyHash = await sha256Hex(rawKey)

  const { error } = await supabase
    .from('api_keys')
    .insert({ user_id: user.id, name, key_hash: keyHash })
  if (error) throw error

  return rawKey
}

export async function deleteApiKey(id) {
  const { error } = await supabase.from('api_keys').delete().eq('id', id)
  if (error) throw error
}
