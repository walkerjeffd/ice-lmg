<template>
  <div>
    <v-toolbar dense dark color="primary">
      <h3 class="headline mb-0"><slot name="title"></slot></h3>
      <v-spacer></v-spacer>
      <v-btn icon color="white" @click="$emit('close')">
        <v-icon>mdi-close</v-icon>
      </v-btn>
    </v-toolbar>
    <v-card-text>
      <slot></slot>
      <ice-feature-box>
        <template v-slot:title><span v-if="theme.citations.length > 1">Citations</span><span v-else>Citation</span></template>
        <v-card-text class="pb-0">
          <div v-for="citation in theme.citations" :key="citation.text">
            {{ citation.text }} <br />
            <v-btn small text outlined color="primary" :href="citation.url" target="_blank" class="text-capitalize mt-2 mb-4">
              Sciencebase <v-icon small right>mdi-open-in-new</v-icon>
            </v-btn>
          </div>
        </v-card-text>
      </ice-feature-box>
    </v-card-text>
  </div>
</template>

<script>
import { mapGetters } from 'vuex'

import IceFeatureBox from '@/components/IceFeatureBox'

export default {
  name: 'IceFeatureContainer',
  components: {
    IceFeatureBox
  },
  computed: {
    ...mapGetters(['theme'])
  }
}
</script>
