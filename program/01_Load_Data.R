# ============================================================================
# 01_Load_Data.R - Load and Format Spatio-Temporal Data
# ============================================================================

cat("📊 Loading Spatio-Temporal Rainfall Data...\n")

library(readr)
library(dplyr)

# Define regions
regions <- c("Barat", "Selatan", "Tengah", "Timur", "Utara")

# Initialize storage
region_data <- list()
coordinates <- data.frame(
  Region = character(),
  Longitude = numeric(),
  Latitude = numeric(),
  stringsAsFactors = FALSE
)

# Load data for each region
for (region in regions) {
  # Try multiple possible paths
  possible_paths <- c(
    paste0("dataset/", region, ".csv"),
    paste0("../dataset/", region, ".csv"),
    paste0("../../dataset/", region, ".csv")
  )
  
  file_path <- NULL
  for (path in possible_paths) {
    if (file.exists(path)) {
      file_path <- path
      break
    }
  }
  
  if (!is.null(file_path)) {
    data <- read_csv(file_path, show_col_types = FALSE)
    region_data[[region]] <- data$PRECTOTCORR
    
    coordinates <- rbind(coordinates, data.frame(
      Region = region,
      Longitude = data$Longitude[1],
      Latitude = data$Latitude[1]
    ))
    
    cat("✅", region, ":", nrow(data), "observations loaded from", file_path, "\n")
  } else {
    cat("❌ File not found for", region, ". Tried:\n")
    for (path in possible_paths) cat("  -", path, "\n")
    stop(paste("Please place", region, ".csv in one of the above locations"))
  }
}

# Convert to matrix
rainfall_matrix <- do.call(cbind, region_data)
colnames(rainfall_matrix) <- regions

# Extract dates from first successful file
first_file <- NULL
for (path in c("../dataset/Barat.csv", "../../dataset/Barat.csv", "../Calis/dataset/Barat.csv", "dataset/Barat.csv")) {
  if (file.exists(path)) {
    first_file <- path
    break
  }
}

if (!is.null(first_file)) {
  dates <- read_csv(first_file, show_col_types = FALSE)$Date
} else {
  dates <- seq(as.Date("2015-01-01"), by = "month", length.out = nrow(rainfall_matrix))
  cat("⚠️ Using default dates\n")
}

# Display info
cat("\n📋 Dataset Structure:\n")
cat("Dimensions:", nrow(rainfall_matrix), "x", ncol(rainfall_matrix), "\n")
cat("Time period:", min(dates), "to", max(dates), "\n")

# Basic statistics
summary_stats <- data.frame(
  Region = regions,
  Mean = round(apply(rainfall_matrix, 2, mean, na.rm = TRUE), 3),
  SD = round(apply(rainfall_matrix, 2, sd, na.rm = TRUE), 3),
  Min = round(apply(rainfall_matrix, 2, min, na.rm = TRUE), 3),
  Max = round(apply(rainfall_matrix, 2, max, na.rm = TRUE), 3)
)
print(summary_stats)

# Save data
save(rainfall_matrix, coordinates, dates, summary_stats,
     file = "output/01_rainfall_data.RData")

cat("\n💾 Data saved to: output/01_rainfall_data.RData\n")
cat("✅ Data loading completed!\n")
cat(paste(rep("=", 50), collapse = ""), "\n")