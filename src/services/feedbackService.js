import { supabase } from './supabase.js'

export async function submitFeedback({ userId, url, feedbackText }) {
  const { error } = await supabase
    .from('feedback')
    .insert({ user_id: userId, url, feedback_text: feedbackText })
  if (error) throw error
}
