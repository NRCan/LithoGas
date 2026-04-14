#' @title monteSerpFeTotal
#'
#' @description
#' Monte Carlo model of hydrogen production through serpentinization, from total iron data
#'
#' @description
#' Computes hydrogen production rates via serpentinization for a set of
#' Monte Carlo trials, using total iron concentration (Fe\eqn{_2}O\eqn{_3}\eqn{_T}.
#' The change in Fe\eqn{^{3+}}/Fe\eqn{_T} ratio between initial
#' (pre-serpentinization) and current states is used to estimate the mass of
#' magnetite (Fe\eqn{_3}O\eqn{_4}) produced and the associated hydrogen yield.
#'
#' @details
#' The monteSerpFeTotal() function takes a single row of a structured dataframe and computes H2 production rate. Parameters are grabbed by column name.
#'
#' @param DF one row of a structured sample dataframe
#' @param numGen Number of Monte Carlo simulations
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
#'     \item{\code{SerpModel}}{Character label: \code{"Fe Total Serp"} to denote allow for filtering of results to one type of model or another.}
#'     }
#'
#' @references
#' Ardakani, O.A., Sherwood Lollar, B., Coutts, D.S., Warr, O.A., et al.
#' (2026).
#'
#' @seealso \code{\link{monteProd}}, \code{\link{monteSerpFeSpecies}},
#'   \code{\link{rtrunc}}
#'
#' @examples
#' data("structuredDF")
#' monteProd(structuredDF[1,],50,serp=TRUE,allowTotalFeSerp=TRUE)
#'
#' @export
monteSerpFeTotal <- function(DF,numGen){

  initColnames <- colnames(DF)
  Fe2O3T <- as.data.frame(rtrunc(numGen,  #Generate a distribution of measured Fe2O3 based on measurement uncertianty
                                 "norm",
                                 lower = unique(DF$Fe2O3TMin),
                                 upper = unique(DF$Fe2O3TMax),
                                 mean = unique(DF$Fe2O3TMean),
                                 sd = unique(DF$Fe2O3TSD)))
  colnames(Fe2O3T) <-"Fe2O3T" #update column name
  DF <- cbind(DF,Fe2O3T)

  DF$FeT <- (DF$Fe2O3T*0.69943) #calculate total Fe wt% from Fe2O3

  #DF$Fe3FeTRatCur <- 0.25
  Fe3FeTRatCur <- as.data.frame(rtrunc(numGen,  #Generate a distribution of initial Fe3+/FeT ratio taking into account the current Fe3/FeT
                                       "norm",
                                       lower = unique(DF$Fe3FeTRatCurMin), #LB, best guess or the current value (if unaltered)
                                       upper = unique(DF$Fe3FeTRatCurMax), #UB, best guess or the current value (if unaltered)
                                       mean = unique(DF$Fe3FeTRatCurMean), #we want to use the measurement if it is below the mean
                                       sd = unique(DF$Fe3FeTRatCurSD)))
  colnames(Fe3FeTRatCur) <-"Fe3FeTRatCur" #update column name
  DF <- cbind(DF,Fe3FeTRatCur)




  Fe3FeTInitalRat <- as.data.frame(rtrunc(numGen,  #Generate a distribution of initial Fe3+/FeT ratio taking into account the current Fe3/FeT
                                          "norm",
                                          lower = unique(DF$Fe3FeTInitalRatMin), #LB, best guess or the current value (if unaltered)
                                          upper = unique(DF$Fe3FeTInitalRatMax), #UB, best guess or the current value (if unaltered)
                                          mean = unique(DF$Fe3FeTInitalRatMean), #we want to use the measurement if it is below the mean
                                          sd = unique(DF$Fe3FeTInitalRatSD)))

  colnames(Fe3FeTInitalRat) <-"Fe3FeTInitalRat" #update column name
  DF <- cbind(DF,Fe3FeTInitalRat)

  #if inital is greater than current, set initial to current
  # Identify where 'a' < 'b' and update 'a' with 'b' values for those rows
  #DF$Fe3FeTInitalRat <- min(DF$Fe3FeTInitalRat, DF$Fe3FeTRatCur)
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
  DF$SerpModel <- "Fe Total Serp"

  DF <- DF %>% select(-all_of(initColnames),-mass)
  return(DF)

}
