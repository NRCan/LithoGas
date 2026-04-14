#' @title joinLitProps
#'
#' @description
#' Generates simulated rock density and porosity values for a given lithology
#' by sampling from truncated normal distributions parameterised by
#' lithology-specific bounds stored in the \code{CRPPData} dataset.
#' Intended for Monte Carlo uncertainty modelling of petrophysical properties
#' when sample-specific rock property distributions are unavailable.
#'
#' @details
#' The function filters \code{CRPPData} for the lithology matching
#' \code{samp$litLith} and uses the corresponding min, max, mean, and
#' standard deviation columns to parameterise truncated normal distributions
#' for rock density and porosity via \code{\link{rtrunc}}.
#'
#' Both properties are sampled independently. The truncation bounds ensure
#' that physically implausible values (e.g. negative porosity or density)
#' are excluded from the output.
#'
#' \code{CRPPData} contains the following columns that are used to for each
#' lithology row:
#' \itemize{
#'   \item \code{rockDenMin}, \code{rockDenMax}, \code{rockDenMean}, \code{rockDenSD}
#'   \item \code{porMin}, \code{porMax}, \code{porMean}, \code{porSD}
#' }
#'
#' This function is called internally by \code{\link{monteProd}} when
#' sample-specific rock property data are absent but a valid \code{litLith}
#' is provided.
#'
#' @param samp A single-row data frame or list containing at least:
#'   \describe{
#'     \item{\code{litLith}}{Character string. The lithology type used to
#'     filter \code{CRPPData} (e.g. \code{"basalt"}, \code{"granite"}).
#'     Must match a value in \code{CRPPData$Lithology}.}
#'   }
#' @param numGen Integer. Number of Monte Carlo samples to generate for
#'   each rock property.
#'
#' @return A data frame with \code{numGen} rows and two columns:
#'   \describe{
#'     \item{\code{rockDen}}{Simulated rock density values in g/cm\eqn{^3}
#'     (truncated normal).}
#'     \item{\code{porosity}}{Simulated porosity values in percent
#'     (truncated normal).}
#'   }
#'
#' @seealso \code{\link{rtrunc}} for the truncated sampling method,
#'   \code{\link{monteProd}} for the main Monte Carlo workflow.
#'
#'
#' @examples
#' samp <- data.frame(litLith = "basalt")
#' results <- joinLitProps(samp, numGen = 50)
#' hist(results$rockDen, main = "Rock Density Distribution")
#' hist(results$porosity, main = "Porosity Distribution")
#'
#' data("structuredDF")
#' samp <- structuredDF[1,]
#' joinLitProps(samp,50)
#'
#' @export
joinLitProps <- function (samp,numGen){
  data("CRPPData", envir = environment()) #get CRPPData from the package
  litProps <- CRPPData %>% filter(Lithology == samp$litLith) #filter for the same lithology as the sample
  rockDen <- as.data.frame(rtrunc(numGen, "norm", #create dataframe of random iterations inside truncated distribution for rock density
                                  lower = litProps$rockDenMin, upper = litProps$rockDenMax,
                                  mean = litProps$rockDenMean, sd = litProps$rockDenSD))
  colnames(rockDen) <- "rockDen"

  porosity <- as.data.frame(rtrunc(numGen, "norm", #create dataframe of random iterations inside truncated distribution for rock porosity
                                   lower = litProps$porMin, upper = litProps$porMax,
                                   mean = litProps$porMean, sd = litProps$porSD))
  colnames(porosity) <- "porosity"
  return(data.frame(rockDen,porosity))
}
