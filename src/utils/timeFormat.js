// Lap and total times are stored as integer milliseconds. The UI accepts a
// flexible string ("1:23.456", "83.4", "1.23.456") so the user can type fast
// without worrying about exact punctuation.

const TIME_PATTERN = /^(?:(\d+)[:.])?(\d{1,2})(?:[.,](\d{1,3}))?$/

export function parseTimeToMs(input) {
  if (input == null) return null
  const trimmed = String(input).trim()
  if (!trimmed) return null

  const match = trimmed.match(TIME_PATTERN)
  if (!match) return null

  const minutes = match[1] ? parseInt(match[1], 10) : 0
  const seconds = parseInt(match[2], 10)
  const fractionRaw = match[3] || ''
  const millis = fractionRaw
    ? parseInt(fractionRaw.padEnd(3, '0').slice(0, 3), 10)
    : 0

  if (Number.isNaN(minutes) || Number.isNaN(seconds) || Number.isNaN(millis)) {
    return null
  }
  return minutes * 60_000 + seconds * 1000 + millis
}

export function formatMsToTime(ms) {
  if (ms == null || Number.isNaN(ms)) return ''
  const total = Math.max(0, Math.round(ms))
  const minutes = Math.floor(total / 60_000)
  const seconds = Math.floor((total % 60_000) / 1000)
  const millis = total % 1000

  const ss = String(seconds).padStart(2, '0')
  const mss = String(millis).padStart(3, '0')
  return `${minutes}:${ss}.${mss}`
}

export function formatDelta(ms) {
  if (ms == null) return ''
  const sign = ms > 0 ? '+' : ms < 0 ? '-' : ''
  return sign + formatMsToTime(Math.abs(ms))
}
