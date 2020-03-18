<template>
  <v-card elevation-1 class="my-2">
    <v-toolbar dense color="grey lighten-2" flat height="32" class="ice-filter-toolbar">
      <strong>{{ variable.label }} <span v-if="variable.units">({{variable.units}})</span></strong>
      <v-tooltip right max-width="600">
        <template v-slot:activator="{ on }">
          <v-icon class="pl-2" v-on="on" small>mdi-information</v-icon>
        </template>
        {{ variable.description }}
      </v-tooltip>
      <v-spacer></v-spacer>
      <v-tooltip bottom open-delay="300">
        <template v-slot:activator="{ on }">
          <v-btn icon small @click="resetFilter" v-on="on" :disabled="!filter">
            <v-icon small>mdi-refresh</v-icon>
          </v-btn>
        </template>
        <span>Reset Filter</span>
      </v-tooltip>
      <v-btn small icon @click="hide = !hide">
        <v-icon v-if="!hide">mdi-menu-up</v-icon>
        <v-icon v-else>mdi-menu-down</v-icon>
      </v-btn>
      <v-btn small icon @click="close"><v-icon small>mdi-close</v-icon></v-btn>
    </v-toolbar>
    <v-card-text v-if="!hide" class="py-0 ml-n1 caption">
      <div v-if="this.variable.type === 'num'">
        Filter:
        <span v-if="filter">{{valueFormatter(inverseTransform(filter[0]))}} to {{valueFormatter(inverseTransform(filter[1]))}}</span>
        <span v-else>None</span>
      </div>
      <div v-else>
        Filter:
        <span v-if="filter && filter.length === 1">{{filter[0]}}</span>
        <span v-else-if="filter">{{filter.length}} values</span>
        <span v-else>None</span>
      </div>
    </v-card-text>
    <div class="ice-filter-chart" v-show="!hide"></div>
  </v-card>
</template>

<script>
import dc from 'dc'
import * as d3 from 'd3'

import evt from '@/lib/events'
import variableMixin from '@/mixins/variable'
import { getCrossfilter } from '@/lib/crossfilter'

export default {
  name: 'IceFilter',
  mixins: [variableMixin],
  props: {
    variable: {
      type: Object,
      required: false
    }
  },
  data () {
    return {
      filter: null,
      hide: false
    }
  },
  mounted () {
    const width = 460
    const el = this.$el.getElementsByClassName('ice-filter-chart').item(0)
    const interval = (this.transform(this.variable.scale.domain[1]) - this.transform(this.variable.scale.domain[0])) / 30
    const xf = getCrossfilter()

    if (this.variable.type === 'num') {
      const dim = xf.dimension(d => this.transform(d[this.variable.id]))
      const group = dim.group(d => Math.floor(d / interval) * interval).reduceCount()
      const margins = { top: 5, right: 40, bottom: 20, left: 50 }

      this.chart = dc.barChart(el)
        .width(width)
        .height(120)
        .margins(margins)
        .dimension(dim)
        .group(group)
        .elasticY(true)
        .transitionDelay(0)
        .x(d3.scaleLinear().domain(this.variable.scale.domain.map(this.transform)))
        .on('filtered', () => {
          const filter = this.chart.dimension().currentFilter()
          if (filter) {
            this.filter = [filter[0], filter[1]]
          } else {
            this.filter = undefined
          }
          evt.$emit('xf:filter')
          evt.$emit('map:render')
        })

      this.chart.xUnits(() => 30)

      this.chart.xAxis()
        .tickFormat(d => this.filterFormatter(this.inverseTransform(d)))

      this.chart.yAxis().ticks(4)
    } else {
      const margins = { top: 0, right: 40, bottom: 30, left: 15 }
      const dim = xf.dimension(d => d[this.variable.id])
      const group = dim.group().reduceCount()
      const count = this.variable.scale.domain.length
      const gap = 5
      const barHeight = 20
      const height = margins.top + margins.bottom + barHeight * count + gap * (count + 1)

      this.chart = dc.rowChart(el)
        .width(width)
        .height(height)
        .margins(margins)
        .dimension(dim)
        .group(group)
        .elasticX(true)
        .ordinalColors(d3.range(this.variable.scale.domain.length).map(d => d3.schemeCategory10[0]))
        .transitionDelay(0)
        .transitionDuration(0)
        .gap(gap)
        // .fixedBarHeight(20)
        .ordering(d => this.variable.scale.domain.findIndex(v => v.id === d.key))
        .label(function (d) {
          return d.key
        })
        .on('filtered', () => {
          const filter = this.chart.filters()
          if (filter && filter.length > 0) {
            this.filter = filter
          } else {
            this.filter = undefined
          }
          evt.$emit('xf:filter')
          evt.$emit('map:render')
        })
        .on('renderlet', (chart) => {
          chart.selectAll('g.row')
            .each(function () {
              const barWidth = +d3.select(this).select('rect').attr('width')
              const textEl = d3.select(this).select('text')
              const textWidth = textEl.node().getBBox().width
              if (barWidth < (10 + textWidth)) {
                textEl
                  .style('fill', 'black')
                  .attr('transform', `translate(${barWidth - 5},0)`)
              } else {
                textEl
                  .style('fill', null)
              }
            })
          chart.select('.axis').selectAll('g.tick:not(:first-of-type) line.grid-line').style('display', 'none')
        })
    }

    this.chart.render()

    evt.$on('filter:render', this.render)
  },
  beforeDestroy () {
    if (this.chart) {
      this.chart.dimension().dispose()
      dc.chartRegistry.deregister(this.chart)
      dc.renderAll()
    }
    evt.$off('filter:render', this.render)
    evt.$emit('xf:filter')
    evt.$emit('map:render')
  },
  methods: {
    render () {
      // console.log('filter:render')
      this.chart && this.chart.render()
    },
    resetFilter () {
      this.chart && this.chart.filterAll()
      dc.redrawAll()
    },
    close () {
      this.$emit('close')
    }
  }
}
</script>

<style>
.dc-chart {
  float: none !important;
}
.ice-filter-toolbar > .v-toolbar__content {
  padding-left: 12px;
  padding-right: 12px;
}
</style>
