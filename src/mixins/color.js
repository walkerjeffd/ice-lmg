import * as d3 from 'd3'
import { schemeCategory20 } from '@/lib/constants'

export default {
  computed: {
    colorScale () {
      if (!this.variable || this.variable.type === 'num') {
        const scale = d3.scaleSequential(d3[`interpolate${this.colorScheme}`])
        if (this.colorInvert) {
          scale.domain([1, 0])
        } else {
          scale.domain([0, 1])
        }
        return scale
      } else if (this.variable.type === 'cat') {
        const scheme = this.variable.scale.domain.length > 10 ? schemeCategory20 : d3.schemeCategory10
        return d3.scaleOrdinal(scheme)
          .domain(this.variable.scale.domain.map(d => d.label))
      }
    }
  }
}
