#' @title monteSerpFeSpecies
#'
#' @description
#' Computes hydrogen production rates via serpentinization for a set of
#' Monte Carlo trials, using measured iron speciation data (Fe\eqn{_2}O\eqn{_3}
#' and FeO). The change in Fe\eqn{^{3+}}/Fe\eqn{_T} ratio between initial
#' (pre-serpentinization) and current states is used to estimate the mass of
#' magnetite (Fe\eqn{_3}O\eqn{_4}) produced and the associated hydrogen yield.
#'
#' @details
#' The function generates Monte Carlo distributions for Fe\eqn{_2}O\eqn{_3}
#' and FeO from truncated normal distributions, then calculates the current
#' Fe\eqn{^{3+}}/Fe\eqn{_T} ratio (\code{Fe3FeTRatCur}). An initial
#' Fe\eqn{^{3+}}/Fe\eqn{_T} ratio (\code{Fe3FeTInitalRat}) is also sampled,
#' constrained to not exceed the current ratio (i.e. oxidation state can only
#' increase during serpentinization).
#'
#' The difference between current and initial Fe\eqn{^{3+}}/Fe\eqn{_T}
#' (\code{Fe3FeTRatDiff}) is used to calculate the mass of Fe\eqn{_3}O\eqn{_4}
#' produced per unit volume of rock (\code{Fe3O4Diff_wt}), from which
#' hydrogen moles are derived stoichiometrically
#' (1 Fe\eqn{_3}O\eqn{_4} \eqn{\rightarrow} 1 H\eqn{_2}).
#'
#' Rock density is converted from g/cm\eqn{^3} to kg/m\eqn{^3} internally.
#' Production rates are normalised by sample age (\code{Age} in Ma).
#'
#' This function is called internally by \code{\link{monteProd}} when
#' \code{serp = TRUE} and all required iron speciation columns are present.
#'
#' @param DF A data frame of Monte Carlo trials (\code{numGen} rows) for a
#'   single sample, as produced by \code{\link{monteProd}}. Must contain
#'   iron speciation columns (Fe\eqn{_2}O\eqn{_3} and FeO min/max/mean/SD),
#'   initial Fe\eqn{^{3+}}/Fe\eqn{_T} columns, rock density (\code{rockDen}),
#'   and age (\code{Age}).
#' @param numGen Integer. Number of Monte Carlo simulations. Must match
#'   \code{nrow(DF)}.
#'
#' @return A data frame with \code{numGen} rows containing computed
#'   serpentinization variables. Input columns from \code{DF} are removed;
#'   only newly computed columns are returned for binding by
#'   \code{\link{monteProd}}. Key output columns include:
#'   \describe{
#'     \item{\code{SerpMolH2Rate}}{Hydrogen production rate
#'       (mol H\eqn{_2} / m\eqn{^3} rock / year).}
#'     \item{\code{SerpMassH2Rate}}{Hydrogen production rate
#'       (kg H\eqn{_2} / m\eqn{^3} rock / year).}
#'     \item{\code{SerpMolH2}}{Cumulative hydrogen production
#'       (mol H\eqn{_2} / m\eqn{^3} rock) over sample age.}
#'     \item{\code{SerpMassH2}}{Cumulative hydrogen mass
#'       (kg H\eqn{_2} / m\eqn{^3} rock) over sample age.}
#'     \item{\code{SerpModel}}{Character label: \code{"Fe Species Serp"} to denote allow for filtering of results to one type of model or another.}
#'   }
#'
#' @references
#' Ardakani, O.A., Sherwood Lollar, B., Coutts, D.S., Warr, O.A., et al. (2026).
#'
#' @seealso \code{\link{monteProd}}, \code{\link{monteSerpFeTotal}},
#'   \code{\link{rtrunc}}
#'
#' @examples
#' data("structuredDF")
#' df <- monteProd(structuredDF[2,], numGen = 50, serp = TRUE)
#'
#' @export
monteSerpFeSpecies <- function(DF,numGen){

  initColnames <- colnames(DF)
  #First bit of iron ratios stuff
  Fe2O3 <- as.data.frame(rtrunc(numGen,  #Generate a distribution of measured Fe2O3 based on measurement uncertianty
                                "norm",
                                lower = unique(DF$Fe2O3Min),
                                upper = unique(DF$Fe2O3Max),
                                mean = unique(DF$Fe2O3Mean),
                                sd = unique(DF$Fe2O3SD)))
  colnames(Fe2O3) <-"Fe2O3" #update column name

  FeO <- as.data.frame(rtrunc(numGen,  #Generate a distribution of measured FeO based on measurement uncertainty
                              "norm",
                              lower = unique(DF$FeOMin),
                              upper = unique(DF$FeOMax),
                              mean = unique(DF$FeOMean),
                              sd = unique(DF$FeOSD)))
  colnames(FeO) <-"FeO" #update column name

  DF <- cbind(DF,Fe2O3,FeO) #bind all information into one dataframe

  DF$FeT <- (DF$Fe2O3*0.69943) + (DF$FeO*0.77731) #calculate total Fe wt% from Fe2O3 and FeO converting to Fe and summing
  DF$Fe3FeTRatCur <- (DF$Fe2O3*0.69943)/DF$FeT #calculate current Fe3+ / FeT ratio
  Fe3FeTInitalRat <- as.data.frame(rtrunc(numGen,  #Generate a distribution of initial Fe3+/FeT ratio taking into account the current Fe3/FeT
                                          "norm",
                                          lower = min(unique(DF$Fe3FeTInitalRatMin), unique(DF$Fe3FeTRatCur))-0.001, #LB, best guess or the current value (if unaltered)
                                          upper = min(unique(DF$Fe3FeTInitalRatMax), unique(DF$Fe3FeTRatCur))+0.001, #UB, best guess or the current value (if unaltered)
                                          mean = min(unique(DF$Fe3FeTInitalRatMean),unique(DF$Fe3FeTRatCur)), #we want to use the measurement if it is below the mean
                                          sd = unique(DF$Fe3FeTInitalRatSD)))


  colnames(Fe3FeTInitalRat) <-"Fe3FeTInitalRat"
  DF <- cbind(DF,Fe3FeTInitalRat)

  DF$Fe3FeTInitalRat <- pmin(DF$Fe3FeTInitalRat, DF$Fe3FeTRatCur)

  #Second portion of iron ratio
  DF$Fe3FeTRatDiff <- DF$Fe3FeTRatCur - DF$Fe3FeTInitalRat
  DF$Fe3O4Diff_wt <- DF$Fe3FeTRatDiff * DF$FeT / 0.7236

  #Calculate hydrogen
  #convert to kg/m3
  DF$rockDen <- DF$rockDen * 1000 #convert CRPP data from g/cm3 to kg/m3
  DF$mass <- DF$rockDen #make a dummy sample mass column

  #convert mass to hydrogen if 100% converted to Fe3O4
  DF$molFe3O4 <- (DF$rockDen * (DF$Fe3O4Diff_wt/100))*(1000/231.5386) #find number of moles Fe3O4 per mass (kg) that makes up 1 cubic meter. Fe3O4 is 231.5386 g/mol or 0.2315386 kg/mol
  DF$SerpMolH2 <- DF$molFe3O4 #find hydrogen mols assuming some conversion rate (convRate) (e.g., 100%) completion (1Fe3O43 --> 1 H2)
  DF$SerpMassH2 <- DF$SerpMolH2 * 2.016 / 1000 #find hydrogen mass (kg) for that mols (mols hydrogen * 2.016 g/mol)
  DF$SerpMassH2Rate <- DF$SerpMassH2 / (DF$Age * 1000000) #age is in units of millions of year (Ma) so multiply by 1,000,000 to get years
  DF$SerpMolH2Rate <- DF$SerpMolH2 / (DF$Age * 1000000)
  DF$SerpModel <- "Fe Species Serp"
  DF <- DF %>% select(-initColnames, -mass)
  return(DF)

}
