# LithoGas

<!-- badges: start -->
![R](https://img.shields.io/badge/R-%3E%3D4.0-276DC3?logo=r&logoColor=white)
![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow)
<!-- badges: end -->

**LithoGas** is an R package for Monte Carlo modelling of geologic hydrogen (H₂) and helium (He) production rates via radiolysis and serpentinization. It implements the methods of Warr et al. (2023) and Ardakani et al. (2026), extended to economic source area estimations and deep time production modelling.

---

## Overview

Geologic hydrogen and helium are generated in the deep subsurface through two primary mechanisms:

- **Radiolysis** — water splitting driven by alpha, beta, and gamma radiation from the radioactive decay of U, Th, and K in surrounding rocks
- **Serpentinization** — oxidation of Fe²⁺ to Fe³⁺ (as magnetite, Fe₃O₄) during hydration of ultramafic rocks, releasing H₂ stoichiometrically

LithoGas propagates measurement uncertainties through both models using Monte Carlo simulation, producing distributions of production rates rather than single-point estimates. Results can be scaled to arbitrary source rock volumes for economic feasibility assessment.

---

## Installation

LithoGas is not yet on CRAN. Install directly from GitHub:

```r
# install.packages("devtools")
devtools::install_github("yourusername/LithoGas")
```

---

## Quick Start

```r
library(LithoGas)

# Load the example dataset (lithology-based rock properties)
data("monteDataLithCat")

# Run Monte Carlo simulation with radiolysis (500 trials per sample)
results <- monteProd(lithCat, numGen = 500, rad = TRUE)

# Summarise results by sample
sumDF <- monteSum(results, summaryField = "Sample")

# Plot H2 production scaled by source rock volume
plots <- monteH2Plot(sumDF)
plots[[2]]  # view the ggplot2 object
```

---

## Core Workflow

```
Input dataframe
      │
      ▼
 monteProd()          ← main wrapper; iterates over samples
      │
      ├──► joinLitProps()     ← assigns rock density & porosity from CRPPData
      │                          (when litLith provided, no sample data)
      │
      ├──► monteRad()         ← radiolysis H2 & He production rates
      │                          (when rad = TRUE)
      │
      └──► monteSerpFeSpecies()  ← serpentinization H2 production rates
                                    (when serp = TRUE)
      │
      ▼
 monteSum()           ← summarises trials to min/mean/max per sample
      │
      ▼
 monteH2Plot()        ← log-log source area plot for H2
 monteHePlot()        ← log-log source area plot for He
```

---

## Functions

### Modelling

| Function | Description |
|---|---|
| `monteProd()` | Main Monte Carlo wrapper. Runs radiolysis and/or serpentinization models over all samples in a structured input dataframe |
| `monteRad()` | Radiolysis model for H₂ and He production rates (Warr et al. 2023). Called internally by `monteProd()` |
| `monteSerpFeSpecies()` | Serpentinization model using iron speciation data (Fe₂O₃ + FeO). Called internally by `monteProd()` |
| `joinLitProps()` | Assigns rock density and porosity distributions from `CRPPData` by lithology. Called internally by `monteProd()` |
| `rtrunc()` | Generates random samples from a truncated normal (or any) distribution via the inverse CDF method |

### Summarising & Plotting

| Function | Description |
|---|---|
| `monteSum()` | Summarises Monte Carlo output to one row per sample (min/mean/max production rates) |
| `monteH2Plot()` | Log-log source area plot of H₂ production rate vs. source rock volume (0.1–100 km³) |
| `monteHePlot()` | Log-log source area plot of He production rate vs. source rock volume (0.1–100 km³) |

---

## Input Data

LithoGas accepts a structured dataframe where each row is one sample. All continuous parameters are defined as truncated normal distributions using four columns per variable: `Min`, `Max`, `Mean`, `SD`.

Two approaches are supported for rock properties:

**Option 1 — Sample-specific rock properties** (use `monteDataRockProps` as a template)

Provide `rockDenMin/Max/Mean/SD` and `porMin/Max/Mean/SD` directly in your input dataframe.

**Option 2 — Lithology-based rock properties** (use `monteDataLithCat` as a template)

Provide a `litLith` column matching a lithology in `CRPPData`. Rock density and porosity distributions are looked up automatically.

```r
# View available lithologies
data("CRPPData")
unique(CRPPData$Lithology)
```

### Required columns by model

| Model | Required columns |
|---|---|
| All runs | `Sample`, `AgeMa`, `AgeUnc2S_Ma`, rock properties or `litLith`, `fluDenMin/Max/Mean/SD` |
| Radiolysis (`rad = TRUE`) | Above + `uMin/Max/Mean/SD`, `thMin/Max/Mean/SD`, `kMin/Max/Mean/SD` |
| Serpentinization (`serp = TRUE`) | Above + `Fe2O3Min/Max/Mean/SD`, `FeOMin/Max/Mean/SD`, `Fe3FeTInitalRatMin/Max/Mean/SD` |

A blank input template is included in the package:

```r
# Copy the input template to your working directory
file.copy(system.file("extdata", "inputTemplate.csv", package = "LithoGas"), ".")
```

---

## Datasets

| Dataset | Description |
|---|---|
| `monteDataLithCat` | Example input using lithology-based rock properties from `CRPPData` |
| `monteDataRockProps` | Example input using sample-specific rock property distributions |
| `CRPPData` | Summarised Canadian Rock Physical Property Database (Enkin 2018), grouped by lithology |

---

## Output

`monteProd()` returns a long-format dataframe with `numGen` rows per sample, containing all input columns plus computed outputs. Key output columns:

| Column | Description | Units |
|---|---|---|
| `RadMolsH2Rate` | Radiolytic H₂ production rate | mol H₂ / m³ rock / year |
| `RadMolsHeRate` | Radiolytic He production rate | mol He / m³ rock / year |
| `SerpMolH2Rate` | Serpentinization H₂ production rate | mol H₂ / m³ rock / year |
| `RadMolH2` | Cumulative radiolytic H₂ over sample age | mol H₂ / m³ rock |
| `SerpMolH2` | Cumulative serpentinization H₂ over sample age | mol H₂ / m³ rock |

---

## Citation

If you use LithoGas in your research, please cite:

> Ardakani, O.A., Sherwood Lollar, B., Coutts, D.S., Warr, O.A., Delonde, C., Kabanov, P., Lister, C. (2026). *(full citation pending publication)*

The radiolysis model is based on:

> Warr, O., Song, M., Sherwood Lollar, B. (2023). The application of Monte Carlo modelling to quantify in situ hydrogen and associated element production in the deep subsurface. *Frontiers in Earth Science*, v.11.

Rock property data sourced from:

> Enkin, R.J. (2018). The Canadian Rock Physical Property Database: first public release. *Geological Survey of Canada*, Open File 8460, 68 p. Natural Resources Canada. https://ostrnrcan-dostrncan.canada.ca/entities/publication/c4c0cede-365c-4c87-8077-8e045e874de6

---

## Authors

- **Daniel Coutts** — Natural Resources Canada (daniel.coutts@nrcan-rncan.gc.ca)
- **Oliver Warr** — University of Toronto
- **Omid Ardakani** — Natural Resources Canada
- **Barbara Sherwood Lollar** — University of Toronto

---

## License

This package is licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) — free for non-commercial use with attribution.
