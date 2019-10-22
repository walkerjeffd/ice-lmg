<template>
  <ice-feature-container v-if="selected" @close="$emit('close')">
    <template v-slot:title>
      HUC12: {{selected.properties.huc12}}
    </template>

    <div v-if="dataset">
      <ice-huc12-properties-box :properties="dataset.properties"></ice-huc12-properties-box>
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
import IceHuc12PropertiesBox from '@/components/IceHuc12PropertiesBox'

export default {
  name: 'Huc12Qquantile',
  props: ['selected'],
  components: {
    IceFeatureContainer,
    IceFeatureBox,
    IceHuc12PropertiesBox
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
            // enabled: false
          },
          tooltip: {
            valueDecimals: 1,
            valueSuffix: ' m3/s',
            shared: true,
            headerFormat: '<span style="font-size: 10px">Quantile: {point.key}%</span><br/>'
          },
          xAxis: {
            type: 'linear',
            title: {
              text: 'Quantile (%)'
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
  mounted () {
    this.updateDataset()
  },
  watch: {
    dataset () {
      this.updateCharts()
    },
    selected () {
      this.updateDataset()
    }
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
          console.log('Huc12Qquantile: error', err)
        })
    },
    updateCharts () {
      if (!this.dataset) {
        this.charts.quantiles.series = []
        return
      }

      const quantiles = [
        '0.03',
        '0.5',
        '05',
        '10',
        '20',
        '30',
        '40',
        '50',
        '60',
        '70',
        '80',
        '90',
        '95',
        '99.5',
        '99.97'
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
