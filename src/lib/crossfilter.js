import * as crossfilter from 'crossfilter2'

const xf = crossfilter()
// const all = xf.groupAll()

const byFeature = {
  map: new Map()
}

export function setData (data, key) {
  xf.remove(() => true)
  xf.add(data)

  if (byFeature.dim) byFeature.dim.dispose()

  byFeature.dim = xf.dimension(d => d[key])
  byFeature.map.clear()
}

export function setVariable (variable) {
  return new Promise((resolve, reject) => {
    if (byFeature.group) byFeature.group.dispose()

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
  // return all.value()
  return byFeature.group.all().filter(d => d.value.count > 0).length
}

export function getTotalCount () {
  return byFeature.map.size
  // return xf.size()
}
