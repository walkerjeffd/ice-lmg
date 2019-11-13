# generate primary gage theme

library(tidyverse)
library(glue)

source("functions.R")

theme <- load_theme("gage-primary")

theme_ids <- c("gage-cov", "gage-qstat", "gage-qtrend")
themes <- map(theme_ids, ~ readRDS(glue("rds/{.}.rds")))
themes <- set_names(themes, nm = theme_ids)

theme$config$citations <- unname(map(themes, ~ .$theme$config$citations[[1]]))

# merge variables ---------------------------------------------------------

df_variables <- map_df(themes, ~ .$variables$df) %>% 
  filter(primary)

cfg_variables <- transform_variables(df_variables)

variables <- list(
  df = df_variables,
  config = cfg_variables
)

# merge datasets ----------------------------------------------------------

variables_gage_cov <- themes$`gage-cov`$variables$df %>% 
  filter(primary) %>% 
  pull(id)
df_gage_cov <- themes$`gage-cov`$dataset$out %>% 
  select(id, decade, variables_gage_cov)

variables_gage_qstat <- themes$`gage-qstat`$variables$df %>% 
  filter(primary) %>% 
  pull(id)
df_gage_qstat <- themes$`gage-qstat`$dataset$out %>% 
  select(id, decade, variables_gage_qstat)

variables_gage_qtrend <- themes$`gage-qtrend`$variables$df %>%
  filter(primary) %>%
  pull(id)
df_gage_qtrend <- themes$`gage-qtrend`$dataset$out %>%
  select(id, decade, variables_gage_qtrend)

df <- df_gage_cov %>% 
  full_join(df_gage_qstat, by = c("id", "decade")) %>% 
  full_join(df_gage_qtrend, by = c("id", "decade")) %>% 
  left_join(
    themes$`gage-cov`$layer$df %>% 
      select(id, lat = dec_lat_va, lon = dec_long_va),
    by = "id"
  ) %>% 
  select(id, lat, lon, decade, everything())

dataset <- list(
  out = df
)


# layer -------------------------------------------------------------------

layer <- themes$`gage-cov`$layer


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

