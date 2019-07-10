import Vue from 'vue'

import './plugins/vuetify'
import './plugins/highcharts'
import './plugins/leaflet'
import './plugins/axios'
import './plugins/dc'

import 'dc/dc.css'
import '@/assets/styles.css'

import App from './App.vue'
import store from './store'

Vue.config.productionTip = false

new Vue({
  store,
  render: h => h(App)
}).$mount('#app')
