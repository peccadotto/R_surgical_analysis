# Surgical Analysis Pipeline

> **Author:** Andrea Peccati (`Peccadotto`)\
> **Repository:** <https://github.com/peccadotto/R_surgical_analysis>

## Overview

The **Surgical Analysis Pipeline** is an automated workflow built in **R** and integrated with **Quarto** (`.qmd`) to process, aggregate, and generate comprehensive PDF reports of surgical activity and medical procedures. It is designed to handle multi-year surgical logs, anonymize sensitive patient information, calculate key performance indicators (such as lead surgeon rates and career period distributions), and export clean analytical outputs in multiple formats (`.rds` and `.xlsx`).

------------------------------------------------------------------------

## Key Features

- **Automated Package Management:** Automatically checks for required dependencies, installs missing packages from CRAN, and handles environment setups.
- **Data Integration & Cleansing:** Merges historical CSV datasets spanning multiple years, parses dates and surgical times, handles patient data privacy through masking, and classifies career stages (*Resident* vs. *Attending*).
- **Advanced Aggregations & Pivots:**
  - Yearly surgical and procedural volume tracking with cumulative counts and year-over-year percentage differences.
  - Lead surgeon role analysis (`Role == 1` vs. others) with percentage breakdowns.
  - Professional practice location and career period partitioning across major clinical centers.
  - Top 15 procedure frequency analysis mapped against standard ICD-9 procedure codes.
- **Multi-Format Exporting:** Saves processed datasets into an internal R structure (`export.rds`) and an Excel workbook (`export.xlsx`) for downstream reporting.
- **Dynamic Quarto Reporting:** Compiles custom-styled HTML and PDF reports featuring:
  - Professional custom ggplot themes and tailored color palettes.
  - Striped data tables via `kableExtra` highlighting running totals and deltas.
  - Visual breakdowns for yearly productivity, lead surgeon evolution, facility distribution, and top ICD-9 procedures.

------------------------------------------------------------------------

## Project Structure

``` text
R_surgical_analysis/
│
├── data/
│   ├── 20122017.csv            # Raw surgical logs (2012–2017)
│   ├── 20172020.csv            # Raw surgical logs (2017–2020)
│   ├── 20212025.csv            # Raw surgical logs (2021–2025)
│   ├── 20262030.csv            # Raw surgical logs (2026–2030)
│   ├── icd9_procedures.csv     # ICD-9 procedure reference codes
│   ├── export.rds              # Processed R data list (generated)
│   └── export.xlsx             # Processed Excel workbook (generated)
│
├── version_2.R                 # Main pipeline script
├── report_version_2.qmd        # Quarto document template (pdf)
├── report_version_2_plot.qmd   # Quarto document template (html)
└── README.md                   # Project documentation
```

------------------------------------------------------------------------

## Prerequisites & Dependencies

The R script automatically verifies and installs the following required CRAN packages if they are missing:

- `tidyverse` (Data manipulation and visualization: `dplyr`, `stringr`, `readr`, etc.)
- `formattable` (Formatting numbers and percentages)
- `janitor` (Cross-tabulation and total row adornment)
- `lubridate` (Date and time parsing)
- `quarto` (Dynamic report rendering interface)
- `scales` (Scale functions for graphics and formatting)
- `writexl` (Exporting data frames to Excel spreadsheets)

> **Note on Quarto:** Ensure that Quarto is installed on your system. The script includes a Windows path configuration for RStudio's bundled Quarto binary (`C:\Program Files\RStudio\resources\app\bin\quarto\bin\quarto.exe`), which can be modified depending on your operating system.

------------------------------------------------------------------------

## Usage Guide

1.  **Clone the Repository:**

    ``` bash
    git clone https://github.com/peccadotto/R_surgical_analysis.git
    cd R_surgical_analysis
    ```

2.  **Prepare Your Data:** Place your source CSV files inside the `data/` directory matching the naming convention (`20122017.csv`, `20172020.csv`, etc.), ensuring they include semicolon separators (`sep = ";"`) and appropriate column headers (`Date`, `Start` for surgery start time, `End` for surgery end time, `Patient` after anonymization, `Gender`, `DOB` for date of birth, `Proc` for ICD9 code of performed procedure, `Role` as 1 for leading surgeon or 2\|3 for 2nd\|3rd surgeon, `Place`).

3.  **Run the Analysis Script:** Open and execute `version_2.R` in RStudio or via R command line:

    ``` r
    source("verison_2.R")
    ```

    This script will process the raw files, print summary tables to the console, save the processed outputs to `data/export.rds` and `data/export.xlsx`, and automatically trigger the Quarto render to output the final HTML and PDF reports.

------------------------------------------------------------------------

## License

This project is open-source and available under the [MIT License](LICENSE).
