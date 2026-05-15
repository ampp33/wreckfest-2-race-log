import { reactive } from 'vue'

export const toastStore = reactive({
  items: []
})

let nextId = 1

export function pushToast(message, type = 'info', timeoutMs = 3000) {
  const id = nextId++
  toastStore.items.push({ id, message, type })
  setTimeout(() => removeToast(id), timeoutMs)
}

export function removeToast(id) {
  const idx = toastStore.items.findIndex(t => t.id === id)
  if (idx !== -1) toastStore.items.splice(idx, 1)
}
