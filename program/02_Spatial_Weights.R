# ============================================================================
# 02_Spatial_Weights.R - Create and Normalize Spatial Weight Matrices
# ============================================================================

cat("🗺️ Creating and Normalizing Spatial Weight Matrices...\n")

library(spdep)

# ============================================================================
# 1️⃣ Load Data
# ============================================================================
load("output/01_rainfall_data.RData")

regions <- colnames(rainfall_matrix)
n_regions <- length(regions)

coords_matrix <- as.matrix(coordinates[, c("Longitude", "Latitude")])
rownames(coords_matrix) <- coordinates$Region

# ============================================================================
# 2️⃣ Calculate Distance Matrix
# ============================================================================
dist_matrix <- as.matrix(dist(coords_matrix))
rownames(dist_matrix) <- colnames(dist_matrix) <- regions

cat("📏 Distance Matrix (km approx):\n")
print(round(dist_matrix, 2))

# ============================================================================
# 3️⃣ Create Base Weight Matrices
# ============================================================================

# 3.1 Uniform Weights
uniform_weights <- matrix(1, n_regions, n_regions)
diag(uniform_weights) <- 0
rownames(uniform_weights) <- colnames(uniform_weights) <- regions

# 3.2 Inverse Distance Weights
inverse_distance_weights <- matrix(0, n_regions, n_regions)
for (i in 1:n_regions) {
  for (j in 1:n_regions) {
    if (i != j) inverse_distance_weights[i, j] <- 1 / dist_matrix[i, j]
  }
}
rownames(inverse_distance_weights) <- colnames(inverse_distance_weights) <- regions

# 3.3 Cross-Correlation Weights
cor_matrix <- cor(rainfall_matrix, use = "pairwise.complete.obs")
cross_correlation_weights <- abs(cor_matrix)
diag(cross_correlation_weights) <- 0
rownames(cross_correlation_weights) <- colnames(cross_correlation_weights) <- regions

# ============================================================================
# 4️⃣ Define Standardization and Normalization Functions
# ============================================================================

# 4.1 Row-standardization (jumlah per baris = 1)
standardize_W <- function(W) {
  W[is.na(W)] <- 0
  rs <- rowSums(W)
  W <- sweep(W, 1, rs, "/")
  W[!is.finite(W)] <- 0
  return(W)
}

# 4.2 Normalization tanpa standarisasi baris (0–1 scaling)
normalize_W <- function(W) {
  W[is.na(W)] <- 0
  W <- W / max(W, na.rm = TRUE)
  diag(W) <- 0
  return(W)
}

# ============================================================================
# 5️⃣ Apply Both Transformations
# ============================================================================
W_uniform_std <- standardize_W(uniform_weights)
W_inv_std     <- standardize_W(inverse_distance_weights)
W_corr_std    <- standardize_W(cross_correlation_weights)

W_uniform_norm <- normalize_W(uniform_weights)
W_inv_norm     <- normalize_W(inverse_distance_weights)
W_corr_norm    <- normalize_W(cross_correlation_weights)

# ============================================================================
# 6️⃣ Store Results (Raw, Standardized, Normalized)
# ============================================================================
spatial_weights_raw <- list(
  uniform = uniform_weights,
  inverse_distance = inverse_distance_weights,
  cross_correlation = cross_correlation_weights
)

spatial_weights_std <- list(
  uniform = W_uniform_std,
  inverse_distance = W_inv_std,
  cross_correlation = W_corr_std
)

spatial_weights_norm <- list(
  uniform = W_uniform_norm,
  inverse_distance = W_inv_norm,
  cross_correlation = W_corr_norm
)

# ============================================================================
# 7️⃣ Validation and Display
# ============================================================================
cat("\n🔍 Row-Sum Check (Standardized only):\n")
for (name in names(spatial_weights_std)) {
  W <- spatial_weights_std[[name]]
  cat(name, "→ mean(rowSums) =", round(mean(rowSums(W)), 4), "\n")
}

cat("\n📊 Example (Standardized):\n")
cat("\nUniform (std):\n"); print(round(W_uniform_std, 3))
cat("\nInverse Distance (std):\n"); print(round(W_inv_std, 3))
cat("\nCross-Correlation (std):\n"); print(round(W_corr_std, 3))

cat("\n📊 Example (Normalized 0–1):\n")
cat("\nUniform (norm):\n"); print(round(W_uniform_norm, 3))
cat("\nInverse Distance (norm):\n"); print(round(W_inv_norm, 3))
cat("\nCross-Correlation (norm):\n"); print(round(W_corr_norm, 3))

# ============================================================================
# 8️⃣ Check Matrix Differences
# ============================================================================
cat("\nMatrix Equality Check:\n")
cat("Uniform vs Inverse Distance:", identical(uniform_weights, inverse_distance_weights), "\n")
cat("Uniform vs Cross-Correlation:", identical(uniform_weights, cross_correlation_weights), "\n")
cat("Inverse Distance vs Cross-Correlation:", identical(inverse_distance_weights, cross_correlation_weights), "\n")

# ============================================================================
# 9️⃣ Save Results
# ============================================================================
save(
  spatial_weights_raw, spatial_weights_std, spatial_weights_norm,
  dist_matrix, cor_matrix, coordinates,
  uniform_weights, inverse_distance_weights, cross_correlation_weights,
  W_uniform_std, W_inv_std, W_corr_std,
  W_uniform_norm, W_inv_norm, W_corr_norm,
  file = "output/02_spatial_weights.RData"
)

cat("\n💾 Spatial weights saved to: output/02_spatial_weights.RData\n")
cat("✅ Spatial weight creation completed!\n")
cat(paste(rep("=", 50), collapse = ""), "\n")