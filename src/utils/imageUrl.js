// Resolves an image URL stored in the database to one usable in <img src>.
// Absolute URLs (http/https/data) are returned untouched. Relative paths
// (e.g. "track-images/big-valley-speedway.png") are prefixed with Vite's
// BASE_URL so they work both at root ("/") and under a project subpath
// ("/wreckfest-race-tracker/") on GitHub Pages.
export function resolveImageUrl(value) {
  if (!value) return ''
  if (/^(https?:|data:)/i.test(value)) return value
  const base = import.meta.env.BASE_URL || '/'
  const trimmed = value.replace(/^\/+/, '')
  return base.endsWith('/') ? base + trimmed : base + '/' + trimmed
}

// Derives the local track image path from its slug.
export function trackImageUrl(slug) {
  return resolveImageUrl(`track-images/${slug}.png`)
}

// Derives the local variation map image path from track + variation slugs.
export function variationImageUrl(trackSlug, variationSlug) {
  return resolveImageUrl(`track-variation-images/${trackSlug}--${variationSlug}.png`)
}
