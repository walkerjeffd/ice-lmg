<template>
  <ice-feature-box>
    <template v-slot:title>Gage Properties</template>
    <v-list dense v-if="properties">
      <v-list-item>
        <v-list-item-content class="align-start">Site Number</v-list-item-content>
        <v-list-item-content class="align-end">{{ properties.site_no }}</v-list-item-content>
      </v-list-item>
      <v-list-item>
        <v-list-item-content class="align-start">HUC12</v-list-item-content>
        <v-list-item-content class="align-end">{{ properties.huc12 }}</v-list-item-content>
      </v-list-item>
      <v-list-item>
        <v-list-item-content class="align-start">Latitude</v-list-item-content>
        <v-list-item-content class="align-end">{{ properties.dec_lat_va  }}</v-list-item-content>
      </v-list-item>
      <v-list-item>
        <v-list-item-content class="align-start">Longitude</v-list-item-content>
        <v-list-item-content class="align-end">{{ properties.dec_long_va  }}</v-list-item-content>
      </v-list-item>
    </v-list>
  </ice-feature-box>
</template>

<script>
import IceFeatureBox from '@/components/IceFeatureBox'
export default {
  name: 'IceGagePropertiesBox',
  props: ['properties'],
  components: {
    IceFeatureBox
  }
}
</script>
