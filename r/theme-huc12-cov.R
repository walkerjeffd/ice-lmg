# theme: huc12-cov

library(tidyverse)

source("functions.R")

theme <- load_theme("huc12-cov")

variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables

# load dataset ------------------------------------------------------------

df_dataset <- load_dataset(theme, col_types = cols(
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
  mutate(id = str_c(huc12, as.character(comid), sep = "-")) %>% 
  select(id, everything()) %>% 
  arrange(id, decade) %>% 
  filter(
    !(id == "031001011006-16808225" & dec_lat_va < 27.0505)
  ) %>% 
  mutate(
    total_forest = deciduous_forest + evergreen_forest + mixed_forest,
    total_forest = if_else(total_forest > 100, 100, total_forest),
    total_wetland = herbaceous_wetland + woody_wetland,
    total_wetland = if_else(total_wetland > 100, 100, total_wetland)
  )

out_dataset <- df_dataset %>% 
  select(id, decade, lat = dec_lat_va, lon = dec_long_va, variables$df$id)

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
  select(id, comid, huc12, dec_long_va, dec_lat_va) %>% 
  distinct() %>% 
  create_layer()

ggplot(layer$sf) +
  geom_sf()


# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)


# feature data ------------------------------------------------------------

df_feature <- dataset$out %>% 
  select(-lat, -lon) %>% 
  nest(values = -id) %>% 
  mutate(
    values = map(values, function (x) {
      x %>% 
        arrange(decade)
    })
  ) %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature)


# variable ranges ---------------------------------------------------------

summary(out_dataset)

# => use max(pretty(values)) for domain ranges
out_dataset %>% 
  select(-id, -decade, -lat, -lon) %>% 
  select_if(is.numeric) %>% 
  pivot_longer(everything(), "var", "value") %>% 
  mutate(var = ordered(var, levels = variables$df$id)) %>% 
  group_by(var) %>% 
  summarise(
    min = min(pretty(value)),
    max = max(pretty(value))
  ) %>% 
  # write_csv("~/vars.csv")
  print(n = Inf)

# pretty log breaks
out_dataset %>% 
  select(-id, -decade, -lat, -lon) %>% 
  select_if(is.numeric) %>% 
  pivot_longer(everything(), "var", "value") %>% 
  mutate(var = ordered(var, levels = variables$df$id)) %>% 
  filter(value > 0) %>%  # POSITIVE NON-ZERO VALUES ONLY
  group_by(var) %>% 
  summarise(
    min_log = min(scales::log_breaks()(value)),
    max_log = max(scales::log_breaks()(value))
  ) %>% 
  # write_csv("~/vars.csv")
  print(n = Inf)

