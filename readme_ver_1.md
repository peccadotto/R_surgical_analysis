# **SURGICAL ANALYSIS PROJECT**

**Author:** Dr. Andrea PECCATI

**Output Format:** Interactive Robobook (HTML)

This project provides a comprehensive statistical analysis of personal surgical procedures performed since 2012.

It automates the entire workflow, from raw data cleaning and transformation to the generation of a professional, interactive HTML report.

## **REPORT PREVIEW**

![](report_preview.png)

## **PROJECT STRUCTURE**

-   **`surgical_analysis.R`**:\
    The core engine. It handles library dependencies, data ingestion, cleaning, and statistical computation, and it exports the data for the report.
-   **`surgical_analysis.Rmd`**:\
    The reporting layer. It imports the processed environment and renders the visual dashboard using `ggplot2` and `kableExtra`
-   **`data/`** *(Directory)*:\
    Expected location for anonymized CSV files.\
    [Note: This folder is typically excluded from version control to maintain data silos]
-   **`surgical_analysis.RData`**\
    The bridge file containing exported functions and dataframes used for report generation

## **PRIVACY AND DATA PROTECTION**

-   All data utilized in this project has been **fully anonymized** prior to the creation of the source CSV files to ensure patient privacy

-   There is **no sensitive personal information** (PII) or health-protected identifiers within the datasets

-   The analysis is performed exclusively on de-identified variables such as visit types, timestamps, and payment categories

## **INSTRUCTIONS**

1.  **Prepare Data**\
    Place your anonymized CSV files (formatted with `;` separator) into the `/data` folder

2.  **Process:**\
    Execute the R script to clean and transform the data:

    ```         
    source("surgical_analysis.R")
    ```

3.  **Render**\
    Knit the .RMarkdown file in RStudio or via console:

    ```         
    rmarkdown::render("surgical_analysis.Rmd")
    ```

## **KEY FEATURES**

-   **Automated Data Ingestion**\
    Scans the `/data` directory for CSV files

-   **Integrity Auditing**\
    Uses a custom `check_missing()` function to monitor data quality and NA percentages

-   **Clinical activity monitoring and academic performance tracking**, focusing on three main pillars:

    -   **Performed procedures**: analysis of the total amount of procedures performed per year

    -   **Procedures as lead surgeon**: analysis of the percentage of procedures performed as lead surgeon

    -   **Top 15 procedures**: analysis of the top 15 procedures (ICD-9 classification)

-   **Professional Reporting**\
    Generates a mobile-responsive "Robobook" report with interactive tables, stacked bar charts, and cumulative growth metrics

## **TECH STACK**

-   **Language:** R (verison ≥ 4.1.0 required for the native pipe operator `|>`)

-   **RStudio:** Recommended for knitting the `.Rmd` report

-   **Operating System:** Windows, macOS, or Linux

-   **Manipulation:** `tidyverse` (dplyr, purrr, tidyr), `lubridate`

-   **Visualization:** `ggplot2`

-   **Table Formatting:** `kableExtra`

-   **UI/UX:** `rmdformats` (Robobook template)