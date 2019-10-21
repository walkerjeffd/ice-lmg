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
        <v-card-text>
          <a :href="theme.citation.url" target="_blank">{{ theme.citation.text }}</a>
          <span class="px-2"><v-icon small>mdi-open-in-new</v-icon></span>
          <span>[<em class="px-1">Sciencebase</em>]</span>
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
