<template>
  <v-app>
    <v-app-bar app dark>
      <a href="https://www.usgs.gov/centers/lmg-water" target="_blank" class="mr-4 ml-1">
        <v-img src="./assets/lmg-logo.png" alt="USGS LMGWSC Logo" height="42" width="42"></v-img>
      </a>
      <v-toolbar-title class="headline">
        USGS LMGWSC | <span class="font-weight-light">Data Visualization Tool</span>
      </v-toolbar-title>
      <v-spacer></v-spacer>
      <v-btn text href="http://ecosheds.org">
        <v-icon small left>mdi-home</v-icon> SHEDS
      </v-btn>
    </v-app-bar>
    <v-content v-if="$vuetify.breakpoint.smAndUp">
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
      <v-container fluid>
        <v-row no-gutters>
          <v-col>
            <v-card class="ice-card elevation-10">
              <v-container class="pa-0">
                <v-row no-gutters>
                  <v-col class="text-center">
                    <v-btn block tile medium color="secondary" @click="dialogs.welcome = true">
                      <v-icon medium left>mdi-home</v-icon> Welcome
                    </v-btn>
                  </v-col>
                  <v-col class="text-center">
                    <v-btn block tile medium color="secondary" @click="dialogs.contact = true">
                      <v-icon medium left>mdi-email</v-icon> Contact
                    </v-btn>
                  </v-col>
                  <v-col class="text-center">
                    <v-btn block tile medium color="secondary" @click="dialogs.help = true">
                      <v-icon medium left>mdi-help</v-icon> Help
                    </v-btn>
                  </v-col>
                </v-row>
              </v-container>
            </v-card>
            <v-card class="ice-card elevation-10 mt-2">
              <v-toolbar dark dense color="primary">
                <h4>Dataset: <span v-if="theme">{{ theme.title }}</span><span v-else>None</span></h4>
                <!-- <strong>Current Dataset</strong>:
                <span v-if="loading.theme">Loading... <v-progress-circular indeterminate color="primary" :size="20" class="ml-2"></v-progress-circular></span>
                <span v-else-if="error.theme"><v-icon color="error" size="19">mdi-alert</v-icon> {{error.theme}}</span>
                <span v-else-if="theme">{{ theme.title }}</span>
                <span v-else>None</span> -->
              </v-toolbar>
              <v-card-text v-if="theme" class="pb-0">
                <decade-dimension v-if="theme.dimensions.decade"></decade-dimension>
              </v-card-text>
              <v-divider></v-divider>
              <v-card-actions>
                <!-- <v-btn small outlined text color="primary">
                  <v-icon left small>mdi-information</v-icon> About Dataset
                </v-btn>
                <v-spacer></v-spacer> -->
                <v-btn small outlined text color="primary" @click="dialogs.theme = true">
                  <v-icon left small>mdi-folder-open</v-icon> Open Dataset Browser
                </v-btn>
                <!-- <v-btn small outlined text color="primary" @click="clearTheme" v-if="theme">
                  <v-icon left small>mdi-close</v-icon> Close
                </v-btn> -->
                <v-spacer></v-spacer>
                <v-btn small outlined text color="primary" v-if="theme" @click="dialogs.download = true">
                  <v-icon left small>mdi-download</v-icon> Download
                </v-btn>
              </v-card-actions>
            </v-card>
            <v-card class="ice-card elevation-10 mt-2" v-if="theme">
              <v-tabs
                v-model="tabs.active"
                background-color="primary"
                color="white"
                dark
                slider-color="white">
                <v-tab ripple>
                  Variable
                </v-tab>
                <v-tab ripple>
                  Crossfilters
                </v-tab>
                <v-spacer></v-spacer>
                <v-btn icon small @click="tabs.hide = !tabs.hide" class="align-self-center mr-1">
                  <v-icon small v-if="!tabs.hide">mdi-menu-up</v-icon>
                  <v-icon small v-else>mdi-menu-down</v-icon>
                </v-btn>
                <v-tab-item :transition="false" :reverse-transition="false">
                  <v-card v-show="!tabs.hide">
                    <v-card-text v-if="theme.id !== 'gage-qtrend'">
                      <v-autocomplete
                        label="Select variable..."
                        :items="mapVariables"
                        v-model="variable"
                        return-object
                        dense
                        item-value="id"
                        item-text="label"
                        :menu-props="{ closeOnClick: false, closeOnContentClick: false, openOnClick: false, maxHeight: 400 }"
                        class="mt-2">
                        <template v-slot:item="data">
                          <v-list-item-content class="pl-3 body-2" v-html="data.item.label"></v-list-item-content>
                          <v-tooltip right max-width="600">
                            <template v-slot:activator="{ on }">
                              <v-icon v-on="on" small color="grey lighten-1">mdi-information</v-icon>
                            </template>
                            {{ data.item.description }}
                          </v-tooltip>
                        </template>
                      </v-autocomplete>
                    </v-card-text>
                    <v-card-text v-else>
                      <trend-variable @update="setVariableById"></trend-variable>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
                <v-tab-item :transition="false" :reverse-transition="false">
                  <v-card v-show="!tabs.hide" :max-height="$vuetify.breakpoint.height - 550" style="overflow-y: auto">
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
                          <v-list-item-action>
                            <v-checkbox small :value="data.attrs.inputValue"></v-checkbox>
                          </v-list-item-action>
                          <v-list-item-content class="body-2" v-html="data.item.label"></v-list-item-content>
                        </template>
                      </v-autocomplete>
                      <p>Filtered: {{ counts.filtered }} of {{ counts.total }}</p>
                      <ice-filter v-for="variable in filters" :key="variable.id" :variable="variable" @close="removeFilter(variable)"></ice-filter>
                    </v-card-text>
                  </v-card>
                </v-tab-item>
              </v-tabs>
            </v-card>
            <ice-legend-box v-if="theme"></ice-legend-box>
            <v-card class="ice-card elevation-10 mt-2" v-if="debug.visible">
              <v-toolbar dense dark color="red darken-4">
                <h4>Debug</h4>
                <v-spacer></v-spacer>
                <v-btn icon small @click="debug.hide = !debug.hide">
                  <v-icon small v-if="!debug.hide">mdi-menu-up</v-icon>
                  <v-icon small v-else>mdi-menu-down</v-icon>
                </v-btn>
              </v-toolbar>
              <v-card-text v-if="!debug.hide">
                <pre>{{ $vuetify.application.top }}</pre>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
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
      <v-container fluid>
        <v-row >
          <v-col>
            <v-card>
              <v-card-text>
                <h2 class="text-center mb-4"><v-icon large>mdi-alert</v-icon></h2>
                <p class="text-center">
                  This application is only designed for desktop computers, and does not support mobile devices.
                </p>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
      </v-container>
    </v-content>
    <v-dialog
      v-model="dialogs.welcome"
      max-width="1000"
      scrollable>
      <v-card>
        <v-toolbar dark dense color="primary">
          <v-toolbar-title><v-icon left>mdi-home</v-icon> Welcome</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.welcome = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text class="mt-4">
          <div class="text-center mb-8">
            <h2>Welcome to the USGS Lower Mississippi Gulf Water Science Center's Data Visualization Tool</h2>
          </div>
          <p>
            Lorem ipsum dolor sit amet consectetur, adipisicing elit. Hic dicta repellat molestiae. Odio rem laboriosam esse vel nisi sed rerum dolorem, deleniti eligendi fuga! Obcaecati voluptatem recusandae id quasi molestiae?
          </p>
          <p>
            Lorem ipsum dolor sit amet consectetur, adipisicing elit. Hic dicta repellat molestiae. Odio rem laboriosam esse vel nisi sed rerum dolorem, deleniti eligendi fuga! Obcaecati voluptatem recusandae id quasi molestiae?
          </p>

          <div class="text-center mt-8 mb-4">
            <v-btn
              color="success"
              large
              @click="dialogs.welcome = false; dialogs.theme = true">
              Get Started <v-icon>mdi-chevron-double-right</v-icon>
            </v-btn>
          </div>
        </v-card-text>

        <v-divider class="mb-8"></v-divider>

        <v-card-text>
          <v-alert type="warning" outlined prominent icon="mdi-alert">
            <h2>Disclaimer</h2>
            This information is preliminary and is subject to revision. It is being provided to meet the need for timely best science. The information is provided on the condition that neither the U.S. Geological Survey nor the U.S. Government may be held liable for any damages resulting from the authorized or unauthorized use of the information.
          </v-alert>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.welcome = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-dialog
      v-model="dialogs.contact"
      max-width="1000"
      scrollable>
      <v-card>
        <v-toolbar dark color="primary">
          <v-toolbar-title><v-icon left>mdi-email</v-icon> Contact Information</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.contact = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text class="mt-8">
          <p class="body-1">Questions, comments, problems? Please contact one of the team members listed below.</p>
          <h4>USGS Contact</h4>
          <p class="ml-4">
            Kirk D. Rodgers, PhD<br>
            Hydrologist, and Eastern Region Diversity Subcouncil Chairman<br>
            U.S. Geological Survey Lower Mississippi-Gulf Water Science Center<br>
            E-mail: <a href="mailto:krodgers@usgs.gov">krodgers@usgs.gov</a>
          </p>
          <h4>Site Administrator</h4>
          <p class="ml-4">
            Jeffrey D. Walker, PhD<br>
            Environmental Data Scientist<br>
            <a href="https://ecosheds.org" target="_blank">Spatial Hydro-Ecological Decision System (SHEDS)</a><br>
            <a href="https://walkerenvres.com" target="_blank">Walker Environmental Research, LLC</a><br>
            E-mail: <a href="mailto:jeff@walkerenvres.com">jeff@walkerenvres.com</a>
          </p>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.contact = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-dialog
      v-model="dialogs.help"
      max-width="1000"
      scrollable>
      <v-card>
        <v-toolbar dark color="primary">
          <v-toolbar-title><v-icon left>mdi-help</v-icon> User Guide</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.help = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text class="mt-4">
          <p>Lorem ipsum dolor sit amet consectetur adipisicing elit. Temporibus iste quae dolores quibusdam numquam, ut soluta rerum earum doloremque officia culpa laudantium esse amet mollitia voluptas exercitationem commodi magni natus.</p>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.help = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-dialog
      v-model="dialogs.download"
      max-width="1000"
      scrollable>
      <v-card>
        <v-toolbar dark color="primary">
          <v-toolbar-title><v-icon left>mdi-download</v-icon> Download</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.download = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <!-- <v-card-text class="mt-4">
          <h2>Instructions</h2>
          <p class="body-1">
            The current dataset can be downloaded using the buttons below.
          </p>
          <p class="body-1">
            Clicking on either button will trigger the application to download two files:
          </p>
          <ol class="body-1">
            <li>Dataset file in comma separate values (CSV) format.</li>
            <li>Metadata file describing each column in the dataset</li>
          </ol>
        </v-card-text>

        <v-divider></v-divider> -->

        <v-card-text class="my-4" v-if="theme">
          <v-container>
            <v-row>
              <v-col class="text-center">
                <h2>Complete Dataset</h2>
                <p class="font-italic my-8">Includes all gages or HUC12s regardless of any filters that are currently set, and data for all decades.</p>
                <v-btn color="success" @click="downloadDataset(false)">
                  <v-icon>mdi-download</v-icon> Complete Dataset (CSV)
                </v-btn>
              </v-col>
              <v-divider vertical></v-divider>
              <v-col class="text-center">
                <h2>Filtered Dataset</h2>
                <p class="font-italic my-8">Includes only gages or HUC12s that meet any existing filters, and only data for the current decade.</p>
                <v-btn color="success" @click="downloadDataset(true)">
                  <v-icon>mdi-download</v-icon> Filtered Dataset (CSV)
                </v-btn>
              </v-col>
            </v-row>
          </v-container>

          <v-divider class="my-4"></v-divider>

          <h2 v-if="theme.citations.length > 1">Citations </h2>
          <h2 v-else>Citation </h2>
          <p v-for="citation in theme.citations" :key="citation.text">
            {{citation.text}} <a :href="citation.url" target="_blank">{{ citation.url }}</a>.
          </p>

          <v-alert color="warning" outlined prominent icon="mdi-alert" class="mb-0">
            <h2>Disclaimer</h2>
            This information is preliminary and is subject to revision. It is being provided to meet the need for timely best science. The information is provided on the condition that neither the U.S. Geological Survey nor the U.S. Government may be held liable for any damages resulting from the authorized or unauthorized use of the information.
          </v-alert>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.download = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
    <v-dialog
      v-model="dialogs.theme"
      max-width="1200"
      scrollable>
      <v-card>
        <v-toolbar dark color="primary">
          <v-toolbar-title>Dataset Browser</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-btn icon @click="dialogs.theme = false">
            <v-icon>mdi-close</v-icon>
          </v-btn>
        </v-toolbar>

        <v-card-text>
          <v-row justify="space-between">
            <v-col sm="4">
              <v-treeview
                v-model="themes.selected"
                :active.sync="themes.active"
                :open.sync="themes.open"
                :items="themes.options"
                activatable
                return-object
                open-on-click
                dense>
                <template v-slot:prepend="{ item, open }">
                  <v-icon v-if="item.children">
                    {{ open ? 'mdi-folder-open' : 'mdi-folder' }}
                  </v-icon>
                  <v-icon v-else>
                    {{ 'mdi-table' }}
                  </v-icon>
                </template>
              </v-treeview>
            </v-col>
            <v-divider vertical></v-divider>
            <v-col class="d-flex">
              <div v-for="theme in themes.active" :key="theme.id" class="pt-4 black--text">
                <h2 class="mb-2">{{theme.name}}</h2>
                <p>{{theme.description}}</p>
                <div class="text-center my-8">
                  <v-btn large color="green" dark @click="selectTheme(theme)" :loading="loading.theme">
                    Load Dataset
                    <v-icon right>mdi-chevron-double-right</v-icon>
                  </v-btn>
                </div>
                <v-divider class="my-4"></v-divider>
                <div v-if="theme.citations">
                  <h3 v-if="theme.citations.length > 1">Citations: </h3>
                  <h3 v-else>Citation: </h3>
                  <div v-for="citation in theme.citations" :key="citation.text" class="mt-4">
                    {{citation.text}} <a :href="citation.url" target="_blank">{{ citation.url }}</a>.
                  </div>
                </div>
              </div>

              <div class="pt-4" style="width:100%" v-if="themes.active.length === 0">
                <v-alert color="success" prominent outlined icon="mdi-chevron-left">
                  Select a dataset from the list.
                </v-alert>
              </div>
            </v-col>
          </v-row>
        </v-card-text>

        <v-divider></v-divider>

        <v-card-actions>
          <v-spacer></v-spacer>
          <v-btn
            color="primary"
            text
            @click="dialogs.theme = false">
            Close
          </v-btn>
        </v-card-actions>
      </v-card>
    </v-dialog>
  </v-app>
