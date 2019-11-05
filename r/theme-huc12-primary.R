# generate primary huc12 theme

library(tidyverse)
library(glue)

source("functions.R")

theme <- load_theme("huc12-primary")

theme_ids <- c("huc12-cov", "huc12-qquantile")
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

variables_cov <- themes$`huc12-cov`$variables$df %>% 
  filter(primary) %>% 
  pull(id)
df_cov <- themes$`huc12-cov`$dataset$out %>% 
  select(id, decade, variables_cov)

variables_qquantile <- themes$`huc12-qquantile`$variables$df %>% 
  filter(primary) %>% 
  pull(id)
df_qquantile <- themes$`huc12-qquantile`$dataset$out %>% 
  select(id, decade, variables_qquantile)

df <- df_cov %>% 
  full_join(df_qquantile, by = c("id", "decade"))

dataset <- list(
  out = df
)


# layer -------------------------------------------------------------------

layer <- themes$`huc12-cov`$layer


# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)


# feature data ------------------------------------------------------------

df_feature <- dataset$out %>% 
  nest(values = -id) %>% 
  mutate(
    values = map(values, function (x) {
      x %>% 
        arrange(decade)
    })
  ) %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature)
