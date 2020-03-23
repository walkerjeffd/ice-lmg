<template>
  <ice-feature-container v-if="selected" @close="$emit('close')">
    <template v-slot:title>
      Selected Gage: {{selected.id}}
    </template>

    <div v-if="dataset">
      <ice-gage-properties-box :properties="dataset.properties"></ice-gage-properties-box>
      <ice-feature-box>
        <template v-slot:title>Basin Characteristics</template>
        <v-list dense>
          <v-list-item v-for="variableId in tables.cov.fields" :key="variableId">
            <v-list-item-content class="align-start" width="20">{{ variableById(variableId).label }}:</v-list-item-content>
            <v-list-item-content class="align-end">{{ variableFormatter(variableId)(dataset.values.cov[0][variableId]) }} {{ variableById(variableId).units }}</v-list-item-content>
          </v-list-item>
        </v-list>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Hydro-geologic Classifications</template>
        <v-list dense>
          <v-list-item v-for="variableId in tables.cat.fields" :key="variableId">
            <v-list-item-content class="align-start" width="20">{{ variableById(variableId).label }}:</v-list-item-content>
            <v-list-item-content class="align-end">{{ variableFormatter(variableId)(dataset.values.cov[0][variableId]) }}</v-list-item-content>
          </v-list-item>
        </v-list>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Land Use</template>
        <highcharts class="chart" :options="charts.landUse"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Annual Precipitation</template>
        <highcharts class="chart" :options="charts.ppt"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Annual Air Temperature</template>
        <highcharts class="chart" :options="charts.temp"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Streamflow Statistics</template>
        <highcharts class="chart" :options="charts.qStat"></highcharts>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Streamflow Trends (Mann-Kendall by Season)</template>
        <div v-if="values && values.qtrend.mk && values.qtrend.mk.length > 0">
          <v-card-text>
            <v-checkbox
              v-model="signif.mk"
              label="Significant Trend Results Only (p < 0.05)"
              hide-details
              class="mt-0">
            </v-checkbox>
          </v-card-text>
          <highcharts class="chart" :options="charts.mkSeason"></highcharts>
        </div>
        <div v-else>
          <v-card-text>
            Trend results not available for selected gage
          </v-card-text>
        </div>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Streamflow Trends (Annual Quantile-Kendall)</template>
        <div v-if="values && values.qtrend.qk && values.qtrend.qk.length > 0">
          <v-card-text>
            <v-checkbox
              v-model="signif.qk"
              label="Significant Trend Results Only (p < 0.05)"
              hide-details
              class="mt-0">
            </v-checkbox>
          </v-card-text>
          <highcharts class="chart" :options="charts.qkAnnual"></highcharts>
        </div>
        <div v-else>
          <v-card-text>
            Trend results not available for selected gage
          </v-card-text>
        </div>
      </ice-feature-box>
    </div>
    <div v-else>
      Loading...
    </div>
  </ice-feature-container>
</template>

<script>
import themeSelect from '@/mixins/themeSelect'

const seasons = ['Spring', 'Summer', 'Fall', 'Winter']

