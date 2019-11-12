# theme: gage-qtrend

library(tidyverse)
library(glue)

source("functions.R")

theme <- load_theme("gage-qtrend")

variables <- load_variables(theme)
# MANUAL: copy meta-variables.csv to themes.xlsx$variables


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

# load quantile kendall test ----------------------------------------------

read_qk <- function(decade, season) {
  cat(glue("read_qk({decade},{season})"), "\n")
  if (season == "Annual") {
    filename <- glue("{decade}_QK_Results.xls")
  } else {
    filename <- glue("{season}_QK_{decade}_Results.xls")
  }
  filepath <- file.path(config::get("data_dir"), "sciencebase", theme$id, "Trend analysis results", "Quantile-Kendall results", decade, filename)
  
  sheets <- readxl::excel_sheets(filepath)
  
  map_df(sheets, function(sheet) {
    readxl::read_xls(filepath, sheet = sheet, na = "NaN", skip = 1, col_names = c(
      "quantile", "slopeLog", "slopePct", "pValue", "pValueAdj", "tau", "rho1", "rho2", "freq", "z"
      )
    ) %>%
      mutate(
        quantile = as.integer(quantile),
        gage = !!sheet
      )
  }) %>% 
    select(gage, everything())
}

# all resultes
df_qk_all <- crossing(
  decade = seq(1950, 2000, by = 10),
  season = c("Annual", "Spring", "Summer", "Fall", "Winter")
) %>% 
  mutate(
    data = map2(decade, season, ~ read_qk(decade = .x, season = .y))
  ) %>% 
  unnest(data)

# only min, median, max quantiles
df_qk <- df_qk_all %>% 
  group_by(season) %>% 
  mutate(
    quantile = case_when(
      quantile == min(quantile) ~ "min",
      quantile == floor(median(quantile)) ~ "median",
      quantile == max(quantile) ~ "max",
      TRUE ~ NA_character_
    )
  ) %>% 
  ungroup() %>% 
  mutate(season = tolower(season)) %>% 
  filter(!is.na(quantile)) %>% 
  select(decade, id = gage, season, quantile, slopepct = slopePct) %>% 
  pivot_longer(slopepct, "var", "value") %>% 
  unite("var", c(season, quantile, var)) %>% 
  mutate(var = str_c("qk_", var)) %>% 
  pivot_wider(names_from = var, values_from = value)

qk_vars <- crossing(
  test = "qk",
  season = c("Spring", "Summer", "Fall", "Winter", "Annual"),
  quantile = c("Min", "Median", "Max"),
  var = "slopepct"
) %>%
  mutate(
    var = tolower(str_c(test, season, quantile, var, sep = "_")),
    label = glue("{season} {quantile} Streamflow - QK Trend Slope"),
    description = glue("Estimated Sen slope (%/yr) of {season} {quantile} streamflow based on Quantile-Kendall test")
  ) %>% 
  left_join(
    df_qk %>% 
      pivot_longer(c(-decade, -id), "var", "value") %>% 
      group_by(var) %>% 
      summarise(
        min = min(value),
        q01 = quantile(value, prob = 0.01),
        median = quantile(value, prob = 0.5),
        q99 = quantile(value, prob = 0.99),
        max = max(value)
      ),
    by = "var"
  ) %>% 
  mutate(
    quantile = ordered(quantile, levels = c("Min", "Median", "Max")),
    season = ordered(season, levels = c("Annual", "Spring", "Summer", "Fall", "Winter"))
  ) %>% 
  arrange(season, quantile)


# load mann kendall test ---------------------------------------------------

read_mk <- function(decade, season) {
  cat(glue("read_mk({decade},{season})"), "\n")
  
  if (decade %in% c(1980, 1990)) {
    filename <- glue("{season}Ave_1970.xlsx")
  } else {
    filename <- glue("{season}Ave_{decade}.xlsx")
  }
  filepath <- file.path(config::get("data_dir"), "sciencebase", theme$id, "Trend analysis results", "Mann-Kendall results", decade, filename)
  readxl::read_xlsx(filepath, sheet = 1, na = "NaN", skip = 1, col_names = c("Row", "Site", "Tau", "Tau.p", "SensSlope", "Z", "Z.p")) %>% 
    select(-Row)
}

# mann-kendall
df_mk <- crossing(
  decade = seq(1950, 2000, by = 10),
  season = c(
    month.abb,
    c("Spring", "Summer", "Winter", "Fall"),
    glue("Q{sprintf('%02d', 10*(0:10))}")
  )
) %>% 
  mutate(
    data = map2(decade, season, read_mk)
  ) %>% 
  unnest(data) %>% 
  select(
    decade, id = Site, season, slope = SensSlope
  ) %>% 
  pivot_longer(c(slope), "var", "value") %>% 
  mutate(season = tolower(season)) %>% 
  unite("var", c(season, var)) %>%
  mutate(var = str_c("mk_", var)) %>% 
  pivot_wider(names_from = var, values_from = value)


