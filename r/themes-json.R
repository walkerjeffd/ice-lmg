# generate themes.json config file

library(tidyverse)
library(jsonlite)
library(readxl)

config <- config::get()

themes <- read_xlsx(file.path(config$data_dir, "themes.xlsx"), sheet = "themes") %>% 
  mutate(
    sciencebase = map2(sciencebase_title, sciencebase_url, ~ list(title = .x, url = .y))
  ) %>% 
  select(group, id, name, description, sciencebase)

list(
  list(
    id = "gage",
    name = "Streamflow Gages",
    children = themes %>% 
      filter(group == "gage") %>% 
      select(-group)
  ),
  list(
    id = "huc12",
    name = "HUC12 Basins",
    children = themes %>% 
      filter(group == "huc12") %>% 
      select(-group)
  )
) %>% 
  # toJSON(auto_unbox = TRUE, pretty = TRUE)
  write_json("../src/assets/themes.json", auto_unbox = TRUE, pretty = TRUE)
