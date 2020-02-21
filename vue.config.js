module.exports = {
  publicPath: process.env.NODE_ENV === 'production' ? '/lmg-restore/' : '/',
  'transpileDependencies': [
    'vuetify'
  ]
}
