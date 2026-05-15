<template>
  <div
    ref="container"
    class="relative select-none rounded overflow-hidden bg-black"
    :class="editMode ? 'cursor-crosshair' : ''"
    @click="onContainerClick"
  >
    <img
      ref="mapImg"
      :src="imageUrl"
      :alt="alt"
      class="w-full h-auto block pointer-events-none"
      draggable="false"
    />

    <!-- Edit mode hint -->
    <div
      v-if="editMode"
      class="absolute top-2 left-2 bg-orange-500/80 text-white text-xs px-2 py-0.5 rounded font-medium pointer-events-none"
    >
      Click map to add turn
    </div>

    <!-- Controls: pencil in view mode, discard+save in edit mode -->
    <div class="absolute top-2 right-2 flex gap-1 z-10">
      <template v-if="!editMode">
        <button
          type="button"
          class="p-1.5 bg-brand-bg/80 dark:bg-brand-surface-dark/80 backdrop-blur-sm rounded shadow text-brand-secondary dark:text-brand-secondary-dark hover:text-brand-accent transition-colors"
          title="Edit annotations"
          @click.stop="$emit('toggle-edit')"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" viewBox="0 0 20 20" fill="currentColor">
            <path d="M13.586 3.586a2 2 0 112.828 2.828l-.793.793-2.828-2.828.793-.793zM11.379 5.793L3 14.172V17h2.828l8.38-8.379-2.83-2.828z"/>
          </svg>
        </button>
      </template>
      <template v-else>
        <button
          type="button"
          class="p-1.5 bg-brand-bg/80 dark:bg-brand-surface-dark/80 backdrop-blur-sm rounded shadow text-brand-muted dark:text-brand-muted-dark hover:text-red-500 transition-colors"
          title="Discard changes"
          @click.stop="$emit('discard')"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        </button>
        <button
          type="button"
          class="p-1.5 bg-brand-bg/80 dark:bg-brand-surface-dark/80 backdrop-blur-sm rounded shadow text-brand-muted dark:text-brand-muted-dark hover:text-green-600 transition-colors"
          title="Save annotations"
          @click.stop="$emit('save')"
        >
          <svg xmlns="http://www.w3.org/2000/svg" class="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2.5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
          </svg>
        </button>
      </template>
    </div>

    <!-- Annotation circles, positioned by normalized percentage coordinates -->
    <div
      v-for="ann in annotations"
      :key="ann.id"
      class="absolute -translate-x-1/2 -translate-y-1/2 w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold text-white transition-all cursor-pointer ring-2"
      :class="ann.id === selectedId
        ? 'bg-blue-500/85 ring-blue-300 scale-110'
        : 'bg-brand-accent/75 ring-brand-accent/50 hover:bg-brand-accent hover:scale-105'"
      :style="{ left: ann.x + '%', top: ann.y + '%' }"
      @click.stop="$emit('select', ann.id)"
    >
      {{ ann.number }}
    </div>
  </div>
</template>

<script>
export default {
  name: 'AnnotationMap',
  props: {
    imageUrl: { type: String, required: true },
    alt: { type: String, default: 'Track map' },
    annotations: { type: Array, default: () => [] },
    editMode: { type: Boolean, default: false },
    selectedId: { type: String, default: null },
  },
  emits: ['toggle-edit', 'add-annotation', 'select', 'save', 'discard'],
  methods: {
    onContainerClick(event) {
      if (!this.editMode) return
      const img = this.$refs.mapImg
      const rect = img.getBoundingClientRect()
      if (
        event.clientX < rect.left || event.clientX > rect.right ||
        event.clientY < rect.top || event.clientY > rect.bottom
      ) return
      const x = ((event.clientX - rect.left) / rect.width) * 100
      const y = ((event.clientY - rect.top) / rect.height) * 100
      this.$emit('add-annotation', { x, y })
    }
  }
}
</script>
