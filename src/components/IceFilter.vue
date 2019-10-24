<template>
  <v-card elevation-1 class="my-2">
    <!-- <h4>{{ variable.label }}</h4> -->
    <v-toolbar dense color="grey lighten-2" flat height="32" class="ice-filter-toolbar">
      <strong>{{ variable.label }} <span v-if="variable.units">({{variable.units}})</span></strong>
      <v-tooltip right max-width="600">
        <template v-slot:activator="{ on }">
          <v-icon class="pl-2" v-on="on" small>mdi-information</v-icon>
        </template>
        {{ variable.description }}
      </v-tooltip>
      <v-spacer></v-spacer>
      <v-btn small icon @click="hide = !hide">
        <v-icon v-if="!hide">mdi-menu-up</v-icon>
        <v-icon v-else>mdi-menu-down</v-icon>
      </v-btn>
      <v-btn small icon @click="close"><v-icon small>mdi-close</v-icon></v-btn>
    </v-toolbar>
    <v-card-text v-if="!hide">
      Filter Range:
      <span v-if="filter">{{textFormatter(inverseTransform(filter[0]))}} - {{textFormatter(inverseTransform(filter[1]))}} (<span @click="resetFilter">reset</span>)</span>
      <span v-else>None</span>
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
  calculated () {

  },
  mounted () {
    const interval = (this.transform(this.variable.scale.domain[1]) - this.transform(this.variable.scale.domain[0])) / 30
    const xf = getCrossfilter()
    const dim = xf.dimension(d => this.transform(d[this.variable.id]))
    const group = dim.group(d => Math.floor(d / interval) * interval).reduceCount()

    this.chart = dc.barChart(this.$el.getElementsByClassName('ice-filter-chart').item(0))
      .width(550)
      .height(200)
      .margins({ top: 10, right: 50, bottom: 30, left: 40 })
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
      .tickFormat(d => this.axisFormatter(this.inverseTransform(d)))

    this.chart.render()

    evt.$on('filter:render', this.render)
  },
  beforeDestroy () {
    this.chart.dimension().dispose()
    dc.chartRegistry.deregister(this.chart)
    dc.renderAll()
    evt.$off('filter:render', this.render)
    evt.$emit('xf:filter')
    evt.$emit('map:render')
  },
  methods: {
    render () {
      console.log('filter:render')
      this.chart.render()
    },
    resetFilter () {
      this.chart.dimension().filterAll()
    },
    close () {
      this.$emit('close')
    }
  }
}
</script>

<style>
.ice-filter-toolbar > .v-toolbar__content {
  padding-left: 12px;
  padding-right: 12px;
}
</style>
