# -----------------------------------------------------------------------------
# SURGICAL ANALYSIS
# -----------------------------------------------------------------------------
# Author_name:      Andrea Peccati
# Author_nickname:  Peccadotto
# Creation_date:    2026-10
# Github URL:       https://github.com/peccadotto/R_surgical_analysis
# -----------------------------------------------------------------------------

# 1) Setup

  packages <- c(
    "tidyverse",
    "formattable",
    "janitor",
    "lubridate",
    "quarto",
    "scales",
    "writexl"
  )
  
  for (pkg in packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      message("!! Package '", pkg, "' not found. Installing it...")
      tryCatch(
        install.packages(pkg, dependencies = TRUE),
        error = function(e) {
          message(
            "!! Error while trying to install the '",
            pkg,
            "' package: ",
            e$message
          )
        }
      )
    }
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }
  
  rm(list = ls())

# 2) Data import

  df_20122017 <- read.csv("data/20122017.csv", sep = ";", header = TRUE)  
  df_20172020 <- read.csv("data/20172020.csv", sep = ";", header = TRUE)  
  df_20212025 <- read.csv("data/20212025.csv", sep = ";", header = TRUE)  
  df_20262030 <- read.csv("data/20262030.csv", sep = ";", header = TRUE)
  
# 3) Data merge
  
  df_names <- mget(ls(pattern = "^df_"))
  df <- bind_rows(df_names)
  rm(df_names)
  
  df <- df |>
    select(-c(ID, Descr)) |>
    mutate(
      Date = dmy(Date),
      Start = hm(Start),
      End = hm(End),
      Time = (period_to_seconds(End) - period_to_seconds(Start)) / 60,
      Patient = str_replace_all(Patient, "\\S", "*"),
      Gender = as.factor(Gender),
      DOB = dmy(DOB),
      Proc = as.character(Proc),
      Role = as.factor(Role),
      Place = as.factor(Place),
      Period = ifelse(Date <= dmy("11-07-2017"), "Resident", "Attending"),
      Year = year(Date)
    ) |>
    arrange(Date, Start) 
  
