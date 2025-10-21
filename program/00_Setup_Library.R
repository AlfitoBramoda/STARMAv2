# ==============================================================================
# 00_Setup_Library.R
# Environment setup and package installation for STARIMA analysis
# ==============================================================================

cat("Setting up STARIMA environment...\n")

# Required packages for STARIMA analysis
required_packages <- c(
  "starma", "spdep", "tseries", "urca", "forecast", 
  "dplyr", "tidyr", "ggplot2", "gridExtra", "corrplot", 
  "readr", "sf", "car"
)

# Install missing packages
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(new_packages)) {
  cat("Installing missing packages:", paste(new_packages, collapse = ", "), "\n")
  install.packages(new_packages, dependencies = TRUE)
}

# Load all packages
cat("Loading packages...\n")
invisible(lapply(required_packages, library, character.only = TRUE))

# Create output directories if they don't exist
if(!dir.exists("output")) dir.create("output", recursive = TRUE)
if(!dir.exists("plots")) dir.create("plots", recursive = TRUE)

cat("Environment setup complete!\n")
cat("Packages loaded:", paste(required_packages, collapse = ", "), "\n")