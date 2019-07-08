<template>
  <v-app>
    <v-toolbar app dark height="64">
      <v-toolbar-title class="headline text-uppercase">
        <span>ICE</span>
        <span class="font-weight-light px-2">|</span>
        <span class="font-weight-light">Lower Mississippi Gulf Region</span>
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn flat small href="http://ice.ecosheds.org">
        <span class="mr-2">ICE Home</span>
      </v-btn>
      <v-btn flat small href="http://ecosheds.org">
        <span class="mr-2">SHEDS Home</span>
      </v-btn>
    </v-toolbar>
    <v-content v-if="$vuetify.breakpoint.smAndUp">
      <v-hover>
        <v-navigation-drawer
          v-model="leftSidebar.open"
          dark
          app
          :mini-variant="!hover"
          hide-overlay
          stateless
          temporary
          slot-scope="{ hover }"
          class="mr-2 left-drawer">
          <v-list class="pt-0">
            <v-divider></v-divider>
            <v-list-tile
              v-for="item in leftSidebar.items"
              :key="item.title"
              @click.stop="dialogs[item.dialog] = true">
              <v-list-tile-action>
                <v-icon>{{ item.icon }}</v-icon>
              </v-list-tile-action>
              <v-list-tile-content>
                <v-list-tile-title>{{ item.title }}</v-list-tile-title>
              </v-list-tile-content>
            </v-list-tile>
          </v-list>
        </v-navigation-drawer>
      </v-hover>
      <ice-map :basemaps="map.basemaps" :center="[31.5, -89]" :zoom="6">
        <ice-map-layer
          name="points"
          set-bounds
          :layer="layer"
          :getFill="getFeatureFill"
          :getValue="getFeatureValue"
          :selected="feature.selected"
          @click="selectFeature">
        </ice-map-layer>
      </ice-map>
      <v-container fluid fill-height class="ice-container">
        <v-layout>
          <v-flex>
            <v-card class="ice-card elevation-10">
              <v-toolbar dark class="subheading">
                <strong class=" pr-2">Theme: </strong>
                <span v-if="loading.theme">Loading... <v-progress-circular indeterminate color="primary" :size="20" class="ml-2"></v-progress-circular></span>
                <span v-else-if="error.theme"><v-icon color="error" size="19">mdi-alert</v-icon> {{error.theme}}</span>
                <span v-else-if="theme">{{ theme.title }}</span>
                <span v-else>None</span>
                <v-spacer></v-spacer>
                <v-btn small color="default" @click="dialogs.theme = true">Browse</v-btn>
              </v-toolbar>
              <v-tabs
                v-model="tabs.active"
                color="blue"
                dark
                slider-color="white">
                <v-tab ripple>
                  <v-icon small class="mr-1">mdi-table</v-icon> Variables
                </v-tab>
                <v-tab ripple>
                  <v-icon small class="mr-1">mdi-chart-bar</v-icon> Histograms &amp; Filters
                </v-tab>
                <v-spacer></v-spacer>
                <v-btn icon small outline @click="tabs.hide = !tabs.hide" class="mt-2 hide">
                  <v-icon v-if="!tabs.hide">mdi-menu-up</v-icon>
                  <v-icon v-else>mdi-menu-down</v-icon>
                </v-btn>
                <v-tab-item :transition="false" :reverse-transition="false">
                  <!-- <v-toolbar dark class="subheading">
                    <strong class=" pr-2">Theme: </strong>
                    <span v-if="loading.theme">Loading... <v-progress-circular indeterminate color="primary" :size="20" class="ml-2"></v-progress-circular></span>
                    <span v-else-if="error.theme"><v-icon color="error" size="19">mdi-alert</v-icon> {{error.theme}}</span>
                    <span v-else-if="theme">{{ theme.title }}</span>
                    <span v-else>None</span>
                    <v-spacer></v-spacer>
                    <v-btn small color="default" @click="dialogs.theme = true">Browse</v-btn>
                  </v-toolbar> -->
                  <v-card v-show="!tabs.hide" :max-height="$vuetify.breakpoint.height - 250" style="overflow-y: auto">
                    <v-card-text>
                      <v-autocomplete
                        :items="variables"
                        v-model="variable"
                        return-object
                        dense
                        item-value="id"
                        item-text="label"
                        label="Select variable...">
                      </v-autocomplete>
                      <v-subheader class="pl-0">Select Decade</v-subheader>
                      <v-slider
                        v-model="decade.value"
                        :tick-labels="decade.labels"
                        :max="decade.labels.length - 1"
                        step="1"
                        ticks="always"
                        tick-size="7">
                      </v-slider>
                      <v-subheader class="pl-0" v-if="variable">{{ variable.label }}<span v-if="variable.units">&nbsp;({{ variable.units }})</span></v-subheader>
                      <ice-legend id="legend" :colorScale="colorScale" :variable="variable" class="pt-3" v-if="variable"></ice-legend>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
                <v-tab-item :transition="false" :reverse-transition="false">
                  <v-card v-show="!tabs.hide">
                    <v-card-text>
                      <v-autocomplete
                        :items="variables"
                        v-model="filters"
                        multiple
                        dense
                        return-object
                        item-value="id"
                        item-text="label"
                        label="Select variable(s)...">
                      </v-autocomplete>
                      <p>Filtered: {{ counts.filtered }} of {{ counts.total }}</p>
                      <ice-filter v-for="variable in filters" :key="variable.id" :variable="variable" @close="removeFilter(variable)"></ice-filter>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
              </v-tabs>
            </v-card>
          </v-flex>
          <v-flex xs9>
            <v-card class="ice-card elevation-10">
              <v-toolbar dense dark>
                <h4>Debug</h4>
                <v-spacer></v-spacer>
                <v-btn icon small outline @click="debug.hide = !debug.hide" class="mt-2 hide">
                  <v-icon v-if="!debug.hide">mdi-menu-up</v-icon>
                  <v-icon v-else>mdi-menu-down</v-icon>
                </v-btn>
              </v-toolbar>
              <v-card-text v-if="!debug.hide">
                <pre>feature.selected: {{ !!feature.selected }}</pre>
                <!-- <pre>decadeValue: {{decadeValue}}</pre> -->
                <!-- <pre>counts: {{ counts }}</pre>
                <pre>filters: {{ filters }}</pre>
                <pre>variable: {{ variable }}</pre>
                <pre>layer: {{ layer }}</pre>
                <pre>decade: {{ decade.value }}</pre>
                <pre>feature: {{ feature.selected }}</pre> -->
              </v-card-text>
            </v-card>
          </v-flex>
        </v-layout>
      </v-container>
      <v-navigation-drawer
        :value="!!feature.selected"
        right
        temporary
        fixed
        app
        hide-overlay
        stateless
        :height="$vuetify.breakpoint.height - 64"
        width="600">
        <component v-if="theme" :is="theme.id" :selected="feature.selected"></component>
      </v-navigation-drawer>
    </v-content>
    <v-content v-else>
      <v-container fill-height fluid grid-list-xs class="px-2">
        <v-layout row justify-space-around>
          <v-flex xs12>
            <v-card>
              <v-card-text>
                <h2 class="text-xs-center mb-4">:(</h2>
                <p class="text-xs-center">
                  Sorry, ICE is only designed for desktop computers, and does not support mobile.
                </p>
              </v-card-text>
            </v-card>
          </v-flex>
        </v-layout>
      </v-container>
    </v-content>
    <v-dialog
      v-model="dialogs.welcome"
      max-width="1000"
      scrollable>
      <v-card>
        <v-card-title class="headline">Welcome to ICE</v-card-title>

        <v-card-text>
          Lorem ipsum, dolor sit amet consectetur adipisicing elit. Obcaecati id molestias tempora commodi inventore aliquid voluptas perspiciatis non, quis dignissimos, veritatis ut quia vero, tempore dolorem praesentium excepturi. Quos, id?
        </v-card-text>

        <v-card-actions>
          <v-spacer></v-spacer>

          <v-btn
            color="green darken-1"
            flat="flat"
            @click="dialogs.welcome = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-dialog
      v-model="dialogs.theme"
      max-width="1000"
      scrollable>
      <v-card>
        <v-toolbar dark color="primary">
          <v-toolbar-title>Themes</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.theme = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text>
          <v-layout row wrap justify-space-between>
            <v-flex xs4 style="border-right: 1px solid #CCC;">
              <v-treeview
                v-model="themes.selected"
                :active.sync="themes.active"
                :open.sync="themes.open"
                :items="themes.options"
                activatable
                light
                return-object
                open-on-click>
                <template v-slot:prepend="{ item, open }">
                  <v-icon v-if="item.children">
                    {{ open ? 'mdi-folder-open' : 'mdi-folder' }}
                  </v-icon>
                  <v-icon v-else>
                    {{ 'mdi-table' }}
                  </v-icon>
                </template>
              </v-treeview>
            </v-flex>
            <v-flex xs8 class="pl-4">
              <div v-for="theme in themes.active" :key="theme.id">
                <h2 class="mb-2">{{theme.title}}</h2>
                <p>{{theme.description}}</p>
                <div v-if="theme.sciencebase" class="my-2 subheading">
                  <p>
                    <strong>ScienceBase: </strong>
                    <a :href="theme.sciencebase.url" target="_blank">{{theme.sciencebase.title}}</a>
                  </p>
                </div>
                <div class="text-xs-center mt-4">
                  <v-btn large color="green" dark @click="selectTheme(theme)">
                    Load Theme
                    <v-icon right>mdi-chevron-double-right</v-icon>
                  </v-btn>
                </div>
              </div>

              <div>
                <p v-if="themes.active.length === 0">
                  Select a theme from the list above.
                </p>
              </div>
            </v-flex>
          </v-layout>
        </v-card-text>
      </v-card>
    </v-dialog>
  </v-app>
</template>

<script>
import { mapGetters } from 'vuex'

import IceMap from '@/components/IceMap'
import IceMapLayer from '@/components/IceMapLayer'
import IceFilter from '@/components/IceFilter'
import IceLegend from '@/components/IceLegend'

import GageCov from '@/components/datasets/GageCov'
import GageTrends from '@/components/datasets/GageTrends'
import GageFlow from '@/components/datasets/GageFlow'

import * as d3 from 'd3'

import { getValueById, getCrossfilter, getFilteredCount, getTotalCount } from '@/lib/crossfilter'
import themes from '@/assets/themes'
import evt from '@/lib/events'
import variableMixin from '@/mixins/variable'

export default {
  name: 'App',
  mixins: [variableMixin],
  components: {
    IceMap,
    IceMapLayer,
    IceFilter,
    IceLegend,
    GageCov,
    GageFlow,
    GageTrends
  },
  data: () => ({
    filters: [],
    debug: {
      hide: false
    },
    tabs: {
      active: 0,
      hide: false
    },
    leftSidebar: {
      open: true,
      items: [
        { title: 'Welcome', dialog: 'welcome', icon: 'mdi-home' },
        { title: 'Download', dialog: 'download', icon: 'mdi-download' },
        { title: 'Settings', dialog: 'settings', icon: 'mdi-settings' },
        { title: 'Tutorial', dialog: 'tutorial', icon: 'mdi-help' },
        { title: 'Contact Us', dialog: 'contact', icon: 'mdi-email' },
        { title: 'About', dialog: 'about', icon: 'mdi-information' }
      ]
    },
    rightSidebar: {
      open: true
    },
    dialogs: {
      theme: false,
      welcome: false,
      download: false,
      settings: false,
      tutorial: false,
      contact: false,
      about: false
    },
    decade: {
      value: 5,
      labels: ['1950s', '1960s', '1970s', '1980s', '1990s', '2000s']
    },
    loading: {
      theme: false
    },
    error: {
      theme: null
    },
    themes: {
      active: [],
      selected: [],
      open: themes.map(d => d.id),
      options: themes
    },
    feature: {
      selected: null
    },
    dims: {},
    counts: {
      total: 0,
      filtered: 0
    },
    map: {
      basemaps: [
        {
          name: 'ESRI World Imagery',
          visible: true,
          url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          attribution: 'Tiles &copy; Esri &mdash; Source: Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community'
        },
        {
          name: 'OpenStreetMap',
          visible: false,
          url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
        }
      ]
    }
  }),
  computed: {
    ...mapGetters(['theme', 'variables', 'layer']),
    decadeValue () {
      return typeof this.decade.value === 'number' ? (1950 + this.decade.value * 10).toString() : null
    },
    variable: {
      get () {
        return this.$store.getters.variable
      },
      set (value) {
        return this.$store.dispatch('setVariable', value)
      }
    },
    colorScale () {
      return d3.scaleSequential(d3.interpolateViridis)
    }
  },
  mounted () {
    this.dims.decade = getCrossfilter().dimension(d => d.decade)
    // this.selectDecade(this.decade.options[0])
    this.selectTheme(themes[0].children[0]).then(this.updateCounts)
    this.decade.value = 5
    this.selectDecade(this.decadeValue)

    evt.$on('xf:filter', this.updateCounts)
  },
  beforeDestroy () {
    console.log('app:beforeDestroy')
    this.dims.decade.dispose()
  },
  watch: {
    'decade.value' (value) {
      this.selectDecade(this.decadeValue)
    },
    variable () {
      evt.$emit('map:render')
    }
  },
  methods: {
    updateCounts () {
      this.counts.total = getTotalCount()
      this.counts.filtered = getFilteredCount()
    },
    selectTheme (theme) {
      this.loading.theme = true
      this.error.theme = null

      return this.$store.dispatch('loadTheme', theme)
        .then((theme) => {
          this.loading.theme = false
          this.error.theme = null
          this.dialogs.theme = false
        })
        .catch((err) => {
          console.error(err)
          this.loading.theme = false
          this.error.theme = 'Failed to load theme'
          this.dialogs.theme = false
        })
    },
    selectFeature (feature) {
      console.log('selectFeature():', feature)

      if (!feature || this.feature.selected === feature) {
        this.feature.selected = null
      } else {
        this.feature.selected = feature
        // TODO: fetch drainage area layer
      }
    },
    getFeatureValue (feature) {
      return getValueById(feature.properties.id)
    },
    getFeatureFill (feature) {
      const value = this.getFeatureValue(feature).mean
      return this.colorScale(this.variableScale(value))
    },
    selectDecade (decade) {
      // console.log('selectDecade', decade)
      if (decade) {
        this.dims.decade.filterExact(this.decadeValue)
      } else {
        this.dims.decade.filterAll()
      }
      evt.$emit('map:render')
      evt.$emit('xf:filter')
      evt.$emit('filter:render')
    },
    removeFilter (variable) {
      this.filters.splice(this.filters.findIndex(v => v === variable), 1)
    }
  }
}
</script>

<style>
.v-toolbar {
  background: rgba(0, 0, 0, 0.8) !important;
}
.left-drawer {
  background: rgba(50, 50, 50, 0.6) !important;
}
.v-navigation-drawer {
  margin-top: 64px !important;
}

.v-list {
  background: none !important;
}
.v-dialog__content {
  align-items: start !important;
}
.v-dialog.v-dialog--active {
  margin-top: 64px !important;
}

.ice-container {
  padding-left: 100px;
}
.ice-card {
  width: 600px;
}
</style>
