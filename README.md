# Ganga Basin Rainfall Analysis

Computational hydrological analysis of long-term rainfall over the Ganga River Basin using IMD high-resolution gridded data and MATLAB — spatial filtering, trend analysis, extreme-event detection, and future projection over the 2015–2024 decade.

## Overview

Processes 10 years (2015–2024) of IMD 0.25° × 0.25° daily gridded rainfall data for the Ganga Basin (a 64 × 41 × 3,653 lon–lat–time grid). The workflow loads and aggregates yearly NetCDF files, computes basin-average daily and annual rainfall, fits linear and polynomial trends, flags extreme-rainfall days, and visualizes the spatial distribution of rainfall.

## Dataset

- **Source:** India Meteorological Department (IMD) — High-Resolution (0.25° × 0.25°) Daily Gridded Rainfall
- **Files:** `RF25ind<YEAR>_rfp25.nc`, one per year (2015–2024)
- **Basin extent (bounding box):** 73°2′E – 89°5′E, 21°6′N – 31°21′N

> The raw NetCDF files are **not** included in this repository (large; available from the [IMD portal](https://mausam.imd.gov.in/)). Place the yearly files in the working directory before running.

## Method

| Stage | Description |
|-------|-------------|
| Spatial filtering | Slice the national IMD grid to the Ganga Basin bounding box |
| Multi-year aggregation | Concatenate yearly NetCDF files; handles the `rf` / `RAINFALL` variable-name difference across IMD releases |
| Basin averaging | Daily basin-mean rainfall with `omitnan` to exclude ocean/fill cells |
| Trend analysis | Linear (`polyfit` deg 1) and 2nd-degree polynomial fits on annual totals |
| Extreme events | Days exceeding the 95th-percentile daily-rainfall threshold |
| Projection | Extrapolation to 2025–2027 (linear and polynomial models) |

## Key Findings (2015–2024)

- Linear rainfall trend: **+19.10 mm/year**
- 95th-percentile extreme threshold: **12.41 mm/day**
- Extreme-rainfall days over the decade: **183**
- Rainfall concentrated over the northern and eastern basin (Himalayan and Bay-of-Bengal influence)

> Projections are simple statistical extrapolations of a 10-year record, not climate forecasts. A 10-year window is short for robust climatic trends (30+ years is standard); see the Assumptions & Limitations section of the report.

## Running

1. MATLAB R2018b or later (uses `ncread`, `polyfit`, `prctile`).
2. Place the yearly `RF25ind<YEAR>_rfp25.nc` files in the project directory.
3. Open and run `Ganga_Basin_Analysis.m`. Update the `filename` path at the top if your data sits elsewhere.

## Files

| File | Description |
|------|-------------|
| `Ganga_Basin_Analysis.m` | Full analysis script |
| `Ganga_Basin_Analysis.docx` | Project report with figures and discussion |

## Author

Rishit Bhardwaj — B.Tech Civil Engineering, IIT (ISM) Dhanbad
