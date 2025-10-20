# ============================================================================
# 03_BoxCox_Transform.R
# Fungsi: Transformasi Box-Cox untuk stabilisasi varians
# Output: boxcox_data.RData (data_bc, lambda_bc)
# ============================================================================

cat("=== 03 BOX-COX TRANSFORMATION ===\n")

# Load data from previous steps
load("output/01_rainfall_data.RData")
load("output/02_spatial_weights.RData")

# Initialize results
lambda_bc <- numeric(ncol(rainfall_matrix))
names(lambda_bc) <- colnames(rainfall_matrix)
data_bc <- matrix(0, nrow = nrow(rainfall_matrix), ncol = ncol(rainfall_matrix))
colnames(data_bc) <- colnames(rainfall_matrix)

cat("--- FINDING OPTIMAL LAMBDA VALUES ---\n")

# Find optimal lambda for each region
for(i in 1:ncol(rainfall_matrix)) {
  region <- colnames(rainfall_matrix)[i]
  data_col <- rainfall_matrix[, i]
  
  # Add small constant to avoid zero values
  data_col <- data_col + 0.001
  
  # Find optimal lambda using Box-Cox
  bc_result <- BoxCox.lambda(data_col, method = "loglik")
  lambda_bc[i] <- bc_result
  
  # Apply Box-Cox transformation
  if(abs(bc_result) < 1e-6) {
    # If lambda ≈ 0, use log transformation
    data_bc[, i] <- log(data_col)
  } else {
    # Standard Box-Cox transformation
    data_bc[, i] <- (data_col^bc_result - 1) / bc_result
  }
  
  cat("✓", region, "- Lambda:", round(bc_result, 4), "\n")
}

cat("\n--- TRANSFORMATION SUMMARY ---\n")
print(data.frame(
  Region = names(lambda_bc),
  Lambda = round(lambda_bc, 4),
  Transformation = ifelse(abs(lambda_bc) < 1e-6, "Log", "Box-Cox")
))

# Compare variance before and after transformation
cat("\n--- VARIANCE COMPARISON ---\n")
var_before <- apply(rainfall_matrix, 2, var)
var_after <- apply(data_bc, 2, var)

variance_comparison <- data.frame(
  Region = colnames(rainfall_matrix),
  Var_Before = round(var_before, 4),
  Var_After = round(var_after, 4),
  Reduction = round((var_before - var_after) / var_before * 100, 2)
)
print(variance_comparison)

# Visualization: Before vs After transformation
cat("\n--- CREATING VISUALIZATIONS ---\n")

# Prepare data for plotting
plot_data <- data.frame(
  Date = rep(dates, 2),
  Region = rep(rep(colnames(rainfall_matrix), each = nrow(rainfall_matrix)), 2),
  Value = c(as.vector(rainfall_matrix), as.vector(data_bc)),
  Type = rep(c("Original", "Box-Cox Transformed"), each = nrow(rainfall_matrix) * ncol(rainfall_matrix))
)

# Time series comparison plot
p1 <- ggplot(plot_data, aes(x = Date, y = Value, color = Region)) +
  geom_line() +
  facet_wrap(~Type, scales = "free_y", ncol = 1) +
  labs(title = "Rainfall Data: Original vs Box-Cox Transformed",
       x = "Date", y = "Value") +
  theme_minimal()

print(p1)
ggsave("plots/03_boxcox_comparison.png", p1, width = 12, height = 8)

# Distribution comparison (histogram)
p2 <- ggplot(plot_data, aes(x = Value, fill = Region)) +
  geom_histogram(alpha = 0.7, bins = 30) +
  facet_grid(Type ~ Region, scales = "free") +
  labs(title = "Distribution Comparison: Original vs Box-Cox Transformed",
       x = "Value", y = "Frequency") +
  theme_minimal() +
  theme(legend.position = "none")

print(p2)
ggsave("plots/03_distribution_comparison.png", p2, width = 15, height = 8)

cat("✓ Visualizations saved to plots/ folder\n")

# Save transformed data
save(data_bc, lambda_bc, variance_comparison, file = "output/03_boxcox_data.RData")
cat("✓ Transformed data saved to output/03_boxcox_data.RData\n")

cat("\n=== 03 BOX-COX TRANSFORMATION COMPLETED ===\n")