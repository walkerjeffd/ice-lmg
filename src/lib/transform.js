export default {
  transform (type) {
    switch (type) {
      case 'log':
        return d => Math.log10(d)
      case 'log1p':
        return d => Math.log10(d + 1)
      default:
        return d => d
    }
  },
  inverse (type) {
    switch (type) {
      case 'log':
        return d => Math.pow(10, d)
      case 'log1p':
        return d => Math.pow(10, d) - 1
      default:
        return d => d
    }
  }
}
