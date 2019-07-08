# Streamflow Gage Covariates

library(tidyverse)
library(jsonlite)
library(glue)
library(xml2)
library(sf)
library(config)


config <- get()

theme_id <- "gage-cov"
theme_path <- file.path("../data/", theme_id)

stopifnot(dir.exists(theme_path))


# extract variables from sciencebase metadata -----------------------------

meta <- read_xml(file.path(config$sciencebase$dir, theme_id, "Summary of basin characteristics for NHD v.2 catchments in the southeastern U.S., 1950-2010 at USGS streamflow-gaging stations.xml"))
meta_attrs <- xml_find_all(meta, './eainfo/detailed/attr')

df_meta_vars <- tibble(
  i = 1:length(meta_attrs)
) %>% 
  mutate(
    el = map(i, ~ meta_attrs[.]),
    attrlabl = map_chr(el, ~ xml_text(xml_child(., "attrlabl"))),
    attrdef = map_chr(el, ~ xml_text(xml_child(., "attrdef"))),
    rdommin = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommin"))),
    rdommax = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/rdommax"))),
    attrunit = map_chr(el, ~ xml_text(xml_child(., "attrdomv/rdom/attrunit"))),
  ) %>% 
  mutate_at(vars(rdommin, rdommax), parse_number)
# View(df_meta_vars)

df_meta_vars %>% 
  select(-i, -el) %>% 
  write_csv(file.path(theme_path, "variables-meta.csv"), na = "")


# MANUAL ------------------------------------------------------------------

# copy variables from "variables-meta.csv" to "variables.csv"
# edit ranges, descriptions, units, etc


# load variables ----------------------------------------------------------

df_vars <- read_csv(file.path(theme_path, "variables.csv"), col_types = cols(
  id = col_character(),
  label = col_character(),
  units = col_character(),
  description = col_character(),
  value_min = col_double(),
  value_max = col_double(),
  type = col_character(),
  scale_domain_min = col_double(),
  scale_domain_max = col_double(),
  scale_transform = col_character(),
  formats_text = col_character(),
  formats_axis = col_character(),
  decadal = col_logical()
))

vars <- map(1:nrow(df_vars), ~ list(
  id = df_vars$id[.],
  label = df_vars$label[.],
  units = df_vars$units[.],
  type = df_vars$type[.],
  description = df_vars$description[.],
  scale = list(
    domain = c(df_vars$scale_domain_min[.], df_vars$scale_domain_max[.]),
    transform = df_vars$scale_transform[.]
  ),
  formats = list(
    text = df_vars$formats_text[.],
    axis = df_vars$formats_axis[.]
  )
))


# process data ------------------------------------------------------------

df_sb <- read_csv(file.path(config$sciencebase$dir, theme_id, "all_gage_covariates.csv"), col_types = cols(
  .default = col_double(),
  site_no = col_character(),
  huc12 = col_character(),
  aquifers = col_character(),
  cat_aquifers = col_character(),
  bedperm = col_character(),
  ecol3 = col_character(),
  cat_ecol3 = col_character(),
  hlr = col_character(),
  physio = col_character(),
  cat_physio = col_character(),
  soller = col_character(),
  cat_soller = col_character(),
  statsgo = col_character()
))

df <- df_sb %>% 
  select(-comid, -huc12, -dec_long_va, -dec_lat_va) %>% 
  rename(id = site_no)

stopifnot(all(!is.na(df)))

df %>% 
  write_csv(file.path(theme_path, "data.csv"), na = "")


# process spatial layer ---------------------------------------------------

df_layer <- df_sb %>% 
  select(id = site_no, huc12, lat = dec_lat_va, lon = dec_long_va)

sf_layer <- st_as_sf(df_layer, crs = 4326, coords = c("lon", "lat"))

plot(sf_layer)

st_write(sf_layer, dsn = file.path(theme_path, "layer.json"), driver = "GeoJSON", delete_dsn = TRUE)

# export theme config -----------------------------------------------------

ls_theme <- list(
  id = "gage-cov",
  title = "Streamflow Gages > Basin Characteristics",
  layer = list(
    url = glue("{theme_id}/layer.json")
  ),
  data = list(
    url = glue("{theme_id}/data.csv"),
    group = list(
      by = "id"
    )
  ),
  variables = vars
)
toJSON(ls_theme, auto_unbox = TRUE, pretty = TRUE)

write_json(ls_theme, path = file.path(theme_path, "theme.json"), auto_unbox = TRUE, pretty = TRUE)

# feature datasets ---------------------------------------------------------

decadal_vars <- df_vars %>% 
  filter(decadal) %>% 
  pull(id)

df_feature <- df %>% 
  arrange(id, decade) %>% 
  group_by(id) %>% 
  nest() %>% 
  mutate(
    constants = map(data, function (x) {
      x %>% 
        select(-decadal_vars) %>% 
        select(-decade) %>% 
        filter(row_number() == 1)
    }),
    decadals = map(data, function (x) {
      x %>% 
        arrange(decade) %>% 
        select(decadal_vars)
    })
  )


if (!dir.exists(file.path(theme_path, "features"))) {
  cat("Creating featured directory: ", file.path(theme_path, "features"), "\n", sep = "")
  dir.create(file.path(theme_path, "features"))
}

for (i in 1:nrow(df_feature)) {
  feature_data <- list(
    id = df_feature$id[[i]],
    values = c(as.list(df_feature$constants[[i]]), as.list(df_feature$decadals[[i]]))
  )
  write_json(feature_data, path = file.path(theme_path, "features", glue("{feature_data$id}.json")), auto_unbox = TRUE, pretty = TRUE)
}
