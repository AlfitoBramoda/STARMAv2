# STARIMA Program Guide - Penjelasan Cara Kerja

Dokumen ini menjelaskan cara kerja setiap file program dalam analisis STARIMA secara detail.

## 📋 Overview Workflow

```
Data Mentah → Transformasi → Stasioneritas → Modeling → Prediksi → Visualisasi
```

---

## 00_Setup_Library.R
**Tujuan**: Environment setup and package installation

**Cara Kerja**:
1. **Install packages** yang belum ada secara otomatis
2. **Load semua library** yang dibutuhkan (tidyverse, forecast, tseries, dll)
3. **Set global options** untuk output yang konsisten
4. **Create directories** output/ dan plots/ jika belum ada

**Output**: Environment siap untuk analisis

---

## 01_Load_Data.R
**Tujuan**: Load and format spatio-temporal rainfall data

**Cara Kerja**:
1. **Read CSV files** dari 5 wilayah (Barat, Selatan, Tengah, Timur, Utara)
2. **Convert dates** dan susun dalam matrix format
3. **Extract coordinates** untuk analisis spasial
4. **Basic statistics** - summary, mean, variance per wilayah
5. **EDA visualizations**:
   - Time series plot semua wilayah
   - Correlation matrix antar wilayah
   - Boxplot distribusi per wilayah
   - Pola musiman bulanan

**Output**: 
- `rainfall_matrix` (120×5): Data curah hujan terstruktur
- `coordinates`: Lokasi geografis setiap wilayah
- `dates`: Vector tanggal
- 4 plot EDA

**Mengapa Penting**: Memahami pola, trend, dan hubungan antar wilayah sebelum modeling

---

## 02_Spatial_Weights.R
**Tujuan**: Create spatial weight matrices (adjacency, distance, correlation)

**Cara Kerja**:
1. **Calculate distance matrix** menggunakan Haversine formula
2. **Uniform weights**: Bobot sama untuk semua tetangga (1/n)
3. **Inverse distance weights**: Bobot berbanding terbalik dengan jarak kuadrat
4. **Cross-correlation weights**: Bobot berdasarkan korelasi data curah hujan
5. **Row standardization**: Setiap baris dijumlah = 1

**Formula Inverse Distance**:
```
wij = 1/dij²  dimana dij = jarak Haversine antara wilayah i dan j
W_standardized = W / rowSums(W)
```

**Output**: 
- `W_uniform`: Matriks bobot seragam
- `W_inv`: Matriks bobot inverse distance
- `W_corr`: Matriks bobot cross-correlation
- `distance_matrix`: Matriks jarak antar wilayah

**Mengapa Penting**: 
- **Spatial dependency** - wilayah dekat memiliki pengaruh lebih besar
- **STARIMA modeling** membutuhkan struktur spasial
- **Different weights** untuk different spatial relationships

---

## 03_BoxCox_Transform.R
**Tujuan**: Optional Box-Cox transformation for variance stabilization

**Cara Kerja**:
1. **Find optimal λ** untuk setiap wilayah menggunakan maximum likelihood
2. **Apply transformation**:
   - Jika λ ≈ 0: gunakan log transformation
   - Jika λ ≠ 0: gunakan formula Box-Cox: (x^λ - 1)/λ
3. **Compare variance** sebelum dan sesudah transformasi
4. **Visualize** perbandingan distribusi dan time series

**Formula Box-Cox**:
```
y(λ) = (x^λ - 1)/λ  jika λ ≠ 0
y(λ) = ln(x)        jika λ = 0
```

**Output**:
- `data_bc`: Data yang sudah ditransformasi
- `lambda_bc`: Nilai λ optimal per wilayah
- Plot perbandingan before/after

**Mengapa Penting**: Data dengan varians stabil lebih cocok untuk modeling time series

---

## 04_STACF_STPACF_Before.R
**Tujuan**: STACF/STPACF analysis before differencing with confidence bands

**Cara Kerja**:
1. **Calculate STACF/STPACF** untuk 3 jenis spatial weights:
   - Uniform weights
   - Inverse distance weights  
   - Cross-correlation weights
2. **Confidence bands**: ±1.96/√n untuk signifikansi statistik
3. **Single plot layout**: 2x3 grid (3 STACF + 3 STPACF)
4. **Function-based plotting**: Menghindari plot individual