mk_vars <- crossing(
  test = "mk",
  season = c(
    month.abb,
    c("Spring", "Summer", "Fall", "Winter"),
    glue("Q{sprintf('%02d', 10*(0:10))}")
  ),
  var = "slope"
) %>%
  mutate(
    var = tolower(str_c(test, season, var, sep = "_")),
    label = glue("{season} Streamflow - MK Trend Slope"),
    description = glue("Estimated Sen slope (m3/s/yr) of {season} streamflow based on Mann-Kendall test")
  ) %>% 
  left_join(
    df_mk %>% 
      pivot_longer(c(-decade, -id), "var", "value") %>% 
      group_by(var) %>% 
      summarise(
        min = min(value),
        q01 = quantile(value, prob = 0.01),
        median = quantile(value, prob = 0.5),
        q99 = quantile(value, prob = 0.99),
        max = max(value)
      ),
    by = "var"
  ) %>% 
  mutate(
    season = ordered(season, levels = c(
      month.abb,
      c("Spring", "Summer", "Fall", "Winter"),
      glue("Q{sprintf('%02d', 10*(0:10))}")
    ))
  ) %>% 
  arrange(season)

# merge -------------------------------------------------------------------

setdiff(df_mk$id, df_qk$id)
setdiff(df_qk$id, df_mk$id)

df_dataset <- full_join(
  df_mk, df_qk,
  by = c("decade", "id")
)

stopifnot(all(df_layer$id %in% unique(df_dataset$id)))
stopifnot(all(unique(df_dataset$id) %in% df_layer$id))

out_dataset <- df_dataset %>% 
  left_join(
    df_layer %>% 
      select(id, lat = dec_lat_va, lon = dec_long_va),
    by = "id"
  ) %>% 
  select(id, lat, lon, decade, variables$df$id)

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

# df_vars <- bind_rows(
#   qk_vars,
#   mk_vars
# )
# 
# write_csv(df_vars, "../data/huc12-qquantile/r-vars.csv")

# export ------------------------------------------------------------------

export_theme(theme, variables, dataset, layer)

# feature data ------------------------------------------------------------
# 
# df_feature <- dataset$out %>% 
#   mutate(
#     mklevel = ordered(mklevel, levels = c(months, seasons, quantiles))
#   ) %>%
#   arrange(id, mklevel, decade) %>% 
#   nest(values = -id) %>% 
#   mutate(
#     values = map(values, function (x) {
#       x %>% 
#         mutate(
#           group = case_when(
#             mklevel %in% seasons ~ "season",
#             mklevel %in% months ~ "month",
#             mklevel %in% quantiles ~ "quantile"
#           )
#         ) %>% 
#         group_by(decade, group) %>% 
#         nest() %>% 
#         # converts group: {mklevel:{}} to group [{mklevel}, {mklevel}]
#         mutate(
#           data = map(data, function (y) {
#             y %>%
#               group_by(mklevel) %>%
#               nest() %>%
#               mutate(data = map(data, ~ as.list(.))) %>%
#               spread(mklevel, data) %>%
#               flatten()
#           })
#         ) %>%
#         spread(group, data)
#     })
#   ) %>% 
#   append_feature_properties(layer)

df_feature <- dataset$out %>% 
  select(-lat, -lon) %>% 
  group_by(id) %>% 
  nest(values = -id) %>% 
  mutate(
    values = map2(id, values, function (i, v) {
      v %>% 
        arrange(decade) %>% 
        mutate(
          qk_annual_slopepct = map(decade, function (d) {
            df_qk_all %>% 
              filter(
                gage == i,
                season == "Annual",
                decade == d
              ) %>% 
              arrange(quantile) %>% 
              pull(slopePct)
          })
        )
    })
  ) %>% 
  append_feature_properties(layer)

write_feature_json(theme, df_feature)


df_qk_all


# variable ranges ---------------------------------------------------------

summary(out_dataset)

# => use max(pretty(values)) for domain ranges
out_dataset %>% 
  select(-id, -decade, -lat, -lon) %>% 
  select_if(is.numeric) %>% 
  pivot_longer(everything(), "var", "value") %>% 
  mutate(var = ordered(var, levels = variables$df$id)) %>% 
  group_by(var) %>% 
  filter(
    value >= quantile(value, probs = 0.1, na.rm = TRUE),
    value <= quantile(value, probs = 0.9, na.rm = TRUE)
  ) %>% 
  summarise(
    min = min(pretty(value)),
    max = max(pretty(value)),
    min = if_else(abs(min) > max, min, -max),
    max = if_else(abs(min) > max, -min, max)
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
  select(starts_with("mk_")) %>% 
  pivot_longer(everything(), "var", "value") %>% 
  mutate(var = ordered(var, levels = variables$df$id)) %>% 
  ggplot(aes(value)) +
  geom_histogram() +
  facet_wrap(vars(var), scales = "free")

