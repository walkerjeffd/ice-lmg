# generate themes.json config file

library(tidyverse)
library(jsonlite)
library(readxl)

config <- config::get()

themes <- read_xlsx(file.path(config$data_dir, "themes.xlsx"), sheet = "themes") %>% 
  filter(!skip) %>% 
  mutate(
    citation = map2(citation_text, citation_url, ~ list(text = .x, url = .y))
  ) %>% 
  select(group, id, name, description, citation)

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
