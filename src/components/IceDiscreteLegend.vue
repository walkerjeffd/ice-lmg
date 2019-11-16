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
  name: 'IceDiscreteLegend',
  mixins: [VariableMixin, ColorMixin],
  props: ['id'],
  data () {
    return {
      svg: null,
      margins: {
        left: 10,
        top: 0,
        right: 20,
        bottom: 20
      },
      width: 500,
      itemHeight: 15,
      itemRadius: 5,
      itemPadding: 5
    }
  },
  computed: {
    ...mapGetters(['colorScheme', 'colorType', 'colorInvert', 'variable']),
    domain () {
      return this.colorScale ? this.colorScale.domain() : []
    },
    range () {
      return this.colorScale ? this.colorScale.range() : []
    }
  },
  mounted () {
    this.svg = d3.select(this.$el)
      .append('svg')
      .attr('preserveAspectRatio', 'xMinYMin meet')

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
      this.renderDiscrete()
    },
    renderDiscrete () {
      this.svg.attr('viewBox', `0 0 ${this.width} ${this.itemHeight * this.domain.length}`)

      this.container = this.svg
        .append('g')
        .attr('transform', `translate(${this.margins.left}, ${this.margins.top})`)

      const items = this.container.selectAll('g')
        .data(this.domain, d => d)
        .enter()
        .append('g')
        .attr('class', 'tame-legend-color-discrete-item')

      items.append('circle')
        .attr('cx', this.itemRadius)
        .attr('cy', (d, i) => this.itemRadius + (this.itemRadius * 2 + this.itemPadding) * i)
        .attr('r', this.itemRadius)
        .attr('fill', (d) => {
          return this.colorScale(d)
        })

      items.append('text')
        .attr('x', this.itemRadius * 2 + 10)
        .attr('y', (d, i) => this.itemRadius + (this.itemRadius * 2 + this.itemPadding) * i)
        .attr('dy', '0.35em')
        .text(d => d)
    },
    clear () {
      this.svg && this.svg.select('g').remove()
    }
  }
}
</script>

<style>
g.legend-axis path {
  fill: none;
}
</style>
