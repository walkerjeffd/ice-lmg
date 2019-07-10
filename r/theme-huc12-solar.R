# theme: huc12-solar

library(tidyverse)

source("functions.R")

theme <- load_theme("huc12-solar")

variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables

# load dataset ------------------------------------------------------------

df_dataset <- load_dataset(theme, col_types = cols(
  .default = col_double(),
  comid = col_character(),
  huc12 = col_character()
)) %>% 
  mutate(id = str_c(huc12, as.character(comid), sep = "-")) %>% 
  select(id, everything()) %>% 
  arrange(id) %>% 
  select(-decade) %>% 
  distinct() %>% 
  filter(
    !(id == "031001011006-16808225" & dec_lat_va < 27.0505)
  )

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
  select(id, comid, huc12, dec_long_va, dec_lat_va) %>% 
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
