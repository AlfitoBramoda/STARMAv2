# ============================================================================
# 04_STACF_STPACF_Before.R - STACF/STPACF Analysis Before Differencing
# ============================================================================

cat("📊 STACF/STPACF Analysis (Before Differencing)...\n")

library(starma)
library(ggplot2)

# Load data
load("output/03_boxcox_data.RData")
load("output/02_spatial_weights.RData")

# Use final_data from Box-Cox step
data_before <- final_data
regions <- colnames(data_before)

cat("Data dimensions:", dim(data_before), "\n")

# ============================================================================
# Calculate STACF/STPACF for each weight matrix
# ============================================================================

results_before <- list()

for (weight_name in names(spatial_weights_std)) {
  cat("\n📈 Processing", weight_name, "weights...\n")
  
  W <- spatial_weights_std[[weight_name]]
  
  # Row standardize weights (kecuali untuk uniform)
  if (weight_name == "uniform") {
    W_std <- W  # Uniform weights tidak perlu standardisasi
  } else {
    W_std <- W / (rowSums(W) + 1e-10)
    W_std[is.nan(W_std) | is.infinite(W_std)] <- 0
  }
  
  # Calculate STACF and STPACF
  stacf_vals <- stacf(data_before, wlist = list(W_std), tlag.max = 40)
  stpacf_vals <- stpacf(data_before, wlist = list(W_std), tlag.max = 40)
  
  results_before[[weight_name]] <- list(
    stacf = stacf_vals,
    stpacf = stpacf_vals,
    weights = W_std
  )
  
  cat("STACF range:", range(stacf_vals), "\n")
  cat("STPACF range:", range(stpacf_vals), "\n")
}

# ============================================================================
# Create plots
# ============================================================================

cat("\n📊 Creating STACF/STPACF plots (Before Differencing)...\n")

# Create function to plot all at once
plot_stacf_stpacf <- function() {
  par(mfrow = c(2, 3), mar = c(4, 4, 3, 1))
  
  weight_names <- names(results_before)
  n_obs <- nrow(data_before)
  
  # Calculate confidence bands (95% confidence level)
  conf_level <- 1.96 / sqrt(n_obs)
  
  # Row 1: STACF plots
  for (i in 1:length(weight_names)) {
    name <- weight_names[i]
    stacf_vals <- results_before[[name]]$stacf
    plot(stacf_vals, type = "h", lwd = 3, col = "blue",
         main = paste("STACF -", name, "(Before)"),
         xlab = "Lag", ylab = "STACF")
    abline(h = 0, col = "red", lty = 2)
    abline(h = c(-conf_level, conf_level), col = "blue", lty = 3, lwd = 2)
    grid()
  }
  
  # Row 2: STPACF plots
  for (i in 1:length(weight_names)) {
    name <- weight_names[i]
    stpacf_vals <- results_before[[name]]$stpacf
    plot(stpacf_vals, type = "h", lwd = 3, col = "darkgreen",
         main = paste("STPACF -", name, "(Before)"),
         xlab = "Lag", ylab = "STPACF")
    abline(h = 0, col = "red", lty = 2)
    abline(h = c(-conf_level, conf_level), col = "darkgreen", lty = 3, lwd = 2)
    grid()
  }
}

# Display in RStudio (single combined plot)
plot_stacf_stpacf()

# Save to file
png("plots/04_STACF_STPACF_before.png", width = 1500, height = 1000)
plot_stacf_stpacf()
dev.off()

# ============================================================================
# Summary statistics
# ============================================================================

cat("\n📋 STACF/STPACF Summary (Before Differencing):\n")
for (name in names(results_before)) {
  stacf_vals <- results_before[[name]]$stacf
  stpacf_vals <- results_before[[name]]$stpacf
  
  cat(name, ":\n")
  cat("  STACF - Mean:", round(mean(stacf_vals), 4), 
      ", Max:", round(max(abs(stacf_vals)), 4), "\n")
  cat("  STPACF - Mean:", round(mean(stpacf_vals), 4), 
      ", Max:", round(max(abs(stpacf_vals)), 4), "\n")
}

# Save results
save(results_before, data_before, 
     file = "output/04_stacf_before.RData")

cat("\n💾 Results saved to: output/04_stacf_before.RData\n")
cat("📊 Plot saved to: plots/04_STACF_STPACF_before.png\n")
cat("✅ STACF/STPACF analysis (before) completed!\n")
cat(paste(rep("=", 50), collapse = ""), "\n")