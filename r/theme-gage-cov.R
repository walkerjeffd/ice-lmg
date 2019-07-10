# theme: gage-cov

library(tidyverse)

source("functions.R")

theme <- load_theme("gage-cov")

variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables

# load dataset ------------------------------------------------------------

df_dataset <- load_dataset(theme, col_types = cols(
  .default = col_double(),
  site_no = col_character(),
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
  mutate(id = site_no) %>% 
  select(id, everything()) %>% 
  arrange(id, decade)

out_dataset <- df_dataset %>% 
  select(id, decade, variables$df$id)

dataset <- list(
  df = df_dataset,
  out = out_dataset
)

stopifnot(
  dataset$out %>% 
    mutate(id_decade = str_c(id, decade, sep = "-")) %>% 
    filter(duplicated(id_decade)) %>% 
    nrow() == 0
)

# layer -------------------------------------------------------------------

layer <- df_dataset %>% 
  select(id, site_no, comid, huc12, dec_long_va, dec_lat_va) %>% 
  distinct() %>% 
  create_layer()

layer$df %>%
  filter(comid == 766886)

ggplot(layer$sf) +
  geom_sf()

# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)

# feature data ------------------------------------------------------------

df_feature <- dataset$out %>% 
  group_by(id) %>% 
  nest(.key = "values") %>% 
  mutate(
    values = map(values, function (x) {
      x %>% 
        arrange(decade)
    })
  ) %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature)
