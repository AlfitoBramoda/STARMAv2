# ============================================================================
# 03_Stationarity_Test.R
# Fungsi: Uji stasioneritas menggunakan ADF dan KPSS test
# Output: stationarity_results.RData
# ============================================================================

cat("=== 05 STATIONARITY TESTS ===\n")

# Load data from previous step
load("output/03_boxcox_data.RData")

# Initialize results storage
adf_results <- data.frame(
  Region = colnames(data_bc),
  ADF_Statistic = numeric(ncol(data_bc)),
  ADF_PValue = numeric(ncol(data_bc)),
  ADF_Stationary = logical(ncol(data_bc))
)

kpss_results <- data.frame(
  Region = colnames(data_bc),
  KPSS_Statistic = numeric(ncol(data_bc)),
  KPSS_PValue = numeric(ncol(data_bc)),
  KPSS_Stationary = logical(ncol(data_bc))
)

cat("--- AUGMENTED DICKEY-FULLER (ADF) TEST ---\n")
cat("H0: Non-stationary (unit root exists)\n")
cat("H1: Stationary (no unit root)\n\n")

# ADF Test for each region
for(i in 1:ncol(data_bc)) {
  region <- colnames(data_bc)[i]
  ts_data <- ts(data_bc[, i], frequency = 12)
  
  # ADF test
  adf_test <- adf.test(ts_data, alternative = "stationary")
  
  adf_results$ADF_Statistic[i] <- adf_test$statistic
  adf_results$ADF_PValue[i] <- adf_test$p.value
  adf_results$ADF_Stationary[i] <- adf_test$p.value < 0.05
  
  cat("✓", region, "- ADF p-value:", round(adf_test$p.value, 4), 
      ifelse(adf_test$p.value < 0.05, "(Stationary)", "(Non-stationary)"), "\n")
}

cat("\n--- KWIATKOWSKI-PHILLIPS-SCHMIDT-SHIN (KPSS) TEST ---\n")
cat("H0: Stationary (trend stationary)\n")
cat("H1: Non-stationary (unit root exists)\n\n")

# KPSS Test for each region
for(i in 1:ncol(data_bc)) {
  region <- colnames(data_bc)[i]
  ts_data <- ts(data_bc[, i], frequency = 12)
  
  # KPSS test
  kpss_test <- kpss.test(ts_data, null = "Trend")
  
  kpss_results$KPSS_Statistic[i] <- kpss_test$statistic
  kpss_results$KPSS_PValue[i] <- kpss_test$p.value
  kpss_results$KPSS_Stationary[i] <- kpss_test$p.value > 0.05
  
  cat("✓", region, "- KPSS p-value:", round(kpss_test$p.value, 4), 
      ifelse(kpss_test$p.value > 0.05, "(Stationary)", "(Non-stationary)"), "\n")
}

# Combined results
stationarity_summary <- data.frame(
  Region = colnames(data_bc),
  ADF_Stationary = adf_results$ADF_Stationary,
  KPSS_Stationary = kpss_results$KPSS_Stationary,
  Both_Agree = adf_results$ADF_Stationary & kpss_results$KPSS_Stationary,
  Final_Status = ifelse(adf_results$ADF_Stationary & kpss_results$KPSS_Stationary, 
                       "STATIONARY", "NON-STATIONARY")
)

cat("\n--- STATIONARITY SUMMARY ---\n")
print(stationarity_summary)

# Count stationary regions
stationary_count <- sum(stationarity_summary$Both_Agree)
cat("\nStationary regions:", stationary_count, "out of", nrow(stationarity_summary), "\n")

# Recommendation
if(stationary_count == nrow(stationarity_summary)) {
  cat("✅ All regions are stationary. Ready for modeling.\n")
} else {
  non_stationary <- stationarity_summary$Region[!stationarity_summary$Both_Agree]
  cat("⚠️  Non-stationary regions:", paste(non_stationary, collapse = ", "), "\n")
  cat("📋 Recommendation: Apply differencing in step 05.\n")
}

# Visualization: Test statistics
cat("\n--- CREATING VISUALIZATIONS ---\n")

# Prepare data for plotting
test_data <- data.frame(
  Region = rep(colnames(data_bc), 2),
  Test = rep(c("ADF", "KPSS"), each = ncol(data_bc)),
  Statistic = c(adf_results$ADF_Statistic, kpss_results$KPSS_Statistic),
  PValue = c(adf_results$ADF_PValue, kpss_results$KPSS_PValue),
  Stationary = c(adf_results$ADF_Stationary, kpss_results$KPSS_Stationary)
)

# P-value comparison plot
p1 <- ggplot(test_data, aes(x = Region, y = PValue, fill = Stationary)) +
  geom_col() +
  geom_hline(yintercept = 0.05, linetype = "dashed", color = "red") +
  facet_wrap(~Test, scales = "free_y") +
  labs(title = "Stationarity Test Results",
       subtitle = "Red line = 0.05 significance level",
       x = "Region", y = "P-Value") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  scale_fill_manual(values = c("TRUE" = "green", "FALSE" = "red"))

print(p1)
ggsave("plots/05_stationarity_tests.png", p1, width = 12, height = 6)

# Time series plot with stationarity status
ts_plot_data <- data.frame(
  Date = rep(1:nrow(data_bc), ncol(data_bc)),
  Region = rep(colnames(data_bc), each = nrow(data_bc)),
  Value = as.vector(data_bc),
  Status = rep(stationarity_summary$Final_Status, each = nrow(data_bc))
)

p2 <- ggplot(ts_plot_data, aes(x = Date, y = Value, color = Status)) +
  geom_line() +
  facet_wrap(~Region, scales = "free_y") +
  labs(title = "Box-Cox Transformed Data with Stationarity Status",
       x = "Time Index", y = "Transformed Value") +
  theme_minimal() +
  scale_color_manual(values = c("STATIONARY" = "blue", "NON-STATIONARY" = "red"))

print(p2)
ggsave("plots/05_timeseries_stationarity.png", p2, width = 15, height = 10)

cat("✓ Visualizations saved to plots/ folder\n")

# Save results
save(adf_results, kpss_results, stationarity_summary, 
     file = "output/05_stationarity_results.RData")
cat("✓ Stationarity results saved to output/05_stationarity_results.RData\n")

cat("\n=== 05 STATIONARITY TESTS COMPLETED ===\n")