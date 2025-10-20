# ============================================================================
# 04_STACF_STPACF_Before.R
# Fungsi: Plot Space-Time ACF dan PACF sebelum differencing (traditional plots)
# Output: stacf_before.png, stpacf_before.png
# ============================================================================

cat("=== 04 SPACE-TIME ACF/PACF BEFORE DIFFERENCING ===\n")

# Load data from previous steps
load("output/02_spatial_weights.RData")
load("output/03_boxcox_data.RData")

# Parameters
max_lag <- 40
n_regions <- ncol(data_bc)

cat("--- CALCULATING SPACE-TIME ACF ---\n")

# Calculate Space-Time ACF using spatial weights
stacf_results <- list()
for(i in 1:n_regions) {
  region <- colnames(data_bc)[i]
  
  # Create spatially weighted series using cross-correlation weights
  weighted_series <- as.vector(data_bc %*% W_corr[i, ])
  
  # Calculate ACF for weighted series
  ts_weighted <- ts(weighted_series, frequency = 12)
  acf_result <- acf(ts_weighted, lag.max = max_lag, plot = FALSE)
  
  stacf_results[[region]] <- data.frame(
    Region = region,
    Lag = 0:max_lag,
    STACF = c(1, acf_result$acf[1:max_lag])
  )
}

cat("✓ STACF calculated for all regions\n")

cat("--- CALCULATING SPACE-TIME PACF ---\n")

# Calculate Space-Time PACF using spatial weights
stpacf_results <- list()
for(i in 1:n_regions) {
  region <- colnames(data_bc)[i]
  
  # Create spatially weighted series
  weighted_series <- as.vector(data_bc %*% W_corr[i, ])
  
  # Calculate PACF for weighted series
  ts_weighted <- ts(weighted_series, frequency = 12)
  pacf_result <- pacf(ts_weighted, lag.max = max_lag, plot = FALSE)
  
  stpacf_results[[region]] <- data.frame(
    Region = region,
    Lag = 1:max_lag,
    STPACF = pacf_result$acf[1:max_lag]
  )
}

cat("✓ STPACF calculated for all regions\n")

cat("--- CREATING VISUALIZATIONS ---\n")

# Combine STACF data
stacf_data <- bind_rows(stacf_results)

# STACF Plot (traditional ACF style)
p1 <- ggplot(stacf_data, aes(x = Lag, y = STACF)) +
  geom_hline(yintercept = 0, color = "black") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dashed", color = "blue", alpha = 0.7) +
  geom_segment(aes(xend = Lag, yend = 0), color = "red") +
  geom_point(color = "red", size = 1) +
  facet_wrap(~Region, ncol = 3) +
  labs(title = "Space-Time Autocorrelation Function (STACF) - Before Differencing",
       subtitle = "Spatially weighted using cross-correlation matrix",
       x = "Lag", y = "STACF") +
  theme_minimal() +
  ylim(-1, 1)

print(p1)
ggsave("plots/04_stacf_before.png", p1, width = 12, height = 8)

# Combine STPACF data
stpacf_data <- bind_rows(stpacf_results)

# STPACF Plot (traditional PACF style)
p2 <- ggplot(stpacf_data, aes(x = Lag, y = STPACF)) +
  geom_hline(yintercept = 0, color = "black") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dashed", color = "blue", alpha = 0.7) +
  geom_segment(aes(xend = Lag, yend = 0), color = "red") +
  geom_point(color = "red", size = 1) +
  facet_wrap(~Region, ncol = 3) +
  labs(title = "Space-Time Partial Autocorrelation Function (STPACF) - Before Differencing",
       subtitle = "Spatially weighted using cross-correlation matrix",
       x = "Lag", y = "STPACF") +
  theme_minimal() +
  ylim(-1, 1)

print(p2)
ggsave("plots/04_stpacf_before.png", p2, width = 12, height = 8)

# Combined plot
combined_data <- bind_rows(
  stacf_data %>% mutate(Type = "STACF", Value = STACF),
  stpacf_data %>% mutate(Type = "STPACF", Value = STPACF)
)

p3 <- ggplot(combined_data, aes(x = Lag, y = Value)) +
  geom_hline(yintercept = 0, color = "black") +
  geom_hline(yintercept = c(-0.2, 0.2), linetype = "dashed", color = "blue", alpha = 0.7) +
  geom_segment(aes(xend = Lag, yend = 0), color = "red") +
  geom_point(color = "red", size = 0.8) +
  facet_grid(Type ~ Region) +
  labs(title = "STACF and STPACF - Before Differencing",
       x = "Lag", y = "Correlation") +
  theme_minimal() +
  ylim(-1, 1)

print(p3)
ggsave("plots/04_combined_stacf_stpacf_before.png", p3, width = 15, height = 8)

cat("✓ Visualizations saved to plots/ folder\n")

# Summary statistics
cat("\n--- STACF/STPACF SUMMARY ---\n")
max_stacf <- max(abs(stacf_data$STACF[stacf_data$Lag > 0]), na.rm = TRUE)
max_stpacf <- max(abs(stpacf_data$STPACF), na.rm = TRUE)

cat("Max STACF value (excluding lag 0):", round(max_stacf, 4), "\n")
cat("Max STPACF value:", round(max_stpacf, 4), "\n")

# Significant lags
sig_stacf <- sum(abs(stacf_data$STACF[stacf_data$Lag > 0]) > 0.2, na.rm = TRUE)
sig_stpacf <- sum(abs(stpacf_data$STPACF) > 0.2, na.rm = TRUE)

cat("Significant STACF lags (|r| > 0.2):", sig_stacf, "\n")
cat("Significant STPACF lags (|r| > 0.2):", sig_stpacf, "\n")

# Save results
save(stacf_results, stpacf_results, stacf_data, stpacf_data, 
     file = "output/04_stacf_stpacf_before.RData")
cat("✓ STACF/STPACF results saved to output/04_stacf_stpacf_before.RData\n")

cat("\n=== 04 STACF/STPACF BEFORE DIFFERENCING COMPLETED ===\n")