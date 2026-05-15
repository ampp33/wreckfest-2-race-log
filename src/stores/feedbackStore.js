import { reactive } from 'vue'

export const feedbackStore = reactive({ open: false })

export function openFeedback() { feedbackStore.open = true }
export function closeFeedback() { feedbackStore.open = false }
