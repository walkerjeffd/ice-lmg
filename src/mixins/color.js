import * as d3 from 'd3'

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
        return d3.scaleOrdinal(d3.schemeCategory10)
          .domain(this.variable.scale.domain.map(d => d.label))
      }
    }
  }
}
