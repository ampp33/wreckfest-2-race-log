import { reactive } from 'vue'

// Centralised flag so any component (router views, NavBar, floating button,
// global keyboard shortcut) can open the QuickAdd modal without prop chains.
export const quickAddStore = reactive({
  open: false,
  prefillVariationId: null,
  // Set by TrackDetailPage while it's active so openQuickAdd() auto-prefills it.
  currentPageVariationId: null
})

// Non-reactive callback — set by TrackDetailPage to receive race-saved notifications.
let _onRaceSaved = null

export function openQuickAdd(prefillVariationId = null) {
  // uncomment the end of this line if you want quick add on a race
  // page to autofill the track
  quickAddStore.prefillVariationId = prefillVariationId// ?? quickAddStore.currentPageVariationId
  quickAddStore.open = true
}

export function closeQuickAdd() {
  quickAddStore.open = false
  quickAddStore.prefillVariationId = null
}

export function setOnRaceSaved(cb) {
  _onRaceSaved = cb
}

export function clearOnRaceSaved() {
  _onRaceSaved = null
}

export function notifyRaceSaved(variationId) {
  _onRaceSaved?.(variationId)
}
