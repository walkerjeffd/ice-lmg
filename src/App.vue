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
            <v-card class="ice-card elevation-10" v-if="theme">
              <v-toolbar dark dense color="primary" class="subheading ma-0 theme-toolbar">
                <span class="pr-2"><v-icon size="20" class="mr-1">mdi-database</v-icon> <strong>Theme</strong>: </span>
                <span v-if="loading.theme">Loading... <v-progress-circular indeterminate color="primary" :size="20" class="ml-2"></v-progress-circular></span>
                <span v-else-if="error.theme"><v-icon color="error" size="19">mdi-alert</v-icon> {{error.theme}}</span>
                <span v-else-if="theme">{{ theme.title }}</span>
                <span v-else>None</span>
                <v-spacer></v-spacer>
                <v-btn round small color="grey lighten-2 elevation-2" light @click="dialogs.theme = true">
                  <v-icon small class="mr-2">mdi-folder-open</v-icon> Browse
                </v-btn>
              </v-toolbar>
            </v-card>
            <v-card class="ice-card elevation-10 mt-2" v-if="theme">
              <v-tabs
                v-model="tabs.active"
                color="primary"
                dark
                slider-color="white">
                <v-tab ripple>
                  <v-icon small class="mr-1">mdi-table</v-icon> Variable
                </v-tab>
                <v-tab ripple>
                  <v-icon small class="mr-1">mdi-chart-bar</v-icon> Crossfilters
                </v-tab>
                <v-spacer></v-spacer>
                <v-btn icon small outline @click="tabs.hide = !tabs.hide" class="mt-2 grey lighten-2 elevation-2" light>
                  <v-icon v-if="!tabs.hide">mdi-menu-up</v-icon>
                  <v-icon v-else>mdi-menu-down</v-icon>
                </v-btn>
                <v-tab-item :transition="false" :reverse-transition="false">
                  <v-card v-show="!tabs.hide">
                    <v-card-text>
                      <v-autocomplete
                        :items="mapVariables"
                        v-model="variable"
                        return-object
                        dense
                        item-value="id"
                        item-text="label"
                        :menu-props="{ closeOnClick: false, closeOnContentClick: false, openOnClick: false, maxHeight: 400 }"
                        label="Select variable...">
                        <template v-slot:item="data">
                          <v-list-tile-title class="pl-3" v-html="data.item.label"></v-list-tile-title>
                          <v-spacer></v-spacer>
                          <v-tooltip right max-width="600">
                            <template v-slot:activator="{ on }">
                              <v-icon v-on="on" color="grey lighten-1">mdi-information</v-icon>
                            </template>
                            {{ data.item.description }}
                          </v-tooltip>
                        </template>
                      </v-autocomplete>
                      <decade-dimension v-if="theme.dimensions.decade"></decade-dimension>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
                <v-tab-item :transition="false" :reverse-transition="false">
                  <v-card v-show="!tabs.hide" :max-height="$vuetify.breakpoint.height - 450" style="overflow-y: auto">
                    <v-card-text>
                      <v-autocomplete
                        :items="filterVariables"
                        v-model="filters"
                        multiple
                        dense
                        return-object
                        item-value="id"
                        item-text="label"
                        chips
                        deletable-chips
                        clearable
                        label="Select crossfilter variable(s)...">
                        <template v-slot:item="data">
                          <v-list-tile-action>
                            <v-checkbox :value="data.tile.props.value"></v-checkbox>
                          </v-list-tile-action>
                          <v-list-tile-title class="pl-3" v-html="data.item.label"></v-list-tile-title>
                          <v-spacer></v-spacer>
                          <v-tooltip right max-width="600">
                            <template v-slot:activator="{ on }">
                              <v-icon v-on="on" color="grey lighten-1">mdi-information</v-icon>
                            </template>
                            {{ data.item.description }}
                          </v-tooltip>
                          <br>
                        </template>
                      </v-autocomplete>
                      <p>Filtered: {{ counts.filtered }} of {{ counts.total }}</p>
                      <ice-filter v-for="variable in filters" :key="variable.id" :variable="variable" @close="removeFilter(variable)"></ice-filter>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
              </v-tabs>
            </v-card>
            <v-card class="ice-card elevation-10 mt-2">
              <v-toolbar dense dark color="primary">
                <h4>Legend</h4>
                <v-spacer></v-spacer>
                <v-btn icon small outline @click="legend.hide = !legend.hide" class="mt-2 grey lighten-2 elevation-2" light>
                  <v-icon v-if="!legend.hide">mdi-menu-up</v-icon>
                  <v-icon v-else>mdi-menu-down</v-icon>
                </v-btn>
              </v-toolbar>
              <v-card-text v-if="!legend.hide">
                <ice-legend id="legend" :colorScale="colorScale" :variable="variable" class="pt-3" v-if="variable"></ice-legend>
                <div class="text-xs-center grey--text text--darken-2 font-weight-medium" v-if="variable">
                  {{ variable.label }}<span v-if="variable.units">&nbsp;({{ variable.units }})</span>
                  <v-tooltip right max-width="600">
                    <template v-slot:activator="{ on }">
                      <v-icon right v-on="on" small>mdi-help-circle</v-icon>
                    </template>
                    {{ variable.description }}
                  </v-tooltip>
                </div>
              </v-card-text>
            </v-card>
            <v-card class="ice-card elevation-10 mt-2" v-if="debug.visible">
              <v-toolbar dense dark color="red darken-4">
                <h4>Debug</h4>
                <v-spacer></v-spacer>
                <v-btn icon small light @click="debug.hide = !debug.hide" class="mt-2 grey lighten-2 elevation-2">
                  <v-icon v-if="!debug.hide">mdi-menu-up</v-icon>
                  <v-icon v-else>mdi-menu-down</v-icon>
                </v-btn>
              </v-toolbar>
              <v-card-text v-if="!debug.hide">
                <pre>feature.selected: {{ !!feature.selected }}</pre>
                <!-- <pre>counts: {{ counts }}</pre>
                <pre>filters: {{ filters }}</pre>
                <pre>variable: {{ variable }}</pre>
                <pre>layer: {{ layer }}</pre>
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
        :height="$vuetify.breakpoint.height - 70"
        width="600">
        <component v-if="theme" :is="theme.id" :selected="feature.selected" @close="selectFeature()"></component>
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
          <v-toolbar-title>Select a Theme</v-toolbar-title>
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

