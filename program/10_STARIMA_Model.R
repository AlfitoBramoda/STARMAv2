# ============================================================================
# 09_STARIMA_Model.R
# Fungsi: Training model STARIMA dengan berbagai order dan spatial weights
# Output: starima_model.RData
# ============================================================================

cat("=== 10 STARIMA MODEL TRAINING ===\n")

# Load data from previous steps
load("output/02_spatial_weights.RData")
load("output/09_train_test_data.RData")  # Use train data only

# Load STACF/STPACF results for model order guidance
load("output/07_stacf_stpacf_after.RData")

cat("--- MODEL SETUP ---\n")

# Convert to time series format (TRAIN DATA ONLY)
n_obs <- nrow(train_data)
n_regions <- ncol(train_data)
ts_data <- ts(train_data, frequency = 12)

cat("Data dimensions:", n_obs, "x", n_regions, "\n")
cat("Time series frequency: 12 (monthly)\n")

# Define candidate model orders based on STACF/STPACF
candidate_orders <- list(
  c(1, 1),  # AR(1), MA(1)
  c(1, 2),  # AR(1), MA(2)
  c(2, 1),  # AR(2), MA(1)
  c(2, 2),  # AR(2), MA(2)
  c(1, 0),  # AR(1) only
  c(0, 1),  # MA(1) only
  c(0, 2),  # MA(2) only
  c(2, 0)   # AR(2) only
)

# Spatial weight matrices to test
weight_matrices <- list(
  "Uniform" = W_uniform,
  "Inverse_Distance" = W_inv,
  "Cross_Correlation" = W_corr
)

cat("Candidate orders:", length(candidate_orders), "\n")
cat("Spatial weight types:", length(weight_matrices), "\n")

# Initialize results storage
model_results <- data.frame()
best_models <- list()
best_configs <- list()
best_aics <- list(Uniform = Inf, Inverse_Distance = Inf, Cross_Correlation = Inf)

cat("\n--- MODEL ESTIMATION ---\n")

# Simple STARIMA implementation using VAR approach
for(weight_name in names(weight_matrices)) {
  W <- weight_matrices[[weight_name]]
  
  cat("Testing spatial weights:", weight_name, "\n")
  
  for(i in 1:length(candidate_orders)) {
    p <- candidate_orders[[i]][1]  # AR order
    q <- candidate_orders[[i]][2]  # MA order
    
    cat("  Order (p,q) = (", p, ",", q, ")", sep = "")
    
    tryCatch({
      # Create spatially lagged variables
      spatial_lag_data <- train_data %*% W
      
      # Prepare data for VAR-type estimation
      if(p > 0) {
        # Create lagged variables for AR terms
        ar_data <- list()
        for(lag in 1:p) {
          if(nrow(train_data) > lag) {
            ar_data[[paste0("lag", lag)]] <- train_data[(1:(nrow(train_data)-lag)), ]
            ar_data[[paste0("spatial_lag", lag)]] <- spatial_lag_data[(1:(nrow(spatial_lag_data)-lag)), ]
          }
        }
        
        # Combine AR data
        if(length(ar_data) > 0) {
          combined_ar <- do.call(cbind, ar_data)
          y_data <- train_data[((p+1):nrow(train_data)), ]
          
          # Simple linear regression for each region
          coefficients <- list()
          residuals <- matrix(NA, nrow = nrow(y_data), ncol = ncol(y_data))
          log_likelihood <- 0
          
          for(region in 1:n_regions) {
            lm_model <- lm(y_data[, region] ~ combined_ar)
            coefficients[[colnames(data_centered)[region]]] <- coef(lm_model)
            residuals[, region] <- residuals(lm_model)
            log_likelihood <- log_likelihood + logLik(lm_model)
          }
          
          # Calculate AIC
          n_params <- length(unlist(coefficients))
          aic <- -2 * log_likelihood + 2 * n_params
          bic <- -2 * log_likelihood + log(nrow(y_data)) * n_params
          
        } else {
          aic <- Inf
          bic <- Inf
        }
      } else {
        # MA-only or intercept-only model
        if(q > 0) {
          # Simple MA approximation using residuals from AR(1)
          ar1_residuals <- matrix(NA, nrow = n_obs-1, ncol = n_regions)
          for(region in 1:n_regions) {
            ar1_model <- lm(data_centered[2:n_obs, region] ~ data_centered[1:(n_obs-1), region])
            ar1_residuals[, region] <- residuals(ar1_model)
          }
          
          # Estimate MA parameters (simplified)
          ma_coefficients <- list()
          log_likelihood <- 0
          
          for(region in 1:n_regions) {
            if(q == 1 && nrow(ar1_residuals) > 1) {
              ma_data <- ar1_residuals[2:nrow(ar1_residuals), region]
              ma_lag1 <- ar1_residuals[1:(nrow(ar1_residuals)-1), region]
              ma_model <- lm(ma_data ~ ma_lag1)
              ma_coefficients[[colnames(data_centered)[region]]] <- coef(ma_model)
              log_likelihood <- log_likelihood + logLik(ma_model)
            }
          }
          
          n_params <- length(unlist(ma_coefficients))
          aic <- -2 * log_likelihood + 2 * n_params
          bic <- -2 * log_likelihood + log(nrow(ar1_residuals)-1) * n_params
          
        } else {
          # Intercept-only model
          aic <- sum(apply(data_centered, 2, function(x) AIC(lm(x ~ 1))))
          bic <- sum(apply(data_centered, 2, function(x) BIC(lm(x ~ 1))))
        }
      }
      
      # Store results
      model_results <- rbind(model_results, data.frame(
        Weight_Type = weight_name,
        AR_Order = p,
        MA_Order = q,
        AIC = aic,
        BIC = bic,
        LogLik = ifelse(exists("log_likelihood"), log_likelihood, NA),
        Converged = TRUE
      ))
      
      # Check if this is the best model for this weight type
      if(aic < best_aics[[weight_name]] && is.finite(aic)) {
        best_aics[[weight_name]] <- aic
        best_models[[weight_name]] <- list(
          coefficients = if(exists("coefficients")) coefficients else NULL,
          residuals = if(exists("residuals")) residuals else NULL,
          fitted_values = if(exists("y_data") && exists("residuals")) y_data - residuals else NULL
        )
        best_configs[[weight_name]] <- list(
          weight_type = weight_name,
          weight_matrix = W,
          ar_order = p,
          ma_order = q,
          aic = aic,
          bic = bic
        )
      }
      
      cat(" - AIC:", round(aic, 2), "\n")
      
    }, error = function(e) {
      cat(" - ERROR:", e$message, "\n")
      model_results <<- rbind(model_results, data.frame(
        Weight_Type = weight_name,
        AR_Order = p,
        MA_Order = q,
        AIC = NA,
        BIC = NA,
        LogLik = NA,
        Converged = FALSE
      ))
    })
  }
}

