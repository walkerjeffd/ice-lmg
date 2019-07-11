# compare huc12 datasets

library(tidyverse)
library(glue)

theme_ids <- c("huc12-cov", "huc12-solar")
themes <- map(
  theme_ids,
  ~ readRDS(glue("rds/{.}.rds"))
) %>% 
  set_names(nm = theme_ids)

layers <- map(themes, ~ .$layer$df) %>% 
  bind_rows(.id = "theme")

# same ids
stopifnot(
  identical(
    sort(themes$`huc12-cov`$layer$df$id),
    sort(themes$`huc12-solar`$layer$df$id)
  )
)

# equal counts per theme
stopifnot(
  layers %>% 
    group_by(theme) %>% 
    count() %>% 
    filter(n != 9219) %>% 
    nrow() == 0
)

# equal counts per id
stopifnot(
  layers %>% 
    group_by(id) %>% 
    count() %>% 
    filter(n != 2) %>% 
    nrow() == 0
)

# same comid, huc12 for each id
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
stopifnot(
  layers %>% 
    select(id, dec_long_va, dec_lat_va) %>% 
    distinct() %>% 
    group_by(id) %>% 
    mutate(n = n()) %>% 
    ungroup() %>% 
    filter(n != 1) %>% 
    nrow() == 0
)

