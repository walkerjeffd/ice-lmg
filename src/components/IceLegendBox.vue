<template>
  <v-card class="ice-card elevation-10 mt-2">
    <v-toolbar dense dark color="primary">
      <h3>Legend</h3>
      <v-spacer></v-spacer>
      <v-menu v-model="settings" offset-x :close-on-content-click="false" nudge-right="10">
        <template v-slot:activator="{ on }">
          <v-btn icon small outline class="mt-2 grey lighten-2 elevation-2" light v-on="on">
            <v-icon>mdi-settings-outline</v-icon>
          </v-btn>
        </template>
        <v-card width="400">
          <v-toolbar color="grey" dense dark>
            <h3>Legend Settings</h3>
            <v-spacer></v-spacer>
            <v-btn icon small outline @click="settings = false" class="mt-2 grey lighten-2 elevation-2" light>
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-toolbar>
          <v-autocomplete
            :items="schemes"
            v-model="colorScheme"
            full-width
            box
            hide-details
            class="pt-3 pb-0"
            label="Select color scheme...">
            <template v-slot:selection="data">
              <color-bar :id="`settings-selected`" :scheme="data.item" :invert="colorInvert" :width="200" :height="18"></color-bar>
              <span class="ml-4">{{ data.item }}</span>
            </template>
            <template v-slot:item="data">
              <color-bar :id="`settings-${data.item}`" :scheme="data.item" :invert="colorInvert" :width="200" :height="18"></color-bar>
              <span class="ml-4">{{ data.item }}</span>
            </template>
          </v-autocomplete>

          <v-list>
            <v-list-tile>
              <v-list-tile-action>
                <v-switch v-model="colorInvert" color="orange"></v-switch>
              </v-list-tile-action>
              <v-list-tile-title>Invert Color Scheme</v-list-tile-title>
            </v-list-tile>
          </v-list>
          <!-- <v-autocomplete
            :items="types.options"
            v-model="types.selected"
            full-width
            box
            hide-details
            class="py-3"
            label="Select scale type...">
          </v-autocomplete> -->
          <v-divider></v-divider>
          <v-card-actions class="">
            <v-spacer></v-spacer>
            <v-btn flat color="primary" @click="settings = false">Close</v-btn>
          </v-card-actions>
        </v-card>
      </v-menu>
      <v-btn icon small outline @click="hide = !hide" class="mt-2 grey lighten-2 elevation-2" light>
        <v-icon v-if="!hide">mdi-menu-up</v-icon>
        <v-icon v-else>mdi-menu-down</v-icon>
      </v-btn>
    </v-toolbar>
    <v-card-text v-if="!hide && variable">
      <ice-legend id="legend" class="pt-3" v-if="variable"></ice-legend>
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
</template>

<script>
import { mapGetters } from 'vuex'

import IceLegend from '@/components/IceLegend'
import ColorBar from '@/components/ColorBar'
import variableMixin from '@/mixins/variable'
import { colorSchemes } from '@/lib/constants'
import evt from '@/lib/events'

export default {
  name: 'IceLegendBox',
  mixins: [variableMixin],
  components: {
    IceLegend,
    ColorBar
  },
  data () {
    return {
      hide: false,
      settings: false,
      schemes: colorSchemes,
      types: {
        options: ['Continuous', 'Quantile'],
        selected: 'Continuous'
      }
    }
  },
  computed: {
    ...mapGetters(['variable']),
    colorScheme: {
      get () {
        return this.$store.getters.colorScheme
      },
      set (value) {
        return this.$store.dispatch('setColorScheme', value)
          .then(() => {
            evt.$emit('map:render')
          })
      }
    },
    colorInvert: {
      get () {
        return this.$store.getters.colorInvert
      },
      set (value) {
        return this.$store.dispatch('setColorInvert', value)
          .then(() => {
            evt.$emit('map:render')
          })
      }
    }
  }
}
</script>
