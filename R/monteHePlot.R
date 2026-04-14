#' @title monteHePlot
#'
#' @description
#' Generates a log-log plot of helium production rates scaled across a range of
#' source rock volumes (0.1 to 100 km\eqn{^3}). Each sample in the summary
#' dataframe produced by \code{\link{monteSum}} represented as a line showing
#' how total helium production (mol / year) scales with increasing source rock volume.
#' A secondary y-axis shows equivalent rates in kg / year.
#'
#' @details
#' The function takes the summary dataframe from \code{\link{monteSum}} and
#' iterates over a sequence of source rock volumes from 0.1 to 100 km\eqn{^3}.
#' For each volume, the per-m\eqn{^3} rates are scaled to per-km\eqn{^3} rates
#' (multiplied by 1\eqn{\times}10\eqn{^9}) and then multiplied by the volume
#' to give a total production rate for a source rock body of that size.
#'
#' The resulting \code{volDF} dataframe and \code{ggplot2} object are both
#' returned as a list, allowing the user to access the underlying data or
#' further customise the plot.
#'
#'
#' @param sumDF A summary data frame produced by \code{\link{monteSum}}.
#'   Must contain columns \code{HeRateMin},
#'   \code{HeRateMean}, and \code{HeRateMax} in units of
#'   mol He / m\eqn{^3} / year.
#'
#' @param colorField field for colour to be attributed to lines in the plot
#'
#' @return A list of length 2:
#'   \describe{
#'     \item{\code{[[1]]}}{A data frame (\code{volDF}) containing the
#'       volume-scaled helium production rates for all samples across all
#'       source rock volumes. Columns include \code{vol},
#'       \code{HeRateMin}, \code{HeRateMean}, and \code{HeRateMax} in units
#'       of mol He / year.}
#'     \item{\code{[[2]]}}{A \code{ggplot2} object showing a log-log source
#'       area plot of mean helium production rate vs. source rock volume,
#'       coloured by \code{ModelLabel}. The secondary y-axis shows equivalent
#'       mass rates in kg / year.}
#'   }
#'
#' @references
#' See Ardakani et al. (2026) for discussions of these plots and their use in
#' hydrogen and helium exploration
#'
#' @seealso \code{\link{monteSum}} to generate the required input,
#'   \code{\link{monteH2Plot}} for the equivalent hydrogen plot,
#'   \code{\link{monteProd}} for the main Monte Carlo workflow.
#'
#' @examples
#' data("structuredDF")
#' filtered <- structuredDF[!is.na(structuredDF$uMean), ]
#' df <- monteProd(filtered, numGen = 50, rad = TRUE)
#' sumDF <- monteSum(df, summaryField = "Sample")
#' result <- monteHePlot(sumDF, colorField ="Sample")
#' result[[2]] # view the plot
#'
#' @export
monteHePlot <- function(sumDF, colorField = "Sample"){#,ribbon=FALSE){

  #translate the summary rates from mol/m3/year to mol/km3/year
  sumDF <- sumDF %>%
    select(-SerpH2Min,-SerpH2Mean,-SerpH2Max,-RadH2Min,-RadH2Mean,-RadH2Max,-H2RateMin,-H2RateMean,-H2RateMax,-RadHeMin,-RadHeMean,-RadHeMax) %>% #drop unneeded summary columns
    mutate(HeRateMin = HeRateMin*1E9,
           HeRateMean = HeRateMean*1E9,
           HeRateMax = HeRateMax*1E9)

  #set up an empty dataframe volDF, that we will write our results to
  volDF <- NULL

  #enter for loop going from that iterates from 0.1 km3 to 100 km3 calculating the hydrogen production rate
  for (i in c(0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.6,0.8,0.9,1,2,3,4,5,6,7,8,9,10,20,30,40,50,60,70,80,90,100)) {
    #print(i)
    tempDF <- sumDF #set sumDF to a temporary dataframe
    tempDF$vol <- i #populate the volume
    tempDF$HeRateMin <- tempDF$HeRateMin * i #calculate the minimum hydrogen production rate
    tempDF$HeRateMean <- tempDF$HeRateMean * i
    tempDF$HeRateMax <- tempDF$HeRateMax * i
    volDF <- rbind(volDF, tempDF)
  }

  p <- ggplot(volDF) +
    geom_line(mapping=aes(x=vol, y=HeRateMean, color=!!sym(colorField))) +
    labs(x="Source rock volume (km3)",y="He generation rate (mol/year)", color="Source Rock") +
    theme_bw() + scale_y_log10(sec.axis = sec_axis(~ . * 0.0040026, name = "(kg/year)")) +
    scale_x_log10()

  return(list(volDF,p))

  # xbreaks <- 10^(0:10)
  # xminor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))
  #
  # ybreaks <- 10^(0:10)
  # yminor_breaks <- rep(1:9, 21)*(10^rep(-10:10, each=9))
  # if(ribbon==FALSE){
  #   ggplot(dfProd) +
  #     geom_line(mapping=aes(x=volume,y=meanH2, color=Sample)) +
  #     theme_bw() +
  #     xlab("Source rock volume (km3)") +
  #     ylab("Yearly H2 production (mol H2 / km3 / year)") +
  #     scale_x_log10() +
  #     scale_y_continuous(sec.axis=sec_axis(~.*2.016/1000, name="Produced H2 mass (kg H2 / km3 / year)"))
  # } else {
  #   ggplot(dfProd) +
  #     geom_line(mapping=aes(x=volume,y=meanH2, color=Sample)) +
  #     geom_ribbon(mapping=aes(x=volume,ymin=minH2,ymax=maxH2, fill=Sample),alpha=0.1) +
  #     theme_bw() +
  #     xlab("Source rock volume (km3)") +
  #     ylab("Yearly H2 production (mol H2 / km3 / year)") +
  #     scale_x_log10() +
  #     scale_y_continuous(sec.axis=sec_axis(~.*2.016/1000, name="Produced H2 mass (kg H2 / km3 / year)"))
  # }

}
