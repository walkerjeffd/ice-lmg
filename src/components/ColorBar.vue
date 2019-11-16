<template>
  <svg v-if="scheme"></svg>
</template>

<script>
import * as d3 from 'd3'

import { colorSchemesContinuous } from '@/lib/constants'
import ColorMixin from '../mixins/color'

export default {
  name: 'ColorBar',
  mixins: [ColorMixin],
  props: {
    id: {
      type: String,
      required: true
    },
    scheme: {
      type: String,
      required: true,
      default: 'Viridis',
      validator (value) {
        return colorSchemesContinuous.includes(value)
      }
    },
    invert: {
      type: Boolean,
      default: false
    },
    width: {
      type: Number,
      default: 100
    },
    height: {
      type: Number,
      default: 30
    }
  },
  data () {
    return {
      svg: null
    }
  },
  computed: {
    colorScheme () {
      return this.scheme
    },
    colorInvert () {
      return this.invert
    }
  },
  mounted () {
    this.svg = d3.select(this.$el)
      .attr('width', this.width)
      .attr('height', this.height)

    this.render()
  },
  watch: {
    colorScale () {
      this.render()
    }
  },
  methods: {
    render () {
      this.clear()
      const defs = this.svg.append('defs')

      const linearGradient = defs.append('linearGradient')
        .attr('id', `linear-gradient-${this.id}`)

      linearGradient
        .attr('x1', '0%')
        .attr('y1', '0%')
        .attr('x2', '100%')
        .attr('y2', '0%')

      this.svg.append('rect')
        .attr('width', this.width)
        .attr('height', this.height)
        // .attr('x', this.margins.left)
        .style('fill', `url(#linear-gradient-${this.id}`)

      const delta = 0.2
      const offsets = d3.range(0, 1, delta)
      offsets.push(1)

      linearGradient.selectAll('stop')
        .data(offsets)
        .enter()
        .append('stop')
        .attr('offset', d => d)
        .attr('stop-color', d => this.colorScale(d))
    },
    clear () {
      this.svg.select('defs').remove()
      this.svg.selectAll('rect').remove()
    }
  }
}
</script>
