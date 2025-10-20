# ============================================================================
# STARIMA Pipeline - Automated Execution
# ============================================================================

source("Reset.R")
source("program/00_Setup_Library.R")
source("program/01_Load_Data.R")
source("program/02_Spatial_Weights.R")
source("program/03_BoxCox_Transform.R")
source("program/04_STACF_STPACF_Before.R")
source("program/05_Stationarity_Test.R")
source("program/06_Differencing.R")
source("program/07_STACF_STPACF_After.R")
source("program/08_Data_Centering.R")
source("program/09_STARIMA_Model.R")
source("program/10_Residual_Analysis.R")
source("program/11_Forecasting.R")
source("program/12_Inverse_Transform.R")
source("program/13_Visualization.R")