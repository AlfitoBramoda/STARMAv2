# ============================================================================
# 09_Data_Split.R
# Fungsi: Split data menjadi train (2015-2023) dan test (2024)
# Output: train_data.RData, test_data.RData
# ============================================================================

cat("=== 09 DATA SPLIT (TRAIN/TEST) ===\n")

# Load data from previous step
load("output/01_rainfall_data.RData")  # Need dates for splitting
load("output/08_centered_data.RData")

cat("--- ANALYZING DATE RANGE ---\n")

# Check date range
date_range <- range(dates)
cat("Full date range:", as.character(date_range[1]), "to", as.character(date_range[2]), "\n")

# Extract years from dates
years <- as.numeric(format(dates, "%Y"))
unique_years <- sort(unique(years))
cat("Available years:", paste(unique_years, collapse = ", "), "\n")

# Define split point
train_years <- 2015:2023
test_years <- 2024

cat("\n--- SPLITTING DATA ---\n")
cat("Train period: 2015-2023 (9 years)\n")
cat("Test period: 2024 (1 year)\n")

# Find indices for train and test
# Note: data_centered has fewer rows due to differencing (lost 13 observations)
# Need to align with the dates that correspond to differenced data

# Original dates: 120 observations (2015-01 to 2024-12)
# After seasonal differencing: lose first 12 observations (2015-01 to 2015-12)
# After first differencing: lose 1 more observation (2016-01)
# So differenced data starts from 2016-02 (index 14 in original dates)

start_index_in_original <- 14  # 2016-02
adjusted_dates <- dates[start_index_in_original:length(dates)]

cat("Adjusted date range after differencing:", 
    as.character(adjusted_dates[1]), "to", as.character(adjusted_dates[length(adjusted_dates)]), "\n")

# Split based on adjusted dates
adjusted_years <- as.numeric(format(adjusted_dates, "%Y"))

train_indices <- which(adjusted_years %in% train_years)
test_indices <- which(adjusted_years %in% test_years)

cat("Train observations:", length(train_indices), "\n")
cat("Test observations:", length(test_indices), "\n")

# Split the centered data
train_data <- data_centered[train_indices, ]
test_data <- data_centered[test_indices, ]

# Split corresponding dates
train_dates <- adjusted_dates[train_indices]
test_dates <- adjusted_dates[test_indices]

cat("\n--- TRAIN DATA SUMMARY ---\n")
cat("Dimensions:", nrow(train_data), "x", ncol(train_data), "\n")
cat("Date range:", as.character(train_dates[1]), "to", as.character(train_dates[length(train_dates)]), "\n")
cat("Years covered:", paste(sort(unique(as.numeric(format(train_dates, "%Y")))), collapse = ", "), "\n")

cat("\n--- TEST DATA SUMMARY ---\n")
cat("Dimensions:", nrow(test_data), "x", ncol(test_data), "\n")
cat("Date range:", as.character(test_dates[1]), "to", as.character(test_dates[length(test_dates)]), "\n")
cat("Years covered:", paste(sort(unique(as.numeric(format(test_dates, "%Y")))), collapse = ", "), "\n")

# Verify split
cat("\n--- SPLIT VERIFICATION ---\n")
total_obs <- nrow(train_data) + nrow(test_data)
original_obs <- nrow(data_centered)
cat("Original centered data:", original_obs, "observations\n")
cat("Train + Test:", total_obs, "observations\n")
cat("Split complete:", ifelse(total_obs == original_obs, "✅ YES", "❌ NO"), "\n")

# Basic statistics comparison
cat("\n--- STATISTICAL COMPARISON ---\n")
train_stats <- data.frame(
  Region = colnames(train_data),
  Train_Mean = round(colMeans(train_data), 6),
  Train_SD = round(apply(train_data, 2, sd), 4),
  Test_Mean = round(colMeans(test_data), 6),
  Test_SD = round(apply(test_data, 2, sd), 4)
)
print(train_stats)

# Visualization
cat("\n--- CREATING VISUALIZATIONS ---\n")

# Prepare data for plotting
plot_data <- data.frame()

for(i in 1:ncol(data_centered)) {
  region <- colnames(data_centered)[i]
  
  # Train data
  train_plot <- data.frame(
    Time = 1:nrow(train_data),
    Value = train_data[, i],
    Region = region,
    Type = "Train (2015-2023)",
    Date = train_dates
  )
  
  # Test data
  test_plot <- data.frame(
    Time = (nrow(train_data) + 1):(nrow(train_data) + nrow(test_data)),
    Value = test_data[, i],
    Region = region,
    Type = "Test (2024)",
    Date = test_dates
  )
  
  plot_data <- rbind(plot_data, train_plot, test_plot)
}

# Time series plot showing train/test split
p1 <- ggplot(plot_data, aes(x = Time, y = Value, color = Type)) +
  geom_line(alpha = 0.8) +
  geom_vline(xintercept = nrow(train_data) + 0.5, linetype = "dashed", color = "black", alpha = 0.7) +
  facet_wrap(~Region, scales = "free_y", ncol = 2) +
  labs(title = "Train/Test Data Split",
       subtitle = "Dashed line shows split point between 2023 and 2024",
       x = "Time Index", y = "Centered Value", color = "Dataset") +
  theme_minimal() +
  scale_color_manual(values = c("Train (2015-2023)" = "blue", "Test (2024)" = "red"))

print(p1)
ggsave("plots/09_train_test_split.png", p1, width = 12, height = 10)

# Distribution comparison
p2 <- ggplot(plot_data, aes(x = Value, fill = Type)) +
  geom_histogram(alpha = 0.6, bins = 20, position = "identity") +
  facet_wrap(~Region, scales = "free") +
  labs(title = "Distribution Comparison: Train vs Test",
       x = "Centered Value", y = "Frequency", fill = "Dataset") +
  theme_minimal() +
  scale_fill_manual(values = c("Train (2015-2023)" = "blue", "Test (2024)" = "red"))

print(p2)
ggsave("plots/09_distribution_comparison.png", p2, width = 15, height = 10)

cat("✓ Visualizations saved to plots/ folder\n")

cat("\n--- FINAL SUMMARY ---\n")
cat("Data successfully split for time series validation\n")
cat("Train data: 2015-2023 (", nrow(train_data), "observations)\n")
cat("Test data: 2024 (", nrow(test_data), "observations)\n")
cat("Ready for model training and evaluation\n")

# Save split data
save(train_data, train_dates, test_data, test_dates, train_stats, 
     file = "output/09_train_test_data.RData")
cat("✓ Split data saved to output/09_train_test_data.RData\n")

cat("\n=== 09 DATA SPLIT COMPLETED ===\n")