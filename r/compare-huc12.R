# compare huc12 datasets

library(tidyverse)
library(glue)

theme_ids <- c("huc12-cov", "huc12-qquantile", "huc12-solar")
themes <- map(
  theme_ids,
  ~ readRDS(glue("rds/{.}.rds"))
) %>% 
  set_names(nm = theme_ids)


layers <- map(themes, ~ .$layer$df) %>% 
  bind_rows(.id = "theme")

dataset <- map(themes, ~ .$dataset$out) %>% 
  bind_rows(.id = "theme")


# for each theme, only one comid per huc12
df_theme_huc <- layers %>% 
  group_by(theme, huc12) %>% 
  add_tally() %>% 
  filter(n == 1) %>% 
  arrange(huc12, theme)

# huc12s with varying comid over theme
df_theme_huc %>% 
  group_by(huc12) %>% 
  mutate(
    n = length(unique(comid))
  ) %>% 
  filter(n > 1) %>% 
  filter(huc12 == "031001010604") %>% 
  select(dataset = theme, huc12, comid, dec_long_va, dec_lat_va) %>% 
  mutate(
    dataset = case_when(
      dataset == "huc12-cov" ~ "Basin Characteristics",
      dataset == "huc12-qquantile" ~ "Streamflow Quantile",
      dataset == "huc12-solar" ~ "Solar Radiation"
    )
  ) %>% 
  mutate_at(vars(starts_with("dec_")), ~ sprintf("%.4f", .)) %>% 
  arrange(comid)

layers %>% 
  group_by(theme, huc12) %>% 
  add_tally() %>% 
  filter(n > 2, theme == "huc12-cov") %>% 
  arrange(huc12, theme) %>% 
  select(huc12, comid, dec_long_va, dec_lat_va) %>% 
  mutate_at(vars(starts_with("dec_")), ~ sprintf("%.4f", .))


df_comid <- layers %>% 
  select(theme, comid, dec_long_va, dec_lat_va) %>% 
  distinct()

df_comid %>% 
  group_by(theme, comid) %>% 
  add_tally() %>% 
  filter(n > 1)

layers %>% 
  filter(comid == "16806323") %>% 
  mutate_at(vars(starts_with("dec_")), ~ sprintf("%.4f", .))





x <- layers %>% 
  mutate(has_theme = TRUE) %>% 
  spread(theme, has_theme, fill = FALSE) %>% 
  mutate(
    total = `huc12-cov` + `huc12-qquantile` + `huc12-solar`
  )
x_all <- x %>% 
  filter(total == 3)
x_cov_solar <- x %>% 
  filter(`huc12-cov`, !`huc12-qquantile`, `huc12-solar`)
x_quant <- x %>% 
  filter(!`huc12-cov`, `huc12-qquantile`, !`huc12-solar`)
x_fix <- x_quant %>% 
  select(id:dec_lat_va) %>% 
  full_join(
    x_cov_solar %>% 
      select(id:dec_lat_va),
    by = c("dec_long_va", "dec_lat_va")
  )

x_quant_fix %>% 
  filter(is.na(id.y))
x_quant_fix %>% 
  filter(is.na(id.x))

layers %>% 
  filter(huc12 == "031300110803" | comid == "2299034")