cat("\n--- MODEL SELECTION RESULTS ---\n")

# Sort results by AIC
model_results <- model_results[order(model_results$AIC, na.last = TRUE), ]
print(head(model_results, 10))

cat("\n--- BEST MODELS BY SPATIAL WEIGHT ---\n")
for(weight_name in names(best_configs)) {
  if(!is.null(best_configs[[weight_name]])) {
    config <- best_configs[[weight_name]]
    cat("\n", weight_name, " Weights:\n", sep = "")
    cat("  Model: STARIMA(", config$ar_order, ",1,", config$ma_order, ")\n", sep = "")
    cat("  AIC:", round(config$aic, 4), "\n")
    cat("  BIC:", round(config$bic, 4), "\n")
  } else {
    cat("\n", weight_name, " Weights: No valid model found\n", sep = "")
  }
}

# Visualization
cat("\n--- CREATING VISUALIZATIONS ---\n")

# Model comparison plot
valid_results <- model_results[model_results$Converged & !is.na(model_results$AIC), ]

if(nrow(valid_results) > 0) {
  p1 <- ggplot(valid_results, aes(x = interaction(AR_Order, MA_Order), y = AIC, fill = Weight_Type)) +
    geom_col(position = "dodge", alpha = 0.8) +
    labs(title = "Model Comparison by AIC",
         x = "Model Order (AR.MA)", y = "AIC", fill = "Spatial Weights") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  print(p1)
  ggsave("plots/09_model_comparison.png", p1, width = 12, height = 6)
}

# Create fitted vs actual plots for all three best models
for(weight_name in names(best_models)) {
  if(!is.null(best_models[[weight_name]]) && !is.null(best_models[[weight_name]]$fitted_values)) {
    best_model <- best_models[[weight_name]]
    best_config <- best_configs[[weight_name]]
  fitted_data <- data.frame()
  
  for(i in 1:ncol(data_centered)) {
    region <- colnames(data_centered)[i]
    
    # Get the overlapping time period
    actual_start <- (best_config$ar_order + 1)
    actual_values <- data_centered[actual_start:nrow(data_centered), i]
    fitted_values <- best_model$fitted_values[, i]
    
    # Ensure same length
    min_length <- min(length(actual_values), length(fitted_values))
    time_indices <- actual_start:(actual_start + min_length - 1)
    
    temp_data <- data.frame(
      Time = time_indices,
      Actual = actual_values[1:min_length],
      Fitted = fitted_values[1:min_length],
      Region = region
    )
    
    fitted_data <- rbind(fitted_data, temp_data)
  }
  
    p2 <- ggplot(fitted_data, aes(x = Time)) +
      geom_line(aes(y = Actual, color = "Actual"), alpha = 0.7) +
      geom_line(aes(y = Fitted, color = "Fitted"), alpha = 0.7) +
      facet_wrap(~Region, scales = "free_y", ncol = 2) +
      labs(title = paste("Model Fit: STARIMA(", best_config$ar_order, ",1,", best_config$ma_order, ")", sep = ""),
           subtitle = paste("Spatial weights:", best_config$weight_type),
           x = "Time Index", y = "Value", color = "Type") +
      theme_minimal() +
      scale_color_manual(values = c("Actual" = "blue", "Fitted" = "red"))
    
    print(p2)
    plot_filename <- paste0("plots/09_model_fit_", gsub("_", "", tolower(weight_name)), ".png")
    ggsave(plot_filename, p2, width = 12, height = 10)
    
    cat("✓ Model fit plot saved:", plot_filename, "\n")
  }
}

cat("✓ Visualizations saved to plots/ folder\n")

cat("\n--- FINAL SUMMARY ---\n")
valid_models <- sum(sapply(best_configs, function(x) !is.null(x)))
cat("Valid models found:", valid_models, "out of 3 spatial weight types\n")
if(valid_models > 0) {
  cat("All models saved for comparison in research\n")
  cat("Models ready for evaluation and forecasting\n")
} else {
  cat("No suitable models found - check data and try different orders\n")
}

# Save all results for research comparison
save(best_models, best_configs, model_results, file = "output/10_starima_model.RData")
cat("✓ Model results saved to output/10_starima_model.RData\n")

cat("\n=== 10 STARIMA MODEL TRAINING COMPLETED ===\n")