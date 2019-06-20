<template>
  <div class="map-container">
    <l-map ref="map" :center="center" :zoom="zoom" :options="{ ...options, zoomControl: false }">
      <l-control-zoom position="topright"></l-control-zoom>
      <l-control-layers position="topright"></l-control-layers>
      <l-tile-layer
        v-for="tile in basemaps"
        :key="tile.name"
        :name="tile.name"
        :visible="tile.visible"
        :url="tile.url"
        :attribution="tile.attribution"
        layer-type="base">
      </l-tile-layer>
      <!-- <l-tile-layer :url="tile.url" /> -->
    </l-map>
    <slot v-if="ready"></slot>
  </div>
</template>

<script>
import { LMap, LTileLayer, LControlZoom, LControlLayers } from 'vue2-leaflet'
import * as d3 from 'd3'

import evt from '@/lib/events'
// import * as L from 'leaflet'

export default {
  name: 'IceMap',
  // props: ['getFill', 'layer'],
  props: {
    options: {
      type: Object,
      required: false,
      default: () => {}
    },
    center: {
      type: Array,
      required: false,
      default: () => [42, -72]
    },
    zoom: {
      type: Number,
      required: false,
      default: 8
    },
    basemaps: {
      type: Array,
      required: false,
      default: () => []
    }
  },
  components: {
    LMap,
    LTileLayer,
    LControlZoom,
    LControlLayers
  },
  data: () => ({
    ready: false,
    map: null,
    disableClick: false,
    // initial: {
    //   zoom: 6,
    //   center: [31.5, -89]
    // },
    bounds: null,
    zoomLevel: null
    // tile: {
    //   url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'
    // }
  }),
  computed: {
    // path () {
    //   const map = this.map
    //   function projectPoint (x, y) {
    //     const point = map.latLngToLayerPoint(new L.LatLng(y, x))
    //     this.stream.point(point.x, point.y)
    //   }
    //   const geoTransform = d3.geoTransform({ point: projectPoint })
    //   return d3.geoPath().projection(geoTransform).pointRadius(this.pointRadius)
    // },
    // pointRadius () {
    //   return this.zoomLevel - 2
    // }
  },
  watch: {
    // layer () {
    //   if (this.layer) {
    //     this.map.fitBounds(L.geoJson(this.layer).getBounds())
    //     this.render()
    //   }
    // }
  },
  mounted () {
    this.map = this.$refs.map.mapObject
    this.zoomLevel = this.map.getZoom()

    let moveTimeout
    this.map.on('movestart', () => {
      window.clearTimeout(moveTimeout)
      this.disableClick = true
    })
    this.map.on('moveend', () => {
      moveTimeout = setTimeout(() => {
        this.disableClick = false
      }, 100)
    })
    this.map.on('zoomend', () => {
      this.zoomLevel = this.map.getZoom()
      evt.$emit('map:zoom')
    })

    this.svg = d3.select(this.map.getPanes().overlayPane)
      .append('svg')
      .style('border', '1px solid black')
    this.overlay = this.svg.append('g').attr('class', 'leaflet-zoom-hide')

    this.$on('resize', this.resize)

    this.ready = true
  },
  methods: {
    resize (bounds) {
      if (bounds) this.bounds = bounds

      const padding = 100

      const topLeft = this.bounds[0]
      const bottomRight = this.bounds[1]

      this.svg.attr('width', bottomRight[0] - topLeft[0] + padding)
        .attr('height', bottomRight[1] - topLeft[1] + padding)
        .style('left', `${topLeft[0] - (padding / 2)}px`)
        .style('top', `${topLeft[1] - (padding / 2)}px`)

      this.svg.select('g')
        .attr('transform', `translate(${-(topLeft[0] - (padding / 2))},${-(topLeft[1] - (padding / 2))})`)
    }
    // render () {
    //   this.resizeSvg()
    //   this.renderFeatures()
    // },
    // projectPoint (d) {
    //   const latLng = new L.LatLng(d.geometry.coordinates[1], d.geometry.coordinates[0])
    //   return this.map.latLngToLayerPoint(latLng)
    // },
    // renderFeatures () {
    //   const vm = this;
    //   const features = this.layer.features || []

    //   this.svg
    //     .select('g')
    //     .selectAll('circles')
    //     .remove()

    //   const circles = this.svg
    //     .select('g')
    //     .selectAll('circle')
    //     .data(features, d => d.properties.id)

    //   // const size = this.pointRadius * 20
    //   // const circle = d3.symbol().type(d3.symbolCircle).size(size)

    //   circles.enter()
    //     .append('circle')
    //     .on('click', function (d) {
    //       // !vm.$parent.disableClick && vm.$emit('click', d)
    //       // this.parentNode.appendChild(this) // move to front
    //       if (vm.disableClick) return
    //       this.$emit('click', d)
    //     })
    //     .on('mouseenter', function (d) {
    //       // if (!vm.selected) {
    //       //   // move to front if nothing selected
    //       //   this.parentNode.appendChild(this)
    //       // } else {
    //       //   // move to 2nd from front, behind selected
    //       //   const lastChild = this.parentNode.lastChild
    //       //   this.parentNode.insertBefore(this, lastChild)
    //       // }

    //       d3.select(this)
    //         .style('stroke', 'white')
    //         .style('stroke-width', '1')
    //         .attr('r', 10)
    //     })
    //     .on('mouseout', function (d) {
    //       d3.select(this)
    //         .style('stroke', null)
    //         .style('stroke-width', null)
    //         .attr('r', 5)
    //     })
    //     .merge(circles)
    //     // .attr('transform', (d) => {
    //     //   const point = this.map.latLngToLayerPoint(new L.LatLng(d.geometry.coordinates[1], d.geometry.coordinates[0]))
    //     //   return `translate(${point.x},${point.y})`
    //     // })
    //     // .attr('d', circle)
    //     .attr('r', 5)
    //     .attr('cx', d => this.projectPoint(d).x)
    //     .attr('cy', d => this.projectPoint(d).y)
    //     .style('fill', this.getFill)

    //   circles.exit().remove()
    // }
  }
}
</script>

<style>
.map-container {
  position: absolute;
  width: 100%;
  height: 100%;
  left: 0;
  top: 0;
  z-index: 0;
}

circle {
  cursor: pointer !important;
  pointer-events: visible !important;
}
</style>
