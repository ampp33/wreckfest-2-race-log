<template>
  <div class="flex flex-col gap-2">
    <p v-if="!annotations.length" class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark italic py-4 text-center">
      {{ editMode ? 'Click anywhere on the map to add a turn annotation.' : 'No turn annotations yet. Click the pencil icon on the map to add some.' }}
    </p>

    <div
      v-for="ann in annotations"
      :key="ann.id"
      class="flex items-start gap-2 p-2 rounded border transition-colors cursor-pointer"
      :class="ann.id === selectedId
        ? 'border-blue-400 bg-blue-50 dark:bg-blue-950/30'
        : 'border-brand-border dark:border-brand-border-dark hover:border-brand-secondary dark:hover:border-brand-secondary-dark'"
      @click="$emit('select', ann.id)"
    >
      <!-- Turn number: badge in view mode, editable input in edit mode -->
      <div
        v-if="!editMode"
        class="w-7 h-7 rounded-full bg-brand-accent/75 text-white text-xs font-bold flex items-center justify-center shrink-0 mt-0.5"
      >
        {{ ann.number }}
      </div>
      <input
        v-else
        type="number"
        :value="ann.number"
        min="1"
        class="w-10 h-7 text-center text-xs font-bold rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-bg-dark text-brand-text dark:text-brand-text-dark shrink-0 focus:outline-none focus:ring-1 focus:ring-brand-accent"
        title="Turn number"
        @click.stop
        @input.stop="$emit('update', { id: ann.id, field: 'number', value: +$event.target.value || 1 })"
      />

      <!-- Note: textarea in edit mode, plain text in view mode -->
      <div class="flex-1 min-w-0">
        <textarea
          v-if="editMode"
          :value="ann.note"
          rows="2"
          class="w-full text-sm rounded border border-brand-border dark:border-brand-border-dark bg-brand-bg dark:bg-brand-bg-dark text-brand-text dark:text-brand-text-dark px-2 py-1 resize-y focus:outline-none focus:ring-1 focus:ring-brand-accent"
          placeholder="Notes about this turn…"
          @click.stop
          @input.stop="$emit('update', { id: ann.id, field: 'note', value: $event.target.value })"
        />
        <p v-else class="font-body text-[15px] text-brand-secondary dark:text-brand-secondary-dark py-0.5 break-words whitespace-pre-wrap">
          {{ ann.note || '—' }}
        </p>
      </div>

      <!-- Trash icon (edit mode only) -->
      <button
        v-if="editMode"
        type="button"
        class="text-brand-muted dark:text-brand-muted-dark hover:text-red-500 shrink-0 mt-0.5 transition-colors"
        title="Remove annotation"
        @click.stop="$emit('delete', ann.id)"
      >
        <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"/>
        </svg>
      </button>
    </div>
  </div>
</template>

<script>
export default {
  name: 'AnnotationList',
  props: {
    annotations: { type: Array, default: () => [] },
    editMode: { type: Boolean, default: false },
    selectedId: { type: String, default: null },
  },
  emits: ['select', 'update', 'delete'],
}
</script>
