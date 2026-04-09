# LithoGas

<!-- badges: start -->
![R](https://img.shields.io/badge/R-%3E%3D4.0-276DC3?logo=r&logoColor=white)
![License](https://img.shields.io/badge/License-CC%20BY--NC%204.0-lightgrey)
![Status](https://img.shields.io/badge/Status-In%20Development-yellow)
<!-- badges: end -->

**LithoGas** is an R package for Monte Carlo modelling of geologic hydrogen (H₂) and helium (He) production rates via radiolysis and serpentinization. It implements the methods of Warr et al. (2023) and Ardakani et al. (in review), extended to economic source area estimations and deep time production modelling.

---

## Overview

Geologic hydrogen and helium are generated in the deep subsurface through two primary mechanisms:

- **Radiolysis** — the splitting of water molecules into oxygen ions and H2 molecules by alpha, beta, and gamma radiation from the radioactive decay of U, Th, and K in surrounding minerals
- **Serpentinization** — oxidation of Fe²⁺ to Fe³⁺ during hydration of iron-rich rocks, releasing H₂

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

# Run Monte Carlo simulation with radiolysis (50 trials per sample)
results <- monteProd(lithCat, numGen = 50, rad = TRUE)

# Summarise results by sample
sumDF <- monteSum(results, summaryField = "Sample")

# Plot H2 production scaled by source rock volume
plots <- monteH2Plot(sumDF)
plots[[2]]  # view the ggplot2 object
```

---

## Core Workflow

```
Input dataframe      ← structured dataframe - see examples
      │
      ▼
 monteProd()      ← main wrapper; iterates over samples
      │
      ├──► joinLitProps()      ← function within monteProd() that assigns rock density & porosity from CRPPData
      │                          (when litLith provided, no sample data)
      │
      ├──► monteRad()      ← function within monteProd() that caluclates H2 & He production rates via radiolysis 
      │                      (when rad = TRUE)
      │
      └──► monteSerpFeSpecies()      ← function within monteProd() that calculates H2 production rates via serpentinization from geochemistry data with iron speciation
      │                                (when serp = TRUE)
      │
            └──► monteSerpFeSpecies()      ← function wihtin monteProd() that calculates H2 production rates via serpentinizationfrom geochemistry data with total iron concentration
      │                                      (when serp = TRUE and allowTotalFeSerp = TRUE)
      ▼
 monteSum()           ← summarises trials to min/mean/max per sample
      │
      ▼
 monteH2Plot()        ← log-log source volume plot for H2
 monteHePlot()        ← log-log source volume plot for He
```

---

## Functions

### Modelling

| Function | Description |
|---|---|
| `monteProd()` | Main Monte Carlo wrapper for radiolysis and serpentinization calculations. It runs radiolysis and/or serpentinization models over all samples present in the structured input dataframe. This function checks input samples for correct data availbility prior to completing calculations |
| `monteRad()` | Radiolysis model for H₂ and He production rates (Warr et al. 2023). Called internally by `monteProd()` |
| `monteSerpFeSpecies()` | Serpentinization model for iron speciation data (Fe₂O₃ & FeO). Called internally by `monteProd()` |
| `monteSerpFeTotal()` |  Serpentinization model for total iron concentration data (Fe₂O₃T). Called internally by `monteProd()` |
| `joinLitProps()` | Assigns rock density and porosity distributions from `CRPPData` by lithology. Called internally by `monteProd()` |
| `rtrunc()` | Generates random samples from a truncated normal (or any) distribution via the inverse CDF method |

### Summarising & Plotting

| Function | Description |
|---|---|
| `monteSum()` | Summarises Monte Carlo output to one row per sample (min/mean/max production rates) |
| `monteH2Plot()` | Log-log plot of H₂ production rate vs. source rock volume (0.1–100 km³) |
| `monteHePlot()` | Log-log plot of He production rate vs. source rock volume (0.1–100 km³) |

---

## Input Data

LithoGas accepts a structured dataframe where each row is one sample. All continuous parameters are defined as truncated normal distributions using four columns per variable: `Min`, `Max`, `Mean`, `SD`. One sample can represent a single geochemical analysis where standard deviation represents the analytical uncertainty, or a one sample can represent multiple geochemical analyses where the range represents the group parameters.

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
| All runs | `Sample`, `AgeMa`, `AgeUnc2S_Ma`, rock properties or `litLith`,  |
| Radiolysis (`rad = TRUE`) | Above + `uMin/Max/Mean/SD`, `thMin/Max/Mean/SD`, `kMin/Max/Mean/SD`, `fluDenMin/Max/Mean/SD` |
| Iron speciation serpentinization (`serp = TRUE`) | All Runs + `Fe2O3Min/Max/Mean/SD`, `FeOMin/Max/Mean/SD`, `Fe3FeTInitalRatMin/Max/Mean/SD` |
| Total iron serpentinization (`serp = TRUE` and `allowTotalFeSerp=TRUE`) | All Runs + `Fe2O3TMin/Max/Mean/SD`, `Fe3FeTInitalRatMin/Max/Mean/SD`, `Fe3FeTRatCurMin/Max/Mean/SD` |


Note: monteProd() evaluates each input row/sample for the presence of all required variables prior to performing calculations. It will not run functions where data is not present. As such, multiple methods (radiolysis only, radiolysis + iron speciation serpentinization) can be run from the same input datasheet, as per the example. 
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

| Column | Description | Units | Model |
|---|---|---|---|
| `RadMolsH2Rate` | Radiolytic H₂ production rate | mol H₂ / m³ rock / year | Radiolysis |
| `RadMolsHeRate` | Radiolytic He production rate | mol He / m³ rock / year | Radiolysis |
| `RadMassH2Rate` | Radiolytic He production rate | kg H₂ / m³ rock / year | Radiolysis |
| `RadMassHeRate` | Radiolytic He production rate | kg He / m³ rock / year | Radiolysis |
| `RadMolH2` | Cumulative radiolytic H₂ production over sample age | mol H₂ | Radiolysis |
| `RadMolHe` | Cumulative radiolytic He production over sample age | mole He | Radiolysis |
| `RadMassH2` | Cumulative radiolytic H₂ production over sample age | kg H₂ | Radiolysis |
| `RadMolHe` | Cumulative radiolytic He production over sample age | kg He | Radiolysis |
| `SerpMolH2` | Cumulative serpentinization H₂ production over sample age | mol H₂ | Serpentinization |
| `SerpMassH2` | Cumulative serpentinization H₂ production over sample age | mass H₂ | Serpentinization |
| `SerpMassH2Rate` | Serpentinization H₂ production rate | mol H₂ / m³ rock / year  | Serpentinization |
| `SerpMolH2Rate` | Serpentinization H₂ production rate | kg H₂ / m³ rock / year  | Serpentinization |

---

## Citation

If you use LithoGas in your research, please cite:
> Coutts, D.S., Warr, O.A., Ardakani, O.A., Sherwood Lollar, B. *(in review)*

The serpentininzation model is based on:
> Ardakani, O.A., Sherwood Lollar, B., Coutts, D.S., Warr, O.A., Delonde, C., Kabanov, P., Lister, C. *(in review)*

The radiolysis model is based on:
> Warr, O., Song, M., Sherwood Lollar, B. (2023). The application of Monte Carlo modelling to quantify in situ hydrogen and associated element production in the deep subsurface. *Frontiers in Earth Science*, v.11.

Rock property data sourced from:
> Enkin, R.J. (2018). The Canadian Rock Physical Property Database: first public release. *Geological Survey of Canada*, Open File 8460, 68 p. Natural Resources Canada. https://ostrnrcan-dostrncan.canada.ca/entities/publication/c4c0cede-365c-4c87-8077-8e045e874de6

---

## Authors

- **Daniel Coutts** — Geological Survey of Canada, Natural Resources Canada (daniel.coutts@nrcan-rncan.gc.ca)
- **Oliver Warr** — University of Toronto
- **Omid Ardakani** — Geological Survey of Canada,  Natural Resources Canada
- **Barbara Sherwood Lollar** — University of Toronto

---

## License

This package is licensed under [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/) — free for non-commercial use with attribution.
