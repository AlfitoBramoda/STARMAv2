# ============================================================================
# 07_STACF_STPACF_After.R
# Fungsi: Plot Space-Time ACF dan PACF setelah differencing (traditional plots)
# Output: stacf_after.png, stpacf_after.png
# ============================================================================

cat("=== 07 SPACE-TIME ACF/PACF AFTER DIFFERENCING ===\n")

# Load data from previous steps
load("output/02_spatial_weights.RData")
load("output/06_differenced_data.RData")

# Parameters
max_lag <- 40
n_regions <- ncol(data_diff)

cat("--- CALCULATING SPACE-TIME ACF (AFTER DIFFERENCING) ---\n")

# Calculate Space-Time ACF using spatial weights on differenced data
stacf_results_after <- list()
for(i in 1:n_regions) {
  region <- colnames(data_diff)[i]
  
  # Create spatially weighted series using cross-correlation weights
  weighted_series <- as.vector(data_diff %*% W_corr[i, ])
  
  # Calculate ACF for weighted series
  ts_weighted <- ts(weighted_series, frequency = 12)
  acf_result <- acf(ts_weighted, lag.max = max_lag, plot = FALSE)
  
  stacf_results_after[[region]] <- data.frame(
    Region = region,
    Lag = 0:max_lag,
    STACF = c(1, acf_result$acf[1:max_lag])
  )
}

cat("✓ STACF calculated for all regions (after differencing)\n")

cat("--- CALCULATING SPACE-TIME PACF (AFTER DIFFERENCING) ---\n")

# Calculate Space-Time PACF using spatial weights on differenced data
stpacf_results_after <- list()
for(i in 1:n_regions) {
  region <- colnames(data_diff)[i]
  
  # Create spatially weighted series
  weighted_series <- as.vector(data_diff %*% W_corr[i, ])
  
  # Calculate PACF for weighted series
  ts_weighted <- ts(weighted_series, frequency = 12)
  pacf_result <- pacf(ts_weighted, lag.max = max_lag, plot = FALSE)
  
  stpacf_results_after[[region]] <- data.frame(
    Region = region,
    Lag = 1:max_lag,
    STPACF = pacf_result$acf[1:max_lag]
  )
}

cat("✓ STPACF calculated for all regions (after differencing)\n")

cat("--- CREATING VISUALIZATIONS ---\n")

# Combine STACF data
stacf_data_after <- bind_rows(stacf_results_after)

# STACF Plot (traditional ACF style)
p1 <- ggplot(stacf_data_after, aes(x = Lag, y = STACF)) +
  geom_hline(yintercept = 0, color = "black") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dashed", color = "blue", alpha = 0.7) +
  geom_segment(aes(xend = Lag, yend = 0), color = "red") +
  geom_point(color = "red", size = 1) +
  facet_wrap(~Region, ncol = 3) +
  labs(title = "Space-Time Autocorrelation Function (STACF) - After Differencing",
       subtitle = "Spatially weighted using cross-correlation matrix",
       x = "Lag", y = "STACF") +
  theme_minimal() +
  ylim(-1, 1)

print(p1)
ggsave("plots/07_stacf_after.png", p1, width = 12, height = 8)

# Combine STPACF data
stpacf_data_after <- bind_rows(stpacf_results_after)

# STPACF Plot (traditional PACF style)
p2 <- ggplot(stpacf_data_after, aes(x = Lag, y = STPACF)) +
  geom_hline(yintercept = 0, color = "black") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dashed", color = "blue", alpha = 0.7) +
  geom_segment(aes(xend = Lag, yend = 0), color = "red") +
  geom_point(color = "red", size = 1) +
  facet_wrap(~Region, ncol = 3) +
  labs(title = "Space-Time Partial Autocorrelation Function (STPACF) - After Differencing",
       subtitle = "Spatially weighted using cross-correlation matrix",
       x = "Lag", y = "STPACF") +
  theme_minimal() +
  ylim(-1, 1)

print(p2)
ggsave("plots/07_stpacf_after.png", p2, width = 12, height = 8)

# Combined plot
combined_data_after <- bind_rows(
  stacf_data_after %>% mutate(Type = "STACF", Value = STACF),
  stpacf_data_after %>% mutate(Type = "STPACF", Value = STPACF)
)

