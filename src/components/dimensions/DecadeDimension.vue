<template>
  <div>
    Select decade...
    <v-slider
      v-model="value"
      :tick-labels="labels"
      :max="labels.length - 1"
      step="1"
      ticks="always"
      tick-size="3"
      class="px-4">
    </v-slider>
  </div>
</template>

<script>
import { getCrossfilter } from '@/lib/crossfilter'
import evt from '@/lib/events'
import { mapActions } from 'vuex'

export default {
  name: 'DecadeDimension',
  data () {
    return {
      value: 5,
      labels: ['1950s', '1960s', '1970s', '1980s', '1990s', '2000s']
    }
  },
  computed: {
    decadeValue () {
      return typeof this.value === 'number' ? (1950 + this.value * 10).toString() : null
    }
  },
  watch: {
    value () {
      this.update()
    }
  },
  mounted () {
    const xf = getCrossfilter()
    this.dim = xf.dimension(d => d.decade)
    evt.$on('theme:set', this.update)
  },
  beforeDestroy () {
    evt.$off('theme:set', this.update)
    this.dim.dispose()
  },
  methods: {
    ...mapActions(['setDecade']),
    update () {
      if (this.decadeValue) {
        this.dim.filterExact(this.decadeValue)
        this.setDecade(this.decadeValue)
      } else {
        this.dim.filterAll()
        this.setDecade(null)
      }
      evt.$emit('map:render')
      evt.$emit('xf:filter')
      evt.$emit('filter:render')
    }
  }
}
</script>
