# theme: gage-solar

library(tidyverse)

source("functions.R")

theme <- load_theme("gage-solar")

variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables

# load dataset ------------------------------------------------------------

df_dataset <- load_dataset(theme, col_types = cols(
  .default = col_double(),
  site_no = col_character(),
  comid = col_character(),
  huc12 = col_character()
)) %>% 
  mutate(id = site_no) %>% 
  select(id, everything()) %>% 
  arrange(id) %>% 
  select(-decade) %>% 
  distinct()

out_dataset <- df_dataset %>% 
  select(id, variables$df$id)

dataset <- list(
  df = df_dataset,
  out = out_dataset
)

stopifnot(
  dataset$out %>% 
    filter(duplicated(id)) %>% 
    nrow() == 0
)

# layer -------------------------------------------------------------------

layer <- df_dataset %>% 
  select(id, site_no, comid, huc12, dec_long_va, dec_lat_va) %>% 
  distinct() %>% 
  create_layer()

ggplot(layer$sf) +
  geom_sf()

# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)

# feature data ------------------------------------------------------------

df_feature <- dataset$out %>% 
  group_by(id) %>% 
  nest(.key = "values") %>% 
  mutate(
    values = map(values, ~ as.list(.))
  ) %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature)
