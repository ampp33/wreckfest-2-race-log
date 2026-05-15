<template>
  <div class="mb-4 bg-brand-surface dark:bg-brand-surface-dark rounded border border-brand-border dark:border-brand-border-dark">
    <!-- Collapsible header -->
    <button
      type="button"
      class="w-full flex items-center justify-between px-3 py-2.5 text-left hover:bg-brand-bg dark:hover:bg-brand-surface-dark/70 rounded transition-colors"
      @click="collapsed = !collapsed"
    >
      <span class="font-body font-medium uppercase tracking-widest text-[11px] text-brand-text dark:text-brand-text-dark">Turn Annotations</span>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="w-4 h-4 text-brand-muted dark:text-brand-muted-dark transition-transform"
        :class="collapsed ? '' : 'rotate-180'"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
        stroke-width="2"
      >
        <path stroke-linecap="round" stroke-linejoin="round" d="M19 9l-7 7-7-7"/>
      </svg>
    </button>

    <!-- Content -->
    <div v-if="!collapsed" class="p-3 border-t border-brand-border dark:border-brand-border-dark">
      <div class="flex flex-col md:flex-row gap-4">
        <!-- Map (left) -->
        <div class="md:w-1/2">
          <AnnotationMap
            :image-url="imageUrl"
            :alt="alt"
            :annotations="workingAnnotations"
            :edit-mode="editMode"
            :selected-id="selectedId"
            @toggle-edit="startEdit"
            @add-annotation="addAnnotation"
            @select="toggleSelect"
            @save="saveAnnotations"
            @discard="discardEdit"
          />
        </div>

        <!-- Annotation list (right) -->
        <div class="md:w-1/2">
          <AnnotationList
            :annotations="workingAnnotations"
            :edit-mode="editMode"
            :selected-id="selectedId"
            @select="toggleSelect"
            @update="updateAnnotation"
            @delete="deleteAnnotation"
          />
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import AnnotationMap from './AnnotationMap.vue'
import AnnotationList from './AnnotationList.vue'

export default {
  name: 'VariationAnnotations',
  components: { AnnotationMap, AnnotationList },
  props: {
    imageUrl: { type: String, required: true },
    alt: { type: String, default: 'Track map' },
    annotations: { type: Array, default: () => [] },
  },
  emits: ['save'],
  data() {
    return {
      collapsed: true,
      editMode: false,
      selectedId: null,
      workingAnnotations: [],
      savedAnnotations: [],
    }
  },
  watch: {
    annotations: {
      immediate: true,
      handler(val) {
        this.savedAnnotations = this.cloneAnnotations(val || [])
        if (!this.editMode) {
          this.workingAnnotations = this.cloneAnnotations(this.savedAnnotations)
        }
      }
    }
  },
  methods: {
    cloneAnnotations(arr) {
      return arr.map(a => ({ ...a }))
    },
    startEdit() {
      this.workingAnnotations = this.cloneAnnotations(this.savedAnnotations)
      this.editMode = true
    },
    addAnnotation({ x, y }) {
      const maxNum = this.workingAnnotations.reduce((m, a) => Math.max(m, a.number || 0), 0)
      this.workingAnnotations.push({
        id: crypto.randomUUID(),
        x,
        y,
        number: maxNum + 1,
        note: '',
      })
    },
    toggleSelect(id) {
      this.selectedId = this.selectedId === id ? null : id
    },
    updateAnnotation({ id, field, value }) {
      const ann = this.workingAnnotations.find(a => a.id === id)
      if (ann) ann[field] = value
    },
    deleteAnnotation(id) {
      this.workingAnnotations = this.workingAnnotations.filter(a => a.id !== id)
      if (this.selectedId === id) this.selectedId = null
    },
    saveAnnotations() {
      this.savedAnnotations = this.cloneAnnotations(this.workingAnnotations)
      this.editMode = false
      this.$emit('save', this.cloneAnnotations(this.savedAnnotations))
    },
    discardEdit() {
      this.workingAnnotations = this.cloneAnnotations(this.savedAnnotations)
      this.editMode = false
    },
  }
}
</script>
