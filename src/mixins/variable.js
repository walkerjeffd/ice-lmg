// import { mapGetters } from 'vuex'
import * as d3 from 'd3'

import transform from '@/lib/transform'

export default {
  computed: {
    // ...mapGetters(['variable']),
    // transformType() {
    //   if (!this.variable || !this.variable.scale.transform) {
    //     return null;
    //   }
    //   return this.variable.scale.transform;
    // },
    transform () {
      return transform.transform(this.variable.scale.transform)
    },
    inverseTransform () {
      return transform.inverse(this.variable.scale.transform)
    },
    // extent() {
    //   // transformed units
    //   let extent = [0, 1];
    //   if (this.variable && this.data) {
    //     extent = d3.extent(this.data.map(d => d[this.variable.id]));
    //   }
    //   return extent;
    // },
    textFormatter () {
      return d3.format(this.variable ? this.variable.formats.text : ',.1f')
    },
    axisFormatter () {
      return d3.format(this.variable ? this.variable.formats.axis : ',.1f')
    },
    variableScale () {
      if (!this.variable) return d3.scaleLinear()

      let scale
      switch (this.variable.scale.transform) {
        case 'log':
          scale = d3.scaleLog()
          // const positiveValues = xf.all.all().map(d => d[this.variable.id]).filter(d => d > 0).sort()
          // if (domain[0] <= 0) domain[0] = +d3.quantile(positiveValues, 0.05).toPrecision(1)
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
