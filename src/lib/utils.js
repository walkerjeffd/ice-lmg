import { nest } from 'd3'

export function groupVariables (variables) {
  const groups = nest()
    .key(d => d.group)
    .entries(variables)

  const options = []
  groups.forEach((g, i) => {
    if (i > 0) options.push({ divider: true })

    options.push({ header: g.key })
    g.values.forEach(v => {
      options.push(v)
    })
  })

  return options
}
