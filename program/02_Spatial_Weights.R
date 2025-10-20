# ============================================================================
# 02_Spatial_Weights.R
# Fungsi: Membuat matriks bobot spasial (Uniform, Inverse-Distance, Cross-Correlation)
# Output: spatial_weights.RData (W_uniform, W_inv, W_corr)
# ============================================================================

cat("=== 02 SPATIAL WEIGHTS MATRIX ===\n")

# Load data from previous step
load("output/01_rainfall_data.RData")

n_regions <- nrow(coordinates)
region_names <- coordinates$Region

cat("--- CALCULATING DISTANCE MATRIX ---\n")

# Calculate distance matrix using Haversine formula
distance_matrix <- matrix(0, n_regions, n_regions)
rownames(distance_matrix) <- colnames(distance_matrix) <- region_names

for(i in 1:n_regions) {
  for(j in 1:n_regions) {
    if(i != j) {
      # Haversine distance in km
      distance_matrix[i, j] <- distHaversine(
        c(coordinates$Longitude[i], coordinates$Latitude[i]),
        c(coordinates$Longitude[j], coordinates$Latitude[j])
      ) / 1000  # Convert to km
    }
  }
}

cat("✓ Distance matrix calculated\n")
print(round(distance_matrix, 2))

cat("\n--- CREATING SPATIAL WEIGHT MATRICES ---\n")

# 1. Uniform Weights Matrix
W_uniform <- matrix(1, n_regions, n_regions)
diag(W_uniform) <- 0  # No self-weight
W_uniform <- W_uniform / rowSums(W_uniform)  # Row-standardize
rownames(W_uniform) <- colnames(W_uniform) <- region_names

cat("✓ Uniform weights matrix created\n")

# 2. Inverse Distance Weights Matrix
W_inv <- matrix(0, n_regions, n_regions)
rownames(W_inv) <- colnames(W_inv) <- region_names

for(i in 1:n_regions) {
  for(j in 1:n_regions) {
    if(i != j) {
      W_inv[i, j] <- 1 / distance_matrix[i, j]^2  # Inverse squared distance
    }
  }
}
# Row-standardize
W_inv <- W_inv / rowSums(W_inv)

cat("✓ Inverse distance weights matrix created\n")

# 3. Cross-Correlation Weights Matrix
correlation_matrix <- cor(rainfall_matrix)
W_corr <- abs(correlation_matrix)  # Use absolute correlation
diag(W_corr) <- 0  # No self-weight
W_corr <- W_corr / rowSums(W_corr)  # Row-standardize

cat("✓ Cross-correlation weights matrix created\n")

cat("\n--- WEIGHT MATRICES SUMMARY ---\n")
cat("Uniform Weights (W_uniform):\n")
print(round(W_uniform, 3))

cat("\nInverse Distance Weights (W_inv):\n")
print(round(W_inv, 3))

cat("\nCross-Correlation Weights (W_corr):\n")
print(round(W_corr, 3))

# Visualization
cat("\n--- CREATING VISUALIZATIONS ---\n")

# Prepare data for heatmaps
weight_data <- data.frame(
  From = rep(region_names, each = n_regions),
  To = rep(region_names, n_regions),
  Uniform = as.vector(W_uniform),
  Inverse_Distance = as.vector(W_inv),
  Cross_Correlation = as.vector(W_corr)
)

# Reshape for plotting
weight_long <- weight_data %>%
  pivot_longer(cols = c(Uniform, Inverse_Distance, Cross_Correlation),
               names_to = "Weight_Type", values_to = "Weight")

# Heatmap of all weight matrices
p1 <- ggplot(weight_long, aes(x = To, y = From, fill = Weight)) +
  geom_tile() +
  facet_wrap(~Weight_Type, ncol = 3) +
  scale_fill_gradient(low = "white", high = "red", limits = c(0, 1)) +
  labs(title = "Spatial Weight Matrices Comparison",
       x = "To Region", y = "From Region", fill = "Weight") +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

print(p1)
ggsave("plots/02_spatial_weights.png", p1, width = 15, height = 5)

# Distance vs Weight relationship
dist_weight_data <- data.frame(
  Distance = as.vector(distance_matrix[upper.tri(distance_matrix)]),
  Inverse_Weight = as.vector(W_inv[upper.tri(W_inv)]),
  Correlation_Weight = as.vector(W_corr[upper.tri(W_corr)])
)

p2 <- ggplot(dist_weight_data, aes(x = Distance)) +
  geom_point(aes(y = Inverse_Weight, color = "Inverse Distance"), alpha = 0.7) +
  geom_point(aes(y = Correlation_Weight, color = "Cross Correlation"), alpha = 0.7) +
  labs(title = "Distance vs Spatial Weights",
       x = "Distance (km)", y = "Weight", color = "Weight Type") +
  theme_minimal()

print(p2)
ggsave("plots/02_distance_vs_weights.png", p2, width = 10, height = 6)

cat("✓ Visualizations saved to plots/ folder\n")

# Weight matrix properties
cat("\n--- WEIGHT MATRIX PROPERTIES ---\n")
cat("Row sums (should be 1 for standardized matrices):\n")
cat("W_uniform:", round(rowSums(W_uniform), 3), "\n")
cat("W_inv:", round(rowSums(W_inv), 3), "\n")
cat("W_corr:", round(rowSums(W_corr), 3), "\n")

# Save results
save(W_uniform, W_inv, W_corr, distance_matrix, correlation_matrix,
     file = "output/02_spatial_weights.RData")
cat("✓ Spatial weights saved to output/02_spatial_weights.RData\n")

cat("\n=== 02 SPATIAL WEIGHTS COMPLETED ===\n")