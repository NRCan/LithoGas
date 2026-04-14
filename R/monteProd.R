#' @title monteProd
#'
#' @description
#' The main wrapper function for Monte Carlo modelling of hydrogen and helium
#' production rates via radiolysis and serpentinization. The function loops
#' over each row of a structured input dataframe, generates \code{numGen} Monte Carlo
#' iterations per sample, and returns all trials combined in a single dataframe.
#'
#' @details
#' For each sample row in \code{structDF}, \code{monteProd} performs the
#' following steps:
#'
#' \enumerate{
#'   \item Checks which input data are available (rock properties, age,
#'     radiolysis inputs, iron speciation).
#'   \item Expands the sample row to \code{numGen} rows for Monte Carlo
#'     trials.
#'   \item Generates an age distribution from geochronologic uncertainty
#'     (\code{AgeMa} +/- \code{AgeUnc2S_Ma}/2) if age columns are present.
#'   \item Assigns rock density and porosity either from sample-specific
#'     distributions or from lithology defaults via
#'     \code{\link{joinLitProps}} if \code{litLith} is provided and
#'     sample-specific values are absent.
#'   \item Optionally runs serpentinization modelling via
#'     \code{\link{monteSerpFeSpecies}} if \code{serp = TRUE} and iron
#'     speciation data and age data are present, or total-Fe serpentinization if
#'     \code{allowTotalFeSerp = TRUE}.
#'   \item Optionally runs radiolysis modelling via \code{\link{monteRad}}
#'     if \code{rad = TRUE} and U, Th, K, and age data are present.
#' }
#'
#' Any missing columns from the expected input schema are added as \code{NA}
#' automatically. Parameters are called from the input dataframe by name, so
#' they must match exactly to templates must match the required
#' input fields — see \code{\link{structuredDF}} for the expected structure.
#'
#' Production rates (\code{RadMolsH2Rate}, \code{SerpMolH2Rate},
#' \code{RadMolsHeRate}) are in units of mol gas / m\eqn{^3} rock / year,
#' following Warr et al. (2023) and Ardakani et al. (in review).
#'
#' @param structDF A data frame containing one or more lithogeochemical
#'   samples. Each row is one sample. Column names must match the required
#'   input schema. See \code{structuredDF} for structure. Missing columns
#'   are added as \code{NA} automatically.
#' @param numGen Integer. Number of Monte Carlo iterations to run per sample.
#' @param rad Logical. If \code{TRUE}, radiolysis calculations of hydrogen
#'   and helium production rates are performed via \code{\link{monteRad}}.
#'   Requires \code{uMin}/\code{uMax}/\code{uMean}/\code{uSD},
#'   \code{thMin}/\code{thMax}/\code{thMean}/\code{thSD},
#'   \code{kMin}/\code{kMax}/\code{kMean}/\code{kSD}, and age columns.
#'   Defaults to \code{FALSE}.
#' @param serp Logical. If \code{TRUE}, serpentinization calculations of
#'   hydrogen production rates are performed using iron speciation methods
#'   via \code{\link{monteSerpFeSpecies}}. Requires \code{Fe2O3Min},
#'   \code{Fe2O3Max}/\code{Fe2O3Mean}/\code{Fe2O3SD}/\code{FeOMin},
#'   \code{FeOMax}/\code{FeOMean}/\code{FeOSD}/\code{Fe3FeTInitalRatMin},
#'   \code{Fe3FeTInitalRatMax}/\code{Fe3FeTInitalRatMean},
#'   \code{Fe3FeTInitalRatSD}, and age columns
#'   Defaults to \code{FALSE}.
#' @param allowTotalFeSerp Logical. If \code{TRUE}, total iron
#'   serpentinization calculations are used in lieu of iron speciation
#'   methods when \code{serp = FALSE}. Requires total \code{Fe2O3TMin},
#'   \code{Fe2O3TMax}/\code{Fe2O3TMean}/\code{Fe2O3TSD}/\code{Fe3FeTInitalRatMin},
#'   \code{Fe3FeTInitalRatMax}/\code{Fe3FeTInitalRatMean},
#'   \code{Fe3FeTInitalRatSD}/\code{Fe3FeTRatCurMin}/\code{Fe3FeTRatCurMax},
#'   \code{Fe3FeTRatCurMean}/\code{Fe3FeTRatCurSD}, and age columns.
#'   Defaults to \code{FALSE}.
#'
#' @return A data frame containing all Monte Carlo trials for all input
#'   samples bound by rows. Includes all original input columns plus sampled
#'   petrophysical properties, age distributions, and computed production
#'   rates depending on which models were run.
#'
#' @references
#' Warr, O., Song, M., Sherwood Lollar, B. (2023). The application of Monte
#' Carlo modelling to quantify in situ hydrogen and associated element
#' production in the deep subsurface. Frontiers in Earth Science, v.11.
#'
#' Ardakani, O.A., Sherwood Lollar, B., Coutts, D.S., Warr, O.A., et al.
#' (in Review).
#'
#' @seealso \code{\link{monteRad}}, \code{\link{monteSerpFeSpecies}},
#'   \code{\link{joinLitProps}}, \code{\link{rtrunc}}, \code{\link{monteSum}}
#'
#' @examples
#' data("structuredDF")
#' monteProd(structuredDF,500,TRUE,TRUE,TRUE)
#'
#' @export
monteProd <- function(structDF,numGen,rad=FALSE,serp=FALSE,allowTotalFeSerp=FALSE){

  resultsDF <- NULL

  #Set up columns that we need - add any missing columns
  desired_cols <- c("litLith", "AgeMa",   "AgeUnc2S_Ma", "AgeReference",
                    "Fe3FeTInitalRatMin",  "Fe3FeTInitalRatMax",  "Fe3FeTInitalRatMean",
                    "Fe3FeTInitalRatSD",   "Fe2O3Min", "Fe2O3Max", "Fe2O3Mean",
                    "Fe2O3SD", "FeOMin",  "FeOMax",  "FeOMean", "FeOSD",
                    "Fe2O3TMin", "Fe2O3TMax", "Fe2O3TMean", "Fe2O3TSD",
                    "Fe3FeTRatCurMin", "Fe3FeTRatCurMax", "Fe3FeTRatCurMean",
                    "Fe3FeTRatCurSD", "uMin",    "uMax", "uMean", "uSD",
                    "thMin", "thMax", "thMean", "thSD", "kMin", "kMax", "kMean",
                    "kSD",     "rockDenMin",   "rockDenMax", "rockDenMean",
                    "rockDenSD",    "porMin",  "porMax", "porMean", "porSD",
                    "fluDenMin", "fluDenMax", "fluDenMean", "fluDenSD")

  missing_cols <- setdiff(desired_cols, names(structDF))  # find cols in desired but not in structuredDF
  structDF[missing_cols] <- NA #set the missing columns to NA

  for(i in 1:nrow(structDF)){
    print(paste("Processing sample: ", i))
    monteDF <- NULL #create empty dataframe for Monte Carlo results
    sampDF <- structDF[i,] #take sample i from structuredDF

    #CHECK INPUTS FOR EACH SAMPLE
    #check rock properties - rockDen, por, litLith
    rockDenCheck <- !is.na(sampDF%>%select(rockDenMin, rockDenMax, rockDenMean, rockDenSD))
    porCheck <- !is.na(sampDF%>%select(porMin, porMax, porMean, porSD))

    sampDF$litLith[sampDF$litLith == ""] <- NA #if litLith is "", set to NA first
    litLithCheck <- !is.na(sampDF$litLith) #check if litLith is NA
    litLithCheck <- sampDF$litLith %in% unique(CRPPData$Lithology) #check if litLith rock type is in CRPP data

    #check radiolysis inputs - U, Th, K, fluDen
    uCheck <- !is.na(sampDF%>%select(uMin, uMax, uMean, uSD))
    thCheck <- !is.na(sampDF%>%select(thMin, thMax, thMean, thSD))
    kCheck <- !is.na(sampDF%>%select(kMin, kMax, kMean, kSD))

    #check serpentinization inputs - Fe2O3, FeO,
    SerpCheck <- !is.na(sampDF%>%select(Fe3FeTInitalRatMin, Fe3FeTInitalRatMax, Fe3FeTInitalRatMean, Fe3FeTInitalRatSD, Fe2O3Min, Fe2O3Max, Fe2O3Mean, Fe2O3SD, FeOMin, FeOMax, FeOMean, FeOSD))
    FeTCheck <- !is.na(sampDF%>%select(Fe2O3TMin,Fe2O3TMax,Fe2O3TMean,Fe2O3TSD,Fe3FeTInitalRatMin, Fe3FeTInitalRatMax, Fe3FeTInitalRatMean, Fe3FeTInitalRatSD, Fe3FeTRatCurMin, Fe3FeTRatCurMax, Fe3FeTRatCurMean, Fe3FeTRatCurSD))

    #check age inputs - age + uncertainty
    ageCheck <- !is.na(sampDF%>%select(AgeMa,AgeUnc2S_Ma))
    #END INPUTS CHECK

    #Reproduce the input data for the sample for the number of rows as number of numGen
    monteDF <- sampDF[rep(seq_len(nrow(sampDF)), each = numGen), ] #extend the sample information downards

    #If age inputs are valid use normal distribution to generate ages
    if(sum(ageCheck)==2){
      Age <-  as.data.frame(rnorm(numGen, #Generate distribution of ages based on geochronologic uncertainty
                                  mean = monteDF$AgeMa,
                                  sd = monteDF$AgeUnc2S_Ma/2))
      colnames(Age) <-"Age" #update column name
      monteDF <- cbind(monteDF,Age)
    } else {
      #print(paste("Issues with sample ", i, " age"))
    }

    #If no rock properties add those using the joinLitProps function.
    if(sum(litLithCheck)==1 & sum(rockDenCheck)<4 & sum(porCheck)<4){
      monteDF <- cbind(monteDF,joinLitProps(sampDF,numGen))
    } else if (sum(rockDenCheck)==4 & sum(porCheck)==4){ #otherwise generate them
      rockDen <- as.data.frame(rtrunc(numGen, "norm",
                                      lower = sampDF$rockDenMin,
                                      upper = sampDF$rockDenMax,
                                      mean = sampDF$rockDenMean,
                                      sd = sampDF$rockDenSD))
      colnames(rockDen) <- "rockDen"
      porosity <- as.data.frame(rtrunc(numGen, "norm",
                                       lower = sampDF$porMin,
                                       upper = sampDF$porMax,
                                       mean = sampDF$porMean,
                                       sd = sampDF$porSD))
      colnames(porosity) <- "porosity"
      monteDF <- cbind(monteDF,data.frame(rockDen,porosity))
    }


    if(serp==TRUE & sum(SerpCheck)==12 & sum(ageCheck)==2){
      monteDF <- cbind(monteDF,monteSerpFeSpecies(monteDF,numGen))
    } else if (allowTotalFeSerp==TRUE & sum(FeTCheck)==12){
      monteDF <- cbind(monteDF,monteSerpFeTotal(monteDF,numGen))
    }

    if(rad==TRUE & sum(uCheck)==4 & sum(thCheck)==4 & sum(kCheck)==4 &  sum(ageCheck)==2){
      monteDF <- cbind(monteDF,monteRad(monteDF,numGen))
    }

    resultsDF <- bind_rows(resultsDF,monteDF)
  }

  return(resultsDF)
}
