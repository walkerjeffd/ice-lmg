<template>
  <ice-feature-container v-if="selected" @close="$emit('close')">
    <template v-slot:title>
      Selected HUC12: {{selected.properties.huc12}}
    </template>

    <div v-if="dataset">
      <ice-huc12-properties-box :properties="dataset.properties"></ice-huc12-properties-box>
      <ice-feature-box>
        <template v-slot:title>Basin Characteristics</template>
        <v-list dense>
          <v-list-item v-for="variableId in tables.cov.fields" :key="variableId">
            <v-list-item-content class="align-start" width="20">{{ variableById(variableId).label }}:</v-list-item-content>
            <v-list-item-content class="align-end">{{ variableFormatter(variableId)(dataset.values[decadeIndex][variableId]) }} {{ variableById(variableId).units }}</v-list-item-content>
          </v-list-item>
        </v-list>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Hydro-geologic Classifications</template>
        <v-list dense>
          <v-list-item v-for="variableId in tables.cat.fields" :key="variableId">
            <v-list-item-content class="align-start" width="20">{{ variableById(variableId).label }}:</v-list-item-content>
            <v-list-item-content class="align-end">{{ variableFormatter(variableId)(dataset.values[decadeIndex][variableId]) }}</v-list-item-content>
          </v-list-item>
        </v-list>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Impoundments</template>
        <highcharts class="chart" :options="charts.dams"></highcharts>
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
    </div>
    <div v-else>
      Loading...
    </div>
  </ice-feature-container>
</template>

<script>
import themeSelect from '@/mixins/themeSelect'
import { mapGetters } from 'vuex'

export default {
  name: 'Huc12Primary',
  mixins: [themeSelect],
  data () {
    return {
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
        dams: {
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
                text: '# Dams'
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
        }
      }
    }
  },
  computed: {
    ...mapGetters(['decadeIndex'])
  },
  methods: {
    updateCharts () {
      this.clearCharts()

      this.charts.landUse.series = [
        {
          name: 'Developed',
          data: this.values.map(d => d.developed),
          type: 'line'
        },
        {
          name: 'Hay/Pasture',
          data: this.values.map(d => d.hay_pasture),
          type: 'line'
        },
        {
          name: 'Cultivated Cropland',
          data: this.values.map(d => d.cultivated_cropland),
          type: 'line'
        },
        {
          name: 'Grassland',
          data: this.values.map(d => d.grassland),
          type: 'line'
        },
        {
          name: 'Shrubland',
          data: this.values.map(d => d.shrubland),
          type: 'line'
        },
        {
          name: 'Total Forest',
          data: this.values.map(d => d.total_forest),
          type: 'line'
        },
        {
          name: 'Total Wetland',
          data: this.values.map(d => d.total_wetland),
          type: 'line'
        },
        {
          name: 'Open Water',
          data: this.values.map(d => d.water),
          type: 'line'
        }
      ]

      this.charts.dams.series = [
        {
          name: '# Major Dams Upstream',
          data: this.values.map(d => d.major),
          type: 'line'
        }
      ]

      this.charts.ppt.series = [
        {
          name: 'Mean Precip',
          data: this.values.map(d => d.ppt_mean),
          type: 'line'
        }
      ]

      this.charts.temp.series = [
        {
          name: 'Mean Air Temp',
          data: this.values.map(d => d.temp_mean),
          type: 'line'
        }
      ]

      this.charts.qStat.series = [
        {
          name: '5th Percentile',
          data: this.values.map(d => d.q_f05),
          type: 'line'
        },
        {
          name: 'Median',
          data: this.values.map(d => d.q_f50),
          type: 'line'
        },
        {
          name: '95th Percentile',
          data: this.values.map(d => d.q_f95),
          type: 'line'
        }
      ]
    }
  }
}
</script>
