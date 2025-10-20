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

## Progress Tracker

| No | File | Status | Fungsi | Output |
|----|------|--------|--------|--------|
| 00 | Setup_Library.R | ✅ | Install & load packages | Packages ready |
| 01 | Load_Data.R | ✅ | Load & EDA | rainfall_data.RData |
| 02 | Spatial_Weights.R | ✅ | Bobot spasial | spatial_weights.RData |
| 03 | BoxCox_Transform.R | ✅ | Stabilisasi varians | boxcox_data.RData |
| 04 | STACF_STPACF_Before.R | ✅ | Plot korelasi sebelum | stacf_before.png |
| 05 | Stationarity_Test.R | ✅ | Uji stasioneritas | stationarity_results.RData |
| 06 | Differencing.R | ✅ | Seasonal differencing | differenced_data.RData |
| 07 | STACF_STPACF_After.R | ✅ | Plot korelasi setelah | stacf_after.png |
| 08 | Data_Centering.R | ⏳ | Centering data | centered_data.RData |
| 09 | STARIMA_Model.R | ⏳ | Model training | starima_model.RData |
| 10 | Residual_Analysis.R | ⏳ | Evaluasi residual | residual_plots.png |
| 11 | Forecasting.R | ⏳ | Prediksi | forecast_results.RData |
| 12 | Inverse_Transform.R | ⏳ | Kembalikan ke skala asli | forecast_original.RData |
| 13 | Visualization.R | ⏳ | Plot hasil akhir | forecast_plot.png |

**Legend**: ✅ Complete | ⏳ Pending | ❌ Error

## Cara Menjalankan

1. **Setup**: Jalankan `00_Setup_Library.R` terlebih dahulu
2. **Individual**: Jalankan file program/ satu per satu sesuai urutan
3. **Pipeline**: Jalankan `pipeline.R` untuk eksekusi otomatis

## Requirements
- R >= 4.5.1
- RStudio (recommended)
- Packages: tidyverse, forecast, tseries, spdep, geosphere, dll.