# 4) Report creation
  
  df_pvt_year <- df |>
    select(Year, Patient, Proc) |>
    group_by(Year) |>
    summarise(
      Surgeries = sum(!is.na(Patient) & Patient != ""),
      Procedures = sum(!is.na(Proc) & Proc != "")
    ) |>
    mutate(
      S_cumul = cumsum(Surgeries),
      S_diff = (Surgeries - lag(Surgeries)) / lag(Surgeries),
      S_diff = percent(S_diff, accuracy = 0.01),
      S_diff = coalesce(S_diff, "---"),
      P_cumul = cumsum(Procedures),
      P_diff = (Procedures - lag(Procedures)) / lag(Procedures),
      P_diff = percent(P_diff, accuracy = 0.01),
      P_diff = coalesce(P_diff, "---")
    ) |>
    select(Year, Surgeries, S_cumul, S_diff, Procedures, P_cumul, P_diff) |>
    arrange(Year) |>
    rename(' ' = Year) |>
    as_tibble() |> print()
  
  df_pvt_lead <- df |>
    select(Year, Patient, Proc, Role) |>
    mutate (Lead = ifelse(Role == "1", "LEAD", "Not lead"))|>
    group_by(Year) |>
    summarise(
      Surgeries = sum(!is.na(Patient) & Patient != ""),
      S_lead = sum(!is.na(Patient) & Patient != "" & Lead == "LEAD"),
      S_lead_pct = percent(S_lead / Surgeries, accuracy = 0.01),
      Procedures = sum(!is.na(Proc) & Proc != ""),
      P_lead = sum(!is.na(Proc) & Proc != "" & Lead == "LEAD"),
      P_lead_pct = percent(P_lead / Procedures, accuracy = 0.01)
     ) |>
    adorn_totals(where = "row", name = "TOTAL", fill = "---") |>
    rename(
      ' ' = Year,
      'S_Lead (n)' = S_lead,
      'S_Lead (%)' = S_lead_pct,
      'P_Lead (n)' = P_lead,
      'P_Lead (%)' = P_lead_pct
    ) |>
     as_tibble() |> print()
  
  df_pvt_period <- df |>
    group_by(Period) |>
    summarise(
      Surgeries = sum(!is.na(Patient) & Patient != ""),
      S_pct = sum(!is.na(Patient) & Patient != ""),
      Procedures = sum(!is.na(Proc) & Proc != ""),
      P_pct = sum(!is.na(Proc) & Proc != "")
    ) |>
    arrange(desc(Period)) |>
    adorn_totals(where = "row", name = "TOTAL") |>
    adorn_percentages(
      denominator = "col",
      select_cols = c("S_pct", "P_pct")
    ) |>
    adorn_pct_formatting(
      digits = 2,
      affix_sign = TRUE,
      select_cols = c("S_pct", "P_pct")
    ) |>
    rename(
      ' ' = Period,
      'Surgeries (n)' = Surgeries,
      'Surgeries (%)' = S_pct,
      'Procedures (n)' = Procedures,
      'Procedures (%)' = P_pct
    ) |>
    as_tibble() |> print()
  
  df_pvt_place <- df |>
    group_by(Place) |>
    summarise(
      Surgeries = sum(!is.na(Patient) & Patient != ""),
      S_pct = sum(!is.na(Patient) & Patient != ""),
      Procedures = sum(!is.na(Proc) & Proc != ""),
      P_pct = sum(!is.na(Proc) & Proc != "")
    ) |>
    arrange(desc(Place)) |>
    adorn_totals(where = "row", name = "TOTAL") |>
    adorn_percentages(
      denominator = "col",
      select_cols = c("S_pct", "P_pct")
    ) |>
    adorn_pct_formatting(
      digits = 2,
      affix_sign = TRUE,
      select_cols = c("S_pct", "P_pct")
    ) |>
    rename(
      ' ' = Place,
      'Surgeries (n)' = Surgeries,
      'Surgeries (%)' = S_pct,
      'Procedures (n)' = Procedures,
      'Procedures (%)' = P_pct
    ) |>
    as_tibble() |> print()
  
  icd9 <- read.csv(
    "data/icd9_procedures.csv",
    sep = ";",
    header = TRUE
  ) |>
  mutate (Proc = as.character(Proc)) |>
  select(-Short)
  
  df_pvt_proc <- df |>
    select(Proc) |>
    group_by(Proc) |>
    summarise(
      N = n(),
      Pct = N /length(Proc)
    ) |>
    mutate(Pct = percent(N / sum(N), accuracy = 0.01)) |>
    arrange(desc(N)) |>
    head(15) |>
    left_join(icd9, by = "Proc") |>
    rename(
      ' ' = Proc,
      'n' = N,
      '%' = Pct,
      Description = Long
    ) |>
    as_tibble() |> print()
  
# 5) Data export
  
  ls2save <- list(
    "0) Complete" = df,
    "1) PVT by YEAR" = df_pvt_year,
    "2) PVT by LEAD" = df_pvt_lead,
    "3) PVT by PERIOD" = df_pvt_period,
    "4) PVT by PLACE" = df_pvt_place,
    "5) PVT top 15 PROCEDURES" = df_pvt_proc
  )
  saveRDS(ls2save, file = "data/export.rds")
  write_xlsx(ls2save, path = "data/export.xlsx")
  ls2keep <- ls(pattern = "^df|^df_pvt")
  rm(list = setdiff(ls(), ls2keep))
  
# 6) Show report
  
  Sys.setenv(QUARTO_PATH = "C:\\Program Files\\RStudio\\resources\\app\\bin\\quarto\\bin\\quarto.exe")
  quarto_render("report_version_2.qmd")
  utils::browseURL("report_version_2.pdf")