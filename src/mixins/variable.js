import * as d3 from 'd3'

import transform from '@/lib/transform'

export default {
  computed: {
    transform () {
      return transform.transform(this.variable.scale.transform)
    },
    inverseTransform () {
      return transform.inverse(this.variable.scale.transform)
    },
    valueFormatter () {
      if (!this.variable || !this.variable.formats.value) return (d) => d
      return d3.format(this.variable.formats.value)
    },
    mapFormatter () {
      if (!this.variable || !this.variable.formats.map) return (d) => d
      return d3.format(this.variable.formats.map)
    },
    filterFormatter () {
      if (!this.variable || !this.variable.formats.filter) return (d) => d
      return d3.format(this.variable.formats.filter)
    },
    variableScale () {
      if (!this.variable) return d3.scaleLinear()

      if (this.variable.type === 'cat') return (d) => d

      let scale
      switch (this.variable.scale.transform) {
        case 'log':
          scale = d3.scaleLog()
          break
        case 'linear':
          scale = d3.scaleLinear()
          break
        default:
          scale = d3.scaleLinear()
          break
      }

      return scale
        .domain(this.variable.scale.domain)
        .range([0, 1])
        .clamp(true)
    }
  }
}
