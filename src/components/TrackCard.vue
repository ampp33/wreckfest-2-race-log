<template>
  <router-link
    :to="firstVariationLink"
    class="block rounded-lg overflow-hidden bg-brand-bg dark:bg-brand-surface-dark border border-brand-border dark:border-brand-border-dark shadow-sm hover:shadow-md hover:border-brand-accent transition"
  >
    <div class="aspect-video bg-brand-surface dark:bg-brand-surface-dark overflow-hidden">
      <img
        :src="resolvedImage"
        :alt="track.name"
        class="w-full h-full object-cover"
        loading="lazy"
      />
    </div>
    <div class="p-3">
      <h3 class="font-display font-black tracking-tight truncate text-brand-text dark:text-brand-text-dark">{{ track.name }}</h3>
      <p class="font-body text-[15px] text-brand-muted dark:text-brand-muted-dark mt-1">
        {{ variationCount }} variation{{ variationCount === 1 ? '' : 's' }}
      </p>
      <div v-if="track.track_variations && track.track_variations.length" class="mt-2 flex flex-wrap gap-1">
        <span
          v-for="v in track.track_variations.slice(0, 4)"
          :key="v.id"
          class="font-body font-medium uppercase tracking-widest text-[10px] px-2 py-0.5 rounded bg-brand-surface dark:bg-brand-surface-dark text-brand-secondary dark:text-brand-secondary-dark"
        >
          {{ v.name }}
        </span>
      </div>
    </div>
  </router-link>
</template>

<script>
import { trackImageUrl } from '../utils/imageUrl.js'

export default {
  name: 'TrackCard',
  props: {
    track: { type: Object, required: true }
  },
  computed: {
    variationCount() {
      return (this.track.track_variations || []).length
    },
    firstVariationLink() {
      const first = (this.track.track_variations || [])[0]
      if (!first) return '/'
      return `/track/${this.track.slug}/${first.slug}`
    },
    resolvedImage() {
      return trackImageUrl(this.track.slug)
    }
  }
}
</script>
