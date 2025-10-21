# STARIMA Project - Analisis Curah Hujan Spasial-Temporal

Proyek ini mengimplementasikan model STARIMA (Space-Time AutoRegressive Integrated Moving Average) untuk analisis dan prediksi curah hujan di 5 wilayah berbeda.

## Struktur Proyek

```
📁 STARMAv2/
│
├── 📁 dataset/          # Data mentah curah hujan per wilayah
├── 📁 program/          # File modular analisis (00-13)
├── 📁 output/           # Hasil antar-tahap (.RData)
├── 📁 plots/            # Visualisasi hasil
├── pipeline.R           # Script utama
└── README.md           # Dokumentasi ini
```

## Data
- **Periode**: 2015-2024 (10 tahun)
- **Wilayah**: Barat, Selatan, Tengah, Timur, Utara
- **Variabel**: PRECTOTCORR (curah hujan terkoreksi)
- **Koordinat**: Longitude, Latitude
- **Data Split**: 
  - **Train**: 2015-2023 (9 tahun) untuk model training
  - **Test**: 2024 (1 tahun) untuk model evaluation

### Core Pipeline Files & Progress Status:

| No | File | Description | Status | Output |
|----|------|-------------|--------|--------|
| 00 | Setup_Library.R | Environment setup and package installation | ✅ | Packages ready |
| 01 | Load_Data.R | Load and format spatio-temporal rainfall data | ✅ | rainfall_data.RData |
| 02 | Spatial_Weights.R | Create spatial weight matrices | ✅ | spatial_weights.RData |
| 03 | BoxCox_Transform.R | Box-Cox transformation for variance stabilization | ✅ | boxcox_data.RData |
| 04 | STACF_STPACF_Before.R | STACF/STPACF analysis before differencing with confidence bands | ✅ | stacf_before.png |
| 05 | Stationarity_Test.R | Unit root tests (ADF, KPSS) | ✅ | stationarity_results.RData |
| 06 | Differencing.R | Apply seasonal differencing (1-B^12) with D=1, d=0 | ✅ | differenced_data.RData |
| 07 | STACF_STPACF_After.R | STACF/STPACF analysis after differencing with confidence bands | ✅ | stacf_after.png |
| 08 | Data_Centering.R | Data centering and scaling | ⏳ | centered_data.RData |
| 09 | Data_Split.R | Split data into train/test sets for validation | ⏳ | train_test_data.RData |
| 10 | STARIMA_Model.R | Model identification and estimation | ⏳ | starima_model.RData |
| 11 | Residual_Analysis.R | Residual diagnostics and model validation | ⏳ | residual_plots.png |
| 12 | Forecasting.R | Generate forecasts using best model | ⏳ | forecast_results.RData |
| 13 | Inverse_Transform.R | Inverse transformations to original scale | ⏳ | forecast_original.RData |
| 14 | Visualization.R | Comprehensive visualizations and summary | ⏳ | forecast_plot.png |

**Legend**: ✅ Complete | ⏳ Pending | ❌ Error

## Cara Menjalankan

1. **Setup**: Jalankan `00_Setup_Library.R` terlebih dahulu
2. **Individual**: Jalankan file program/ satu per satu sesuai urutan
3. **Pipeline**: Jalankan `pipeline.R` untuk eksekusi otomatis

## Requirements
- R >= 4.5.1
- RStudio (recommended)
- Packages: tidyverse, forecast, tseries, spdep, geosphere, dll.

## 🔧 Key Features

### Spatial Weight Matrices:
1. **Adjacency Weights** - Based on nearest neighbors
2. **Distance Weights** - Inverse distance weighting
3. **Correlation Weights** - Based on cross-correlation threshold

### Model Selection:
- Multiple STARIMA model orders tested
- AIC-based model selection
- Comprehensive residual diagnostics

### Transformations:
- Box-Cox transformation (optional)
- Differencing for stationarity
- Data centering and scaling
- Full inverse transformation chain

### Diagnostics:
- Ljung-Box test for residual autocorrelation
- Jarque-Bera test for normality
- Model comparison metrics

## 📈 Methodology

The pipeline follows the standard STARIMA methodology:

1. **Data Preparation**: Load and format spatio-temporal data
2. **Spatial Structure**: Define spatial relationships through weight matrices
3. **Stationarity**: Test and achieve stationarity through differencing
4. **Model Identification**: Use STACF/STPACF for model order selection
5. **Estimation**: Fit STARIMA models with different specifications
6. **Validation**: Comprehensive residual analysis and diagnostics
7. **Forecasting**: Generate multi-step ahead forecasts
8. **Visualization**: Create comprehensive plots and summaries

## 🛠️ Troubleshooting

### Common Issues:

1. **Package Installation Errors**:
   - Run `00_Setup_Library.R` separately
   - Install packages manually if needed

2. **Data Loading Errors**:
   - Verify CSV files are in `../dataset/` directory
   - Check CSV format matches expected structure

3. **Model Estimation Failures**:
   - Try different model orders in `10_STARIMA_Model.R`
   - Check data quality and stationarity

4. **Memory Issues**:
   - Reduce forecast horizon in `12_Forecasting.R`
   - Use smaller lag orders in STACF/STPACF analysis

### Error Logs:
Check `output/pipeline_execution_log.RData` for detailed execution information.

## 📚 References

- Pfeifer, P.E. and Deutsch, S.J. (1980). A three-stage iterative procedure for space-time modeling
- Cliff, A.D. and Ord, J.K. (1975). Model building and the analysis of spatial pattern in human geography
- Box, G.E.P. and Jenkins, G.M. (1976). Time Series Analysis: Forecasting and Control

## 👥 Support

For issues or questions:
1. Check the troubleshooting section above
2. Review error messages in the console output
3. Examine individual step outputs for debugging

## 📄 License

This pipeline is provided for educational and research purposes.

---

**Last Updated**: 2024
**Version**: 1.0
**Author**: STARIMA Pipeline Project