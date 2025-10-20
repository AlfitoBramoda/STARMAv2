# ============================================================================
# Reset.R - Clean All Output Files and Environment
# Fungsi: Menghapus semua file output dan membersihkan environment
# ============================================================================

cat("=== RESETTING STARIMA PROJECT ===\n")

# Clear R environment
rm(list = ls())
cat("✓ Environment cleared\n")

# Remove all files in output folder
if(dir.exists("output")) {
  output_files <- list.files("output", full.names = TRUE)
  if(length(output_files) > 0) {
    file.remove(output_files)
    cat("✓ Output files removed:", length(output_files), "files\n")
  } else {
    cat("✓ Output folder already empty\n")
  }
} else {
  dir.create("output")
  cat("✓ Output folder created\n")
}

# Remove all files in plots folder
if(dir.exists("plots")) {
  plot_files <- list.files("plots", full.names = TRUE)
  if(length(plot_files) > 0) {
    file.remove(plot_files)
    cat("✓ Plot files removed:", length(plot_files), "files\n")
  } else {
    cat("✓ Plots folder already empty\n")
  }
} else {
  dir.create("plots")
  cat("✓ Plots folder created\n")
}

# Clear plots panel (if in RStudio)
if(exists("rstudioapi") && rstudioapi::isAvailable()) {
  try({
    # Clear plots panel
    dev.off()
    graphics.off()
    # Clear console
    rstudioapi::sendToConsole("cat('\014')", execute = FALSE)
  }, silent = TRUE)
} else {
  # Clear plots if not in RStudio
  try({
    dev.off()
    graphics.off()
  }, silent = TRUE)
}

cat("\n=== RESET COMPLETE ===\n")
cat("Project ready for fresh analysis!\n")