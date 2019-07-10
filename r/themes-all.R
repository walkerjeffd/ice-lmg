# generate all themes

library(tidyverse)

themes <- c("gage-cov", "gage-qstat", "gage-solar", "huc12-cov", "huc12-solar")

for (t in themes) {
  cat("Theme:", t, "\n")
  source(glue::glue("theme-{t}.R"))
}