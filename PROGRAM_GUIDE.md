# STARIMA Program Guide - Penjelasan Cara Kerja

Dokumen ini menjelaskan cara kerja setiap file program dalam analisis STARIMA secara detail.

## 📋 Overview Workflow

```
Data Mentah → Transformasi → Stasioneritas → Modeling → Prediksi → Visualisasi
```

---

## 00_Setup_Library.R
**Tujuan**: Persiapan environment dan package

**Cara Kerja**:
1. **Install packages** yang belum ada secara otomatis
2. **Load semua library** yang dibutuhkan (tidyverse, forecast, tseries, dll)
3. **Set global options** untuk output yang konsisten
4. **Create directories** output/ dan plots/ jika belum ada

**Output**: Environment siap untuk analisis

---

## 01_Load_Data.R
**Tujuan**: Memuat dan eksplorasi data awal

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
**Tujuan**: Membuat matriks bobot spasial

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
**Tujuan**: Stabilisasi varians data

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
**Tujuan**: Analisis korelasi spasial-temporal sebelum differencing

**Cara Kerja**:
1. **Space-Time ACF (STACF)**:
   - Menggunakan spatial weights (W_corr) untuk weighted series
   - Mengukur korelasi temporal pada berbagai lag (0-40)
   - Traditional ACF plot format
2. **Space-Time PACF (STPACF)**:
   - Korelasi parsial setelah menghilangkan efek lag sebelumnya
   - Traditional PACF plot format
3. **Spatial weighting**: Setiap wilayah diweight dengan cross-correlation matrix

**Output**: 
- Plot STACF dan STPACF traditional style
- Combined plots untuk comparison
- Data untuk identifikasi model order

**Mengapa Penting**: 
- **Baseline analysis** sebelum differencing
- **Model identification** - menentukan order (p,q) awal
- **Spatial-temporal patterns** dalam data raw

---

## 05_Stationarity_Test.R
**Tujuan**: Uji stasioneritas data

**Cara Kerja**:
1. **Augmented Dickey-Fuller (ADF) Test**:
   - H0: Data non-stasioner (ada unit root)
   - H1: Data stasioner
   - Jika p-value < 0.05 → reject H0 → stasioner
2. **KPSS Test**:
   - H0: Data stasioner
   - H1: Data non-stasioner  
   - Jika p-value > 0.05 → fail to reject H0 → stasioner
3. **Kombinasi hasil** kedua test untuk kesimpulan final

**Output**:
- Hasil p-value ADF dan KPSS per wilayah
- Status stasioneritas (TRUE/FALSE)
- Rekomendasi differencing jika diperlukan

**Mengapa Penting**: Model STARIMA membutuhkan data stasioner

---



## 06_Differencing.R
**Tujuan**: Membuat data stasioner melalui seasonal + first differencing

**Cara Kerja**:
1. **Step 1**: Seasonal differencing (lag 12) untuk menghilangkan pola musiman
2. **Step 2**: First differencing pada hasil step 1 untuk menghilangkan trend
3. **Combined approach**: ∇∇₁₂yt = ∇(yt - yt-12)
4. **Stationarity test**: ADF + KPSS pada hasil akhir
5. **Visualization**: Proses transformasi bertahap

**Formula Lengkap**:
```
Step 1: Seasonal differencing
yt_seasonal = yt - yt-12

Step 2: First differencing  
yt_final = yt_seasonal - yt_seasonal-1
       = (yt - yt-12) - (yt-1 - yt-13)
```

**Output**: 
- Data stasioner dengan d=1, D=1
- Kehilangan 13 observasi (12+1)
- Model notation: STARIMA(p,1,q)(P,1,Q)₁₂

**Mengapa Penting**: 
- Curah hujan memiliki **strong seasonality** (wet/dry seasons)
- **Seasonal differencing** menghilangkan pola musiman
- **First differencing** menghilangkan trend residual
- **Combined approach** lebih efektif untuk climate data

---

## 07_STACF_STPACF_After.R
**Tujuan**: Verifikasi korelasi setelah differencing dan identifikasi model order

**Cara Kerja**:
1. **Calculate STACF/STPACF** pada data yang sudah di-difference
2. **Spatial weighting** menggunakan W_corr dari step 02
3. **Traditional ACF/PACF plots** untuk interpretasi mudah
4. **Before vs After comparison** untuk validasi differencing
5. **Model order suggestion** berdasarkan cut-off patterns

**Expected Results After Good Differencing**:
- **STACF**: Rapid decay, clear cut-off untuk MA order
- **STPACF**: Clear cut-off untuk AR order  
- **Values**: Mayoritas dalam batas ±0.2
- **Seasonality**: Hilang atau minimal

**Model Identification Rules**:
```
STACF cut-off at lag q → MA(q) component
STPACF cut-off at lag p → AR(p) component
Both decay gradually → ARMA(p,q)
```

**Output**: 
- Plots STACF/STPACF yang "clean"
- Suggested model order: STARIMA(p,1,q)(P,1,Q)₁₂
- Confirmation bahwa data siap untuk modeling

**Mengapa Penting**: 
- **Validation** bahwa differencing strategy berhasil
- **Model selection** berdasarkan correlation patterns
- **Quality check** sebelum lanjut ke parameter estimation

---

## 08_Data_Centering.R
**Tujuan**: Centering data untuk menghilangkan bias spasial

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

## 09_STARIMA_Model.R
**Tujuan**: Training model STARIMA

**Cara Kerja**:
1. **Try different orders** (p,q) berdasarkan STACF/STPACF
2. **Test different spatial weights**
3. **Select best model** berdasarkan AIC/BIC
4. **Estimate parameters** menggunakan maximum likelihood

**Model STARIMA(p,q)**:
```
Φ(B,s)Zt = Θ(B,s)εt
dimana B = backshift operator, s = spatial lag
```

**Output**: Model STARIMA terbaik dengan parameter estimasi

**Mengapa Penting**: Inti dari analisis - model untuk prediksi

---

## 10_Residual_Analysis.R
**Tujuan**: Evaluasi kualitas model

**Cara Kerja**:
1. **Calculate residuals** dari model
2. **ACF/PACF residuals** - harus seperti white noise
3. **Ljung-Box test** - test independensi residual
4. **Normality test** - Shapiro-Wilk atau Jarque-Bera

**Output**: Plot diagnostik dan hasil test

**Mengapa Penting**: Validasi bahwa model sudah adequate

---

## 11_Forecasting.R
**Tujuan**: Prediksi curah hujan masa depan

**Cara Kerja**:
1. **Generate forecasts** menggunakan model STARIMA
2. **Calculate prediction intervals** (confidence bands)
3. **Multi-step ahead prediction**

**Output**: Forecast values dengan confidence intervals

**Mengapa Penting**: Tujuan utama - prediksi untuk planning

---

## 12_Inverse_Transform.R
**Tujuan**: Kembalikan hasil ke skala asli

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

## 13_Visualization.R
**Tujuan**: Visualisasi hasil akhir

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
00 → 01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13
```

**Urutan Terbaru**:
- **00**: Setup Library
- **01**: Load Data  
- **02**: Spatial Weights
- **03**: BoxCox Transform
- **04**: STACF/STPACF Before
- **05**: Stationarity Test
- **06**: Differencing
- **07**: STACF/STPACF After
- **08**: Data Centering
- **09**: STARIMA Model
- **10**: Residual Analysis
- **11**: Forecasting
- **12**: Inverse Transform
- **13**: Visualization

Setiap file bergantung pada output file sebelumnya, sehingga harus dijalankan berurutan.