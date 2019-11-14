<template>
  <div>
    <v-checkbox
      v-model="value"
      label="Show Significant Trend Results Only (p < 0.05)"
      hide-details>
    </v-checkbox>
  </div>
</template>

<script>
import { getCrossfilter } from '@/lib/crossfilter'
import evt from '@/lib/events'

export default {
  name: 'SignifDimension',
  data () {
    return {
      value: false
    }
  },
  watch: {
    value () {
      this.update()
    }
  },
  mounted () {
    const xf = getCrossfilter()
    this.dim = xf.dimension(d => d.signif)
    evt.$on('theme:set', this.update)
  },
  beforeDestroy () {
    this.dim.dispose()
  },
  methods: {
    update () {
      console.log('signif-dimension: update()', this.value)
      this.dim.filterExact(this.value)
      evt.$emit('map:render')
      evt.$emit('xf:filter')
      evt.$emit('filter:render')
    }
  }
}
</script>
