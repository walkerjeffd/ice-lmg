<template>
  <div>
    <v-toolbar dense dark color="primary">
      <h3 class="headline mb-0"><slot name="title"></slot></h3>
      <v-spacer></v-spacer>
      <v-btn flat icon color="white" @click="$emit('close')">
        <v-icon>mdi-close</v-icon>
      </v-btn>
    </v-toolbar>
    <v-card-text>
      <slot></slot>
      <ice-feature-box>
        <template v-slot:title>Citation</template>
        <v-card-text class="pb-0">
          {{ theme.citation.text }}
        </v-card-text>
        <v-card-actions>
          <v-btn small text outline color="primary" :href="theme.citation.url" target="_blank" class="text-capitalize ml-1">
            Sciencebase <v-icon small right>mdi-open-in-new</v-icon>
          </v-btn>
        </v-card-actions>
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
