# ============================================================================
# 00_Setup_Library.R
# Fungsi: Install & load semua library yang dibutuhkan untuk analisis STARIMA
# Output: Semua package siap digunakan
# ============================================================================

# Daftar package yang dibutuhkan
required_packages <- c(
  "tidyverse",     # Data manipulation & visualization
  "forecast",      # Time series forecasting
  "tseries",       # Time series analysis & tests
  "spdep",         # Spatial dependence analysis
  "geosphere",     # Geographic calculations
  "corrplot",      # Correlation matrix visualization
  "gridExtra",     # Multiple plots arrangement
  "lubridate",     # Date manipulation
  "ggplot2",       # Advanced plotting
  "dplyr",         # Data manipulation
  "readr",         # Data reading
  "starma"         # STARMA modeling (if available)
)

# Function untuk install package jika belum ada
install_if_missing <- function(packages) {
  new_packages <- packages[!(packages %in% installed.packages()[,"Package"])]
  if(length(new_packages)) {
    cat("Installing missing packages:", paste(new_packages, collapse = ", "), "\n")
    install.packages(new_packages, dependencies = TRUE)
  }
}

# Install missing packages
install_if_missing(required_packages)

# Load semua packages
cat("Loading required packages...\n")
for(pkg in required_packages) {
  if(pkg == "starma" && !require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("Warning: starma package not available. Will use alternative methods.\n")
    next
  }
  library(pkg, character.only = TRUE, quietly = TRUE)
  cat("✓", pkg, "loaded\n")
}

# Set global options
options(digits = 4)
options(scipen = 999)

# Create output directories if not exist
if(!dir.exists("output")) dir.create("output")
if(!dir.exists("plots")) dir.create("plots")

cat("\n=== Setup Complete ===\n")
cat("All required packages loaded successfully!\n")
cat("Ready for STARIMA analysis.\n")