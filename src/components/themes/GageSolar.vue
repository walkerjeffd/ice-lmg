<template>
  <ice-feature-container v-if="selected" @close="$emit('close')">
    <template v-slot:title>
      Selected Gage: {{selected.id}}
    </template>

    <div v-if="dataset">
      <ice-gage-properties-box :properties="dataset.properties"></ice-gage-properties-box>

      <ice-feature-box>
        <template v-slot:title>Monthly Solar Radiation</template>
        <highcharts class="chart" :options="charts.solar"></highcharts>
      </ice-feature-box>
    </div>
    <div v-else>
      Loading...
    </div>
  </ice-feature-container>
</template>

<script>
import highcharts from 'highcharts'

import themeSelect from '@/mixins/themeSelect'

const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']

export default {
  name: 'GageSolar',
  mixins: [themeSelect],
  data () {
    return {
      charts: {
        solar: {
          chart: {
            height: 300,
            width: 450,
            marginTop: 20,
            type: 'column'
          },
          title: {
            text: null
          },
          legend: {
            enabled: false
          },
          tooltip: {
            valueDecimals: 1,
            valueSuffix: ' kWh/m2/day',
            shared: true
          },
          xAxis: {
            type: 'category',
            categories: months,
            title: {
              text: 'Month'
            }
          },
          yAxis: {
            title: {
              text: 'kWh/m2/day'
            }
          },
          series: []
        }
      }
    }
  },
  beforeDestroy () {
    this.charts.solar.yAxis.plotLines = []
  },
  methods: {
    updateCharts () {
      this.clearCharts()
      this.charts.solar.yAxis.plotLines = []

      if (!this.dataset) return

      this.charts.solar.series = [
        {
          name: 'Mean',
          data: months.map(m => this.dataset.values[`dni_${m.toLowerCase()}`])
        }
      ]
      this.charts.solar.yAxis.plotLines = [{
        value: this.dataset.values.dni_ann,
        color: 'red',
        dashStyle: 'shortdash',
        width: 2,
        label: {
          text: `Annual Avg = ${highcharts.numberFormat(this.dataset.values.dni_ann, 1, '.', ',')} kWh/m2/day`
        },
        zIndex: 4
      }]
    }
  }
}
</script>
