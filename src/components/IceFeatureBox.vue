<template>
  <v-card class="mb-3">
    <v-toolbar dense height="32" color="grey lighten-2" flat>
      <h4>
        <slot name="title"></slot>
      </h4>
      <v-spacer></v-spacer>
      <v-btn icon small @click="hide = !hide">
        <v-icon v-if="!hide">mdi-menu-up</v-icon>
        <v-icon v-else>mdi-menu-down</v-icon>
      </v-btn>
    </v-toolbar>
    <v-divider></v-divider>
    <slot v-if="!hide"></slot>
  </v-card>
</template>

<script>
export default {
  name: 'IceFeatureBox',
  data () {
    return {
      hide: false
    }
  }
}
</script>
