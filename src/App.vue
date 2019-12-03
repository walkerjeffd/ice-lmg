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
          :getFill="getFill"
          :getValue="getValue"
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
            <v-card class="ice-card elevation-10 mt-2 pb-0" ref="dataset">
              <v-toolbar dark dense color="primary">
                <h4>Dataset: <span v-if="theme">{{ theme.title }}</span><span v-else>None</span></h4>
                <v-spacer></v-spacer>
                <v-btn icon small @click="collapse.dataset = !collapse.dataset">
                  <v-icon small v-if="!collapse.dataset">mdi-menu-up</v-icon>
                  <v-icon small v-else>mdi-menu-down</v-icon>
                </v-btn>
              </v-toolbar>
              <v-card-text v-if="theme && !collapse.dataset && (theme.dimensions.decade || theme.dimensions.signif)">
                <decade-dimension v-if="theme.dimensions.decade"></decade-dimension>
                <div class="subheading" v-if="theme.id === 'gage-primary' || theme.id === 'gage-qtrend'">
                  <v-icon small>mdi-information</v-icon> For trend test results, the decade slider sets the starting point of the period of record, which always ends in 2015 (e.g., if 1970s is selected, then trend tests are based on flows from 1970-2015).
                </div>
                <signif-dimension v-if="theme.dimensions.signif"></signif-dimension>
              </v-card-text>
              <v-divider v-if="theme && !collapse.dataset && (theme.dimensions.decade || theme.dimensions.signif)"></v-divider>
              <v-card-actions>
                <v-btn small outlined text color="primary" @click="dialogs.theme = true">
                  <v-icon left small>mdi-folder-open</v-icon> Open Dataset Browser
                </v-btn>
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
                <v-btn icon small @click="collapse.tabs = !collapse.tabs" class="align-self-center mr-1">
                  <v-icon small v-if="!collapse.tabs">mdi-menu-up</v-icon>
                  <v-icon small v-else>mdi-menu-down</v-icon>
                </v-btn>
                <v-tab-item :transition="false" :reverse-transition="false">
                  <v-card v-show="!collapse.tabs">
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
                        class="mt-2"
                        hide-details>
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
                  <v-card v-show="!collapse.tabs" :max-height="$vuetify.breakpoint.height - heights.dataset - heights.legend - heights.debug - 205" style="overflow-y: auto">
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
            <ice-legend-box v-if="theme" ref="legend" :collapse="collapse.legend" @collapse="collapse.legend = !collapse.legend"></ice-legend-box>
            <v-card class="ice-card elevation-10 mt-2" v-if="debug" ref="debug">
              <v-toolbar dense dark color="red darken-4">
                <h4>Debug</h4>
                <v-spacer></v-spacer>
                <v-btn icon small @click="collapse.debug = !collapse.debug">
                  <v-icon small v-if="!collapse.debug">mdi-menu-up</v-icon>
                  <v-icon small v-else>mdi-menu-down</v-icon>
                </v-btn>
              </v-toolbar>
              <v-card-text v-if="!collapse.debug">
                <pre>heights: {{ heights }}</pre>
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

        <v-card-text class="mt-4 black--text">
          <div class="text-center mb-8">
            <h2 class="headline">Welcome to the USGS Lower Mississippi Gulf Water Science Center's <br> Data Visualization Tool</h2>
          </div>

          <div class="text-center my-8">
            <v-btn
              color="success"
              x-large
              @click="dialogs.welcome = false; dialogs.theme = true">
              Get Started <v-icon>mdi-chevron-double-right</v-icon>
            </v-btn>
          </div>

          <v-divider class="mb-4"></v-divider>

          <h4 class="title">Project Background</h4>
          <p class="body-1">
            Human alteration of waterways has impacted the minimum and maximum streamflows in more than 86% of monitored streams nationally and may be the primary cause for ecological impairment in river and stream ecosystems. Restoration of freshwater inflows can positively affect shellfish, fisheries, habitat, and water quality in streams, rivers, and estuaries. Increasingly, state and local decision-makers and federal agencies are turning their attention to the restoration of flows as part of a holistic approach to restoring water quality and habitat and to protecting and replenishing living coastal and marine resources and the livelihoods that depend on them.
          </p>
          <p class="body-1">
            In 2017, the USGS and US EPA began collaborating on a comprehensive, large-scale, state-of-the-science foundational
            project (RESTORE) to provide vital information on the timing and delivery of freshwater to streams, bays, estuaries, and wetlands
            of the Gulf Coast. The information generated through this project will provide local, state, and federal officials the
            ability to evaluate how streamflow withdrawals and reservoir operations throughout the watershed may alter streamflow metrics
            and freshwater inputs to the estuary.
          </p>
          <p class="body-1">
            <a href="https://www.usgs.gov/centers/lmg-water/science/streamflow-alteration-assessments-support-bay-and-estuary-restoration-gulf" target="_blank">
              Click here to read more about the RESTORE project
            </a>
          </p>

          <h4 class="title">About The Application</h4>
          <p class="body-1">
            This application provides a set of interactive data visualization tools to explore datasets generated by USGS researchers
            for the RESTORE project. The purpose of this tool is to help stakeholders, decision makers and other interested users
            access these datasets and develop a better understanding of spatial and temporal streamflow patterns in
            the Lower Mississippi-Gulf Region.
          </p>
          <p class="body-1">
            This application is part of the <a href="https://ecosheds.org" target="_blank">Spatial Hydro-Ecological Decision System (SHEDS)</a>
            and built using the <a href="http://ice.ecosheds.org" target="_blank">Interactive Catchment Explorer</a> framework by
            <a href="https://walkerenvres.com" target="_blank">Walker Environmental Research LLC</a>.
          </p>

          <v-divider class="mb-4"></v-divider>

          <disclaimer></disclaimer>
        </v-card-text>

        <v-divider class="mb-4"></v-divider>

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

        <v-card-text class="mt-8 black--text">
          <p class="body-1">Questions, comments, problems? Please contact one of the team members listed below.</p>
          <h4>USGS Contact</h4>
          <p class="ml-4">
            Kirk D. Rodgers, PhD<br>
            Hydrologist, and Eastern Region Diversity Subcouncil Chairman<br>
            <a href="https://www.usgs.gov/centers/lmg-water" target="_blank">U.S. Geological Survey Lower Mississippi-Gulf Water Science Center</a><br>
            E-mail: <a href="mailto:krodgers@usgs.gov">krodgers@usgs.gov</a>
          </p>
          <h4>Site Administrator</h4>
          <p class="ml-4">
            Jeffrey D. Walker, PhD<br>
            Environmental Data Scientist<br>
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
          <v-alert type="warning" outlined prominent>
            User Guide is under development
          </v-alert>
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

        <v-card-text class="my-4 black--text" v-if="theme">
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

          <v-divider class="my-8"></v-divider>

          <h2 v-if="theme.citations.length > 1">Citations </h2>
          <h2 v-else>Citation </h2>
          <p v-for="citation in theme.citations" :key="citation.text">
            {{citation.text}} <a :href="citation.url" target="_blank">{{ citation.url }}</a>.
          </p>

          <v-divider class="my-8"></v-divider>

          <disclaimer></disclaimer>
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
                  <v-icon v-else-if="item.id === 'gage-primary' || item.id === 'huc12-primary'">
                    {{ 'mdi-star' }}
                  </v-icon>
                  <v-icon v-else>
                    {{ 'mdi-table' }}
                  </v-icon>
                </template>
                <template v-slot:label="{ item }">
                  <span v-if="item.children" class="subtitle-1">
                    {{item.name}}
                  </span>
                  <span v-else-if="item.id === 'gage-primary' || item.id === 'huc12-primary'" class="font-weight-bold">
                    {{item.name}}
                  </span>
                  <span v-else>
                    {{item.name}}
                  </span>
                </template>
              </v-treeview>
            </v-col>
            <v-divider vertical></v-divider>
            <v-col class="d-flex">
              <div v-for="theme in themes.active" :key="theme.id" class="pt-4 black--text">
                <h2 class="mb-2">{{theme.title}}</h2>
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

              <div class="pt-4 black--text" style="width:100%" v-if="themes.active.length === 0">
                <v-alert color="success" prominent outlined icon="mdi-chevron-left">
                  Select a dataset from the list.
                </v-alert>

                <h4 class="title">About</h4>
                <p class="body-2">
                  Use the Dataset Browser to load a specific dataset into the application. Only one dataset can be loaded at any given time.
                </p>
                <p class="body-2">
                  Datasets are organized into two groups: Streamflow Gages and HUC12 Basins. The first group provides data associated
                  with USGS streamflow gages. The second group provides data
                  associated the pour pounts of all level-12 Hydrologic Unit Code (HUC12) basins in the region.
                </p>
                <p class="body-2">
                  Primary Datasets (<v-icon small>mdi-star</v-icon>) include a combination of the key variables
                  from the datasets within each group (either Gages or HUC12 Basins).
                </p>
                <p class="body-2">
                  The other datasets (<v-icon small>mdi-table</v-icon>) include all available variables for that dataset. Each of these datasets
                  corresponds to one of the datasets posted to the
                  <a href="https://www.sciencebase.gov/catalog/item/59b7ed9be4b08b1644df5d50" target="_blank">Science Base repository</a>
                  for the RESTORE project.
                </p>
                <h4 class="title">First Time Here?</h4>
                <p class="body-2">
                  Start with one of the Primary Datasets to begin exploring key metrics associated with either the Streamflow Gages or
                  HUC12 Basins. To explore a specific dataset in more detail, return here and load that dataset to access all available variables.
                </p>
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

