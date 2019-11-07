<template>
  <div>
    <!-- <v-subheader class="pl-0">Select Level</v-subheader> -->
    <v-autocomplete
      :items="group.options"
      v-model="group.selected"
      dense
      item-value="id"
      item-text="label"
      :menu-props="{ closeOnClick: false, closeOnContentClick: false, openOnClick: false, maxHeight: 400 }"
      label="Select trend analysis level...">
    </v-autocomplete>
    <v-slider
      v-model="level.value"
      :tick-labels="selectedGroupOptions"
      :max="selectedGroupOptions.length - 1"
      step="1"
      ticks="always"
      tick-size="3"
      color="primary">
    </v-slider>
    <!-- <pre>{{group.selected}},{{level.value}},{{selectedLevel}}</pre> -->
  </div>
</template>

<script>
import { getCrossfilter } from '@/lib/crossfilter'
import evt from '@/lib/events'

export default {
  name: 'MklevelDimension',
  data () {
    return {
      group: {
        selected: 'season',
        options: [
          {
            id: 'season',
            label: 'Season'
          },
          {
            id: 'month',
            label: 'Month'
          },
          {
            id: 'quantile',
            label: 'Flow Quantile'
          }
        ]
      },
      level: {
        value: 1,
        options: {
          season: ['Spring', 'Summer', 'Fall', 'Winter'],
          month: ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
          quantile: ['Q00', 'Q10', 'Q20', 'Q30', 'Q40', 'Q50', 'Q60', 'Q70', 'Q80', 'Q90', 'Q100']
        }
      }
    }
  },
  computed: {
    selectedGroupOptions () {
      return this.group.selected ? this.level.options[this.group.selected] : []
    },
    selectedLevel () {
      return this.selectedGroupOptions[this.level.value]
    }
  },
  watch: {
    selectedLevel () {
      this.update()
    },
    'group.selected' () {
      // console.log(this.selectedGroupOptions)
      this.level.value = Math.floor(this.selectedGroupOptions.length / 2)
    }
  },
  mounted () {
    const xf = getCrossfilter()
    this.dim = xf.dimension(d => d.mklevel)
    evt.$on('theme:set', this.update)
  },
  beforeDestroy () {
    if (this.dim) this.dim.dispose()
  },
  methods: {
    update () {
      if (!this.dim) return
      this.dim.filterExact(this.selectedLevel)
      evt.$emit('map:render')
      evt.$emit('xf:filter')
      evt.$emit('filter:render')
    }
  }
}
</script>
