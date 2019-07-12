<template>
  <ice-feature-container v-if="selected" @close="$emit('close')">
    <template v-slot:title>
      Gage: {{selected.id}}
    </template>

    <div v-if="dataset">
      <ice-gage-properties-box :properties="dataset.properties"></ice-gage-properties-box>
      <ice-feature-box>
        <template v-slot:title>Options</template>
        <v-card-text class="py-0">
          <v-radio-group v-model="maxPVal" row label="Significance Level:">
            <v-radio label="p <= 0.05" value="0.05"></v-radio>
            <v-radio label="p <= 0.10" value="0.10"></v-radio>
            <v-radio label="Any p-value" value="1"></v-radio>
          </v-radio-group>
        </v-card-text>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Mann-Kendall: Seasonal</template>
        <highcharts class="chart" :options="charts.season"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Mann-Kendall: Monthly</template>
        <highcharts class="chart" :options="charts.month"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Mann-Kendall: By Quantile</template>
        <highcharts class="chart" :options="charts.quantile"></highcharts>
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

const seasons = ['Spring', 'Summer', 'Fall', 'Winter']
const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
const quantiles = ['Q00', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'Q100']

export default {
  name: 'GageQtrend',
  props: ['selected'],
  components: {
    IceFeatureContainer,
    IceFeatureBox,
    IceGagePropertiesBox
  },
  data () {
    return {
      dataset: null,
      maxPVal: '1',
      charts: {
        season: {
          chart: {
            height: 300,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          tooltip: {
            shared: true,
            headerFormat: '<span style="font-size: 10px">Season: {point.key}</span><br/>'
          },
          xAxis: {
            type: 'category',
            categories: seasons,
            max: seasons.length - 1,
            title: {
              text: 'Season'
            }
          },
          yAxis: [
            {
              title: {
                text: 'm3/s/yr'
              }
            }
          ],
          series: []
        },
        month: {
          chart: {
            height: 300,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          tooltip: {
            shared: true,
            headerFormat: '<span style="font-size: 10px">Month: {point.key}</span><br/>'
          },
          xAxis: {
            type: 'category',
            categories: months,
            title: {
              text: 'Month'
            }
          },
          yAxis: [
            {
              title: {
                text: 'm3/s/yr'
              }
            }
          ],
          series: []
        },
        quantile: {
          chart: {
            height: 300,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          tooltip: {
            shared: true,
            headerFormat: '<span style="font-size: 10px">Quantile: {point.key}</span><br/>'
          },
          xAxis: {
            type: 'category',
            categories: quantiles,
            title: {
              text: 'Quantile'
            }
          },
          yAxis: [
            {
              title: {
                text: 'm3/s/yr'
              }
            }
          ],
          series: []
        }
      }
    }
  },
  computed: {
    ...mapGetters(['theme', 'variableById'])
  },
  mounted () {
    this.fetchData()
  },
  watch: {
    selected () {
      this.fetchData()
    },
    dataset () {
      this.updateCharts()
    },
    maxPVal () {
      this.updateCharts()
    }
  },
  methods: {
    fetchData () {
      if (!this.selected) {
        this.dataset = null
        return
      }
      this.$http.get(`/${this.theme.id}/features/${this.selected.id}.json`)
        .then((response) => {
          this.dataset = response.data
        })
        .catch((err) => {
          console.log('GageQtrend: error', err)
          this.dataset = null
          this.loading = false
        })
    },
    clearCharts () {
      this.charts.season.series = []
      this.charts.month.series = []
      this.charts.quantile.series = []
    },
    updateCharts () {
      if (!this.dataset) this.clearCharts()
      this.charts.season.series = this.dataset.values.map(d => ({
        name: `${d.decade}s`,
        data: seasons.map(season => ({
          y: d.season[season].mk_pval <= +this.maxPVal ? d.season[season].mk_slope : null,
          pval: d.season[season].mk_pval
        })),
        type: 'line',
        connectNulls: true,
        marker: {
          enabled: true,
          fillColor: '#FFFFFF',
          lineWidth: 1,
          lineColor: null,
          symbol: 'circle',
          radius: 3
        },
        tooltip: {
          pointFormatter: function () {
            return `<span style="color:${this.color}">●</span> ${this.series.name}: <b>${highcharts.numberFormat(this.y, 1, '.', ',')}</b> m3/s/yr (p = <b>${highcharts.numberFormat(this.pval, 3, '.', ',')}</b>)<br/>`
          }
        }
      }))

      this.charts.month.series = this.dataset.values.map(d => ({
        name: `${d.decade}s`,
        data: months.map(month => ({
          y: d.month[month].mk_pval <= +this.maxPVal ? d.month[month].mk_slope : null,
          pval: d.month[month].mk_pval
        })),
        type: 'line',
        connectNulls: true,
        marker: {
          enabled: true,
          fillColor: '#FFFFFF',
          lineWidth: 1,
          lineColor: null,
          symbol: 'circle',
          radius: 3
        },
        tooltip: {
          pointFormatter: function () {
            return `<span style="color:${this.color}">●</span> ${this.series.name}: <b>${highcharts.numberFormat(this.y, 1, '.', ',')}</b> m3/s/yr (p = <b>${highcharts.numberFormat(this.pval, 3, '.', ',')}</b>)<br/>`
          }
        }
      }))

      this.charts.quantile.series = this.dataset.values.map(d => ({
        name: `${d.decade}s`,
        data: quantiles.map(quantile => ({
          y: d.quantile[quantile].mk_pval <= +this.maxPVal ? d.quantile[quantile].mk_slope : null,
          pval: d.quantile[quantile].mk_pval
        })),
        type: 'line',
        connectNulls: true,
        marker: {
          enabled: true,
          fillColor: '#FFFFFF',
          lineWidth: 1,
          lineColor: null,
          symbol: 'circle',
          radius: 3
        },
        tooltip: {
          pointFormatter: function () {
            return `<span style="color:${this.color}">●</span> ${this.series.name}: <b>${highcharts.numberFormat(this.y, 1, '.', ',')}</b> m3/s/yr (p = <b>${highcharts.numberFormat(this.pval, 3, '.', ',')}</b>)<br/>`
          }
        }
      }))
    }
  }
}
</script>