</template>

<script>
import { mapGetters } from 'vuex'

import IceMap from '@/components/IceMap'
import IceMapLayer from '@/components/IceMapLayer'
import IceFilter from '@/components/IceFilter'
import IceLegendBox from '@/components/IceLegendBox'

import DecadeDimension from '@/components/dimensions/DecadeDimension'

import TrendVariable from '@/components/TrendVariable'

import GagePrimary from '@/components/themes/GagePrimary'
import GageCov from '@/components/themes/GageCov'
import GageQstat from '@/components/themes/GageQstat'
import GageQtrend from '@/components/themes/GageQtrend'
import GageSolar from '@/components/themes/GageSolar'
import Huc12Primary from '@/components/themes/Huc12Primary'
import Huc12Cov from '@/components/themes/Huc12Cov'
import Huc12Qquantile from '@/components/themes/Huc12Qquantile'
import Huc12Solar from '@/components/themes/Huc12Solar'

import { getValueById, getFilteredCount, getTotalCount } from '@/lib/crossfilter'
import themes from '@/assets/themes'
import evt from '@/lib/events'
import { groupVariables } from '@/lib/utils'
import { downloadDataset } from '@/lib/download'
import VariableMixin from '@/mixins/variable'
import ColorMixin from '@/mixins/color'

