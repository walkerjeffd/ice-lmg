parse_xml_attrs <- function (xml_attrs) {
  tibble(
    i = 1:length(xml_attrs)
  ) %>% 
    mutate(
      el = map(i, ~ xml_attrs[.]),
      attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
      attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
      rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
      rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
      attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
    ) %>% 
    mutate_at(vars(rdommin, rdommax), parse_number) %>% 
    select(
      variable = attrlabl,
      description = attrdef,
      unit = attrunit,
      value_min = rdommin,
      value_max = rdommax
    )
}
