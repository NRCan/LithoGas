#' @keywords internal
#' @importFrom utils data
#' @importFrom stats rnorm runif sd
#' @importFrom dplyr filter select bind_rows group_by summarize mutate left_join all_of across where
#' @importFrom ggplot2 ggplot aes geom_line geom_ribbon theme_bw xlab ylab
#'   scale_x_log10 scale_y_continuous sec_axis labs scale_y_log10
#' @importFrom rlang sym
#' @importFrom magrittr %>%
"_PACKAGE"

utils::globalVariables(c(
  # Datasets
  "CRPPData", "structuredDF",

  # Sample identifiers
  "Lithology",  "Sample", "AgeMa",  "AgeUnc2S_Ma",  "Age",

  # Rock properties
  "rockDen", "rockDenMin", "rockDenMax", "rockDenMean", "rockDenSD",
  "porosity", "porMin", "porMax", "porMean", "porSD",

  # Radiolysis related - monteRad()
  "uMin", "uMax", "uMean", "uSD",
  "thMin", "thMax", "thMean", "thSD",
  "kMin", "kMax", "kMean", "kSD",
  "EKA", "EKB", "EKG",
  "EThA", "EThB", "EThG",
  "EUA", "EUB", "EUG",
  "ENetA", "ENetB", "ENetG",
  "sysDen",  "W","YH2A", "YH2B", "YH2G",
  "RadH2Rate_molm3yr", "RadHeRate_molm3yr", "RadH2_molm3", "RadHe_molm3",

  # Serpentinization related - monteSerpFeSpecies() & monteSerpFeTotal()
  "Fe2O3Min", "Fe2O3Max", "Fe2O3Mean", "Fe2O3SD",
  "Fe2O3TMin", "Fe2O3TMax", "Fe2O3TMean", "Fe2O3TSD",
  "FeOMin", "FeOMax", "FeOMean", "FeOSD",
  "Fe3FeTInitalRatMin", "Fe3FeTInitalRatMax",
  "Fe3FeTInitalRatMean", "Fe3FeTInitalRatSD",
  "Fe3FeTRatCurMin", "Fe3FeTRatCurMax",
  "Fe3FeTRatCurMean", "Fe3FeTRatCurSD",
  "mass",
  "SerpH2_molm3", "SerpH2Rate_molm3yr",

  #monteSum()
  "sampleField",
  "SerpH2RateMin_molm3yr", "SerpH2RateMean_molm3yr", "SerpH2RateMax_molm3yr",
  "RadH2RateMin_molm3yr","RadH2RateMean_molm3yr","RadH2RateMax_molm3yr",
  "H2RateMin_molm3yr",  "H2RateMean_molm3yr",  "H2RateMax_molm3yr",
  "RadHeRateMin_molm3yr","RadHeRateMean_molm3yr","RadHeRateMax_molm3yr",
  "RadHeMax_molm3yr",  "HeRateMin_molm3yr",  "HeRateMean_molm3yr","HeRateMax_molm3yr",

  #plotting - monteH2Plot() and monteHePlot()
  "vol_km",  "colorField",
  "H2RateMin_molyr", "H2RateMean_molyr", "H2RateMax_molyr",
  "HeRateMin_molyr", "HeRateMean_molyr", "HeRateMax_molyr"

))
