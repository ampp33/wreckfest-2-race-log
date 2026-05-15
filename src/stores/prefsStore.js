import { reactive, watch } from 'vue'

const STORAGE_KEY = 'wreckfest:prefs'

const defaults = {
  lastVehicleId: null,
  lastTuning: null,
  lastTrackVariationId: null,
  darkMode: false
}

function loadFromStorage() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return { ...defaults }
    const parsed = JSON.parse(raw)
    return { ...defaults, ...parsed }
  } catch {
    return { ...defaults }
  }
}

export const prefsStore = reactive(loadFromStorage())

watch(
  () => ({ ...prefsStore }),
  value => {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(value))
    } catch {
      // Storage may be unavailable in private browsing — fail silently.
    }
  },
  { deep: true }
)

export function applyDarkModeClass() {
  const root = document.documentElement
  if (prefsStore.darkMode) {
    root.classList.add('dark')
  } else {
    root.classList.remove('dark')
  }
}

watch(() => prefsStore.darkMode, applyDarkModeClass, { immediate: false })
