# generate all themes

library(tidyverse)

themes <- c("gage-cov", "gage-qstat", "gage-qtrend", "gage-solar", "huc12-cov", "huc12-qquantile", "huc12-solar")
# themes <- c("gage-cov", "gage-qstat", "gage-qtrend", "gage-solar")

for (t in themes) {
  cat("Theme:", t, "\n")
  source(glue::glue("theme-{t}.R"))
}
