<template>
  <v-card v-if="selected">
    <v-card-title primary-title>
      <h3 class="headline mb-0">Selected Gage: {{selected.properties.id}}</h3>
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
      <v-card>
        <v-card-title><h4>Time-Varying Variables</h4></v-card-title>
        <v-divider></v-divider>
        <v-list dense>
          <v-list-tile v-for="variableId in tables.constants.fields" :key="variableId">
            <v-list-tile-content class="align-start">{{ variableById(variableId).label }}:</v-list-tile-content>
            <v-list-tile-content class="align-end">{{ dataset.values[variableId] }} {{ variableById(variableId).units }}</v-list-tile-content>
          </v-list-tile>
        </v-list>
      </v-card>
    </v-card-text>
    <v-card-actions>
      <v-btn flat color="primary" @click="onClose">Close</v-btn>
    </v-card-actions>
  </v-card>
</template>

<script>
import { mapGetters } from 'vuex'

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
      this.$http.get(`/${this.theme.id}/features/${this.selected.properties.id}.json`)
        .then((response) => {
          console.log('GageCov: response', response.data)
          this.dataset = response.data
          this.loading = false
        })
        .catch((err) => {
          console.log('GageCov: error', err)
          this.dataset = null
          this.loading = false
        })
    },
    onClose () {
      this.$emit('close')
    }
  }
}
</script>
