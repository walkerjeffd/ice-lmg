# theme: huc12-cov

library(tidyverse)
library(jsonlite)
library(glue)
library(xml2)
library(sf)
library(readxl)

config <- config::get()

source("functions.R")

theme_id <- "huc12-cov"
theme_path <- file.path("../data/", theme_id)

if (!dir.exists(theme_path)) {
  cat(glue("Creating theme directory: {theme_path}"), "\n")
  dir.create(theme_path)
}


# load variables from xml metadata ----------------------------------------

xml <- read_xml(file.path(config$data_dir, "sciencebase", theme_id, "Summary of basin characteristics for NHD, v.2 catchments in the southeastern U.S., 1950-2010 at 12-digit hydrologic unit code (HUC12) pour points.xml"))
xml_find_all(xml, './eainfo/detailed') # only one file
xml_attrs <- xml_find_all(xml, './eainfo/detailed[1]/attr')

df_vars <- parse_xml_attrs(xml_attrs)

# load dataset ------------------------------------------------------------

df_dataset <- read_csv(file.path(config$data_dir, "sciencebase", theme_id, "all_huc12_covariates.csv"), col_types = cols(
  .default = col_double(),
  comid = col_character(),
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
)) %>% 
  arrange(huc12, comid, decade)

# output dataset (combine huc12-comid to generate unique id field)
out_dataset <- df_dataset %>% 
  mutate(id = str_c(huc12, as.character(comid), sep = "-")) %>% 
  select(-huc12, -comid, -dec_long_va, -dec_lat_va) %>% 
  select(id, everything()) %>% 
  distinct()
stopifnot(
  out_dataset %>% 
    mutate(id_decade = str_c(id, decade)) %>% 
    filter(duplicated(id_decade)) %>% 
    nrow() == 0
)

# layer -------------------------------------------------------------------

df_layer <- df_dataset %>% 
  mutate(id = str_c(huc12, as.character(comid), sep = "-")) %>% 
  select(id, huc12, comid, dec_long_va, dec_lat_va) %>% 
  group_by(id) %>%
  filter(row_number() == 1)
stopifnot(all(!duplicated(df_layer$id)))

sf_layer <- st_as_sf(df_layer, crs = 4326, coords = c("dec_long_va", "dec_lat_va"))

ggplot(sf_layer) +
  geom_sf()


# variables ---------------------------------------------------------------

df_vars %>%
  filter(
    !variable %in% c("comid", "huc12", "decade", "dec_long_va", "dec_lat_va")
  ) %>% 
  write_csv(file.path(theme_path, "meta-variables.csv"))

# MANUAL: copy meta-variables.csv to themes.xlsx$variables

theme_config <- read_xlsx(file.path(config$data_dir, "themes.xlsx"), sheet = "themes") %>% 
  filter(id == theme_id) %>% 
  as.list()
vars_config <- read_xlsx(file.path(config$data_dir, "themes.xlsx"), sheet = "variables") %>% 
  filter(theme == theme_id)

out_vars <- map(1:nrow(vars_config), ~ list(
  id = vars_config$id[.],
  label = vars_config$label[.],
  units = vars_config$units[.],
  type = vars_config$type[.],
  description = vars_config$description[.],
  scale = list(
    domain = c(vars_config$scale_domain_min[.], vars_config$scale_domain_max[.]),
    transform = vars_config$scale_transform[.]
  ),
  formats = list(
    text = vars_config$formats_text[.],
    axis = vars_config$formats_axis[.]
  ),
  dims = list(
    decade = vars_config$dims_decade[.]
  )
))

# export ------------------------------------------------------------------

# rds
list(
  variables = df_vars,
  layer = sf_layer,
  dataset = df_dataset
) %>% 
  saveRDS(glue("rds/{theme_id}.rds"))

# layer (geojson)
sf_layer %>% 
  st_write(dsn = file.path(theme_path, "layer.json"), driver = "GeoJSON", delete_dsn = TRUE, layer_options = "ID_FIELD=id")

# dataset (csv)
out_dataset %>% 
  write_csv(file.path(theme_path, "data.csv"))

# theme (json)
list(
  id = theme_id,
  title = str_c(if_else(theme_config$group == "gage", "Gages > ", "HUC12s > "), theme_config$name),
  layer = list(
    url = glue("{theme_id}/layer.json")
  ),
  data = list(
    url = glue("{theme_id}/data.csv"),
    group = list(
      by = "id"
    )
  ),
  variables = out_vars
) %>% 
  write_json(path = file.path(theme_path, "theme.json"), auto_unbox = TRUE, pretty = TRUE)


# export data by feature --------------------------------------------------

if (!dir.exists(file.path(theme_path, "features"))) {
  cat(glue("Creating theme/features directory: {file.path(theme_path, 'features')}"), "\n")
  dir.create(file.path(theme_path, "features"))
}

df_feature <- out_dataset %>% 
  arrange(id, decade) %>% 
  group_by(id) %>% 
  nest() %>% 
  mutate(
    values = map(data, function (x) {
      x %>% 
        select(-decade) %>% 
        select(filter(vars_config, !dims_decade)$id) %>% 
        filter(row_number() == 1)
    }),
    arrays = map(data, function (x) {
      x %>% 
        arrange(decade) %>% 
        select(filter(vars_config, dims_decade)$id)
    })
  )

for (i in 1:nrow(df_feature)) {
  feature_data <- list(
    id = df_feature$id[[i]],
    values = c(as.list(df_feature$values[[i]]), as.list(df_feature$arrays[[i]]))
  )
  write_json(feature_data, path = file.path(theme_path, "features", glue("{feature_data$id}.json")), auto_unbox = TRUE, pretty = TRUE)
}
