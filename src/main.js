import Vue from 'vue'

import './plugins/highcharts'
import './plugins/leaflet'
import './plugins/axios'
import './plugins/dc'
import './plugins/vue2-filters'

import '@/assets/styles.css'

import App from './App.vue'
import store from './store'
import vuetify from './plugins/vuetify'

Vue.config.productionTip = false

new Vue({
  store,
  vuetify,
  render: h => h(App)
}).$mount('#app')
