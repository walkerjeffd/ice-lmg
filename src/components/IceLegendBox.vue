<template>
  <v-card class="ice-card elevation-10 mt-2">
    <v-toolbar dense dark color="primary">
      <h4>Legend</h4>
      <v-spacer></v-spacer>
      <v-menu v-model="settings" offset-x :close-on-content-click="false" nudge-right="60px">
        <template v-slot:activator="{ on }">
          <v-btn icon small v-on="on" :disabled="!variable || variable.type === 'cat'">
            <v-icon small>mdi-settings-outline</v-icon>
          </v-btn>
        </template>
        <v-card width="400">
          <v-toolbar color="grey" dense dark>
            <h4>Legend Settings</h4>
            <v-spacer></v-spacer>
            <v-btn icon small @click="settings = false">
              <v-icon>mdi-close</v-icon>
            </v-btn>
          </v-toolbar>
          <v-autocomplete
            :items="schemes"
            v-model="colorScheme"
            full-width
            filled
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
            <v-list-item>
              <v-list-item-action>
                <v-switch v-model="colorInvert" color="orange"></v-switch>
              </v-list-item-action>
              <v-list-item-content>Invert Color Scheme</v-list-item-content>
            </v-list-item>
          </v-list>
          <v-divider></v-divider>
          <v-card-actions class="">
            <v-spacer></v-spacer>
            <v-btn text color="primary" @click="settings = false">Close</v-btn>
          </v-card-actions>
        </v-card>
      </v-menu>
      <v-btn icon small @click="$emit('collapse')">
        <v-icon small v-if="!collapse">mdi-menu-up</v-icon>
        <v-icon small v-else>mdi-menu-down</v-icon>
      </v-btn>
    </v-toolbar>
    <v-card-text v-if="!collapse && variable">
      <ice-continuous-legend id="legend" class="pt-3" v-if="variable && variable.type === 'num'"></ice-continuous-legend>
      <ice-discrete-legend id="legend" class="pt-3" v-if="variable && variable.type === 'cat'"></ice-discrete-legend>
      <div class="text-center grey--text text--darken-2 font-weight-medium" v-if="variable">
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

import IceContinuousLegend from '@/components/IceContinuousLegend'
import IceDiscreteLegend from '@/components/IceDiscreteLegend'
import ColorBar from '@/components/ColorBar'
import variableMixin from '@/mixins/variable'
import { colorSchemesContinuous } from '@/lib/constants'
import evt from '@/lib/events'

export default {
  name: 'IceLegendBox',
  mixins: [variableMixin],
  props: ['collapse'],
  components: {
    IceContinuousLegend,
    IceDiscreteLegend,
    ColorBar
  },
  data () {
    return {
      settings: false,
      schemes: colorSchemesContinuous
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
