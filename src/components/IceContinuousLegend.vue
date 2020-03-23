<template>
  <div v-show="variable">
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import * as d3 from 'd3'

import VariableMixin from '../mixins/variable'
import ColorMixin from '../mixins/color'

export default {
  name: 'IceContinuousLegend',
  mixins: [VariableMixin, ColorMixin],
  props: ['id'],
  data () {
    return {
      svg: null,
      margins: {
        left: 10,
        right: 0,
        top: 10,
        bottom: 5
      },
      height: 200,
      width: 150,
      barWidth: 25
    }
  },
  computed: {
    ...mapGetters(['colorScheme', 'colorType', 'colorInvert', 'variable']),
    barHeight () {
      return this.height - this.margins.top - this.margins.bottom
    }
  },
  mounted () {
    this.svg = d3.select(this.$el)
      .append('svg')
      .attr('class', 'ice-continuous-legend')
      .attr('width', `${this.width}px`)
      .attr('height', `${this.height}px`)

    this.render()
  },
  beforeDestroy () {
  },
  watch: {
    variable () {
      this.render()
    },
    colorScale () {
      this.render()
    },
    variableScale () {
      this.render()
    }
  },
  methods: {
    render () {
      this.clear()
      this.draw()
    },
    draw () {
      const defs = this.svg.append('defs')

      const linearGradient = defs.append('linearGradient')
        .attr('id', `linear-gradient-${this.id}`)

      linearGradient
        .attr('x1', '0%')
        .attr('y1', '100%')
        .attr('x2', '0%')
        .attr('y2', '0%')

      this.svg.append('rect')
        .attr('width', this.barWidth)
        .attr('height', this.barHeight)
        .attr('x', this.margins.left)
        .attr('y', this.margins.top)
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

      this.svg.append('g')
        .attr('class', 'legend-axis')
        .attr('transform', `translate(${this.margins.left + this.barWidth}, ${this.margins.top})`)

      const axisScale = this.variableScale
        .copy()
        .rangeRound([this.barHeight, 0])

      const axis = d3.axisRight(axisScale)

      axis.ticks(5, this.variable.formats.map)
      this.svg.select('g.legend-axis')
        .call(axis)

      if (this.variable.scale.clipped[0]) {
        const tick = this.svg.select('g.tick text')
        if (tick.datum() === axisScale.domain()[0]) {
          tick.text(`${tick.text()} or less`)
        }
      }
      if (this.variable.scale.clipped[1]) {
        const ticks = this.svg.selectAll('g.tick text')
          .filter(function () { // eslint-disable-line func-names
            return d3.select(this).text() !== ''
          })
        const tick = d3.select(ticks.nodes()[ticks.size() - 1])
        if (tick.datum() === axisScale.domain()[1]) {
          tick.text(`${tick.text()} or more`)
        }
      }
    },
    clear () {
      this.svg.select('g.legend-axis').remove()
      this.svg.select('defs').remove()
      this.svg.selectAll('rect').remove()
    }
  }
}
</script>

<style>
svg.ice-continuous-legend g.tick > text {
  font-size: 1.2em;
}
</style>
