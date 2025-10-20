# ============================================================================
# 06_Differencing.R
# Fungsi: Seasonal + First differencing (d=1, D=1) untuk data curah hujan
# Output: differenced_data.RData
# ============================================================================

cat("=== 06 DIFFERENCING (Seasonal + First) ===\n")

# Load data from previous steps
load("output/03_boxcox_data.RData")
load("output/05_stationarity_results.RData")

cat("--- APPLYING SEASONAL + FIRST DIFFERENCING ---\n")
cat("Step 1: Seasonal differencing (lag 12)\n")
cat("Step 2: First differencing (d=1)\n")

# Step 1: Seasonal differencing (lag 12)
data_seasonal <- matrix(NA, nrow = nrow(data_bc) - 12, ncol = ncol(data_bc))
colnames(data_seasonal) <- colnames(data_bc)

for(i in 1:ncol(data_bc)) {
  region <- colnames(data_bc)[i]
  data_seasonal[, i] <- diff(data_bc[, i], lag = 12)
  cat("✓", region, "- Seasonal differencing applied (lag 12)\n")
}

# Step 2: First differencing on seasonally differenced data
data_diff <- matrix(NA, nrow = nrow(data_seasonal) - 1, ncol = ncol(data_seasonal))
colnames(data_diff) <- colnames(data_seasonal)

for(i in 1:ncol(data_seasonal)) {
  region <- colnames(data_seasonal)[i]
  data_diff[, i] <- diff(data_seasonal[, i], differences = 1)
  cat("✓", region, "- First differencing applied\n")
}

# Store differencing information
diff_info <- data.frame(
  Region = colnames(data_bc),
  Original_Stationary = stationarity_summary$Both_Agree,
  Seasonal_Diff = TRUE,
  First_Diff = TRUE,
  Final_Stationary = FALSE
)

cat("\n--- TESTING STATIONARITY AFTER DIFFERENCING ---\n")

# Test stationarity after combined differencing
for(i in 1:ncol(data_diff)) {
  region <- colnames(data_diff)[i]
  ts_data <- data_diff[, i]
  
  # ADF test
  adf_test <- adf.test(ts_data, alternative = "stationary")
  # KPSS test
  kpss_test <- kpss.test(ts_data, null = "Trend")
  
  # Check if both tests agree on stationarity
  adf_stationary <- adf_test$p.value < 0.05
  kpss_stationary <- kpss_test$p.value > 0.05
  both_agree <- adf_stationary & kpss_stationary
  
  diff_info$Final_Stationary[i] <- both_agree
  
  cat("✓", region, "- ADF p-value:", round(adf_test$p.value, 4),
      "KPSS p-value:", round(kpss_test$p.value, 4),
      ifelse(both_agree, "(Stationary)", "(Non-stationary)"), "\n")
}

cat("\n--- DIFFERENCING SUMMARY ---\n")
print(diff_info)

# Count final stationary regions
final_stationary_count <- sum(diff_info$Final_Stationary)
cat("\nFinal stationary regions:", final_stationary_count, "out of", nrow(diff_info), "\n")

if(final_stationary_count == nrow(diff_info)) {
  cat("✅ All regions are now stationary after seasonal + first differencing\n")
} else {
  non_stat_regions <- diff_info$Region[!diff_info$Final_Stationary]
  cat("⚠️ Still non-stationary:", paste(non_stat_regions, collapse = ", "), "\n")
}

# Visualization
cat("\n--- CREATING VISUALIZATIONS ---\n")

# Prepare data for plotting (original → seasonal → final)
plot_data <- data.frame()

for(i in 1:ncol(data_bc)) {
  region <- colnames(data_bc)[i]
  
  # Original data
  original_data <- data.frame(
    Time = 1:nrow(data_bc),
    Value = data_bc[, i],
    Region = region,
    Type = "Original (Box-Cox)"
  )
  
  # Seasonal differenced data
  seasonal_data <- data.frame(
    Time = 13:nrow(data_bc),  # Start from 13 (lost 12 obs)
    Value = data_seasonal[, i],
    Region = region,
    Type = "Seasonal Differenced"
  )
  
  # Final differenced data
  final_data <- data.frame(
    Time = 14:nrow(data_bc),  # Start from 14 (lost 13 obs total)
    Value = data_diff[, i],
    Region = region,
    Type = "Seasonal + First Differenced"
  )
  
  plot_data <- rbind(plot_data, original_data, seasonal_data, final_data)
}

# Time series comparison plot
p1 <- ggplot(plot_data, aes(x = Time, y = Value, color = Type)) +
  geom_line(alpha = 0.7) +
  facet_wrap(~Region, scales = "free_y", ncol = 2) +
  labs(title = "Differencing Process: Original → Seasonal → Final",
       x = "Time Index", y = "Value", color = "Data Type") +
  theme_minimal() +
  scale_color_manual(values = c(
    "Original (Box-Cox)" = "blue", 
    "Seasonal Differenced" = "orange",
    "Seasonal + First Differenced" = "red"
  ))

print(p1)
ggsave("plots/06_differencing_process.png", p1, width = 14, height = 10)

# Distribution comparison
p2 <- ggplot(plot_data, aes(x = Value, fill = Type)) +
  geom_histogram(alpha = 0.6, bins = 25, position = "identity") +
  facet_wrap(~Region, scales = "free") +
  labs(title = "Distribution Evolution Through Differencing",
       x = "Value", y = "Frequency", fill = "Data Type") +
  theme_minimal() +
  scale_fill_manual(values = c(
    "Original (Box-Cox)" = "blue", 
    "Seasonal Differenced" = "orange",
    "Seasonal + First Differenced" = "red"
  ))

print(p2)
ggsave("plots/06_distribution_evolution.png", p2, width = 15, height = 10)

cat("✓ Visualizations saved to plots/ folder\n")

cat("\n--- FINAL DATA SUMMARY ---\n")
cat("Original data dimensions:", nrow(data_bc), "x", ncol(data_bc), "\n")
cat("After seasonal differencing:", nrow(data_seasonal), "x", ncol(data_seasonal), "\n")
cat("Final differenced data:", nrow(data_diff), "x", ncol(data_diff), "\n")
cat("Total observations lost:", nrow(data_bc) - nrow(data_diff), "(12 + 1 = 13)\n")
cat("Differencing order: d=1, D=1 (seasonal lag 12)\n")
cat("Model notation: STARIMA(p,1,q)(P,1,Q)₁₂\n")

# Save results
save(data_diff, data_seasonal, diff_info, file = "output/06_differenced_data.RData")
cat("✓ Differenced data saved to output/06_differenced_data.RData\n")

cat("\n=== 06 DIFFERENCING COMPLETED ===\n")