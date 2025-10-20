# ============================================================================
# 08_Data_Centering.R
# Fungsi: Centering data yang sudah di-difference untuk menghilangkan bias spasial
# Output: centered_data.RData
# ============================================================================

cat("=== 08 DATA CENTERING ===\n")

# Load data from previous step
load("output/06_differenced_data.RData")

cat("--- CALCULATING MEANS ---\n")

# Calculate mean for each region from differenced data
region_means <- colMeans(data_diff, na.rm = TRUE)
cat("Regional means before centering:\n")
print(round(region_means, 6))

# Initialize centered data matrix
data_centered <- matrix(NA, nrow = nrow(data_diff), ncol = ncol(data_diff))
colnames(data_centered) <- colnames(data_diff)

cat("\n--- APPLYING CENTERING ---\n")

# Center each region by subtracting its mean
for(i in 1:ncol(data_diff)) {
  region <- colnames(data_diff)[i]
  data_centered[, i] <- data_diff[, i] - region_means[i]
  cat("✓", region, "- Mean removed:", round(region_means[i], 6), "\n")
}

# Verify centering
centered_means <- colMeans(data_centered, na.rm = TRUE)
cat("\n--- VERIFICATION ---\n")
cat("Regional means after centering:\n")
print(round(centered_means, 10))

# Check if means are effectively zero (within numerical precision)
all_centered <- all(abs(centered_means) < 1e-10)
cat("All regions centered (mean ≈ 0):", ifelse(all_centered, "✅ YES", "❌ NO"), "\n")

# Summary statistics
cat("\n--- CENTERING SUMMARY ---\n")
centering_summary <- data.frame(
  Region = colnames(data_diff),
  Original_Mean = round(region_means, 6),
  Centered_Mean = round(centered_means, 10),
  Mean_Removed = round(region_means, 6)
)
print(centering_summary)

# Compare variance before and after centering
var_before <- apply(data_diff, 2, var, na.rm = TRUE)
var_after <- apply(data_centered, 2, var, na.rm = TRUE)

cat("\n--- VARIANCE COMPARISON ---\n")
variance_comparison <- data.frame(
  Region = colnames(data_diff),
  Var_Before = round(var_before, 6),
  Var_After = round(var_after, 6),
  Var_Change = round(var_after - var_before, 10)
)
print(variance_comparison)

cat("Variance preserved (should be ~0 change):", 
    ifelse(all(abs(variance_comparison$Var_Change) < 1e-10), "✅ YES", "❌ NO"), "\n")

# Visualization
cat("\n--- CREATING VISUALIZATIONS ---\n")

# Prepare data for plotting
plot_data <- data.frame()

for(i in 1:ncol(data_diff)) {
  region <- colnames(data_diff)[i]
  
  # Before centering
  before_data <- data.frame(
    Time = 1:nrow(data_diff),
    Value = data_diff[, i],
    Region = region,
    Type = "Before Centering"
  )
  
  # After centering
  after_data <- data.frame(
    Time = 1:nrow(data_centered),
    Value = data_centered[, i],
    Region = region,
    Type = "After Centering"
  )
  
  plot_data <- rbind(plot_data, before_data, after_data)
}

# Time series comparison
p1 <- ggplot(plot_data, aes(x = Time, y = Value, color = Type)) +
  geom_line(alpha = 0.7) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black", alpha = 0.5) +
  facet_wrap(~Region, scales = "free_y", ncol = 2) +
  labs(title = "Data Centering: Before vs After",
       subtitle = "Dashed line shows zero mean reference",
       x = "Time Index", y = "Value", color = "Data Type") +
  theme_minimal() +
  scale_color_manual(values = c("Before Centering" = "blue", "After Centering" = "red"))

print(p1)
ggsave("plots/08_centering_comparison.png", p1, width = 12, height = 10)

# Distribution comparison
p2 <- ggplot(plot_data, aes(x = Value, fill = Type)) +
  geom_histogram(alpha = 0.6, bins = 30, position = "identity") +
  geom_vline(xintercept = 0, linetype = "dashed", color = "black", alpha = 0.7) +
  facet_wrap(~Region, scales = "free") +
  labs(title = "Distribution: Before vs After Centering",
       subtitle = "Dashed line shows zero mean reference",
       x = "Value", y = "Frequency", fill = "Data Type") +
  theme_minimal() +
  scale_fill_manual(values = c("Before Centering" = "blue", "After Centering" = "red"))

print(p2)
ggsave("plots/08_distribution_centering.png", p2, width = 15, height = 10)

# Mean comparison plot
mean_data <- data.frame(
  Region = names(region_means),
  Before = region_means,
  After = centered_means
) %>%
  pivot_longer(cols = c(Before, After), names_to = "Stage", values_to = "Mean")

p3 <- ggplot(mean_data, aes(x = Region, y = Mean, fill = Stage)) +
  geom_col(position = "dodge", alpha = 0.8) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "black") +
  labs(title = "Regional Means: Before vs After Centering",
       x = "Region", y = "Mean Value", fill = "Stage") +
  theme_minimal() +
  scale_fill_manual(values = c("Before" = "blue", "After" = "red"))

print(p3)
ggsave("plots/08_means_comparison.png", p3, width = 10, height = 6)

cat("✓ Visualizations saved to plots/ folder\n")

cat("\n--- FINAL DATA SUMMARY ---\n")
cat("Data dimensions:", nrow(data_centered), "x", ncol(data_centered), "\n")
cat("All regions centered:", ifelse(all_centered, "✅ YES", "❌ NO"), "\n")
cat("Variance preserved:", ifelse(all(abs(variance_comparison$Var_Change) < 1e-10), "✅ YES", "❌ NO"), "\n")
cat("Data ready for STARIMA modeling\n")

# Save results
save(data_centered, region_means, centering_summary, variance_comparison, 
     file = "output/08_centered_data.RData")
cat("✓ Centered data saved to output/08_centered_data.RData\n")

cat("\n=== 08 DATA CENTERING COMPLETED ===\n")