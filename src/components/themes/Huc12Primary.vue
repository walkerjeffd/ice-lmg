<template>
  <ice-feature-container v-if="selected" @close="$emit('close')">
    <template v-slot:title>
      Selected HUC12: {{selected.properties.huc12}}
    </template>

    <div v-if="dataset">
      <ice-huc12-properties-box :properties="dataset.properties"></ice-huc12-properties-box>
    </div>
    <div v-else>
      Loading...
    </div>
  </ice-feature-container>
</template>

<script>
import themeSelect from '@/mixins/themeSelect'

export default {
  name: 'Huc12Primary',
  mixins: [themeSelect],
  methods: {
    updateCharts () {
      this.clearCharts()
    }
  }
}
</script>