**Output**: 
- 1 gambar dengan 6 plot (2x3 layout)
- Confidence bands untuk interpretasi
- Summary statistik per weight type

**Mengapa Penting**: 
- **Baseline analysis** sebelum differencing
- **Model identification** - menentukan order (p,q) awal
- **Spatial weight comparison** - pilih yang terbaik

---

## 05_Stationarity_Test.R
**Tujuan**: Unit root tests (ADF, KPSS)

**Cara Kerja**:
1. **Augmented Dickey-Fuller (ADF) Test**:
   - H0: Data non-stasioner (ada unit root)
   - H1: Data stasioner
   - Jika p-value < 0.05 → reject H0 → stasioner
2. **KPSS Test**:
   - H0: Data stasioner
   - H1: Data non-stasioner  
   - Jika p-value > 0.05 → fail to reject H0 → stasioner
3. **Summary table** dengan hasil kedua test
4. **Visualization**: Bar plot p-values dengan threshold α=0.05

**Output**:
- Summary table per wilayah
- Both_Agree kolom untuk konsistensi
- Bar plot ADF vs KPSS p-values
- need_differencing flag

**Mengapa Penting**: Menentukan apakah perlu differencing untuk stationarity

---

## 06_Differencing.R
**Tujuan**: Apply seasonal differencing (1-B^12) with D=1, d=0

**Cara Kerja**:
1. **Seasonal differencing only**: (1-B¹²) operator
2. **Parameters**: D=1 (seasonal), d=0 (regular)
3. **Minimal approach**: Sesuai rekomendasi guardrail
4. **Post-differencing validation**: ADF + KPSS tests
5. **Before vs After comparison**: Tabel perbandingan
6. **Visualization**: 2x5 layout (original vs differenced untuk 5 wilayah)

**Formula**:
```
Operator: (1-B¹²)
yt_diff = yt - yt-12
Kehilangan: 12 observasi pertama
```

**Output**: 
- Data hasil seasonal differencing
- Comparison table before/after
- differencing_success flag
- Plot 2x5 (5 wilayah, before vs after)

**Mengapa Penting**: 
- **Minimal differencing** - keep it simple (D=1, d=0)
- **Seasonal pattern removal** - hilangkan pola musiman
- **Preserve long-term level** - tidak over-difference

---

## 07_STACF_STPACF_After.R
**Tujuan**: STACF/STPACF analysis after differencing with confidence bands

**Cara Kerja**:
1. **Calculate STACF/STPACF** untuk 3 jenis spatial weights
2. **Reduced lag**: 20 (vs 40 sebelumnya) untuk fokus pola utama
3. **Confidence bands**: ±1.96/√n untuk signifikansi
4. **Function-based plotting**: 2x3 layout dalam 1 gambar
5. **Before vs After comparison**: Validasi differencing effectiveness

**Expected Results**:
- **Faster decay** ke nol dibanding sebelum differencing
- **Reduced periodic spikes** - seasonal pattern hilang
- **Clear cut-off patterns** untuk model identification

**Output**: 
- 1 gambar 2x3 (3 STACF + 3 STPACF)
- Persentase reduction dari before differencing
- Summary statistik per weight type
- Confirmation data siap modeling

**Mengapa Penting**: 
- **Validation** differencing berhasil
- **Model order identification** dari cut-off patterns
- **Spatial weight selection** untuk modeling

---

## 08_Data_Centering.R
**Tujuan**: Data centering and scaling

**Cara Kerja**:
1. **Calculate mean** setiap wilayah dari data yang sudah di-difference
2. **Subtract mean** dari setiap observasi
3. **Verify** bahwa mean baru = 0
4. **Preserve stationarity** yang sudah dicapai dari differencing

**Formula**: `centered_data = differenced_data - mean(differenced_data)`

**Output**: 
- Data dengan mean = 0 per wilayah
- Tetap mempertahankan stasioneritas
- Siap untuk STARIMA modeling

**Mengapa Penting**: 
- **Remove spatial bias** - perbedaan level antar wilayah
- **Improve model convergence** - parameter estimation lebih stabil
- **Standard practice** dalam spatial-temporal modeling

---

## 09_Data_Split.R
**Tujuan**: Split data into train/test sets for validation

