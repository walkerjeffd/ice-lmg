<template>
  <div class="ice-map-container">
    <l-map ref="map" :options="{ ...options, zoomControl: false }">
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
    </l-map>
    <slot v-if="ready"></slot>
  </div>
</template>

<script>
import { LMap, LTileLayer, LControlZoom, LControlLayers } from 'vue2-leaflet'
import * as L from 'leaflet'
import * as d3 from 'd3'

import evt from '@/lib/events'

export default {
  name: 'IceMap',
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
    bounds: null,
    zoomLevel: null
  }),
  mounted () {
    // console.log('map:mounted')
    this.map = this.$refs.map.mapObject
    this.map.setView(this.center, this.zoom)

    this.zoomLevel = this.map.getZoom()

    let moveTimeout
    this.map.on('movestart', () => {
      window.clearTimeout(moveTimeout)
      this.disableClick = true
    })
    this.map.on('moveend', () => {
      // console.log('map:moveend', this.map.getCenter().toString())
      moveTimeout = setTimeout(() => {
        this.disableClick = false
      }, 100)
    })
    this.map.on('zoomend', () => {
      this.zoomLevel = this.map.getZoom()
      evt.$emit('map:zoom')
    })

    const svgLayer = L.svg()
    this.map.addLayer(svgLayer)

    this.svg = d3.select(svgLayer.getPane()).select('svg')
      .classed('leaflet-zoom-animated', false)
      .classed('leaflet-zoom-hide', true)
      .classed('map', true)
      .attr('pointer-events', null)
      .style('z-index', 201)

    this.ready = true
  }
}
</script>

<style>
.ice-map-container {
  position: absolute;
  width: 100%;
  height: 100%;
  left: 0;
  top: 0;
  z-index: 0;
}
</style>
