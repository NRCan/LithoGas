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
  "CRPPData", "structuredDF", "modelDF",

  # Sample identifiers
  "Lithology",  "Sample",  "mass",  "volume",  "sysDen",

  # Age
  "AgeMa",  "AgeUnc2S_Ma",  "Age",

  # Rock properties
  "rockDen", "rockDenMin", "rockDenMax", "rockDenMean", "rockDenSD",
  "porosity", "porMin", "porMax", "porMean", "porSD",

  # Radiolysis related
  "uMin", "uMax", "uMean", "uSD",
  "thMin", "thMax", "thMean", "thSD",
  "kMin", "kMax", "kMean", "kSD",
  "EKA", "EKB", "EKG",
  "EThA", "EThB", "EThG",
  "EUA", "EUB", "EUG",
  "ENetA", "ENetB", "ENetG",
  "W","YH2A", "YH2B", "YH2G",
  "RadMassH2Rate", "RadMolsH2Rate",
  "RadH2Min", "RadH2Mean", "RadH2Max",
  "RadMassHeRate", "RadMolsHeRate",
  "RadHeMin", "RadHeMean", "RadHeMax", "RadMolH2Rate", "RadMolHeRate",  "RadMassH2Rate", "RadMassHeRate",

  # Serpentinization related
  "Fe2O3Min", "Fe2O3Max", "Fe2O3Mean", "Fe2O3SD",
  "Fe2O3TMin", "Fe2O3TMax", "Fe2O3TMean", "Fe2O3TSD",
  "FeOMin", "FeOMax", "FeOMean", "FeOSD",
  "Fe3FeTInitalRatMin", "Fe3FeTInitalRatMax",
  "Fe3FeTInitalRatMean", "Fe3FeTInitalRatSD",
  "Fe3FeTRatCurMin", "Fe3FeTRatCurMax",
  "Fe3FeTRatCurMean", "Fe3FeTRatCurSD",
  "SerpRateMolH2",
  "SerpH2Min", "SerpH2Mean", "SerpH2Max", "SerpMolH2Rate", "SerpMassH2Rate",

  # H2 outputs
  "H2total",  "meanH2", "minH2", "maxH2", "H2RateMin",  "H2RateMean", "H2RateMax",

  # He outputs
  "Hetotal",  "meanHe", "minHe", "maxHe", "HeRateMin", "HeRateMean", "HeRateMax",

  #Plotting and summary
  "colorField", "vol"
))
