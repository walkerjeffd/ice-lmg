import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios'
import { csvParse, extent } from 'd3'

import { setData, getData, setVariable } from '@/lib/crossfilter'

Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    theme: null,
    variable: null
  },
  getters: {
    theme: state => state.theme,
    variables: state => (state.theme ? state.theme.variables : []),
    variable: state => state.variable,
    variableById: state => id => {
      return state.theme.variables.find(v => v.id === id)
    },
    layer: state => (state.theme ? state.theme.layer : null)
  },
  mutations: {
    SET_THEME (state, theme) {
      state.theme = theme
    },
    SET_VARIABLE (state, variable) {
      state.variable = variable
    }
  },
  actions: {
    loadTheme ({ commit, dispatch }, theme) {
      if (!theme) {
        commit('SET_THEME', null)
        return
      }

      return axios.get(`/${theme.id}/theme.json`)
        .then((response) => {
          const theme = response.data
          const variable = theme.variables[0]

          return { theme, variable }
        })
        .then(({ theme, variable }) => {
          return axios.get(theme.data.url)
            .then((response) => response.data)
            .then((csvString) => {
              return csvParse(csvString, (d, i) => {
                const x = {
                  $index: i,
                  id: d.id,
                  decade: d.decade
                }

                theme.variables.forEach(v => {
                  x[v.id] = v.type === 'num' ? +d[v.id] : d[v.id]
                })

                return x
              })
            })
            .then(data => ({ theme, variable, data }))
        })
        .then(({ theme, variable, data }) => {
          setData(data, theme.data.group.by)

          commit('SET_THEME', theme)
          return dispatch('setVariable', variable)
        })
    },
    setVariable ({ commit }, variable) {
      const values = getData().map(d => d[variable.id])
      variable.extent = extent(values)
      return setVariable(variable)
        .then(() => commit('SET_VARIABLE', variable))
    }
  }
})
