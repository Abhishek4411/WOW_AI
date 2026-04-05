# Chapter 3: Satellite Data and Spectral Indices

## 3.1 Satellite Platforms and Sensors for Water Quality Monitoring

Monitoring water quality in complex coastal ecosystems such as Chilika Lagoon demands high-resolution, multi-temporal satellite data capable of capturing dynamic environmental changes. Among various remote sensing platforms, the Landsat 8 and 9 satellites, and the Sentinel-2 constellation have emerged as pivotal tools for aquatic ecological assessment due to their spectral, spatial, and temporal capabilities.

### 3.1.1 Landsat 8 and 9

Landsat 8 and Landsat 9 operate with the Operational Land Imager (OLI) and Thermal Infrared Sensor (TIRS), providing multispectral data across visible, near-infrared (NIR), and shortwave infrared (SWIR) bands at 30-meter spatial resolution, with thermal bands at 100 meters resampled to 30 meters (MDPI, 2024). The revisit period is 16 days per satellite, collectively offering an 8-day revisit with both operating. Their spectral bands are tailored for terrestrial and aquatic applications, capable of detecting surface reflectance variations linked to biological and physical water parameters.

These satellites have been extensively used to derive spectral indices sensitive to turbidity, chlorophyll-a concentration, and suspended sediments, crucial for monitoring eutrophication, sediment loads, and algal blooms (MDPI, 2024; IEEE, 2024). Landsat data are open-access, enabling long-term environmental monitoring and comparative studies across years.

### 3.1.2 Sentinel-2

The Sentinel-2 constellation, operated by the European Space Agency, comprises two satellites (Sentinel-2A and 2B) with multispectral imagers capturing 13 spectral bands from visible to shortwave infrared with spatial resolutions of 10, 20, and 60 meters. Sentinel-2 provides heightened temporal resolution with a revisit period of 5 days at the equator when considering both satellites, enabling finer temporal granularity crucial for tracking rapid changes in water quality (MDPI, 2024).

Sentinel-2's higher spatial resolution in the visible and NIR bands facilitates distinction of subtle spectral variations indicative of water constituents. Its data synergy with Landsat extends analytical robustness, allowing cross-validation and improved temporal coverage in water quality assessments (MDPI, 2024).

## 3.2 Multi-temporal Satellite Imagery

Utilization of multi-temporal imagery spanning multiple years (2019-2024) forms the backbone of time-series analysis in Chilika Lagoon monitoring efforts. Analysis of seasonal and inter-annual variability relies on consistent spectral data, permitting the detection of trends, episodic events, and anthropogenic impacts on water quality (MDPI, 2024). Both Landsat and Sentinel provide such temporal depth, which is vital for ecosystem dynamics assessments and management decision support.

## 3.3 Preprocessing Techniques

Effective application of satellite data for water quality necessitates preprocessing steps including atmospheric correction, radiometric calibration, and geometric correction to ensure accuracy and comparability. Atmospheric correction algorithms mitigate the effects of aerosols, water vapor, and solar angle variations, standardizing reflectance values critical for spectral index computation (MDPI, 2024).

Cloud masking, band resampling, and mosaicking further enhance data quality for temporal analyses. Both Landsat and Sentinel datasets benefit from publicly available preprocessing toolkits like Google Earth Engine and GRASS GIS, which have been employed in Chilika studies (MDPI, 2024).

## 3.4 Spectral Bands Relevant to Water Quality

Key spectral bands leveraged from these satellites include:
- Blue (450-510 nm): Sensitive to suspended sediments and turbid waters
- Green (530-590 nm): Proxy for chlorophyll content
- Red (640-670 nm): Crucial for vegetation and algal detection
- Near Infrared (NIR) (850-880 nm): Sensitive to biomass and organic matter
- Shortwave Infrared (SWIR) (1550-1750 nm): Useful for sediment moisture and water absorption characteristics

Integration of these bands allows computation of spectral indices tailored for specific water quality parameters.

---

# 3.5 Spectral Indices for Water Quality Assessment

Spectral indices provide normalized reflectance measures that enhance discrimination of water constituents by reducing external noise such as illumination and background reflectance. They are critical in remote sensing of aquatic environments for quantifying parameters like turbidity, chlorophyll-a concentration, and suspended sediments.

