import { reactive } from 'vue'

export const trackSearchStore = reactive({ open: false })

export function openTrackSearch() { trackSearchStore.open = true }
export function closeTrackSearch() { trackSearchStore.open = false }
