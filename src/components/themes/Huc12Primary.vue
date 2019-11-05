<template>
  <ice-feature-container v-if="selected" @close="$emit('close')">
    <template v-slot:title>
      HUC12: {{selected.properties.huc12}}
    </template>

    <div v-if="dataset">
      <ice-huc12-properties-box :properties="dataset.properties"></ice-huc12-properties-box>
    </div>
    <div v-else>
      Loading...
    </div>
  </ice-feature-container>
</template>

<script>
import { mapGetters } from 'vuex'
// import highcharts from 'highcharts'

import IceFeatureContainer from '@/components/IceFeatureContainer'
// import IceFeatureBox from '@/components/IceFeatureBox'
import IceHuc12PropertiesBox from '@/components/IceHuc12PropertiesBox'

export default {
  name: 'GagePrimary',
  props: ['selected'],
  components: {
    IceFeatureContainer,
    // IceFeatureBox,
    IceHuc12PropertiesBox
  },
  data () {
    return {
      dataset: null
    }
  },
  computed: {
    ...mapGetters(['theme', 'variableById'])
  },
  mounted () {
    this.fetchData()
  },
  watch: {
    selected () {
      this.fetchData()
    }
  },
  methods: {
    fetchData () {
      if (!this.selected) {
        this.dataset = null
        return
      }
      this.$http.get(`/${this.theme.id}/features/${this.selected.id}.json`)
        .then((response) => {
          this.dataset = response.data
        })
        .catch((err) => {
          console.log('Huc12Primary: error', err)
          this.dataset = null
          this.loading = false
        })
    }
  }
}
</script>
