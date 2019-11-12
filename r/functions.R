load_theme <- function(id) {
  theme <- list(
    id = id,
    path = file.path("../data/", id),
    config = readxl::read_xlsx(file.path(config::get("data_dir"), "themes.xlsx"), sheet = "themes") %>% 
      filter(id == !!id) %>% 
      mutate(
        citations = map2(citation_text, citation_url, ~ list(text = .x, url = .y))
      ) %>% 
      as.list()
  )
  
  theme$config$meta_file_index <- as.numeric(str_split(theme$config$meta_file_index, ",")[[1]])
  
  if (!dir.exists(theme$path)) {
    cat(glue::glue("Creating theme directory: {theme$path}"), "\n")
    dir.create(theme$path)
  }
  
  
  if (!dir.exists(file.path(theme$path, "features"))) {
    cat(glue::glue("Creating theme/features directory: {file.path(theme$path, 'features')}"), "\n")
    dir.create(file.path(theme$path, "features"))
  }
  
  theme
}

parse_xml_attrs <- function (xml_attrs) {
  tibble(
    i = 1:length(xml_attrs)
  ) %>% 
    mutate(
      el = map(i, ~ xml_attrs[.]),
      attrlabl = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrlabl"))),
      attrdef = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrdef"))),
      rdommin = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrdomv/rdom/rdommin"))),
      rdommax = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrdomv/rdom/rdommax"))),
      attrunit = map_chr(el, ~ xml2::xml_text(xml2::xml_child(., "attrdomv/rdom/attrunit"))),
    ) %>% 
    mutate_at(vars(rdommin, rdommax), parse_number) %>% 
    select(
      variable = attrlabl,
      description = attrdef,
      unit = attrunit,
      value_min = rdommin,
      value_max = rdommax
    )
}

extract_meta_variables <- function(theme) {
  # to find meta_file_index
  # > xml2::xml_find_all(xml2::read_xml(meta_xml_path), './eainfo/detailed')
  meta_xml_path <- file.path(config::get("data_dir"), "sciencebase", theme$id, theme$config$meta_file)
  meta_xml <- xml2::read_xml(meta_xml_path)
  map(theme$config$meta_file_index, function (index) {
    meta_xml_attrs <- xml2::xml_find_all(meta_xml, glue::glue('./eainfo/detailed[{index}]/attr'))
    parse_xml_attrs(meta_xml_attrs)
  }) %>% 
    bind_rows(.id = "index")
}


load_variables <- function(theme, index_names = NULL) {
  meta <- extract_meta_variables(theme)
  meta %>%
    write_csv(file.path(theme$path, "meta-variables.csv"))
  
  df <- readxl::read_xlsx(file.path(config::get("data_dir"), "themes.xlsx"), sheet = "variables") %>% 
    filter(theme == !!theme$id)
  
  cfg <- transform_variables(df)
  
  list(
    df = df,
    config = cfg,
    meta = meta
  )
}

transform_variables <- function(df) {
  cfg <- list()
  if (nrow(df) > 0) {
    cfg <- map(1:nrow(df), ~ list(
      id = df$id[.],
      label = df$label[.],
      description = df$description[.],
      units = df$units[.],
      type = df$type[.],
      map = df$map[.],
      filter = df$filter[.],
      group = df$group[.],
      scale = list(
        domain = c(df$scale_domain_min[.], df$scale_domain_max[.]),
        transform = df$scale_transform[.]
      ),
      formats = list(
        text = df$formats_text[.],
        axis = df$formats_axis[.]
      ),
      dimensions = list(
        decade = df$dims_decade[.],
        mklevel = df$dims_mklevel[.]
      )
    )) 
  }
  cfg
}

load_dataset <- function (theme, col_types) {
  read_csv(file.path(config::get("data_dir"), "sciencebase", theme$id, theme$config$data_file), col_types = col_types)
}

create_layer <- function (df, coords = c("dec_long_va", "dec_lat_va")) {
  stopifnot(all(!duplicated(df$id)))
  
  sf_layer <- sf::st_as_sf(df, crs = 4326, coords = coords)
  
  stopifnot(all(!duplicated(sf_layer$id)))
  
  list(
    df = df,
    sf = sf_layer
  )
}


export_theme <- function (theme, variables, dataset, layer) {
  cat("saving theme data to ", glue::glue("rds/{theme$id}.rds"), "\n", sep = "")
  list(
    theme = theme,
    variables = variables,
    layer = layer,
    dataset = dataset
  ) %>% 
    saveRDS(glue::glue("rds/{theme$id}.rds"))
  
  cat("saving layer to ", file.path(theme$path, "layer.json"), "\n", sep = "")
  layer$sf %>% 
    sf::st_write(dsn = file.path(theme$path, "layer.json"), driver = "GeoJSON", delete_dsn = TRUE, layer_options = "ID_FIELD=id")
  
  cat("saving dataset to ", file.path(theme$path, "data.csv"), "\n", sep = "")
  dataset$out %>% 
    write_csv(file.path(theme$path, "data.csv"), na = "")
  
  cat("saving config to ", file.path(theme$path, "theme.json"), "\n", sep = "")
  list(
    id = theme$id,
    title = str_c(
      case_when(
        theme$config$group == "gage" ~ "Gages > ",
        theme$config$group == "huc12" ~ "HUC12s > ",
        TRUE ~ ""
      ),
      theme$config$name
    ),
    description = theme$config$description,
    citations = theme$config$citations,
    layer = list(
      url = glue::glue("{theme$id}/layer.json")
    ),
    data = list(
      url = glue::glue("{theme$id}/data.csv"),
      group = list(
        by = "id"
      )
    ),
    dimensions = list(
      decade = theme$config$dims_decade,
      mklevel = theme$config$dims_mklevel
    ),
    variables = variables$config
  ) %>% 
    jsonlite::write_json(path = file.path(theme$path, "theme.json"), auto_unbox = TRUE, pretty = TRUE)
}

write_feature_json <- function(theme, df) {
  cat(glue::glue("saving feature data to {file.path(theme$path, 'features')} (n = {nrow(df)})"), "\n", sep = "")
  pb <- progress::progress_bar$new(total = nrow(df))
  for (i in 1:nrow(df)) {
    pb$tick()
    id <- df$id[[i]]
    jsonlite::write_json(
      list(
        id = id,
        properties = df[i, ]$properties[[1]],
        values = df[i, ]$values[[1]]
      ),
      path = file.path(theme$path, "features", glue::glue("{id}.json")),
      auto_unbox = TRUE,
      pretty = TRUE,
      dataframe = "rows",
      na = "null"
    )
  }
}

append_feature_properties <- function(df, layer) {
  df %>% 
    left_join(
      layer$df %>% 
        nest(properties = -id) %>% 
        mutate(
          properties = map(properties, ~ as.list(.))
        ),
      by = "id"
    ) %>% 
    select(id, properties, values)
}
