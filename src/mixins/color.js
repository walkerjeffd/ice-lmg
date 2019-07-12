import * as d3 from 'd3'

export default {
  computed: {
    colorScale () {
      const scale = d3.scaleSequential(d3[`interpolate${this.colorScheme}`])
      if (this.colorInvert) {
        scale.domain([1, 0])
      } else {
        scale.domain([0, 1])
      }
      return scale
    }
  }
}
