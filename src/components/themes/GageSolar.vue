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
import { mapGetters } from 'vuex'
import highcharts from 'highcharts'

import IceFeatureContainer from '@/components/IceFeatureContainer'
import IceFeatureBox from '@/components/IceFeatureBox'
import IceGagePropertiesBox from '@/components/IceGagePropertiesBox'

const months = [
  {
    value: 'jan',
    label: 'Jan'
  },
  {
    value: 'feb',
    label: 'Feb'
  },
  {
    value: 'mar',
    label: 'Mar'
  },
  {
    value: 'apr',
    label: 'Apr'
  },
  {
    value: 'may',
    label: 'May'
  },
  {
    value: 'jun',
    label: 'Jun'
  },
  {
    value: 'jul',
    label: 'Jul'
  },
  {
    value: 'aug',
    label: 'Aug'
  },
  {
    value: 'sep',
    label: 'Sep'
  },
  {
    value: 'oct',
    label: 'Oct'
  },
  {
    value: 'nov',
    label: 'Nov'
  },
  {
    value: 'dec',
    label: 'Dec'
  }
]

export default {
  name: 'GageSolar',
  props: ['selected'],
  components: {
    IceFeatureContainer,
    IceFeatureBox,
    IceGagePropertiesBox
  },
  data () {
    return {
      dataset: null,
      charts: {
        solar: {
          chart: {
            height: 300,
            width: 500,
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
            categories: months.map(d => d.label),
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
  computed: {
    ...mapGetters(['theme'])
  },
  watch: {
    dataset () {
      this.updateCharts()
    },
    selected () {
      this.updateDataset()
    }
  },
  mounted () {
    this.updateDataset()
  },
  beforeDestroy () {
    this.charts.solar.series = []
    this.charts.solar.yAxis.plotLines = []
  },
  methods: {
    updateDataset () {
      if (!this.selected) {
        this.dataset = null
        return
      }
      return this.$http.get(`/${this.theme.id}/features/${this.selected.id}.json`)
        .then((response) => {
          this.dataset = response.data
        })
        .catch((err) => {
          console.log('GageSolar: error', err)
        })
    },
    updateCharts () {
      if (!this.dataset) {
        this.charts.solar.series = []
        this.charts.solar.yAxis.plotLines = []
        return
      }

      const values = this.dataset.values

      this.charts.solar.series = [
        {
          name: 'Mean',
          data: months.map(m => values[`dni_${m.value}`])
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
