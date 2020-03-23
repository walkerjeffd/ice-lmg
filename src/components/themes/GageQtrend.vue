<template>
  <ice-feature-container v-if="selected" @close="$emit('close')">
    <template v-slot:title>
      Selected Gage: {{selected.id}}
    </template>

    <div v-if="dataset">
      <ice-gage-properties-box :properties="dataset.properties"></ice-gage-properties-box>
      <ice-feature-box>
        <template v-slot:title>Settings</template>
        <v-card-text>
          <v-checkbox
            v-model="signif"
            label="Show Significant Trend Results Only (p < 0.05)"
            hide-details
            class="mt-0">
          </v-checkbox>
        </v-card-text>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Mann-Kendall: Monthly</template>
        <highcharts class="chart" :options="charts.month"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Mann-Kendall: Seasonal</template>
        <highcharts class="chart" :options="charts.season"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Mann-Kendall: By Quantile</template>
        <highcharts class="chart" :options="charts.quantile"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Quantile-Kendall: Annual</template>
        <highcharts class="chart" :options="charts.qkAnnual"></highcharts>
      </ice-feature-box>
    </div>
    <div v-else>
      Loading...
    </div>
  </ice-feature-container>
</template>

<script>
import { range, format } from 'd3'

import themeSelect from '@/mixins/themeSelect'

const seasons = ['Spring', 'Summer', 'Fall', 'Winter']
const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
const quantiles = range(0, 110, 10)

export default {
  name: 'GageQtrend',
  mixins: [themeSelect],
  data () {
    return {
      signif: false,
      charts: {
        season: {
          chart: {
            height: 300,
            width: 450,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          tooltip: {
            valueDecimals: 1,
            valueSuffix: ' m3/s/yr',
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
                text: 'Trend Slope (m3/s/yr)'
              }
            }
          ],
          series: []
        },
        month: {
          chart: {
            height: 300,
            width: 450,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          tooltip: {
            valueDecimals: 1,
            valueSuffix: ' m3/s/yr',
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
                text: 'Trend Slope (m3/s/yr)'
              }
            }
          ],
          series: []
        },
        quantile: {
          chart: {
            height: 300,
            width: 450,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          tooltip: {
            valueDecimals: 1,
            valueSuffix: ' m3/s/yr',
            shared: true,
            headerFormat: '<span style="font-size: 10px">Quantile: {point.key}</span><br/>'
          },
          xAxis: {
            title: {
              text: 'Quantile (%)'
            }
          },
          yAxis: [
            {
              title: {
                text: 'Trend Slope (m3/s/yr)'
              }
            }
          ],
          series: []
        },
        qkAnnual: {
          chart: {
            height: 300,
            width: 450,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          tooltip: {
            valueDecimals: 1,
            valueSuffix: ' %/yr',
            shared: true,
            headerFormat: '<span style="font-size: 10px">Rank: {point.x}</span><br/>'
          },
          xAxis: {
            title: {
              text: 'Rank'
            }
          },
          yAxis: [
            {
              title: {
                text: 'Trend Slope (%/yr)'
              }
            }
          ],
          series: []
        }
      }
    }
  },
  watch: {
    signif () {
      this.updateCharts()
    }
  },
  methods: {
    updateCharts () {
      this.clearCharts()

      this.charts.season.series = this.values
        .filter(d => d.signif === this.signif)
        .map(d => ({
          name: `${d.decade}s`,
          data: seasons.map(season => d[`mk_${season.toLowerCase()}_slope`]),
          type: 'line',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 3
          }
        }))

      this.charts.month.series = this.values
        .filter(d => d.signif === this.signif)
        .map(d => ({
          name: `${d.decade}s`,
          data: months.map(month => d[`mk_${month.toLowerCase()}_slope`]),
          type: 'line',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 3
          }
        }))

      this.charts.quantile.series = this.values
        .filter(d => d.signif === this.signif)
        .map(d => ({
          name: `${d.decade}s`,
          data: quantiles.map(quantile => [quantile, d[`mk_q${format('02d')(quantile)}_slope`]]),
          type: 'line',
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 3
          }
        }))

      this.charts.qkAnnual.series = this.values
        .filter(d => d.signif === this.signif)
        .map(d => ({
          name: `${d.decade}s`,
          data: d.qk_annual_slopepct,
          type: 'line'
        }))
    }
  }
}
</script>
