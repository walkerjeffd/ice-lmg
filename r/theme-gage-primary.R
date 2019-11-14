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
df_gage_cov <- bind_rows(
  df_gage_cov %>% 
    mutate(signif = TRUE),
  df_gage_cov %>% 
    mutate(signif = FALSE)
) %>% 
  select(id, decade, signif, variables_gage_cov)

variables_gage_qstat <- themes$`gage-qstat`$variables$df %>% 
  filter(primary) %>% 
  pull(id)
df_gage_qstat <- themes$`gage-qstat`$dataset$out %>% 
  select(id, decade, variables_gage_qstat)
df_gage_qstat <- bind_rows(
  df_gage_qstat %>% 
    mutate(signif = TRUE),
  df_gage_qstat %>% 
    mutate(signif = FALSE)
) %>% 
  select(id, decade, signif, variables_gage_qstat)

variables_gage_qtrend <- themes$`gage-qtrend`$variables$df %>%
  filter(primary) %>%
  pull(id)
df_gage_qtrend <- themes$`gage-qtrend`$dataset$out %>%
  select(id, decade, signif, variables_gage_qtrend)

df <- df_gage_cov %>% 
  full_join(df_gage_qstat, by = c("id", "decade", "signif")) %>% 
  full_join(df_gage_qtrend, by = c("id", "decade", "signif")) %>% 
  left_join(
    themes$`gage-cov`$layer$df %>% 
      select(id, lat = dec_lat_va, lon = dec_long_va),
    by = "id"
  ) %>% 
  select(id, lat, lon, decade, signif, everything())

dataset <- list(
  out = df
)


# layer -------------------------------------------------------------------

layer <- themes$`gage-cov`$layer


# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)


# feature data ------------------------------------------------------------

df_feature <- dataset$out %>% 
  filter(!signif) %>% 
  select(-lat, -lon) %>% 
  nest(values = -id) %>% 
  mutate(
    values = map2(id, values, function (i, v) {
      v_cov <- v %>% 
        arrange(decade) %>% 
        select(decade, variables_gage_cov)
      v_qstat <- v %>% 
        arrange(decade) %>% 
        select(decade, variables_gage_qstat)
      v_qtrend_mk <- themes$`gage-qtrend`$dataset$out %>% 
        filter(id == i) %>% 
        select(decade, signif, variables_gage_qtrend) %>% 
        select(-starts_with("qk_"))
      x_qk <- themes$`gage-qtrend`$dataset$qk %>% 
        filter(gage == i, season == "Annual") %>% 
        mutate(
          signif = FALSE
        )
      x_qk_signif <- x_qk %>% 
        mutate(
          slopePct = if_else(pValueAdj < 0.05, slopePct, NA_real_),
          signif = TRUE
        )
      v_qtrend_qk <- bind_rows(
        x_qk,
        x_qk_signif
      ) %>% 
        select(decade, signif, slopePct) %>% 
        nest(qk_annual_slopepct = -c(decade, signif)) %>% 
        mutate(qk_annual_slopepct = map(qk_annual_slopepct, ~ .$slopePct))
      
      list(
        cov = v_cov,
        qstat = v_qstat,
        qtrend = list(
          mk = v_qtrend_mk,
          qk = v_qtrend_qk
        )
      )
    })
  ) %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature)

