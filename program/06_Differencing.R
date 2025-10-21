# ============================================================================
# 06_Differencing.R - Apply Seasonal Differencing (1-B^12)
# ============================================================================

cat("📊 Applying Seasonal Differencing (D=1, d=0)...\n")

library(tseries)
library(urca)

# Load data
load("output/05_stationarity_results.RData")

regions <- colnames(data_test)

cat("Original data dimensions:", dim(data_test), "\n")

# ============================================================================
# Apply Seasonal Differencing (1-B^12)
# ============================================================================

# Apply seasonal differencing with lag 12
differenced_data <- apply(data_test, 2, function(x) {
  # Remove first 12 observations due to differencing
  diff(x, lag = 12)
})

colnames(differenced_data) <- regions

cat("Differenced data dimensions:", dim(differenced_data), "\n")
cat("Lost observations due to differencing:", nrow(data_test) - nrow(differenced_data), "\n")

# ============================================================================
# Validate Post-Differencing Stationarity
# ============================================================================

cat("\n🔍 Validating stationarity after differencing...\n")

post_diff_results <- list()

for (i in 1:ncol(differenced_data)) {
  region <- regions[i]
  series <- differenced_data[, i]
  
  cat("\n📈 Testing", region, "after differencing...\n")
  
  # Remove NA values
  series_clean <- series[!is.na(series)]
  
  # ADF Test
  adf_test <- adf.test(series_clean, alternative = "stationary")
  
  # KPSS Test
  kpss_test <- kpss.test(series_clean, null = "Level")
  
  post_diff_results[[region]] <- list(
    adf_p_value = adf_test$p.value,
    adf_stationary = adf_test$p.value < 0.05,
    kpss_p_value = kpss_test$p.value,
    kpss_stationary = kpss_test$p.value > 0.05,
    both_agree = (adf_test$p.value < 0.05) & (kpss_test$p.value > 0.05)
  )
  
  cat("ADF p-value:", round(adf_test$p.value, 4), 
      ifelse(adf_test$p.value < 0.05, "(Stationary)", "(Non-stationary)"), "\n")
  cat("KPSS p-value:", round(kpss_test$p.value, 4), 
      ifelse(kpss_test$p.value > 0.05, "(Stationary)", "(Non-stationary)"), "\n")
}

# ============================================================================
# Summary Comparison
# ============================================================================

cat("\n📋 Before vs After Differencing Comparison:\n")

comparison_table <- data.frame(
  Region = regions,
  Before_ADF = sapply(stationarity_results, function(x) round(x$adf_p_value, 4)),
  After_ADF = sapply(post_diff_results, function(x) round(x$adf_p_value, 4)),
  Before_KPSS = sapply(stationarity_results, function(x) round(x$kpss_p_value, 4)),
  After_KPSS = sapply(post_diff_results, function(x) round(x$kpss_p_value, 4)),
  Improved = sapply(regions, function(r) {
    before <- stationarity_results[[r]]$both_agree
    after <- post_diff_results[[r]]$both_agree
    ifelse(after & !before, "YES", ifelse(after, "MAINTAINED", "NO"))
  })
)

print(comparison_table)

# Check overall success
all_stationary <- all(sapply(post_diff_results, function(x) x$both_agree))

cat("\n🔍 Differencing Assessment:\n")
if (all_stationary) {
  cat("✅ All series are now stationary after seasonal differencing\n")
  differencing_success <- TRUE
} else {
  cat("⚠️ Some series may need additional differencing\n")
  differencing_success <- FALSE
}

# ============================================================================
# Visualization
# ============================================================================

cat("\n📊 Creating before/after comparison plots...\n")

# Time series comparison for all 5 regions
par(mfrow = c(2, 5), mar = c(4, 4, 3, 1))

# Row 1: Original series
for (i in 1:ncol(data_test)) {
  region <- regions[i]
  plot(data_test[, i], type = "l", col = "blue", lwd = 2,
       main = paste("Original -", region),
       xlab = "Time", ylab = "Value")
  grid()
}

# Row 2: Differenced series
for (i in 1:ncol(differenced_data)) {
  region <- regions[i]
  plot(differenced_data[, i], type = "l", col = "red", lwd = 2,
       main = paste("Differenced -", region),
       xlab = "Time", ylab = "Differenced Value")
  grid()
}

# Save plot
png("plots/06_differencing_comparison.png", width = 2000, height = 800)
par(mfrow = c(2, 5), mar = c(4, 4, 3, 1))

# Row 1: Original series
for (i in 1:ncol(data_test)) {
  region <- regions[i]
  plot(data_test[, i], type = "l", col = "blue", lwd = 2,
       main = paste("Original -", region),
       xlab = "Time", ylab = "Value")
  grid()
}

# Row 2: Differenced series
for (i in 1:ncol(differenced_data)) {
  region <- regions[i]
  plot(differenced_data[, i], type = "l", col = "red", lwd = 2,
       main = paste("Differenced -", region),
       xlab = "Time", ylab = "Differenced Value")
  grid()
}

dev.off()

# ============================================================================
# Store differencing parameters
# ============================================================================

differencing_params <- list(
  seasonal_lag = 12,
  seasonal_diff = 1,
  regular_diff = 0,
  operator = "(1-B^12)",
  observations_lost = nrow(data_test) - nrow(differenced_data)
)

# Save results
save(differenced_data, post_diff_results, comparison_table, 
     differencing_success, differencing_params, data_test,
     file = "output/06_differenced_data.RData")

cat("\n💾 Results saved to: output/06_differenced_data.RData\n")
cat("📊 Plot saved to: plots/06_differencing_comparison.png\n")
cat("✅ Seasonal differencing completed!\n")
cat("🔧 Applied operator: (1-B^12) with D=1, d=0\n")
cat(paste(rep("=", 50), collapse = ""), "\n")