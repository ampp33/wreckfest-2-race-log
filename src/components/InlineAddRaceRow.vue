<template>
  <tr class="border-b border-brand-border dark:border-brand-border-dark bg-brand-surface dark:bg-brand-bg-dark">
    <td colspan="9" class="py-3">
      <RaceForm
        :vehicles="vehicles"
        :defaults="defaults"
        :saving="saving"
        :autofocus="true"
        @submit="onSubmit"
        @cancel="$emit('cancel')"
      />
    </td>
  </tr>
</template>

<script>
import RaceForm from './RaceForm.vue'

export default {
  name: 'InlineAddRaceRow',
  components: { RaceForm },
  props: {
    vehicles: { type: Array, required: true },
    defaults: { type: Object, default: () => ({}) },
    saving: { type: Boolean, default: false }
  },
  emits: ['submit', 'cancel'],
  methods: {
    onSubmit(payload) {
      this.$emit('submit', payload)
    }
  }
}
</script>