export default {
  name: 'App',
  mixins: [VariableMixin, ColorMixin],
  components: {
    IceMap,
    IceMapLayer,
    IceFilter,
    IceLegendBox,
    DecadeDimension,
    TrendVariable,
    GagePrimary,
    GageCov,
    GageQstat,
    GageQtrend,
    GageSolar,
    Huc12Primary,
    Huc12Cov,
    Huc12Qquantile,
    Huc12Solar
  },
  data: () => ({
    filters: [],
    debug: {
      // visible: process.env.NODE_ENV === 'development',
      visible: false,
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
      contact: false,
      help: false,
      download: false
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
    ...mapGetters(['theme', 'variables', 'layer', 'colorScheme', 'colorInvert']),
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
    }
  },
  mounted () {
    if (!this.theme) this.dialogs.welcome = true
    evt.$on('xf:filter', this.updateCounts)
  },
  beforeDestroy () {
  },
  watch: {
    variable () {
      this.variable && evt.$emit('map:render')
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

      return this.clearTheme()
        .then(() => this.$store.dispatch('loadTheme', theme))
        .then((theme) => {
          this.error.theme = null
          this.updateCounts()
        })
        .catch((err) => {
          console.error(err)
          this.error.theme = 'Failed to load theme'
        })
        .finally(() => {
          evt.$emit('theme:set')
          this.loading.theme = false
          this.dialogs.theme = false
        })
    },
    clearTheme () {
      this.selectFeature()
      this.clearFilters()
      return this.$store.dispatch('clearTheme')
        .then(() => this.updateCounts())
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
      const value = this.getFeatureValue(feature)
      return value ? this.colorScale(this.variableScale(value.mean)) : null
    },
    removeFilter (variable) {
      this.filters.splice(this.filters.findIndex(v => v === variable), 1)
    },
    clearFilters () {
      this.filters = []
    },
    setVariableById (id) {
      const variable = this.$store.getters.variableById(id)
      if (!variable) return
      this.variable = variable
    },
    downloadDataset (filtered) {
      downloadDataset(filtered, this.theme)
        .catch((err) => alert(`Failed to download dataset\n\n${err}`))
    }
  }
}
</script>

<style>
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

.ice-card {
  width: 500px;
}
</style>
