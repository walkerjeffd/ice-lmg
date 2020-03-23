import Vue from 'vue'

const evt = new Vue()

const eventTypes = [
  'map:render',
  'map:zoom',
  'xf:filter',
  'theme:set',
  'filter:render',
  'resize'
]

if (process.env.NODE_ENV === 'development') eventTypes.forEach((d) => evt.$on(d, () => console.log(d)))

export default evt
