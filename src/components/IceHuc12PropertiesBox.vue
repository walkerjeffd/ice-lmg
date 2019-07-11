<template>
  <ice-feature-box>
    <template v-slot:title>HUC12 Properties</template>
    <v-list dense v-if="properties">
      <v-list-tile>
        <v-list-tile-content class="align-start">HUC12</v-list-tile-content>
        <v-list-tile-content class="align-end">{{ properties.huc12 }}</v-list-tile-content>
      </v-list-tile>
      <v-list-tile>
        <v-list-tile-content class="align-start">Latitude</v-list-tile-content>
        <v-list-tile-content class="align-end">{{ properties.dec_lat_va  }}</v-list-tile-content>
      </v-list-tile>
      <v-list-tile>
        <v-list-tile-content class="align-start">Longitude</v-list-tile-content>
        <v-list-tile-content class="align-end">{{ properties.dec_long_va  }}</v-list-tile-content>
      </v-list-tile>
    </v-list>
  </ice-feature-box>
</template>

<script>
import IceFeatureBox from '@/components/IceFeatureBox'
export default {
  name: 'IceHuc12PropertiesBox',
  props: ['properties'],
  components: {
    IceFeatureBox
  }
}
</script>