p3 <- ggplot(combined_data_after, aes(x = Lag, y = Value)) +
  geom_hline(yintercept = 0, color = "black") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dashed", color = "blue", alpha = 0.7) +
  geom_segment(aes(xend = Lag, yend = 0), color = "red") +
  geom_point(color = "red", size = 0.8) +
  facet_grid(Type ~ Region) +
  labs(title = "STACF and STPACF - After Differencing",
       x = "Lag", y = "Correlation") +
  theme_minimal() +
  ylim(-1, 1)

print(p3)
ggsave("plots/07_combined_stacf_stpacf_after.png", p3, width = 15, height = 8)

# Comparison: Before vs After Differencing
cat("--- COMPARISON WITH BEFORE DIFFERENCING ---\n")

# Load before differencing results for comparison
load("output/04_stacf_stpacf_before.RData")

# Create comparison plot
comparison_data <- bind_rows(
  stacf_data %>% mutate(Stage = "Before Differencing", Type = "STACF", Value = STACF),
  stacf_data_after %>% mutate(Stage = "After Differencing", Type = "STACF", Value = STACF),
  stpacf_data %>% mutate(Stage = "Before Differencing", Type = "STPACF", Value = STPACF),
  stpacf_data_after %>% mutate(Stage = "After Differencing", Type = "STPACF", Value = STPACF)
)

p4 <- ggplot(comparison_data, aes(x = Lag, y = Value, color = Stage)) +
  geom_hline(yintercept = 0, color = "black") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dashed", color = "gray", alpha = 0.5) +
  geom_line(alpha = 0.7) +
  geom_point(size = 0.5, alpha = 0.7) +
  facet_grid(Type ~ Region) +
  labs(title = "STACF/STPACF Comparison: Before vs After Differencing",
       x = "Lag", y = "Correlation", color = "Stage") +
  theme_minimal() +
  scale_color_manual(values = c("Before Differencing" = "blue", "After Differencing" = "red")) +
  ylim(-1, 1)

print(p4)
ggsave("plots/07_comparison_before_after.png", p4, width = 15, height = 8)

cat("✓ Visualizations saved to plots/ folder\n")

# Summary statistics
cat("\n--- STACF/STPACF SUMMARY (AFTER DIFFERENCING) ---\n")
max_stacf_after <- max(abs(stacf_data_after$STACF[stacf_data_after$Lag > 0]), na.rm = TRUE)
max_stpacf_after <- max(abs(stpacf_data_after$STPACF), na.rm = TRUE)

cat("Max STACF value (excluding lag 0):", round(max_stacf_after, 4), "\n")
cat("Max STPACF value:", round(max_stpacf_after, 4), "\n")

# Significant lags
sig_stacf_after <- sum(abs(stacf_data_after$STACF[stacf_data_after$Lag > 0]) > 0.2, na.rm = TRUE)
sig_stpacf_after <- sum(abs(stpacf_data_after$STPACF) > 0.2, na.rm = TRUE)

cat("Significant STACF lags (|r| > 0.2):", sig_stacf_after, "\n")
cat("Significant STPACF lags (|r| > 0.2):", sig_stpacf_after, "\n")

# Model order suggestion
cat("\n--- MODEL ORDER SUGGESTION ---\n")
# Find cut-off points for STACF and STPACF
stacf_cutoff <- which(abs(stacf_data_after$STACF[stacf_data_after$Lag > 0]) < 0.2)[1]
stpacf_cutoff <- which(abs(stpacf_data_after$STPACF) < 0.2)[1]

cat("Suggested STARIMA order based on cut-off patterns:\n")
cat("- MA order (q) from STACF cut-off: ~", ifelse(is.na(stacf_cutoff), "3+", stacf_cutoff), "\n")
cat("- AR order (p) from STPACF cut-off: ~", ifelse(is.na(stpacf_cutoff), "3+", stpacf_cutoff), "\n")
cat("- Differencing order (d): 1 (applied)\n")

# Save results
save(stacf_results_after, stpacf_results_after, stacf_data_after, stpacf_data_after, 
     file = "output/07_stacf_stpacf_after.RData")
cat("✓ STACF/STPACF results saved to output/07_stacf_stpacf_after.RData\n")

cat("\n=== 07 STACF/STPACF AFTER DIFFERENCING COMPLETED ===\n")