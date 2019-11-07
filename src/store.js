import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios'
import { csvParse, extent } from 'd3'

import { setData, getData, setVariable } from '@/lib/crossfilter'

Vue.use(Vuex)

export default new Vuex.Store({
  state: {
    theme: null,
    variable: null,
    settings: {
      color: {
        scheme: 'Viridis',
        type: 'continuous',
        invert: false
      }
    }
  },
  getters: {
    theme: state => state.theme,
    variables: state => (state.theme ? state.theme.variables : []),
    variable: state => state.variable,
    variableById: state => id => {
      return state.theme ? state.theme.variables.find(v => v.id === id) : null
    },
    layer: state => (state.theme ? state.theme.layer : null),
    colorScheme: state => state.settings.color.scheme,
    colorType: state => state.settings.color.type,
    colorInvert: state => state.settings.color.invert
  },
  mutations: {
    SET_THEME (state, theme) {
      state.theme = theme
    },
    SET_VARIABLE (state, variable) {
      state.variable = variable
    },
    SET_COLOR_SCHEME (state, scheme) {
      state.settings.color.scheme = scheme
    },
    SET_COLOR_TYPE (state, type) {
      state.settings.color.type = type
    },
    SET_COLOR_INVERT (state, invert) {
      state.settings.color.invert = invert
    }
  },
  actions: {
    clearTheme ({ commit }) {
      commit('SET_THEME', null)
      commit('SET_VARIABLE', null)
      return Promise.resolve(null)
    },
    loadTheme ({ commit, dispatch }, theme) {
      if (!theme) {
        return dispatch('clearTheme')
      }

      return dispatch('clearTheme')
        .then(() => axios.get(`/${theme.id}/theme.json`))
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
                  id: d.id
                }

                if (theme.dimensions.decade) {
                  x.decade = d.decade
                }

                if (theme.dimensions.mklevel) {
                  x.mklevel = d.mklevel
                }

                theme.variables.forEach(v => {
                  x[v.id] = v.type === 'num' ? (d[v.id] === '' ? null : +d[v.id]) : d[v.id]
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
    },
    setColorScheme ({ commit }, scheme) {
      return commit('SET_COLOR_SCHEME', scheme)
    },
    setColorType ({ commit }, type) {
      return commit('SET_COLOR_TYPE', type)
    },
    setColorInvert ({ commit }, invert) {
      return commit('SET_COLOR_INVERT', invert)
    }
  }
})
