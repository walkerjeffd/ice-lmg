import * as crossfilter from 'crossfilter2'

const xf = crossfilter()

const byFeature = {
  map: new Map()
}

export function clearCrossfilter () {
  xf.remove(() => true)
  if (byFeature.group) byFeature.group.dispose()
  if (byFeature.dim) byFeature.dim.dispose()
  byFeature.map.clear()
}

export function setData (data, key) {
  clearCrossfilter()
  xf.add(data)
  byFeature.dim = xf.dimension(d => d[key])
}

export function setVariable (variable) {
  return new Promise((resolve) => {
    if (byFeature.group) byFeature.group.dispose()

    if (variable.type === 'num') {
      byFeature.group = byFeature.dim.group().reduce(
        (p, v) => {
          if (v[variable.id] === null) return p
          p.count += 1
          p.sum += v[variable.id]
          p.mean = p.count >= 1 ? p.sum / p.count : null
          return p
        },
        (p, v) => {
          if (v[variable.id] === null) return p
          p.count -= 1
          p.sum -= v[variable.id]
          p.mean = p.count >= 1 ? p.sum / p.count : null
          return p
        },
        () => {
          return {
            count: 0,
            sum: 0,
            mean: null
          }
        }
      )
    } else {
      byFeature.group = byFeature.dim.group().reduce(
        (p, v) => {
          if (v[variable.id] === null) return p
          p.count += 1
          p.mean = v[variable.id]
          return p
        },
        (p, v) => {
          if (v[variable.id] === null) return p
          p.count -= 1
          p.mean = v[variable.id]
          return p
        },
        () => {
          return {
            count: 0,
            mean: null
          }
        }
      )
    }

    byFeature.group.all().forEach(d => {
      byFeature.map.set(d.key, d.value) // d is a reference, automatically updates after filtering
    })

    resolve()
  })
}

export function getData () {
  return xf.all()
}

export function getValueById (id) {
  return byFeature.map.get(id)
}

export function getCrossfilter () {
  return xf
}

export function getFilteredCount () {
  return byFeature.group ? byFeature.group.all().filter(d => d.value.count > 0).length : 0
}

export function getTotalCount () {
  return byFeature.map.size
}
