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
        left: 20,
        right: 20
      },
      width: 500,
      height: 30,
      axisHeight: 20
    }
  },
  computed: {
    ...mapGetters(['colorScheme', 'colorType', 'colorInvert', 'variable'])
  },
  mounted () {
    this.svg = d3.select(this.$el)
      .append('svg')
      .attr('preserveAspectRatio', 'xMinYMin meet')
      .attr('viewBox', `0 0 ${this.width} ${this.height + this.axisHeight}`)

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
      this.renderContinuous()
    },
    renderContinuous () {
      const defs = this.svg.append('defs')

      const linearGradient = defs.append('linearGradient')
        .attr('id', `linear-gradient-${this.id}`)

      linearGradient
        .attr('x1', '0%')
        .attr('y1', '0%')
        .attr('x2', '100%')
        .attr('y2', '0%')

      this.svg.append('rect')
        .attr('width', this.width - this.margins.left - this.margins.right)
        .attr('height', this.height)
        .attr('x', this.margins.left)
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
        .attr('transform', `translate(${this.margins.left}, ${this.height})`)

      this.renderContinuousAxis()
    },
    renderContinuousAxis () {
      if (!this.variable) return

      const axisScale = this.variableScale
        .copy()
        .rangeRound([0, +this.width - this.margins.left - this.margins.right])

      const axis = d3.axisBottom(axisScale)

      axis.ticks(10, this.variable.formats.axis)
      this.svg.select('g.legend-axis')
        .call(axis)

      if (this.variable.extent[0] < axisScale.domain()[0]) {
        const tick = this.svg.select('g.tick text')
        if (tick.datum() === axisScale.domain()[0]) {
          tick.text(`< ${tick.text()}`)
        }
      }
      if (this.variable.extent[1] > axisScale.domain()[1]) {
        const ticks = this.svg.selectAll('g.tick text')
          .filter(function () { // eslint-disable-line func-names
            return d3.select(this).text() !== ''
          })
        const tick = d3.select(ticks.nodes()[ticks.size() - 1])
        if (tick.datum() === axisScale.domain()[1]) {
          tick.text(`> ${tick.text()}`)
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
g.legend-axis path {
  fill: none;
}
</style>
