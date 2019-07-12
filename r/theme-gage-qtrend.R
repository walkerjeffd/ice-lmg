# theme: gage-qtrend

library(tidyverse)

source("functions.R")

theme <- load_theme("gage-qtrend")

variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables

# load dataset ------------------------------------------------------------


read_mk <- function(decade, group) {
  # cat(glue::glue("decade: {decade}, group: {group}"), "\n")
  if (decade %in% c(1980, 1990)) {
    decade = 1970
  }
  readxl::read_xlsx(
    file.path(config::get("data_dir"), "sciencebase", theme$id, "Trend analysis results", "Mann-Kendall results", decade, glue::glue("{group}Ave_{decade}.xlsx")),
    sheet = 1, na = "NaN"
  ) %>% 
    select(-1)
}

months <- month.abb
seasons <- c("Spring", "Summer", "Winter", "Fall")
quantiles <- glue::glue("Q{sprintf('%02d', 10*(0:10))}")

# mann-kendall
df_dataset <- crossing(
  decade = seq(1950, 2000, by = 10),
  mklevel = c(months, seasons, quantiles)
) %>% 
  mutate(
    data = map2(decade, mklevel, read_mk)
  ) %>% 
  unnest(data) %>% 
  select(
    id = Site, decade, mklevel, mk_tau = Tau, mk_pval = Tau.p, mk_slope = SensSlope
  ) %>% 
  arrange(id, decade, mklevel)

out_dataset <- df_dataset %>% 
  select(id, decade, mklevel, variables$df$id)

dataset <- list(
  df = df_dataset,
  out = out_dataset
)

stopifnot(
  dataset$out %>% 
    mutate(id_decade_level = str_c(id, decade, mklevel, sep = "-")) %>% 
    filter(duplicated(id_decade_level)) %>% 
    nrow() == 0
)

# layer -------------------------------------------------------------------

df_layer <- readxl::read_xlsx(
  file.path(config::get("data_dir"), "sciencebase", theme$id, "Longitude and latitude of sites used in RESTORE Streamflow alteration assessments.xlsx"),
  sheet = 1
) %>% 
  mutate(
    id = site_no,
    huc12 = sprintf("%012.0f", HUC_12)
  ) %>% 
  select(id, site_no, huc12, dec_long_va = Longitude, dec_lat_va = Latitude)

layer <- df_layer %>% 
  create_layer()

ggplot(layer$sf) +
  geom_sf()

# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)

# feature data ------------------------------------------------------------

df_feature <- dataset$out %>% 
  mutate(
    mklevel = ordered(mklevel, levels = c(months, seasons, quantiles))
  ) %>%
  arrange(id, mklevel, decade) %>% 
  group_by(id) %>% 
  nest(.key = "values") %>% 
  mutate(
    values = map(values, function (x) {
      x %>% 
        mutate(
          group = case_when(
            mklevel %in% seasons ~ "season",
            mklevel %in% months ~ "month",
            mklevel %in% quantiles ~ "quantile"
          )
        ) %>% 
        group_by(decade, group) %>% 
        nest() %>% 
        # converts group: {mklevel:{}} to group [{mklevel}, {mklevel}]
        mutate(
          data = map(data, function (y) {
            y %>%
              group_by(mklevel) %>%
              nest() %>%
              mutate(data = map(data, ~ as.list(.))) %>%
              spread(mklevel, data) %>%
              flatten()
          })
        ) %>%
        spread(group, data)
    })
  ) %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature)





z <- x %>% 
  mutate(
    group = case_when(
      mklevel %in% seasons ~ "season",
      mklevel %in% months ~ "month",
      mklevel %in% quantiles ~ "quantile"
    )
  ) %>% 
  group_by(decade, group) %>% 
  nest() %>% 
  # converts group: {mklevel:{}} to group [{mklevel}, {mklevel}]
  mutate(
    data = map(data, function (y) {
      y %>%
        group_by(mklevel) %>%
        nest() %>%
        mutate(data = map(data, ~ as.list(.))) %>%
        spread(mklevel, data) %>%
        flatten()
    })
  ) %>%
  spread(group, data)

