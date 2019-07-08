<template>
  <v-card v-if="selected" style="height:100%">
    <v-card-title primary-title>
      <h3 class="headline mb-0">Selected Gage: {{selected.properties.id}}</h3>
    </v-card-title>
    <v-card-text>
      <p>Theme: Streamflow Gages > Flow</p>
    </v-card-text>
    <v-card-actions>
      <v-btn flat color="primary">text</v-btn>
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
      dataset: null
    }
  },
  computed: {
    ...mapGetters(['theme'])
  },
  mounted () {
    console.log('GageCov: mounted', this.selected)
  },
  watch: {
    selected () {
      console.log('GageCov:watch:selected', this.selected)
      if (!this.selected) {
        this.dataset = null
        return
      }
      this.$http.get(`/${this.theme.id}/features/${this.selected.properties.id}.json`)
        .then((response) => {
          console.log('GageCov: response', response)
          this.dataset = response.data
        })
        .catch((err) => {
          console.log('GageCov: error', err)
        })
    }
  }
}
</script>
