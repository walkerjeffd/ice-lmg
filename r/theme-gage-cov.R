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
  arrange(id, decade) %>% 
  mutate(
    cat_physio = if_else(cat_physio == "acc_physio_3", "cat_physio_3", cat_physio),
    cat_aquifers = if_else(cat_aquifers == "acc_aq111", "cat_aq111", cat_aquifers),
    cat_soller = if_else(cat_soller == "acc_soller_221", "cat_soller_221", cat_soller),
    ed_rch_zone = if_else(ed_rch_zone == 1, "yes", "no"),
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

out_dataset %>% 
  select(-id, -decade, -lat, -lon) %>% 
  select_if(is.numeric) %>% 
  pivot_longer(everything(), "var", "value") %>% 
  mutate(var = ordered(var, levels = variables$df$id)) %>% 
  group_by(var) %>% 
  summarise(
    min = min(value),
    q01 = quantile(value, probs = 0.01),
    q10 = quantile(value, probs = 0.10),
    median = median(value),
    q90 = quantile(value, probs = 0.90),
    q99 = quantile(value, probs = 0.99),
    max = max(value)
  ) %>% 
  print(n = Inf)

out_dataset %>% 
  select(-id, -decade, -lat, -lon) %>% 
  select_if(is.numeric) %>% 
  pivot_longer(everything(), "var", "value") %>% 
  mutate(var = ordered(var, levels = variables$df$id)) %>% 
  ggplot(aes(value)) +
  geom_histogram() +
  facet_wrap(vars(var), scales = "free")


# categorical variables ---------------------------------------------------

out_dataset %>% 
  select(-id) %>% 
  select_if(is_character) %>% 
  gather(var, value) %>% 
  distinct() %>% 
  arrange(var, value) %>% 
  group_by(var) %>% 
  summarise(
    values = str_c(value, collapse = ",")
  )