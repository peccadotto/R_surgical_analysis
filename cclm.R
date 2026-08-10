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
  as_euro <- function (x) {currency(x, symbol = "€", big.mark = ".", decimal.mark = ",", sep = " ")}
  Sys.setenv(QUARTO_PATH = "C:\\Program Files\\RStudio\\resources\\app\\bin\\quarto\\bin\\quarto.exe")

# Importa dati

  cclm_fatti <-
    read.csv("data/cclm/cclm_fatti.csv", sep = ";", header = TRUE) |>
    mutate(
      Seduta = as.character(Seduta),
      Data = dmy(Data),
      Regime = as.factor(Regime),
      NP = parse_number(NP, locale = locale(decimal_mark = ",", grouping_mark = ".")),
      AP = parse_number(AP, locale = locale(decimal_mark = ",", grouping_mark = ".")),
      OP3 = parse_number(OP3, locale = locale(decimal_mark = ",", grouping_mark = ".")),
      ANE = parse_number(ANE, locale = locale(decimal_mark = ",", grouping_mark = ".")),
      Equipe = NP + AP + OP3 + ANE,
      Totale = parse_number(Totale, locale = locale(decimal_mark = ",", grouping_mark = ".")),
      Data_fattura = dmy(Data_fattura),
      Data_pagamento = dmy(Data_pagamento),
      Stagione = case_when(
        Data < dmy("15-08-2023") ~ "2022-2023",
        Data < dmy("15-08-2024") ~ "2023-2024",
        Data < dmy("15-08-2025") ~ "2024-2025",
        TRUE ~ "2025-2026"
      )
    )

  cclm_rifiutati <- 
    read.csv("data/cclm/cclm_rifiutati.csv", sep = ";", header = TRUE) |>
    mutate(
      Regime = ifelse(Regime == "LPN", "Solvente", "Assicurato"),
      NP = parse_number(NP, locale = locale(decimal_mark = ",", grouping_mark = ".")),
      AP = parse_number(AP, locale = locale(decimal_mark = ",", grouping_mark = ".")),
      ANE = parse_number(ANE, locale = locale(decimal_mark = ",", grouping_mark = ".")),
      Equipe = NP + AP + ANE,
      Totale = parse_number(Totale, locale = locale(decimal_mark = ",", grouping_mark = ".")),
      Motivo = as.factor(Motivo),
      PO = case_when(
        NP > AP ~ "Portinaro",
        TRUE ~ "Peccati"
      )
    )

# Crea report

  cclm_pvt_fatti <- cclm_fatti |>
    group_by(Stagione) |>
    summarise(
      Pazienti = n(),
      Sedute = n_distinct(Seduta),
      DH = sum(Regime == "DH", na.rm = TRUE),
      'DH (%)' = DH / Pazienti,
      RO = sum(Regime == "RO", na.rm = TRUE),
      'RO (%)' = RO / Pazienti,
      Assicurati = sum(Assic != "LPN", na.rm = TRUE),
      'Assicurati (%)' = Assicurati / Pazienti,
      Solventi = sum(Assic == "LPN", na.rm = TRUE),
      'Solventi (%)' = Solventi / Pazienti,
      'Tot NP' = sum(NP, na.rm = TRUE),
      'Tot AP' = sum(AP, na.rm = TRUE),
      'Tot equipe' = sum(Equipe, na.rm = TRUE),
      'Tot CCLM' = sum(Totale, na.rm = TRUE) - sum(Equipe, na.rm = TRUE),
      Totale = sum(Totale, na.rm = TRUE)
    ) |>
    pivot_longer(
      cols = -Stagione, 
      names_to = "Indicatore", 
      values_to = "Valore"
    ) |>
    pivot_wider(
      names_from = Stagione, 
      values_from = Valore
    ) |>
    mutate(
      'Totale complessivo' = case_when(
        Indicatore %in% c("Tot NP", "Tot AP", "Tot equipe", "Tot CCLM", "Totale") ~ rowSums(across(-Indicatore), na.rm = TRUE),
        TRUE ~ NA_real_
      )
    ) |>
    mutate(
      across(
        -Indicatore,
        ~ case_when(
          is.na(.x) ~ "",
          Indicatore %in% c("DH (%)", "RO (%)", "Assicurati (%)", "Solventi (%)") ~ percent(.x, accuracy = 0.01),
          Indicatore %in% c("Totale", "Tot CCLM", "Tot equipe", "Tot NP", "Tot AP") ~ as.character(as_euro(.x)),
          TRUE ~ as.character(round(.x, 0))
        )
      )
    ) |>
    print()

  cclm_pvt_operatore <- cclm_rifiutati |>
    group_by(PO) |>
    summarise(
      N = n(),
      NP = sum(NP),
      AP = sum(AP),
      CCLM = sum(Totale)
    ) |> 
    mutate(
      Totale = NP + AP + CCLM,
      `%` = N
    ) |>
    arrange(desc(N)) |>
    relocate(NP:Totale, .after = "%") |>
    adorn_totals(where = "row", name = "Totale") |>
    adorn_percentages(denominator = "col", select_cols = "%") |>
    adorn_pct_formatting(digits = 2, affix_sign = TRUE, select_cols = "%") |>
    mutate(
      NP = as_euro(NP),
      AP = as_euro(AP),
      CCLM = as_euro(CCLM),
      Totale = as_euro(Totale)
    ) |>
    rename(
      " " = PO,
      "Incasso NP" = NP,
      "Incasso AP" = AP,
      "Incasso CCLM" = CCLM,
      "Incasso totale" = Totale
    ) |>
    print()

  cclm_pvt_motivo <- cclm_rifiutati |>
    group_by(Motivo) |>
    summarise(
      N = n(),
    ) |> 
    mutate(`%` = N) |>
    arrange(desc(N)) |>
    adorn_totals(where = "row", name = "Totale") |>
    adorn_percentages(denominator = "col", select_cols = "%") |>
    adorn_pct_formatting(digits = 2, affix_sign = TRUE, select_cols = "%") |>
    rename(" " = Motivo) |>
    print()

  cclm_pvt_regime <- cclm_rifiutati |>
    group_by(Regime) |>
    summarise(
      N = n(),
    ) |> 
    mutate(`%` = N) |>
    arrange(desc(N)) |>
    adorn_totals(where = "row", name = "Totale") |>
    adorn_percentages(denominator = "col", select_cols = "%") |>
    adorn_pct_formatting(digits = 2, affix_sign = TRUE, select_cols = "%") |>
    rename(" " = Regime) |>
    print()

# Esporta dati

  ls2save <- list(
    "0) Interventi fatti" = cclm_fatti,
    "1) PVT interventi fatti" = cclm_pvt_fatti,
    "0) Preventivi rifiutati" = cclm_rifiutati,
    "2) PVT preventivi rifiutati (operatore)" = cclm_pvt_operatore,
    "3) PVT preventivi rifiutati (motivo)" = cclm_pvt_motivo,
    "4) PVT preventivi rifiutati (regime)" = cclm_pvt_regime
  )
  saveRDS(ls2save, file = "data/cclm/export.rds")
  write_xlsx(ls2save, path = "data/cclm/export.xlsx")
  ls2keep <- ls(pattern = "^cclm|^cclm_pvt")
  rm(list = setdiff(ls(), ls2keep))

# Mostra report
  
  quarto_render("report_cclm.qmd")
  utils::browseURL("report_cclm.pdf")