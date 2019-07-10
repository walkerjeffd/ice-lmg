# theme: huc12-solar

library(tidyverse)
library(jsonlite)
library(glue)
library(xml2)
library(sf)
library(readxl)

config <- config::get()

source("functions.R")

theme_id <- "huc12-solar"
theme_path <- file.path("../data/", theme_id)

if (!dir.exists(theme_path)) {
  cat(glue("Creating theme directory: {theme_path}"), "\n")
  dir.create(theme_path)
}



# variables ---------------------------------------------------------------

xml <- read_xml(file.path(config$data_dir, "sciencebase", theme_id, "Solar radiation for HND, v.2 catchments in the southeastern U.S., 1950-2010 at 12-digit hydrologic unit code (HUC12) pour points.xml"))
xml_find_all(xml, './eainfo/detailed') # only one file
xml_attrs <- xml_find_all(xml, './eainfo/detailed[1]/attr')

meta_vars <- parse_xml_attrs(xml_attrs)

meta_vars %>%
  filter(
    !variable %in% c("comid", "site_no", "huc12", "decade", "dec_long_va", "dec_lat_va")
  ) %>% 
  write_csv(file.path(theme_path, "meta-variables.csv"))

# MANUAL: copy meta-variables.csv to themes.xlsx$variables

theme_config <- read_xlsx(file.path(config$data_dir, "themes.xlsx"), sheet = "themes") %>% 
  filter(id == theme_id) %>% 
  as.list()
df_vars <- read_xlsx(file.path(config$data_dir, "themes.xlsx"), sheet = "variables") %>% 
  filter(theme == theme_id)

out_vars <- map(1:nrow(df_vars), ~ list(
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


# load dataset ------------------------------------------------------------

df_dataset <- read_csv(file.path(config$data_dir, "sciencebase", theme_id, "all_huc12_solar.csv"), col_types = cols(
  .default = col_double(),
  comid = col_character(),
  huc12 = col_character()
)) %>% 
  select(-decade) %>% 
  mutate(id = str_c(huc12, as.character(comid), sep = "-")) %>% 
  distinct() %>% 
  select(id, everything())

# output dataset
out_dataset <- df_dataset %>% 
  select(id, df_vars$id) %>% 
  distinct()
stopifnot(all(!duplicated(out_dataset$id)))

# layer -------------------------------------------------------------------

df_layer <- df_dataset %>% 
  select(id, comid, huc12, dec_long_va, dec_lat_va) %>% 
  distinct() %>% 
  group_by(id) %>% 
  filter(row_number() == 1)
stopifnot(all(!duplicated(df_layer$id)))

sf_layer <- st_as_sf(df_layer, crs = 4326, coords = c("dec_long_va", "dec_lat_va"))

ggplot(sf_layer) +
  geom_sf()

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
    id = df_dataset$id[[i]],
    values = df_dataset %>%
      filter(id == df_dataset$id[[i]]) %>% 
      select(df_vars$id) %>% 
      as.list()
  )
  write_json(feature_data, path = file.path(theme_path, "features", glue("{feature_data$id}.json")), auto_unbox = TRUE, pretty = TRUE)
}

