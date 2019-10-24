module.exports = {
  publicPath: process.env.NODE_ENV === 'production' ? '/lmg-dev-v2/' : '/',
  'transpileDependencies': [
    'vuetify'
  ]
}