**Cara Kerja**:
1. **Load centered data** dari step 08
2. **Identify date alignment** - data sudah kehilangan 13 observasi dari differencing
3. **Split by year**: 2015-2023 untuk training, 2024 untuk testing
4. **Verify split**: Pastikan tidak ada data leakage
5. **Statistical comparison**: Bandingkan distribusi train vs test

**Split Strategy**:
```
Original data: 2015-01 to 2024-12 (120 obs)
After differencing: 2016-02 to 2024-12 (107 obs)
Train: 2016-02 to 2023-12 (~95 obs)
Test: 2024-01 to 2024-12 (~12 obs)
```

**Output**: 
- `train_data`: Data training (2015-2023)
- `test_data`: Data testing (2024)
- `train_dates`, `test_dates`: Corresponding dates
- Plots perbandingan train/test

**Mengapa Penting**: 
- **Proper evaluation** - out-of-sample testing
- **Avoid overfitting** - model tidak "melihat" test data
- **Research validity** - standard practice untuk time series
- **Performance metrics** - RMSE, MAE, MAPE pada data unseen

---

## 10_STARIMA_Model.R
**Tujuan**: Model identification and estimation

**Cara Kerja**:
1. **Load train data** dari step 09
2. **Try different orders** (p,q) berdasarkan STACF/STPACF
3. **Test different spatial weights** (Uniform, Inverse Distance, Cross Correlation)
4. **Select best model** berdasarkan AIC/BIC pada training data
5. **Save 3 best models** (satu per spatial weight) untuk comparison

**Model STARIMA(p,q)**:
```
Φ(B,s)Zt = Θ(B,s)εt
dimana B = backshift operator, s = spatial lag
```

**Output**: 
- 3 trained models dengan spatial weights berbeda
- Model comparison results
- Fitted vs actual plots untuk training data

**Mengapa Penting**: 
- **Core modeling** - inti dari analisis STARIMA
- **Multiple candidates** - 3 model untuk evaluasi
- **Training only** - tidak menggunakan test data

---

## 11_Residual_Analysis.R
**Tujuan**: Residual diagnostics and model validation

**Cara Kerja**:
1. **Calculate residuals** dari model
2. **ACF/PACF residuals** - harus seperti white noise
3. **Ljung-Box test** - test independensi residual
4. **Normality test** - Shapiro-Wilk atau Jarque-Bera

**Output**: Plot diagnostik dan hasil test

**Mengapa Penting**: Validasi bahwa model sudah adequate

---

## 12_Forecasting.R
**Tujuan**: Generate forecasts using best model

**Cara Kerja**:
1. **Generate forecasts** menggunakan model STARIMA
2. **Calculate prediction intervals** (confidence bands)
3. **Multi-step ahead prediction**

**Output**: Forecast values dengan confidence intervals

**Mengapa Penting**: Tujuan utama - prediksi untuk planning

---

## 13_Inverse_Transform.R
**Tujuan**: Inverse transformations to original scale

**Cara Kerja**:
1. **Undo centering**: Tambahkan kembali mean
2. **Undo Box-Cox**: Gunakan inverse transformation
3. **Undo differencing**: Cumulative sum

**Formula Inverse Box-Cox**:
```
x = (λy + 1)^(1/λ)  jika λ ≠ 0
x = exp(y)          jika λ = 0
```

**Output**: Forecast dalam skala asli (mm curah hujan)

**Mengapa Penting**: Hasil yang interpretable untuk end-user

---

## 14_Visualization.R
**Tujuan**: Comprehensive visualizations and summary

**Cara Kerja**:
1. **Plot historical data** vs forecast
2. **Show confidence intervals**
3. **Separate plots** per wilayah
4. **Summary statistics** forecast

**Output**: Plot komprehensif hasil prediksi

**Mengapa Penting**: Komunikasi hasil untuk stakeholder

---

## 🔄 Alur Dependensi

```
00 → 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14
```

**Urutan Final**:
- **00**: Setup Library
- **01**: Load Data  
- **02**: Spatial Weights
- **03**: BoxCox Transform
- **04**: STACF/STPACF Before
- **05**: Stationarity Test
- **06**: Differencing
- **07**: STACF/STPACF After
- **08**: Data Centering
- **09**: Data Split (Train/Test)
- **10**: STARIMA Model
- **11**: Residual Analysis
- **12**: Forecasting
- **13**: Inverse Transform
- **14**: Visualization

Setiap file bergantung pada output file sebelumnya, sehingga harus dijalankan berurutan.