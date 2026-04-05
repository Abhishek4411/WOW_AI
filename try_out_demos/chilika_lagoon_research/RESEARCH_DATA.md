# Research on Integrating Remote Sensing and Machine Learning for Water Quality Monitoring in Chilika Lagoon, India

## Overview and Background
Remote sensing and machine learning (ML) have been increasingly applied for efficient, cost-effective, and comprehensive water quality monitoring in Chilika Lagoon, India's largest coastal lagoon and a Ramsar site of international ecological significance. Traditional in situ water quality monitoring methods are labor intensive and time consuming, thus motivating the integration of satellite-based remote sensing data with advanced ML algorithms to assess and predict water quality parameters such as chlorophyll-a (Chl-a), turbidity, and total suspended solids (TSS).

## Satellite Data and Spectral Indices
Several studies from 2019 to 2024 have leveraged multi-temporal satellite imagery, particularly from Landsat 8-9 and Sentinel-2 missions, alongside spectral indices such as:
- Normalized Difference Turbidity Index (NDTI)
- Normalized Difference Chlorophyll Index (NDCI)
- Automatic Water Extraction Index (AWEI)
These indices derived from reflectance in specific spectral bands enable estimation and mapping of key water quality indicators including turbidity, Chl-a concentration, and suspended sediments.

## Machine Learning Approaches
Multiple ML algorithms have been employed to analyze remote sensing data and generate reliable water quality models:
- Artificial Neural Networks (ANN), specifically MultiLayer Perceptron (MLP)
- Random Forest (RF)
- Support Vector Machines (SVM)
- Bagging Regression
- Extreme Gradient Boost
- Support Vector Regression

### Comparative Performance
- ANN models have demonstrated superior capability to model complex nonlinear relationships in water quality parameters, often outperforming RF and SVM in accuracy and precision for ecosystem mapping.
- Random Forest showcases robustness to overfitting, handles high-dimensional data well, and is highly accurate in classification and regression tasks related to water quality.
- SVM models offer strong performance for pattern recognition in water quality assessment, particularly effective with smaller data samples and high-dimensional feature spaces.
- Specific studies report metrics such as:
   - ANN reaching accuracy of up to 96% and correlation coefficient of 0.985 for water quality prediction
   - RF achieving accuracies of 86.67% and sometimes near 100% with feature optimization
   - SVM demonstrating prediction accuracies over 80% and sometimes highest accuracy of 95.4% in water quality index estimation

## Key Research Highlights
### Study 1: Ex Situ Water Quality Monitoring Using Google Earth Engine and Spectral Indices (2024, MDPI)
- Utilized Google Earth Engine (GEE) platform and spectral indices (NDTI, NDCI, AWEI) with Landsat data for monitoring turbidity, chlorophyll-a concentration, and suspended sediment dynamics from 2019 to 2021.
- Findings indicated increased turbidity (NDTI) over the years and effective detection of floating algal blooms and pollution sources.
- Demonstrated utility of satellite-based indices to support sustainable lagoon management.
- URL: https://www.mdpi.com/2220-9964/13/11/381

### Study 2: Artificial Neural Networks for Mapping Chilika Lagoon Using Earth Observation Data (April 2024, MDPI)
- Applied ML classifiers including ANN (MLP), RF, and SVM to Landsat 8-9 OLI/TIRS images for environmental mapping of land cover classes around Chilika Lagoon from 2019 to 2024.
- ANN model delivered superior accuracy and precision in multi-class land cover classification.
- Classified ten distinct land cover types and analyzed spatio-temporal changes related to eutrophication, coastal erosion, and microplastic pollution.
- Used GRASS GIS for image analysis and visualization.
- URL: https://www.mdpi.com/2077-1312/12/5/709

### Study 3: Comparative Analysis of ML Models for Water Quality Prediction
- Surveyed application of ANN, RF, and SVM in water quality monitoring.
- ANN noted for modeling non-linear relationships effectively with high accuracy and correlation.
- RF praised for robustness and high classification accuracy.
- SVM acknowledged for good generalization in small datasets and high-dimensional features.
- Reported metrics include prediction accuracies of 72%-96% for ANN, 86%-100% for RF, and 80%-95.4% for SVM across different water quality parameters.
- Rationale for algorithm selection depends on dataset properties, parameter focus, and prediction vs classification tasks.
- URL references include NIH, MDPI, IEEE Xplore, and other academic publisher sources.

### Study 4: Applications of ANN in Water Quality Index Prediction (Conference, IEEE)
- Demonstrated ANN's efficacy in rapid computation of Water Quality Index (WQI) with predictive accuracy reaching 96%.
- Highlighted ANN's potential to replace traditional hydro-chemical analyses for quick, cost-effective water monitoring.
- URL: https://ieeexplore.ieee.org/document/10199388

## Methodologies and Data
- Use of multi-year Landsat 8-9 and Sentinel-2 satellite image time series from 2019 to 2024
- Calculation of spectral indices sensitive to specific water quality parameters 
- Machine learning image classification and regression models trained and validated on satellite-derived spectral datasets
- Comparative model evaluation using metrics such as overall accuracy, precision, recall, F1-score, Kappa coefficient, RMSE, and R-squared
- Visualization and mapping using GIS software such as GRASS GIS and Google Earth Engine dashboards

## Summary
The integration of remote sensing satellite data with machine learning techniques offers a potent toolset for continuous, scalable, and accurate water quality monitoring in complex ecosystems like Chilika Lagoon. ANN-based models demonstrate strong performance in mapping and prediction, RF models offer robustness and ease of use, while SVM complements with strong generalization capabilities particularly in small datasets. Spectral indices derived from Landsat and Sentinel imagery effectively capture key water quality metrics, enabling ex situ monitoring of turbidity, chlorophyll concentration, and suspended sediments. The reviewed studies collectively advance cost-effective and scalable approaches supporting sustainable management, conservation, and environmental protection of Chilika Lagoon.

---

*This document will be updated as more detailed full-text sources are accessed and analyzed for additional findings, datasets, and metrics.*
