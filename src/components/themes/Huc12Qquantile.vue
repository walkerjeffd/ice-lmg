<template>
  <v-card v-if="selected" style="height:100%">
    <v-card-title primary-title>
      <h3 class="headline mb-0">Selected: {{selected.id}}</h3>
    </v-card-title>
    <v-card-text>
      <p>Theme: {{ theme.title }}</p>
    </v-card-text>
    <v-card-actions>
      <v-btn flat color="primary" @click="$emit('close')">Close</v-btn>
    </v-card-actions>
  </v-card>
</template>

<script>
import { mapGetters } from 'vuex'

export default {
  name: 'Huc12Qquantile',
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
  },
  watch: {
    selected () {
      console.log('Huc12Qquantile:watch:selected', this.selected)
      if (!this.selected) {
        this.dataset = null
        return
      }
      this.$http.get(`/${this.theme.id}/features/${this.selected.id}.json`)
        .then((response) => {
          this.dataset = response.data
        })
        .catch((err) => {
          console.log('Huc12Qquantile: error', err)
        })
    }
  }
}
</script>
