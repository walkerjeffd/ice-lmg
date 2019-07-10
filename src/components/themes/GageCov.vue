<template>
  <v-card v-if="selected">
    <v-card-title primary-title>
      <h3 class="headline mb-0">Selected Gage: {{selected.id}}</h3>
    </v-card-title>
    <v-card-text v-if="loading">
      <p>Loading...</p>
    </v-card-text>
    <v-card-text v-if="!loading && dataset">
      <v-card>
        <v-card-title><h4>Constant Variables</h4></v-card-title>
        <v-divider></v-divider>
        <v-list dense>
          <v-list-tile v-for="variableId in tables.constants.fields" :key="variableId">
            <v-list-tile-content class="align-start" width="20">{{ variableById(variableId).label }}:</v-list-tile-content>
            <v-list-tile-content class="align-end">{{ dataset.values[variableId] }} {{ variableById(variableId).units }}</v-list-tile-content>
          </v-list-tile>
        </v-list>
      </v-card>
      <v-card class="mt-2">
        <v-card-title><h4>Annual Precipitation</h4></v-card-title>
        <v-divider></v-divider>
        <highcharts class="chart" :options="charts.ppt"></highcharts>
      </v-card>
      <v-card class="mt-2">
        <v-card-title><h4>Annual Air Temperature</h4></v-card-title>
        <v-divider></v-divider>
        <highcharts class="chart" :options="charts.temp"></highcharts>
      </v-card>
    </v-card-text>
    <v-card-actions>
      <v-btn flat color="primary" @click="$emit('close')">Close</v-btn>
    </v-card-actions>
  </v-card>
</template>

<script>
import { mapGetters } from 'vuex'
import highcharts from 'highcharts'

export default {
  name: 'GageCov',
  props: ['selected'],
  data () {
    return {
      dataset: null,
      loading: false,
      tables: {
        constants: {
          fields: [
            'basin_area',
            'basin_slope',
            'elev_mean',
            'bfi',
            'rdx',
            'twi',
            'length_km',
            'sinuosity',
            'strm_dens'
          ]
        }
      },
      charts: {
        ppt: {
          chart: {
            height: 200,
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
        }
      }
    }
  },
  computed: {
    ...mapGetters(['theme', 'variableById'])
  },
  mounted () {
    console.log('GageCov: mounted', this.selected)
  },
  watch: {
    selected () {
      console.log('GageCov:watch:selected', this.selected)
      this.fetchData()
    }
  },
  methods: {
    fetchData () {
      console.log('GageCov:fetchData', this.selected)
      if (!this.selected) {
        this.dataset = null
        return
      }
      this.loading = true
      this.$http.get(`/${this.theme.id}/features/${this.selected.id}.json`)
        .then((response) => {
          console.log('GageCov: response', response.data)
          this.dataset = response.data
          this.loading = false

          const pptData = this.dataset.values.ppt_mean.map((m, i) => ({
            mean: m,
            sd: this.dataset.values.ppt_sd[i],
            low: m - this.dataset.values.ppt_sd[i],
            high: m + this.dataset.values.ppt_sd[i]
          }))
          this.charts.ppt.series = [
            {
              name: 'Mean',
              data: pptData.map(d => d.mean),
              type: 'line'
            },
            {
              name: 'Std. Dev.',
              data: pptData,
              type: 'errorbar',
              tooltip: {
                pointFormatter: function () {
                  return `<span style="color:${this.color}">●</span> ${this.series.name}: <b>+/- ${highcharts.numberFormat(this.sd, 0, '.', ',')} mm</b><br/>`
                }
              }
            }
          ]

          const tempData = this.dataset.values.temp_mean.map((m, i) => ({
            mean: m,
            sd: this.dataset.values.temp_sd[i],
            low: m - this.dataset.values.temp_sd[i],
            high: m + this.dataset.values.temp_sd[i]
          }))
          this.charts.temp.series = [
            {
              name: 'Mean',
              data: tempData.map(d => d.mean),
              type: 'line'
            },
            {
              name: 'Std. Dev.',
              data: tempData,
              type: 'errorbar',
              tooltip: {
                pointFormatter: function () {
                  return `<span style="color:${this.color}">●</span> ${this.series.name}: <b>+/- ${highcharts.numberFormat(this.sd, 1, '.', ',')} degC</b><br/>`
                }
              }
            }
          ]
        })
        .catch((err) => {
          console.log('GageCov: error', err)
          this.dataset = null
          this.loading = false
        })
    }
  }
}
</script>
