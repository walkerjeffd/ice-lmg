<template>
  <ice-feature-container v-if="selected" @close="$emit('close')">
    <template v-slot:title>
      Gage: {{selected.id}}
    </template>

    <div v-if="dataset">
      <ice-gage-properties-box :properties="dataset.properties"></ice-gage-properties-box>

      <ice-feature-box>
        <template v-slot:title>Streamflow Quantiles by Decade</template>
        <highcharts class="chart" :options="charts.quantiles"></highcharts>
      </ice-feature-box>
    </div>
    <div v-else>
      Loading...
    </div>
  </ice-feature-container>
</template>

<script>
import { mapGetters } from 'vuex'

import IceFeatureContainer from '@/components/IceFeatureContainer'
import IceFeatureBox from '@/components/IceFeatureBox'
import IceGagePropertiesBox from '@/components/IceGagePropertiesBox'

export default {
  name: 'GageQstat',
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
        quantiles: {
          chart: {
            height: 300,
            marginTop: 20,
            type: 'line'
          },
          title: {
            text: null
          },
          legend: {
            enabled: false
          },
          tooltip: {
            valueDecimals: 1,
            valueSuffix: ' m3/s',
            shared: true,
            headerFormat: '<span style="font-size: 10px">Quantile: {point.key}</span><br/>'
          },
          xAxis: {
            type: 'linear',
            title: {
              text: 'Quantile'
            }
          },
          yAxis: {
            type: 'logarithmic',
            title: {
              text: 'Streamflow (m3/s)'
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
    this.charts.quantiles.series = []
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
          console.log('GageQstat: error', err)
        })
    },
    updateCharts () {
      if (!this.dataset) {
        this.charts.quantiles.series = []
        return
      }

      const quantiles = [
        '0.02',
        '0.05',
        '0.1',
        '0.2',
        '0.5',
        '01',
        '02',
        '05',
        '10',
        '20',
        '25',
        '30',
        '40',
        '50',
        '60',
        '70',
        '75',
        '80',
        '90',
        '95',
        '98',
        '99',
        '99.5',
        '99.8',
        '99.9',
        '99.95',
        '99.98'
      ]

      const values = this.dataset.values
      const quantileSeries = values.map(d => ({
        decade: d.decade,
        quantiles: quantiles.map(q => ({
          x: +q,
          y: d[`f${q}`]
        }))
      }))

      this.charts.quantiles.series = quantileSeries.map(d => ({
        name: `${d.decade}s`,
        data: d.quantiles,
        type: 'line',
        marker: {
          enabled: true,
          fillColor: '#FFFFFF',
          lineWidth: 1,
          lineColor: null,
          symbol: 'circle',
          radius: 2
        }
      }))
    }
  }
}
</script>