import Disclaimer from '@/components/Disclaimer'

import DecadeDimension from '@/components/dimensions/DecadeDimension'
import SignifDimension from '@/components/dimensions/SignifDimension'

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
    Disclaimer,
    DecadeDimension,
    SignifDimension,
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
    // debug: process.env.NODE_ENV === 'development',
    debug: false,
    collapse: {
      dataset: false,
      tabs: false,
      legend: false,
      debug: false
    },
    tabs: {
      active: 0
    },
    filters: [],
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
    heights: {
      dataset: 0,
      legend: 0,
      debug: 0
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
    this.updateHeights()
    evt.$on('xf:filter', this.updateCounts)
  },
  beforeDestroy () {
    evt.$off('xf:filter', this.updateCounts)
  },
  watch: {
    variable () {
      this.updateHeights()
      this.variable && evt.$emit('map:render')
    },
    theme () {
      this.updateHeights()
    },
    collapse: {
      deep: true,
      handler () {
        this.updateHeights()
      }
    }
  },
  methods: {
    updateHeights () {
      this.$nextTick(() => {
        for (let x in this.$refs) {
          this.heights[x] = this.$refs[x] ? this.$refs[x].$el.clientHeight : 0
        }
      })
    },
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
    getValue (feature) {
      return getValueById(feature.id)
    },
    getFill (feature) {
      const value = this.getValue(feature)
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
      this.updateCounts()
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
