# ============================================================================
# 01_Load_Data.R
# Fungsi: Load dataset curah hujan, EDA, dan visualisasi
# Output: rainfall_data.RData, plots EDA
# ============================================================================

cat("=== 01 LOADING DATA ===\n")

# Load datasets
regions <- c("Barat", "Selatan", "Tengah", "Timur", "Utara")
rainfall_list <- list()
coordinates <- data.frame()

for(region in regions) {
  file_path <- file.path("dataset", paste0(region, ".csv"))
  data <- read_csv(file_path, show_col_types = FALSE)
  
  # Convert Date column
  data$Date <- as.Date(data$Date)
  
  # Store rainfall data
  rainfall_list[[region]] <- data$PRECTOTCORR
  
  # Store coordinates
  coordinates <- rbind(coordinates, data.frame(
    Region = region,
    Longitude = data$Longitude[1],
    Latitude = data$Latitude[1]
  ))
}

# Create rainfall matrix (rows = time, cols = regions)
dates <- as.Date(read_csv("dataset/Barat.csv", show_col_types = FALSE)$Date)
rainfall_matrix <- do.call(cbind, rainfall_list)
colnames(rainfall_matrix) <- regions

cat("✓ Data loaded:", nrow(rainfall_matrix), "observations,", ncol(rainfall_matrix), "regions\n")

# Basic statistics
cat("\n--- BASIC STATISTICS ---\n")
print(summary(rainfall_matrix))

# EDA Visualizations
cat("\n--- CREATING VISUALIZATIONS ---\n")

# 1. Time series plot
ts_data <- data.frame(Date = dates, rainfall_matrix) %>%
  pivot_longer(-Date, names_to = "Region", values_to = "Rainfall")

p1 <- ggplot(ts_data, aes(x = Date, y = Rainfall, color = Region)) +
  geom_line() +
  labs(title = "Rainfall Time Series by Region", 
       x = "Date", y = "Rainfall (mm)") +
  theme_minimal()

print(p1)
ggsave("plots/01_rainfall_timeseries.png", p1, width = 12, height = 6)

# 2. Correlation matrix
cor_matrix <- cor(rainfall_matrix)
corrplot(cor_matrix, method = "color", type = "upper", 
         addCoef.col = "black", tl.cex = 0.8, number.cex = 0.7,
         title = "Rainfall Correlation Matrix Between Regions", 
         mar = c(0,0,2,0))
png("plots/01_correlation_matrix.png", width = 800, height = 600)
corrplot(cor_matrix, method = "color", type = "upper", 
         addCoef.col = "black", tl.cex = 0.8, number.cex = 0.7,
         title = "Rainfall Correlation Matrix Between Regions", 
         mar = c(0,0,2,0))
dev.off()

# 3. Boxplot by region
p3 <- ggplot(ts_data, aes(x = Region, y = Rainfall, fill = Region)) +
  geom_boxplot() +
  labs(title = "Rainfall Distribution by Region", 
       x = "Region", y = "Rainfall (mm)") +
  theme_minimal() +
  theme(legend.position = "none")

print(p3)
ggsave("plots/01_boxplot_regions.png", p3, width = 10, height = 6)

# 4. Monthly pattern
ts_data$Month <- month(ts_data$Date, label = TRUE)
monthly_avg <- ts_data %>%
  group_by(Month, Region) %>%
  summarise(Avg_Rainfall = mean(Rainfall, na.rm = TRUE), .groups = "drop")

p4 <- ggplot(monthly_avg, aes(x = Month, y = Avg_Rainfall, color = Region, group = Region)) +
  geom_line(linewidth = 1) +
  geom_point() +
  labs(title = "Average Monthly Rainfall Pattern", 
       x = "Month", y = "Average Rainfall (mm)") +
  theme_minimal()

print(p4)
ggsave("plots/01_monthly_pattern.png", p4, width = 12, height = 6)

cat("✓ Visualizations saved to plots/ folder\n")

# Save data
save(rainfall_matrix, coordinates, dates, file = "output/01_rainfall_data.RData")
cat("✓ Data saved to output/01_rainfall_data.RData\n")

cat("\n=== 01 LOAD DATA COMPLETED ===\n")