# ============================================================================
# 05_Stationarity_Test.R - Unit Root Tests (ADF, KPSS)
# ============================================================================

cat("📊 Stationarity Testing (ADF & KPSS)...\n")

library(tseries)
library(urca)

# Load data
load("output/03_boxcox_data.RData")

data_test <- final_data
regions <- colnames(data_test)

cat("Data dimensions:", dim(data_test), "\n")

# ============================================================================
# Stationarity Tests
# ============================================================================

stationarity_results <- list()

for (i in 1:ncol(data_test)) {
  region <- regions[i]
  series <- data_test[, i]
  
  cat("\n📈 Testing", region, "...\n")
  
  # Remove NA values
  series_clean <- series[!is.na(series)]
  
  # ADF Test (H0: non-stationary)
  adf_test <- adf.test(series_clean, alternative = "stationary")
  
  # KPSS Test (H0: stationary)
  kpss_test <- kpss.test(series_clean, null = "Trend")
  
  # Store results
  stationarity_results[[region]] <- list(
    adf_statistic = adf_test$statistic,
    adf_p_value = adf_test$p.value,
    adf_stationary = adf_test$p.value < 0.05,
    kpss_statistic = kpss_test$statistic,
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
# Summary Table
# ============================================================================

cat("\n📋 Stationarity Test Summary:\n")

summary_table <- data.frame(
  Region = regions,
  ADF_pvalue = sapply(stationarity_results, function(x) round(x$adf_p_value, 4)),
  ADF_Result = sapply(stationarity_results, function(x) ifelse(x$adf_stationary, "Stationary", "Non-stationary")),
  KPSS_pvalue = sapply(stationarity_results, function(x) round(x$kpss_p_value, 4)),
  KPSS_Result = sapply(stationarity_results, function(x) ifelse(x$kpss_stationary, "Stationary", "Non-stationary")),
  Both_Agree = sapply(stationarity_results, function(x) ifelse(x$both_agree, "YES", "NO"))
)

print(summary_table)

# Check if differencing is needed
need_differencing <- !all(sapply(stationarity_results, function(x) x$both_agree))

cat("\n🔍 Overall Assessment:\n")
if (need_differencing) {
  cat("❌ Data is NOT stationary - Differencing required\n")
} else {
  cat("✅ Data is stationary - No differencing needed\n")
}

# ============================================================================
# Visualization
# ============================================================================

cat("\n📊 Creating stationarity test visualization...\n")

# Plot p-values
par(mfrow = c(1, 2), mar = c(8, 4, 3, 1))

# ADF p-values
adf_pvals <- sapply(stationarity_results, function(x) x$adf_p_value)
barplot(adf_pvals, names.arg = regions, las = 2, col = "lightblue",
        main = "ADF Test p-values", ylab = "p-value")
abline(h = 0.05, col = "red", lty = 2, lwd = 2)
text(x = length(regions)/2, y = 0.07, "α = 0.05", col = "red")

# KPSS p-values
kpss_pvals <- sapply(stationarity_results, function(x) x$kpss_p_value)
barplot(kpss_pvals, names.arg = regions, las = 2, col = "lightgreen",
        main = "KPSS Test p-values", ylab = "p-value")
abline(h = 0.05, col = "red", lty = 2, lwd = 2)
text(x = length(regions)/2, y = 0.07, "α = 0.05", col = "red")

# Save plot
png("plots/05_stationarity_tests.png", width = 1200, height = 600)
par(mfrow = c(1, 2), mar = c(8, 4, 3, 1))

barplot(adf_pvals, names.arg = regions, las = 2, col = "lightblue",
        main = "ADF Test p-values", ylab = "p-value")
abline(h = 0.05, col = "red", lty = 2, lwd = 2)
text(x = length(regions)/2, y = 0.07, "α = 0.05", col = "red")

barplot(kpss_pvals, names.arg = regions, las = 2, col = "lightgreen",
        main = "KPSS Test p-values", ylab = "p-value")
abline(h = 0.05, col = "red", lty = 2, lwd = 2)
text(x = length(regions)/2, y = 0.07, "α = 0.05", col = "red")

dev.off()

# Save results
save(stationarity_results, summary_table, need_differencing, data_test,
     file = "output/05_stationarity_results.RData")

cat("\n💾 Results saved to: output/05_stationarity_results.RData\n")
cat("📊 Plot saved to: plots/05_stationarity_tests.png\n")
cat("✅ Stationarity testing completed!\n")
cat(paste(rep("=", 50), collapse = ""), "\n")