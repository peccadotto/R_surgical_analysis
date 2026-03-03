# -----------------------------------------------------------------------------
# SETUP
# -----------------------------------------------------------------------------
  
# 1. Create a vector with the packages to be installed
  packages <- c(
    "bookdown",
    "dplyr",
    "ggplot2",
    "lubridate",
    "rmdformats",
    "tidyverse"
)
  
# 2. If the package is not installed, then install it
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message("!! Package '", pkg, "' not found. Installing it...")
      tryCatch(
        install.packages(pkg, dependencies = TRUE),
        error = function(e) {
          message("!! Error while trying to install the '", pkg, "' package: ", e$message)
        }
      )
    }
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }

  
# -----------------------------------------------------------------------------  
# DATA IMPORT
# -----------------------------------------------------------------------------
  
# 3. Import data from .csv files
  files <- list.files(
    path       = "data",
    pattern    = "surgical_data_\\d{4}\\.csv",
    full.names = TRUE
  )
  
  icd9proc <- read.csv(
    "data/icd9_procedures.csv",
    header     = TRUE,
    sep        = ";",
    colClasses = "character"
  ) |>
  select(c("code", "long_descr", "short_descr"))

# 4. Bind data into a single dataframe
  surgeries_total <- files |>
    set_names() |>
    map_df(~read.csv(
      .x, 
      header     = TRUE, 
      sep        = ";", 
      na.strings = c("")
    ))


# -----------------------------------------------------------------------------    
# DATA CHECK  
# -----------------------------------------------------------------------------
  
# 5. Create a function to search for NA values
  check_missing <- function(df) {
    na_count <- colSums(is.na(df))
    na_pct <- (na_count / nrow(df)) * 100
    results <- data.frame(
      variable = names(na_count),
      missing = na_count,
      pct = round(na_pct, 2),
      row.names = NULL
    )
    results <- results |> arrange(desc(missing))
    return(results)
  }


# -----------------------------------------------------------------------------
# DATA TRANSFORMATION
# -----------------------------------------------------------------------------
  
# 6. Set variables classes
  surgeries_total <- surgeries_total |>
    mutate(
      date       = dmy(date),
      procedure  = as.character(procedure),
      role       = as.factor(role)
    )

# 7. Create new dataframes
  surgeries_stats_wide <- surgeries_total |>
    mutate(year = year(date)) |>
    group_by(year) |>
    summarise(
      procedures = n(),
      lead       = sum(role == 1, na.rm = TRUE),
      pct_lead   = lead / procedures * 100,
  )
  
  procedures_stats_wide <- surgeries_total |>
    mutate(year = year(date)) |>
    group_by(procedure) |>
    summarise(procedures = n()) |>
    arrange(desc(procedures)) |>
    head(15) |>
    mutate(procedure       = as.character(procedure)) |>
    left_join(icd9proc, by = c("procedure" = "code")) |>
    mutate(long_descr      = reorder(long_descr, procedures))
  

# -----------------------------------------------------------------------------
# DATA EXPORT
# -----------------------------------------------------------------------------
  
# 8. Export data for Markdown report
  save(
    check_missing,
    surgeries_total,
    surgeries_stats_wide,
    procedures_stats_wide,
    file = "surgical_analysis.RData"
  )
  
# -----------------------------------------------------------------------------
# ENVIRONMENT CLEANING
# -----------------------------------------------------------------------------
  
# 9. Delete unnecessary objects from the environment
  obj_to_keep <- c(
    "surgeries_total",
    "surgeries_stats_wide",
    "procedures_stats_wide"
  )
  rm(list = setdiff(ls(), obj_to_keep))