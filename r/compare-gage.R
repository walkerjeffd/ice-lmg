# compare gage datasets

library(tidyverse)
library(glue)

theme_ids <- c("gage-cov", "gage-qstat", "gage-solar")
themes <- map(
  theme_ids,
  ~ readRDS(glue("rds/{.}.rds"))
) %>% 
  set_names(nm = theme_ids)

layers <- map(themes, ~ .$layer$df) %>% 
  bind_rows(.id = "theme")


# equal counts per theme
stopifnot(
  layers %>% 
    group_by(theme) %>% 
    count() %>% 
    filter(n != 956) %>% 
    nrow() == 0
)

# equal counts per id
stopifnot(
  layers %>% 
    group_by(id) %>% 
    count() %>% 
    filter(n != 3) %>% 
    nrow() == 0
)

# same comid,huc12 for each id
stopifnot(
  layers %>% 
    select(id, comid, huc12) %>% 
    distinct() %>% 
    group_by(id) %>% 
    count() %>% 
    filter(n != 1) %>% 
    nrow() == 0
)

# same dec_lat_va, dec_long_va for each id
layers %>% 
  select(id, dec_long_va, dec_lat_va) %>% 
  mutate_at(vars(dec_long_va, dec_lat_va), ~ round(., digits = 4)) %>% 
  distinct() %>% 
  group_by(id) %>% 
  mutate(n = n()) %>% 
  ungroup() %>% 
  filter(n != 1)
# only one (id=02358754), but values are similar so it's OK
