# theme: gage-solar

library(tidyverse)
library(jsonlite)
library(glue)
library(xml2)
library(sf)
library(readxl)

config <- config::get()

source("functions.R")

theme_id <- "gage-solar"
theme_path <- file.path("../data/", theme_id)

if (!dir.exists(theme_path)) {
  cat(glue("Creating theme directory: {theme_path}"), "\n")
  dir.create(theme_path)
}


# load variables from xml metadata ----------------------------------------

xml <- read_xml(file.path(config$data_dir, "sciencebase", "gage-solar", "Solar radiation for NHD, v.2 catchments in the southeastern U.S., 1950-2010 at USGS streamflow-gaging stations.xml"))
xml_find_all(xml, './eainfo/detailed') # only one file
xml_attrs <- xml_find_all(xml, './eainfo/detailed[1]/attr')

df_vars <- parse_xml_attrs(xml_attrs)


# load dataset ------------------------------------------------------------

df_dataset_decade <- read_csv(file.path(config$data_dir, "sciencebase", "gage-solar", "all_gage_solar.csv"), col_types = cols(
  .default = col_double(),
  site_no = col_character(),
  comid = col_character(),
  huc12 = col_character()
)) %>% 
  arrange(site_no, decade)

# none of the sites have values varying by decade
df_dataset_decade %>% 
  select(site_no, decade, starts_with("dni_")) %>% 
  gather(var, value, starts_with("dni_")) %>% 
  group_by(site_no, var) %>% 
  summarise(
    range = diff(range(value))
  ) %>% 
  ungroup() %>% 
  filter(range > 0) %>% 
  nrow()

# drop decade dimension
df_dataset <- df_dataset_decade %>% 
  select(-decade) %>% 
  distinct()

# output dataset
out_dataset <- df_dataset %>% 
  select(-dec_long_va, -dec_lat_va) %>% 
  select(id = site_no, starts_with("dni_"))
stopifnot(all(!duplicated(out_dataset$id)))

# layer -------------------------------------------------------------------

df_layer <- df_dataset %>% 
  select(id = site_no, comid, huc12, dec_long_va, dec_lat_va)
stopifnot(all(!duplicated(df_layer$id)))

# duplicated comids
# stopifnot(all(!duplicated(df_layer$comid)))
df_layer %>% 
  group_by(comid) %>% 
  mutate(n = n()) %>% 
  filter(n > 1)

df_dataset %>%
  filter(comid == 766886)

sf_layer <- st_as_sf(df_layer, crs = 4326, coords = c("dec_long_va", "dec_lat_va"))

ggplot(sf_layer) +
  geom_sf()


# variables ---------------------------------------------------------------

df_vars %>%
  filter(
    !variable %in% c("comid", "site_no", "huc12", "decade", "dec_long_va", "dec_lat_va")
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
    )
  ))

# export ------------------------------------------------------------------

# rds
list(
  variables = df_vars,
  layer = sf_layer,
  dataset = df_dataset
) %>% 
  saveRDS("rds/gage-solar.rds")

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

for (i in 1:nrow(df_dataset)) {
  feature_data <- list(
    id = df_dataset$site_no[[i]],
    values = df_dataset %>%
      filter(site_no == df_dataset$site_no[[i]]) %>% 
      select(starts_with("dni_")) %>% 
      as.list()
  )
  write_json(feature_data, path = file.path(theme_path, "features", glue("{feature_data$id}.json")), auto_unbox = TRUE, pretty = TRUE)
}
