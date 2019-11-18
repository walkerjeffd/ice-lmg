import Vue from 'vue'

const eventTypes = [
  'map:render',
  'map:zoom',
  'xf:filter',
  'theme:set',
  'filter:render',
  'resize'
]

const evt = new Vue()

if (process.env.NODE_ENV === 'development') eventTypes.forEach((d) => evt.$on(d, () => console.log(d)))

export default evt
