<template>
  <div>
    <v-select
      :items="test.options"
      v-model="test.selected"
      dense
      item-value="id"
      item-text="label"
      label="Select trend test...">
    </v-select>

    <div v-if="test.selected === 'qk'">
      <v-select
        :items="qkTest.stats.options"
        v-model="qkTest.stats.selected"
        dense
        item-value="id"
        item-text="label"
        label="Select statistic...">
      </v-select>
      <v-select
        :items="qkTest.levels.options"
        v-model="qkTest.levels.selected"
        dense
        return-object
        item-value="id"
        item-text="label"
        label="Select stratification method...">
      </v-select>
      <v-slider
        v-if="qkTest.levels.selected && qkTest.levels.selected.options.length > 1"
        v-model="qkTest.levels.value"
        :tick-labels="qkTest.levels.selected.options.map(d => d.label)"
        :max="qkTest.levels.selected.options.length - 1"
        step="1"
        ticks="always"
        tick-size="3"
        color="primary"
        class="tick-label">
      </v-slider>
    </div>

    <div v-if="test.selected === 'mk'">
      <v-select
        :items="mkTest.levels.options"
        v-model="mkTest.levels.selected"
        dense
        return-object
        item-value="id"
        item-text="label"
        label="Select stratification method...">
      </v-select>
      <v-slider
        v-if="mkTest.levels.selected && mkTest.levels.selected.options.length > 1"
        v-model="mkTest.levels.value"
        :tick-labels="mkTest.levels.selected.options.map(d => d.label)"
        :max="mkTest.levels.selected.options.length - 1"
        step="1"
        ticks="always"
        tick-size="3"
        color="primary"
        class="text-caption">
      </v-slider>
    </div>
    <!-- <pre>variableId: {{variableId}}</pre> -->
  </div>
</template>

<script>
export default {
  name: 'TrendVariable',
  data () {
    return {
      test: {
        selected: null,
        options: [
          {
            id: 'mk',
            label: 'Mann-Kendall Test'
          },
          {
            id: 'qk',
            label: 'Quantile-Kendall Test'
          }
        ]
      },
      mkTest: {
        levels: {
          selected: null,
          value: null,
          options: [
            {
              id: 'season',
              label: 'By Season',
              options: [
                {
                  id: 'spring',
                  label: 'Spring'
                },
                {
                  id: 'summer',
                  label: 'Summer'
                },
                {
                  id: 'fall',
                  label: 'Fall'
                },
                {
                  id: 'winter',
                  label: 'Winter'
                }
              ]
            },
            {
              id: 'month',
              label: 'By Month',
              options: [
                {
                  id: 'jan',
                  label: 'Jan'
                },
                {
                  id: 'feb',
                  label: 'Feb'
                },
                {
                  id: 'mar',
                  label: 'Mar'
                },
                {
                  id: 'apr',
                  label: 'Apr'
                },
                {
                  id: 'may',
                  label: 'May'
                },
                {
                  id: 'jun',
                  label: 'Jun'
                },
                {
                  id: 'jul',
                  label: 'Jul'
                },
                {
                  id: 'aug',
                  label: 'Aug'
                },
                {
                  id: 'sep',
                  label: 'Sep'
                },
                {
                  id: 'oct',
                  label: 'Oct'
                },
                {
                  id: 'nov',
                  label: 'Nov'
                },
                {
                  id: 'dec',
                  label: 'Dec'
                }
              ]
            },
            {
              id: 'quantile',
              label: 'By Quantile',
              options: [
                {
                  id: 'q00',
                  label: '0%'
                },
                {
                  id: 'q10',
                  label: '10%'
                },
                {
                  id: 'q20',
                  label: '20%'
                },
                {
                  id: 'q30',
                  label: '30%'
                },
                {
                  id: 'q40',
                  label: '40%'
                },
                {
                  id: 'q50',
                  label: '50%'
                },
                {
                  id: 'q60',
                  label: '60%'
                },
                {
                  id: 'q70',
                  label: '70%'
                },
                {
                  id: 'q80',
                  label: '80%'
                },
                {
                  id: 'q90',
                  label: '90%'
                },
                {
                  id: 'q100',
                  label: '100%'
                }
              ]
            }
          ]
        }
      },
      qkTest: {
        stats: {
          selected: null,
          options: [
            {
              id: 'min',
              label: 'Minimum'
            },
            {
              id: 'median',
              label: 'Median'
            },
            {
              id: 'max',
              label: 'Maximum'
            }
          ]
        },
        levels: {
          selected: null,
          value: null,
          options: [
            {
              id: 'annual',
              label: 'Annual',
              options: [
                {
                  id: 'annual',
                  label: 'Annual'
                }
              ]
            },
            {
              id: 'season',
              label: 'By Season',
              options: [
                {
                  id: 'spring',
                  label: 'Spring'
                },
                {
                  id: 'summer',
                  label: 'Summer'
                },
                {
                  id: 'fall',
                  label: 'Fall'
                },
                {
                  id: 'winter',
                  label: 'Winter'
                }
              ]
            }
          ]
        }
      }
    }
  },
  computed: {
    qkLevel () {
      if (this.test.selected !== 'qk' || this.qkTest.levels.selected === null) return null
      const option = this.qkTest.levels.selected.options[this.qkTest.levels.value]
      return option && option.id
    },
    mkLevel () {
      if (this.test.selected !== 'mk' || this.mkTest.levels.selected === null) return null
      const option = this.mkTest.levels.selected.options[this.mkTest.levels.value]
      return option && option.id
    },
    variableId () {
      if (this.test.selected === 'mk' && this.mkLevel) return `mk_${this.mkLevel}_slope`
      if (this.test.selected === 'qk' && this.qkLevel && this.qkTest.stats.selected) return `qk_${this.qkLevel}_${this.qkTest.stats.selected}_slopepct`
      return null
    }
  },
  watch: {
    variableId () {
      this.$emit('update', this.variableId)
    },
    'test.selected' () {
      if (this.test.selected === 'qk') {
        this.qkTest.stats.selected = this.qkTest.stats.options[1].id
        this.qkTest.levels.selected = this.qkTest.levels.options[0]
      } else if (this.test.selected === 'mk') {
        this.mkTest.levels.selected = this.mkTest.levels.options[0]
      }
    },
    'qkTest.levels.selected' () {
      this.qkTest.levels.value = 0
    },
    'mkTest.levels.selected' () {
      this.mkTest.levels.value = 0
    }
  },
  mounted () {
    this.test.selected = this.test.options[0].id
  }
}
</script>

<style>
.v-slider__tick-label {
  font-size: 10pt !important;
}
</style>
