import { mapGetters } from 'vuex'
import { format } from 'd3'

import IceFeatureContainer from '@/components/IceFeatureContainer'
import IceFeatureBox from '@/components/IceFeatureBox'
import IceGagePropertiesBox from '@/components/IceGagePropertiesBox'
import IceHuc12PropertiesBox from '@/components/IceHuc12PropertiesBox'

export default {
  props: ['selected'],
  components: {
    IceFeatureContainer,
    IceFeatureBox,
    IceGagePropertiesBox,
    IceHuc12PropertiesBox
  },
  data () {
    return {
      dataset: null
    }
  },
  computed: {
    ...mapGetters(['theme', 'variableById']),
    values () {
      return this.dataset ? this.dataset.values : []
    }
  },
  mounted () {
    this.updateDataset()
  },
  beforeDestroy () {
    this.clearCharts()
  },
  watch: {
    dataset () {
      this.updateCharts()
    },
    selected () {
      this.updateDataset()
    }
  },
  methods: {
    variableFormatter (id) {
      const variable = this.variableById(id)
      if (variable.type === 'cat') {
        const domain = variable.scale.domain
        const map = new Map(domain.map(d => [d.value, d.label]))
        return (d) => map.get(d)
      }
      return format(variable.formats.value)
    },
    updateDataset () {
      if (!this.selected) {
        this.dataset = null
        return
      }
      this.$http.get(`/${this.theme.id}/features/${this.selected.id}.json`)
        .then((response) => {
          this.dataset = response.data
        })
        .catch((err) => {
          console.log(err)
          this.dataset = null
        })
    },
    updateCharts () {
      return null
    },
    clearCharts () {
      if (!this.charts) return
      for (const chart in this.charts) {
        this.charts[chart].series = []
      }
    }
  }
}
