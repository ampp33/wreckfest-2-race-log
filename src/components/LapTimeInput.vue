<template>
  <div
    class="flex items-center rounded border px-2 py-1.5 gap-px cursor-text w-full bg-brand-bg dark:bg-brand-surface-dark"
    :class="focused
      ? 'border-brand-accent ring-1 ring-brand-accent'
      : 'border-brand-border dark:border-brand-border-dark'"
    @click.self="focusActive"
  >
    <input
      ref="mmRef"
      v-model="mm"
      inputmode="numeric"
      placeholder="1"
      class="w-7 text-center bg-transparent outline-none"
      @input="onMmInput"
      @keydown="onMmKeydown"
      @focus="onFocus"
      @blur="onBlur"
    />
    <span class="text-brand-muted dark:text-brand-muted-dark select-none">:</span>
    <input
      ref="ssRef"
      v-model="ss"
      inputmode="numeric"
      placeholder="23"
      class="w-7 text-center bg-transparent outline-none"
      @input="onSsInput"
      @keydown="onSsKeydown"
      @focus="onFocus"
      @blur="onBlur"
    />
    <span class="text-brand-muted dark:text-brand-muted-dark select-none">.</span>
    <input
      ref="msecRef"
      v-model="msec"
      inputmode="numeric"
      placeholder="456"
      class="w-10 text-center bg-transparent outline-none"
      @input="onMsecInput"
      @keydown="onMsecKeydown"
      @focus="onFocus"
      @blur="onBlur"
    />
  </div>
</template>

<script>
export default {
  name: 'LapTimeInput',
  props: {
    modelValue: { type: Number, default: null }
  },
  emits: ['update:modelValue', 'blur'],
  data() {
    return { mm: '', ss: '', msec: '', focused: false }
  },
  created() {
    this.parseFromMs(this.modelValue)
  },
  watch: {
    modelValue(val) {
      if (val === this.computeMs()) return
      this.parseFromMs(val)
    }
  },
  methods: {
    parseFromMs(ms) {
      if (ms == null) { this.mm = ''; this.ss = ''; this.msec = ''; return }
      const total = Math.max(0, Math.round(ms))
      this.mm = String(Math.floor(total / 60_000))
      this.ss = String(Math.floor((total % 60_000) / 1000)).padStart(2, '0')
      this.msec = String(total % 1000).padStart(3, '0')
    },
    computeMs() {
      if (!this.mm && !this.ss && !this.msec) return null
      const m = parseInt(this.mm || '0', 10) || 0
      const s = parseInt(this.ss || '0', 10) || 0
      const ms = parseInt((this.msec || '').padEnd(3, '0').slice(0, 3), 10) || 0
      return m * 60_000 + s * 1_000 + ms
    },
    emitMs() {
      this.$emit('update:modelValue', this.computeMs())
    },
    onMmInput() {
      this.mm = this.mm.replace(/\D/g, '').slice(0, 2)
      this.emitMs()
      if (this.mm.length >= 2) { this.$refs.ssRef.select(); this.$refs.ssRef.focus() }
    },
    onSsInput() {
      this.ss = this.ss.replace(/\D/g, '').slice(0, 2)
      this.emitMs()
      if (this.ss.length >= 2) { this.$refs.msecRef.select(); this.$refs.msecRef.focus() }
    },
    onMsecInput() {
      this.msec = this.msec.replace(/\D/g, '').slice(0, 3)
      this.emitMs()
    },
    onMmKeydown(e) {
      if (e.key === ':' || e.key === '.') { e.preventDefault(); this.$refs.ssRef.select(); this.$refs.ssRef.focus() }
    },
    onSsKeydown(e) {
      if (e.key === 'Backspace' && this.ss === '') { e.preventDefault(); this.$refs.mmRef.focus() }
      if (e.key === '.') { e.preventDefault(); this.$refs.msecRef.select(); this.$refs.msecRef.focus() }
    },
    onMsecKeydown(e) {
      if (e.key === 'Backspace' && this.msec === '') { e.preventDefault(); this.$refs.ssRef.focus() }
    },
    focusActive() {
      if (!this.mm) this.$refs.mmRef.focus()
      else if (this.ss === '') this.$refs.ssRef.focus()
      else this.$refs.msecRef.focus()
    },
    onFocus(e) {
      this.focused = true
      setTimeout(() => e.target && e.target.select(), 0)
    },
    onBlur() {
      setTimeout(() => {
        const active = document.activeElement
        if (![this.$refs.mmRef, this.$refs.ssRef, this.$refs.msecRef].includes(active)) {
          this.focused = false
          if (this.ss) this.ss = this.ss.padStart(2, '0')
          if (this.msec) this.msec = this.msec.padEnd(3, '0')
          this.emitMs()
          this.$emit('blur')
        }
      }, 50)
    }
  }
}
</script>
