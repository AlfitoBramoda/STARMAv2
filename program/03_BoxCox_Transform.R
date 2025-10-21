# ============================================================================
# 03_BoxCox_Transform.R - Box-Cox Transformation (Optional)
# ============================================================================

cat("📦 Box-Cox Transformation Started...\n")

library(forecast)
library(car)

# Load data
load("output/01_rainfall_data.RData")

regions <- colnames(rainfall_matrix)
n_regions <- length(regions)

# Check if transformation is needed
cat("📊 Checking need for Box-Cox transformation...\n")

# Add small constant to handle zeros
rainfall_positive <- rainfall_matrix + 0.001

# Calculate lambda for each region
lambda_values <- numeric(n_regions)
names(lambda_values) <- regions

for (i in 1:n_regions) {
  lambda_values[i] <- BoxCox.lambda(rainfall_positive[, i])
}

cat("Optimal lambda values:\n")
print(round(lambda_values, 4))

# Use overall lambda (median of individual lambdas)
lambda_overall <- median(lambda_values)
cat("Overall lambda:", round(lambda_overall, 4), "\n")

# Apply Box-Cox transformation
if (abs(lambda_overall - 1) > 0.1) {
  cat("Applying Box-Cox transformation...\n")
  
  boxcox_matrix <- apply(rainfall_positive, 2, BoxCox, lambda = lambda_overall)
  colnames(boxcox_matrix) <- regions
  
  # Compare before and after
  cat("\nTransformation Results:\n")
  cat("Original range:", range(rainfall_matrix), "\n")
  cat("Transformed range:", range(boxcox_matrix), "\n")
  
  # Variance comparison
  original_vars <- apply(rainfall_matrix, 2, var, na.rm = TRUE)
  transformed_vars <- apply(boxcox_matrix, 2, var, na.rm = TRUE)
  
  variance_comparison <- data.frame(
    Region = regions,
    Original_Var = round(original_vars, 4),
    Transformed_Var = round(transformed_vars, 4),
    Ratio = round(transformed_vars / original_vars, 4)
  )
  
  print(variance_comparison)
  
  # Use transformed data
  final_data <- boxcox_matrix
  transformation_applied <- TRUE
  
} else {
  cat("Box-Cox transformation not needed (lambda ≈ 1)\n")
  final_data <- rainfall_matrix
  transformation_applied <- FALSE
  boxcox_matrix <- NULL
  variance_comparison <- NULL
}

# Save results
save(final_data, rainfall_matrix, boxcox_matrix, lambda_overall, lambda_values,
     transformation_applied, variance_comparison, coordinates, dates,
     file = "output/03_boxcox_data.RData")

cat("\n💾 Results saved to: output/03_boxcox_data.RData\n")
cat("✅ Box-Cox transformation completed!\n")
cat(paste(rep("=", 50), collapse = ""), "\n")