export default {
  name: 'GagePrimary',
  mixins: [themeSelect],
  data () {
    return {
      signif: {
        mk: false,
        qk: false
      },
      tables: {
        cov: {
          fields: [
            'basin_area',
            'bfi'
          ]
        },
        cat: {
          fields: [
            'cat_aquifers',
            'cat_ecol3',
            'cat_physio'
          ]
        }
      },
      charts: {
        landUse: {
          chart: {
            height: 300,
            width: 450,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          legend: {
            enabled: true
          },
          tooltip: {
            valueDecimals: 0,
            valueSuffix: ' %',
            shared: true
          },
          xAxis: {
            type: 'category',
            categories: ['1950s', '1960s', '1970s', '1980s', '1990s', '2000s'],
            title: {
              text: 'Decade'
            }
          },
          yAxis: [
            {
              title: {
                text: '%'
              }
            }
          ],
          series: []
        },
        ppt: {
          chart: {
            height: 200,
            width: 450,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          legend: {
            enabled: false
          },
          tooltip: {
            valueDecimals: 0,
            valueSuffix: ' mm',
            shared: true
          },
          xAxis: {
            type: 'category',
            categories: ['1950s', '1960s', '1970s', '1980s', '1990s', '2000s'],
            title: {
              text: 'Decade'
            }
          },
          yAxis: [
            {
              title: {
                text: 'mm'
              }
            }
          ],
          series: []
        },
        temp: {
          chart: {
            height: 200,
            width: 450,
            marginTop: 20,
            marginLeft: 70
          },
          title: {
            text: null
          },
          legend: {
            enabled: false
          },
          tooltip: {
            valueDecimals: 1,
            valueSuffix: ' degC',
            shared: true
          },
          xAxis: {
            type: 'category',
            categories: ['1950s', '1960s', '1970s', '1980s', '1990s', '2000s'],
            title: {
              text: 'Decade'
            }
          },
          yAxis: [
            {
              title: {
                text: 'degC'
              }
            }
          ],
          series: []
        },
        qStat: {
          chart: {
            height: 300,
            width: 450,
            marginTop: 20,
            type: 'line'
          },
          title: {
            text: null
          },
          tooltip: {
            valueDecimals: 2,
            valueSuffix: ' m3/s',
            shared: true
          },
          xAxis: {
            type: 'category',
            categories: ['1950s', '1960s', '1970s', '1980s', '1990s', '2000s'],
            title: {
              text: 'Decade'
            }
          },
          yAxis: {
            type: 'logarithmic',
            title: {
              text: 'Streamflow (m3/s)'
            }
          },
          series: []
        },
        mkSeason: {
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
    'signif.mk' () {
      this.updateCharts()
    },
    'signif.qk' () {
      this.updateCharts()
    }
  },
  methods: {
    updateCharts () {
      this.clearCharts()

      if (!this.values || this.values.length === 0) return

      this.charts.landUse.series = [
        {
          name: 'Developed',
          data: this.values.cov.map(d => d.developed),
          type: 'line'
        },
        {
          name: 'Hay/Pasture',
          data: this.values.cov.map(d => d.hay_pasture),
          type: 'line'
        },
        {
          name: 'Cultivated Cropland',
          data: this.values.cov.map(d => d.cultivated_cropland),
          type: 'line'
        },
        {
          name: 'Grassland',
          data: this.values.cov.map(d => d.grassland),
          type: 'line'
        },
        {
          name: 'Shrubland',
          data: this.values.cov.map(d => d.shrubland),
          type: 'line'
        },
        {
          name: 'Total Forest',
          data: this.values.cov.map(d => d.total_forest),
          type: 'line'
        },
        {
          name: 'Total Wetland',
          data: this.values.cov.map(d => d.total_wetland),
          type: 'line'
        },
        {
          name: 'Open Water',
          data: this.values.cov.map(d => d.water),
          type: 'line'
        }
      ]
      this.charts.ppt.series = [
        {
          name: 'Mean Precip',
          data: this.values.cov.map(d => d.ppt_mean),
          type: 'line'
        }
      ]

      this.charts.temp.series = [
        {
          name: 'Mean Air Temp',
          data: this.values.cov.map(d => d.temp_mean),
          type: 'line'
        }
      ]

      this.charts.qStat.series = [
        {
          name: 'Maximum',
          data: this.values.qstat.map(d => d.q_max),
          type: 'line'
        },
        {
          name: 'Mean',
          data: this.values.qstat.map(d => d.q_L1_mean),
          type: 'line'
        },
        {
          name: 'Median',
          data: this.values.qstat.map(d => d.q_f50),
          type: 'line'
        },
        {
          name: 'Median (Non-Zero)',
          data: this.values.qstat.map(d => d.q_median_nonzero),
          type: 'line'
        },
        {
          name: 'Minimum',
          data: this.values.qstat.map(d => d.q_min),
          type: 'line'
        }
      ]

      this.charts.mkSeason.series = this.values.qtrend.mk
        .filter(d => d.signif === this.signif.mk)
        .map(d => ({
          name: `${d.decade}s`,
          data: seasons.map(season => d[`mk_${season.toLowerCase()}_slope`]),
          type: 'line',
          connectNulls: true,
          marker: {
            enabled: true,
            fillColor: '#FFFFFF',
            lineWidth: 1,
            lineColor: null,
            symbol: 'circle',
            radius: 3
          }
        }))

      this.charts.qkAnnual.series = this.values.qtrend.qk
        .filter(d => d.signif === this.signif.qk)
        .map(d => ({
          name: `${d.decade}s`,
          data: d.qk_annual_slopepct,
          type: 'line'
        }))
    }
  }
}
</script>
