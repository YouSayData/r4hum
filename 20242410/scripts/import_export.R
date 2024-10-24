# ==========================================
# Importing and Exporting Data in R
# Using Florence Nightingale's Data
# ==========================================

# Loading necessary libraries
library(HistData)      # Historical datasets (including Nightingale's data)
library(readr)         # For CSV import/export
library(readxl)        # For reading Excel files
library(openxlsx2)     # For writing Excel files
library(skimr)         # For data summary
library(here)          # For file paths
library(tidyverse)

# ==========================================
# 1. Exploring Florence Nightingale's Data
# ==========================================
# Let's load Florence Nightingale's dataset from the HistData package, which shows mortality
# statistics during the Crimean War.

data("Nightingale")

# Preview the first few rows of the data
skim(Nightingale)
as_tibble(Nightingale)

# ==========================================
# 2. Exporting Nightingale Data to CSV
# ==========================================
# We'll export the Nightingale dataset to a CSV file.
# Note: Ensure the 'data' directory exists or create it using dir.create("data")

write_csv(Nightingale, 
          here("data", "nightingale_data.csv")
          )

# ==========================================
# 3. Importing Nightingale Data from CSV
# ==========================================
# Now, let's import the CSV file back into R as if we were receiving it from a collaborator.

imported_nightingale_csv <- read_csv(
  here("data", "nightingale_data.csv")
  )

# Preview the imported CSV data
skim(imported_nightingale_csv)

# import Year  Army Disease Wounds Other as integer
improved_imported_nightingale_csv <- read_csv(
  here("data", "nightingale_data.csv"),
  col_types = cols(
    Year = col_integer(),
    Army = col_integer(),
    Disease = col_integer(),
    Wounds = col_integer(),
    Other = col_integer()
  )
)
improved_imported_nightingale_csv

# ==========================================
# 4. Exporting Nightingale Data to Excel
# ==========================================
# Next, let's export the Nightingale dataset to an Excel file using the openxlsx2 package.

openxlsx2::write_xlsx(
  Nightingale, 
  here("data", "nightingale_data.xlsx")
  )

# Dates are pre 1900, so we need to convert them to character

# Exporting Nightingale data to Excel
openxlsx2::write_xlsx(
  Nightingale |>  mutate(Date = as.character(Date)),
  here("data", "nightingale_data.xlsx")
)

# ==========================================
# 5. Importing Nightingale Data from Excel
# ==========================================
# Now, let's import the dataset back from the Excel file using the readxl package.

imported_nightingale_excel <- read_excel("data/nightingale_data.xlsx")

# Preview the imported Excel data
skim(imported_nightingale_excel)
imported_nightingale_excel

# import Date as date
improved_imported_nightingale_excel <- read_excel(
  here("data", "nightingale_data.xlsx")
  ) |> 
  mutate(Date = ymd(Date))

improved_imported_nightingale_excel
