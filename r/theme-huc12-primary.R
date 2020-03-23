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

categories <- readxl::read_xlsx("xlsx/themes.xlsx", sheet = "categories") %>% 
  filter(theme %in% theme_ids)

cfg_variables <- transform_variables(df_variables, categories)

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
layer_cov <- themes$`huc12-cov`$layer$df

variables_qquantile <- themes$`huc12-qquantile`$variables$df %>% 
  filter(primary) %>% 
  pull(id)
df_qquantile <- themes$`huc12-qquantile`$dataset$out %>% 
  select(id, decade, variables_qquantile)
layer_qquantile <- themes$`huc12-qquantile`$layer$df

# fix qquantile ID by joining on lat,long
qquantile_fix_id <- left_join(
    layer_cov,
    layer_qquantile %>% 
      select(id_qquantile = id, dec_long_va, dec_lat_va),
    by = c("dec_long_va", "dec_lat_va")
  )
df_qquantile_fix <- df_qquantile %>% 
  rename(id_qquantile = id) %>% 
  inner_join(
    select(qquantile_fix_id, id, id_qquantile), by = "id_qquantile"
  )
stopifnot(all(!is.na(df_qquantile_fix)))

df <- df_cov %>% 
  left_join(
    df_qquantile_fix %>% 
      select(-id_qquantile),
    by = c("id", "decade")
  ) %>% 
  left_join(
    themes$`huc12-cov`$layer$df %>% 
      select(id, lat = dec_lat_va, lon = dec_long_va),
    by = "id"
  ) %>% 
  select(id, lat, lon, decade, everything()) %>% 
  complete(nesting(id, lat, lon), decade)

dataset <- list(
  out = df
)


# layer -------------------------------------------------------------------

layer <- themes$`huc12-cov`$layer

stopifnot(identical(sort(unique(layer$sf$id)), sort(unique(df$id))))


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

write_feature_json(theme, df_feature, clear = TRUE)