import DecadeDimension from '@/components/dimensions/DecadeDimension'

import GageCov from '@/components/themes/GageCov'
import GageQstat from '@/components/themes/GageQstat'
import GageQtrend from '@/components/themes/GageQtrend'
import GageQts from '@/components/themes/GageQts'
import GageSolar from '@/components/themes/GageSolar'
import Huc12Cov from '@/components/themes/Huc12Cov'
import Huc12Qquantile from '@/components/themes/Huc12Qquantile'
import Huc12Solar from '@/components/themes/Huc12Solar'

import * as d3 from 'd3'

import { getValueById, getFilteredCount, getTotalCount } from '@/lib/crossfilter'
import themes from '@/assets/themes'
import evt from '@/lib/events'
import { groupVariables } from '@/lib/utils'
import variableMixin from '@/mixins/variable'

export default {
  name: 'App',
  mixins: [variableMixin],
  components: {
    IceMap,
    IceMapLayer,
    IceFilter,
    IceLegend,
    DecadeDimension,
    GageCov,
    GageQstat,
    GageQts,
    GageQtrend,
    GageSolar,
    Huc12Cov,
    Huc12Qquantile,
    Huc12Solar
  },
  data: () => ({
    filters: [],
    debug: {
      visible: process.env.NODE_ENV === 'development',
      hide: true
    },
    tabs: {
      active: 0,
      hide: false
    },
    legend: {
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
    variable: {
      get () {
        return this.$store.getters.variable
      },
      set (value) {
        return this.$store.dispatch('setVariable', value)
      }
    },
    mapVariables () {
      return groupVariables(this.variables.filter(d => d.map))
    },
    filterVariables () {
      return groupVariables(this.variables.filter(d => d.filter))
    },
    colorScale () {
      return d3.scaleSequential(d3.interpolateViridis)
    }
  },
  mounted () {
    this.selectTheme(themes[0].children[0]).then(this.updateCounts)
    evt.$on('xf:filter', this.updateCounts)
  },
  beforeDestroy () {
  },
  watch: {
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

      this.selectFeature()
      this.clearFilters()

      return this.$store.dispatch('loadTheme', theme)
        .then((theme) => {
          this.error.theme = null
          this.updateCounts()
        })
        .catch((err) => {
          console.error(err)
          this.error.theme = 'Failed to load theme'
        })
        .finally(() => {
          this.loading.theme = false
          this.dialogs.theme = false
        })
    },
    selectFeature (feature) {
      if (!feature || this.feature.selected === feature) {
        this.feature.selected = null
      } else {
        this.feature.selected = feature
        // TODO: fetch drainage area layer
      }
    },
    getFeatureValue (feature) {
      return getValueById(feature.id)
    },
    getFeatureFill (feature) {
      const value = this.getFeatureValue(feature).mean
      return this.colorScale(this.variableScale(value))
    },
    removeFilter (variable) {
      this.filters.splice(this.filters.findIndex(v => v === variable), 1)
    },
    clearFilters () {
      this.filters = []
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
