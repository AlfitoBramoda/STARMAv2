# ============================================================================
# 07_STACF_STPACF_After.R - STACF/STPACF Analysis After Differencing
# ============================================================================

cat("📊 STACF/STPACF Analysis (After Differencing)...\n")

library(starma)

# Load data
load("output/06_differenced_data.RData")
load("output/02_spatial_weights.RData")

data_after <- differenced_data
regions <- colnames(data_after)

cat("Data dimensions:", dim(data_after), "\n")

# ============================================================================
# Calculate STACF/STPACF for each weight matrix
# ============================================================================

results_after <- list()

for (weight_name in names(spatial_weights_std)) {
  cat("\n📈 Processing", weight_name, "weights...\n")
  
  W <- spatial_weights_std[[weight_name]]
  
  # Row standardize weights
  if (weight_name == "uniform") {
    W_std <- W
  } else {
    W_std <- W / (rowSums(W) + 1e-10)
    W_std[is.nan(W_std) | is.infinite(W_std)] <- 0
  }
  
  # Calculate STACF and STPACF
  stacf_vals <- stacf(data_after, wlist = list(W_std), tlag.max = 20)
  stpacf_vals <- stpacf(data_after, wlist = list(W_std), tlag.max = 20)
  
  results_after[[weight_name]] <- list(
    stacf = stacf_vals,
    stpacf = stpacf_vals,
    weights = W_std
  )
  
  cat("STACF range:", range(stacf_vals), "\n")
  cat("STPACF range:", range(stpacf_vals), "\n")
}

# ============================================================================
# Create plots function
# ============================================================================

plot_stacf_stpacf_after <- function() {
  par(mfrow = c(2, 3), mar = c(4, 4, 3, 1))
  
  weight_names <- names(results_after)
  n_obs <- nrow(data_after)
  
  # Calculate confidence bands
  conf_level <- 1.96 / sqrt(n_obs)
  
  # Row 1: STACF plots
  for (i in 1:length(weight_names)) {
    name <- weight_names[i]
    stacf_vals <- results_after[[name]]$stacf
    plot(stacf_vals, type = "h", lwd = 3, col = "blue",
         main = paste("STACF -", name, "(After)"),
         xlab = "Lag", ylab = "STACF")
    abline(h = 0, col = "red", lty = 2)
    abline(h = c(-conf_level, conf_level), col = "blue", lty = 3, lwd = 2)
    grid()
  }
  
  # Row 2: STPACF plots
  for (i in 1:length(weight_names)) {
    name <- weight_names[i]
    stpacf_vals <- results_after[[name]]$stpacf
    plot(stpacf_vals, type = "h", lwd = 3, col = "darkgreen",
         main = paste("STPACF -", name, "(After)"),
         xlab = "Lag", ylab = "STPACF")
    abline(h = 0, col = "red", lty = 2)
    abline(h = c(-conf_level, conf_level), col = "darkgreen", lty = 3, lwd = 2)
    grid()
  }
}

# ============================================================================
# Display and save plots
# ============================================================================

cat("\n📊 Creating STACF/STPACF plots (After Differencing)...\n")

# Display in RStudio
plot_stacf_stpacf_after()

# Save to file
png("plots/07_STACF_STPACF_after.png", width = 1500, height = 1000)
plot_stacf_stpacf_after()
dev.off()

# ============================================================================
# Summary statistics
# ============================================================================

cat("\n📋 STACF/STPACF Summary (After Differencing):\n")
for (name in names(results_after)) {
  stacf_vals <- results_after[[name]]$stacf
  stpacf_vals <- results_after[[name]]$stpacf
  
  cat(name, ":\n")
  cat("  STACF - Mean:", round(mean(stacf_vals), 4), 
      ", Max:", round(max(abs(stacf_vals)), 4), "\n")
  cat("  STPACF - Mean:", round(mean(stpacf_vals), 4), 
      ", Max:", round(max(abs(stpacf_vals)), 4), "\n")
}

# ============================================================================
# Compare with before differencing
# ============================================================================

# Load before results for comparison
load("output/04_stacf_before.RData")

cat("\n🔍 Before vs After Differencing Comparison:\n")
for (name in names(results_after)) {
  if (name %in% names(results_before)) {
    before_max <- max(abs(results_before[[name]]$stacf))
    after_max <- max(abs(results_after[[name]]$stacf))
    
    cat(name, "- STACF Max: Before =", round(before_max, 4), 
        ", After =", round(after_max, 4), 
        ", Reduction =", round((before_max - after_max)/before_max * 100, 1), "%\n")
  }
}

# Save results
save(results_after, data_after,
     file = "output/07_stacf_after.RData")

cat("\n💾 Results saved to: output/07_stacf_after.RData\n")
cat("📊 Plot saved to: plots/07_STACF_STPACF_after.png\n")
cat("✅ STACF/STPACF analysis (after) completed!\n")
cat("🔧 Differencing should show faster decay to zero\n")
cat(paste(rep("=", 50), collapse = ""), "\n")