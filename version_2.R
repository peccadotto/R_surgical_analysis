# Setup

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
          message("!! Error while trying to install the '", pkg, "' package: ", e$message)
        }
      )
    }
    suppressPackageStartupMessages(library(pkg, character.only = TRUE))
  }
  
  rm(list = ls())
  Sys.setenv(QUARTO_PATH = "C:\\Program Files\\RStudio\\resources\\app\\bin\\quarto\\bin\\quarto.exe")

# Importa dati

  df_20122017 <- read.csv("data/20122017.csv", sep = ";", header = TRUE)  
  df_20172020 <- read.csv("data/20172020.csv", sep = ";", header = TRUE)  
  df_20212025 <- read.csv("data/20212025.csv", sep = ";", header = TRUE)  
  df_20262030 <- read.csv("data/20262030.csv", sep = ";", header = TRUE)
  
# Unisci dati
  
  nomi_df <- mget(ls(pattern = "^df_")); df <- bind_rows(nomi_df)
  df <- df |>
    select(-c(Nosologico, Descrizione)) |>
    mutate(
      Data = dmy(Data),
      Inizio = hm(Inizio),
      Fine = hm(Fine),
      Durata = (period_to_seconds(Fine) - period_to_seconds(Inizio)) / 60,
      Paziente = str_replace_all(Paziente, "\\S", "*"),
      Sesso = as.factor(Sesso),
      DOB = dmy(DOB),
      Proc = as.character(Proc),
      Ruolo = as.factor(Ruolo),
      Sede = as.factor(Sede),
      Fase = ifelse(Data <= dmy("11-07-2017"), "SSORT", "ORT"),
      Anno = year(Data)
    ) |>
    arrange(Data, Inizio) 
  
# Crea report
  
  df_pvt_anno <- df |>
    select(Anno, Paziente, Proc) |>
    group_by(Anno) |>
    summarise(
      Interventi = sum(!is.na(Paziente) & Paziente != ""),
      Procedure = sum(!is.na(Proc) & Proc != "")
    ) |>
    mutate(
      Interventi_cum = cumsum(Interventi),
      Delta_int = (Interventi - lag(Interventi)) / lag(Interventi),
      Delta_int = percent(Delta_int, accuracy = 0.01),
      Delta_int = coalesce(Delta_int, "---"),
      Procedure_cum = cumsum(Procedure),
      Delta_proc = (Procedure - lag(Procedure)) / lag(Procedure),
      Delta_proc = percent(Delta_proc, accuracy = 0.01),
      Delta_proc = coalesce(Delta_proc, "---")
    ) |>
    select(Anno, Interventi, Interventi_cum, Delta_int, Procedure, Procedure_cum, Delta_proc) |>
    rename(
      'Int' = Interventi,
      'Int (cum)' = Interventi_cum,
      'Int (-%)' = Delta_int,
      'Proc' = Procedure,
      'Proc (cum)' = Procedure_cum,
      'Proc (- %)' = Delta_proc
    ) |>
    arrange(Anno) |>
    as_tibble() |> print()
  
  df_pvt_lead <- df |>
    select(Anno, Paziente, Proc, Ruolo) |>
    mutate (Lead = ifelse(Ruolo == "1", "LEAD", "Not lead"))|>
    group_by(Anno) |>
    summarise(
      Interventi = sum(!is.na(Paziente) & Paziente != ""),
      Interventi_lead = sum(!is.na(Paziente) & Paziente != "" & Lead == "LEAD"),
      Interventi_lead_pct = percent(Interventi_lead / Interventi, accuracy = 0.01),
      Procedure = sum(!is.na(Proc) & Proc != ""),
      Procedure_lead = sum(!is.na(Proc) & Proc != "" & Lead == "LEAD"),
      Procedure_lead_pct = percent(Procedure_lead / Procedure, accuracy = 0.01)
     ) |>
    adorn_totals(where = "row", fill = "---") |>
    rename(
      ' ' = Anno,
      'Int' = Interventi,
      'Int (PO, n)' = Interventi_lead,
      'Int (PO, %)' = Interventi_lead_pct,
      'Proc' = Procedure,
      'Proc (PO, n)' = Procedure_lead,
      'Proc (PO, %)' = Procedure_lead_pct
    ) |>
     as_tibble() |> print()
  
  df_pvt_fase <- df |>
    group_by(Fase) |>
    summarise(
      Interventi = sum(!is.na(Paziente) & Paziente != ""),
      Pct_int = sum(!is.na(Paziente) & Paziente != ""),
      Procedure = sum(!is.na(Proc) & Proc != ""),
      Pct_proc = sum(!is.na(Proc) & Proc != "")
    ) |>
    arrange(desc(Fase)) |>
    adorn_totals(where = "row", name = "Totale") |>
    adorn_percentages(denominator = "col", select_cols = c("Pct_int", "Pct_proc")) |>
    adorn_pct_formatting(digits = 2, affix_sign = TRUE, select_cols = c("Pct_int", "Pct_proc")) |>
    rename(
      ' ' = Fase,
      'Int' = Interventi,
      'Int (%)' = Pct_int,
      'Proc' = Procedure,
      'Proc (%)' = Pct_proc
    ) |>
    as_tibble() |> print()
  
  df_pvt_sede <- df |>
    group_by(Sede) |>
    summarise(
      Interventi = sum(!is.na(Paziente) & Paziente != ""),
      Pct_int = sum(!is.na(Paziente) & Paziente != ""),
      Procedure = sum(!is.na(Proc) & Proc != ""),
      Pct_proc = sum(!is.na(Proc) & Proc != "")
    ) |>
    arrange(desc(Interventi))|>
    adorn_totals(where = "row", name = "Totale") |>
    adorn_percentages(denominator = "col", select_cols = c("Pct_int", "Pct_proc")) |>
    adorn_pct_formatting(digits = 2, affix_sign = TRUE, select_cols = c("Pct_int", "Pct_proc")) |>
    rename(
      ' ' = Sede,
      'Int' = Interventi,
      'Int (%)' = Pct_int,
      'Proc' = Procedure,
      'Proc (%)' = Pct_proc) |>
    as_tibble() |> print()
  
  icd9 <- read.csv("data/icd9_procedures.csv", sep = ";", header = TRUE) |> mutate (Proc = as.character(Proc)) |> select(-Short)
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
      '%' = Pct,
      Descrizione = Long
    ) |>
    as_tibble() |> print()
  
# Esporta dati
  
  ls2save <- list(
    "0) Df completo" = df,
    "1) PVT anno" = df_pvt_anno,
    "2) PVT primo operatore" = df_pvt_lead,
    "3) PVT fase (specializzando vs strutturato)" = df_pvt_fase,
    "4) PVT sede" = df_pvt_sede,
    "5) PVT top 15 procedures" = df_pvt_proc
  )
  saveRDS(ls2save, file = "data/export.rds")
  write_xlsx(ls2save, path = "data/export.xlsx")
  ls2keep <- ls(pattern = "^df|^df_pvt")
  rm(list = setdiff(ls(), ls2keep))
  
# Mostra report
  
  quarto_render("report_version_2.qmd")
  utils::browseURL("report_version_2.pdf")