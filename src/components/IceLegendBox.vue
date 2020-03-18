<template>
  <v-card
    width="250"
    style="position:absolute;bottom:0;right:0;background:rgba(255,255,255,0.75)"
    class="mr-3 mb-7 black--text font-weight-medium">
    <v-toolbar dense dark color="primary">
      <div class="subtitle-1 font-weight-bold">Legend</div>
      <v-spacer></v-spacer>
      <v-menu v-model="settings" :close-on-content-click="false" nudge-top="200px">
        <template v-slot:activator="{ on }">
          <v-btn icon small v-on="on" :disabled="!variable || variable.type === 'cat'">
            <v-icon small>mdi-settings</v-icon>
          </v-btn>
        </template>
        <v-card width="400">
          <v-toolbar color="grey darken-2" dense dark>
            <div class="subtitle-1 font-weight-bold">Legend Settings</div>
            <v-spacer></v-spacer>
            <v-btn icon small @click="settings = false">
              <v-icon small>mdi-close</v-icon>
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
        </v-card>
      </v-menu>
      <v-btn icon small @click="$emit('collapse')">
        <v-icon small v-if="!collapse">mdi-menu-up</v-icon>
        <v-icon small v-else>mdi-menu-down</v-icon>
      </v-btn>
    </v-toolbar>
    <div v-if="variable && !collapse" class="pt-4 pb-2 px-1">
      <div class="pl-2 pb-2">Filtered: {{ counts.filtered.toLocaleString() }} of {{ counts.total.toLocaleString() }}</div>

      <div class="pl-2">
        <v-tooltip left max-width="400">
          <template v-slot:activator="{ on }">
            <span v-on="on" style="border-bottom:1px dotted;cursor:inherit">{{ variable.label }}<span v-if="variable.units">&nbsp;({{ variable.units }})</span></span>
          </template>
          {{ variable.description }}
        </v-tooltip>
      </div>

      <ice-continuous-legend id="legend" class="pt-1" v-if="variable && variable.type === 'num'"></ice-continuous-legend>
      <ice-discrete-legend id="legend" class="pt-1" v-if="variable && variable.type === 'cat'"></ice-discrete-legend>
    </div>
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
  props: ['collapse', 'counts'],
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
