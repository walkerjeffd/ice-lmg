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
            <v-list-item-content class="align-end">{{ variableFormatter(variableId)(dataset.values[0][variableId]) }} {{ variableById(variableId).units }}</v-list-item-content>
          </v-list-item>
        </v-list>
      </ice-feature-box>
      <ice-feature-box>
        <template v-slot:title>Hydro-geologic Classifications</template>
        <v-list dense>
          <v-list-item v-for="variableId in tables.cat.fields" :key="variableId">
            <v-list-item-content class="align-start" width="20">{{ variableById(variableId).label }}:</v-list-item-content>
            <v-list-item-content class="align-end">{{ variableFormatter(variableId)(dataset.values[0][variableId]) }}</v-list-item-content>
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
    </div>
    <div v-else>
      Loading...
    </div>
  </ice-feature-container>
</template>

<script>
import highcharts from 'highcharts'

import themeSelect from '@/mixins/themeSelect'

export default {
  name: 'Huc12Cov',
  mixins: [themeSelect],
  data () {
    return {
      tables: {
        cov: {
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
        },
        cat: {
          fields: [
            'aquifers',
            'cat_aquifers',
            'bedperm',
            'ecol3',
            'cat_ecol3',
            'hlr',
            'physio',
            'cat_physio',
            'soller',
            'cat_soller',
            'statsgo',
            'ed_rch_zone'
          ]
        }
      },
      charts: {
        landUse: {
          chart: {
            height: 300,
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

      const pptData = this.values.map((d, i) => ({
        mean: d.ppt_mean,
        sd: d.ppt_sd,
        low: d.ppt_mean - d.ppt_sd,
        high: d.ppt_mean + d.ppt_sd
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

      const tempData = this.values.map((d, i) => ({
        mean: d.temp_mean,
        sd: d.temp_sd,
        low: d.temp_mean - d.temp_sd,
        high: d.temp_mean + d.temp_sd
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
    }
  }
}
</script>
