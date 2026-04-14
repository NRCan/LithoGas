#' @title monteSum
#'
#' @description
#' Summarises the full Monte Carlo trial dataframe produced by
#' \code{\link{monteProd}} into one row per sample group, returning the
#' minimum, mean, and maximum production rates for hydrogen and helium across
#' all trials. This summary dataframe is the required input for
#' \code{\link{monteH2Plot}} and \code{\link{monteHePlot}}.
#'
#' @details
#' The function groups \code{monteDF} by \code{summaryField} using
#' \code{group_by(!!sym(summaryField))} to allow a user-defined grouping
#' column to be passed as a string. Within each group, min/mean/max are
#' computed for serpentinization hydrogen rates, radiolysis hydrogen rates,
#' and radiolysis helium rates. Combined total hydrogen rates
#' (\code{H2RateMin}, \code{H2RateMean}, \code{H2RateMax}) are computed as
#' the sum of serpentinization and radiolysis contributions.
#'
#' Any missing rate columns (\code{SerpMolH2Rate}, \code{RadMolH2Rate},
#' \code{RadMolHeRate}) are added as \code{NA} automatically, so the function
#' handles outputs from radiolysis-only, serpentinization-only, or combined
#' model runs without error.
#'
#' All production rate output columns are in units of
#' mol gas / m\eqn{^3} rock / year.
#'
#' @param monteDF A data frame of Monte Carlo trials produced by
#'   \code{\link{monteProd}}. Each row is one Monte Carlo trial for one
#'   sample. Must contain a column matching \code{summaryField}.
#' @param summaryField Character string. The name of the column in
#'   \code{monteDF} to group by (e.g. \code{"Sample"}, \code{"litLith"}).
#'   Passed using tidy evaluation via \code{!!sym()}.
#'
#' @return A data frame with one row per unique value of \code{summaryField}
#'   and the following columns:
#'   \describe{
#'     \item{\code{SerpH2Min}, \code{SerpH2Mean}, \code{SerpH2Max}}{Min,
#'       mean, and max serpentinization hydrogen production rate
#'       (mol H\eqn{_2} / m\eqn{^3} / year).}
#'     \item{\code{RadH2Min}, \code{RadH2Mean}, \code{RadH2Max}}{Min,
#'       mean, and max radiolysis hydrogen production rate
#'       (mol H\eqn{_2} / m\eqn{^3} / year).}
#'     \item{\code{H2RateMin}, \code{H2RateMean}, \code{H2RateMax}}{Min,
#'       mean, and max total hydrogen production rate (serp + rad)
#'       (mol H\eqn{_2} / m\eqn{^3} / year).}
#'     \item{\code{RadHeMin}, \code{RadHeMean}, \code{RadHeMax}}{Min,
#'       mean, and max radiolysis helium production rate
#'       (mol He / m\eqn{^3} / year).}
#'     \item{\code{HeRateMin}, \code{HeRateMean}, \code{HeRateMax}}{Min,
#'       mean, and max total helium production rate
#'       (mol He / m\eqn{^3} / year).}
#'   }
#'
#' @seealso \code{\link{monteProd}} to generate the input dataframe,
#'   \code{\link{monteH2Plot}} and \code{\link{monteHePlot}} for
#'   visualising the summary output.
#'
#' @examples
#' data("structuredDF")
#' df <- monteProd(structuredDF, numGen = 50, rad = TRUE, serp = TRUE)
#' monteSum(df, summaryField = "Sample")
#'
#' @export
monteSum <- function(monteDF,summaryField){

  #Add any missing columns to the monte carlo results
  desired_cols <- c("SerpMolH2Rate", "RadMolH2Rate",   "RadMolHeRate")
  missing_cols <- setdiff(desired_cols, names(monteDF))  # find cols in desired but not in A
  monteDF[missing_cols] <- NA

  # Replace infinite values with NA across all numeric columns
  monteDF <- monteDF %>%
    mutate(across(where(is.numeric), ~ ifelse(is.infinite(.), NA, .)))

  #groupby the chosen field and summarize the rates
  sumDF <- monteDF %>%
    group_by(!!sym(summaryField)) %>%
    summarize(SerpH2Min = if(all(is.na(SerpMolH2Rate))) NA_real_ else min(SerpMolH2Rate,na.rm=TRUE),
              SerpH2Mean =  if(all(is.na(SerpMolH2Rate))) NA_real_ else mean(SerpMolH2Rate,na.rm=TRUE),
              SerpH2Max =  if(all(is.na(SerpMolH2Rate))) NA_real_ else max(SerpMolH2Rate,na.rm=TRUE),
              RadH2Min =  if(all(is.na(RadMolH2Rate))) NA_real_ else min(RadMolH2Rate,na.rm=TRUE),
              RadH2Mean =  if(all(is.na(RadMolH2Rate))) NA_real_ else mean(RadMolH2Rate,na.rm=TRUE),
              RadH2Max =  if(all(is.na(RadMolH2Rate))) NA_real_ else max(RadMolH2Rate,na.rm=TRUE),
              H2RateMin = sum(SerpH2Min,RadH2Min, na.rm=TRUE),
              H2RateMean = sum(SerpH2Mean, RadH2Mean, na.rm=TRUE),
              H2RateMax = sum(SerpH2Max, RadH2Max, na.rm=TRUE),
              RadHeMin =  if(all(is.na(RadMolHeRate))) NA_real_ else min(RadMolHeRate ,na.rm=TRUE),
              RadHeMean =  if(all(is.na(RadMolHeRate))) NA_real_ else mean(RadMolHeRate ,na.rm=TRUE),
              RadHeMax =  if(all(is.na(RadMolHeRate))) NA_real_ else max(RadMolHeRate ,na.rm=TRUE),
              HeRateMin = RadHeMin,
              HeRateMean = RadHeMean,
              HeRateMax = RadHeMax)

  # Replace any Inf/-Inf produced by min()/max() on all-NA groups with NA
  sumDF <- sumDF %>%
    mutate(across(where(is.numeric), ~ ifelse(is.infinite(.), NA, .)))

  return(sumDF)
}