## 3.5.1 Normalized Difference Turbidity Index (NDTI)

The Normalized Difference Turbidity Index (NDTI) exploits reflectance differences between red and green bands to estimate turbidity—a key indicator of suspended particulate matter in water (MDPI, 2024). It is computed as:

\[ NDTI = \frac{R_{red} - R_{green}}{R_{red} + R_{green}} \]

where \(R_{red}\) and \(R_{green}\) are surface reflectance in the red and green bands respectively. Elevated NDTI values correlate with higher turbidity, facilitating spatial mapping of sediment plumes, runoff impacts, and pollution sources (MDPI, 2024).

## 3.5.2 Normalized Difference Chlorophyll Index (NDCI)

The Normalized Difference Chlorophyll Index (NDCI) is tailored to chlorophyll-a detection by leveraging the red and NIR bands' reflectance contrast, sensitive to chlorophyll pigmentation in phytoplankton and algal biomass (MDPI, 2024). NDCI is calculated as:

\[ NDCI = \frac{R_{NIR} - R_{red}}{R_{NIR} + R_{red}} \]

where \(R_{NIR}\) and \(R_{red}\) are reflectance in the near-infrared and red bands. This index effectively captures chlorophyll dynamics, crucial for monitoring eutrophication, algal blooms, and overall aquatic health (MDPI, 2024; IEEE, 2024).

## 3.5.3 Automatic Water Extraction Index (AWEI)

The Automatic Water Extraction Index (AWEI) improves water body delineation in turbid or mixed pixels by combining multiple spectral bands, minimizing errors from shadows, dark soils, and vegetation (MDPI, 2024). The AWEI formula commonly used is:

\[ AWEI = 4(R_{green} - R_{SWIR1}) - (0.25 R_{NIR} + 2.75 R_{SWIR2}) \]

where bands correspond to green, near-infrared, and two shortwave infrared bands. AWEI enhances classification accuracy in mapping water extent, supporting water quality assessments by precisely identifying water bodies (MDPI, 2024).

## 3.6 Derivation and Sensitivities

The derivation of these indices relies on the spectral absorption and scattering properties of water constituents. Suspended sediments increase reflectance in red and green bands, captured by NDTI. Chlorophyll absorbs visible red light but reflects NIR, making NDCI effective for chlorophyll estimation. AWEI integrates multiple bands to reduce confounding effects from land-water boundaries and adjacency. Sensitivity analyses in Chilika Lagoon demonstrate these indices' robustness across varying seasons and water conditions (MDPI, 2024).

## 3.7 Applications in Chilika Lagoon

Studies using these indices on Landsat and Sentinel imagery have demonstrated spatial and temporal variability of key water quality metrics in Chilika Lagoon. For instance, NDTI trends have revealed increasing turbidity influenced by sediment inflows and anthropogenic activities (MDPI, 2024). NDCI facilitated detection of algal blooms indicative of eutrophication events, while AWEI's improved water masking supported accurate mapping for ecosystem management.

Satellite-based spectral indices combined with machine learning algorithms have been instrumental in downscaling water quality predictions to localized lagoon zones, thereby directing conservation efforts and informing policy decisions (MDPI, 2024; IEEE, 2024).

---

## 3.8 Summary

The Landsat 8-9 and Sentinel-2 satellites provide complementary capabilities in spatial resolution and revisit frequency, essential for continuous water quality monitoring in Chilika Lagoon. Spectral indices such as NDTI, NDCI, and AWEI, derived from these satellites’ spectral bands, enable refined estimation of turbidity, chlorophyll concentration, and water extent, forming the analytical foundation for remote sensing-based aquatic ecosystem assessment.

The integration of multi-temporal satellite data, spectral indices, and preprocessing methodologies facilitates robust, scalable, and cost-effective monitoring frameworks that underpin advanced machine learning models described in subsequent chapters. These remote sensing tools collectively enhance understanding of environmental dynamics and support sustainable management of the Chilika Lagoon ecosystem.

---

### References

- MDPI, 2024. Remote Sensing and Machine Learning for Water Quality Monitoring in Chilika Lagoon. MDPI Journals.
- IEEE, 2024. Applications of Artificial Neural Networks for Water Quality Index Prediction. IEEE Xplore.
