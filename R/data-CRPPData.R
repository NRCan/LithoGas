#' Canadian Rock Physical Property Database — Lithology Summary (CRPPData)
#'
#' @description
#' A lithology-summarized version of the Canadian Rock Physical Property
#' Database (CRPP) of Enkin (2018). Rock density and porosity distributions
#' are summarized by \code{lithology} column for use as lookup tables in
#' \code{\link{monteProd}}. In \code{\link{monteProd}}, when a sample has a
#' valid \code{litLith} value but no sample-specific rock property data,
#' \code{\link{joinLitProps}} queries this dataset to assign rock density
#' and porosity distributions for Monte Carlo sampling.
#'
#' @details
#' The original CRPP database (Enkin 2018) contains physical property
#' measurements from rock samples across Canada. This summarised version
#' was produced by grouping the original data by lithology category using
#' \code{group_by() \%>\% summarize()}, retaining the min, max, mean,
#' standard deviation, and quartiles of porosity and rock density for each
#' lithology group.
#'
#' Matching in \code{\link{joinLitProps}} is performed by a direct string
#' match on the \code{Lithology} column. The \code{litLith} field in the
#' input sample dataframe must exactly match a value in
#' \code{CRPPData$Lithology}. Available lithologies can be inspected with:
#' \preformatted{
#' data("CRPPData")
#' unique(CRPPData$Lithology)
#' }
#'
#' Porosity values are in percent (\%) and rock density values are in
#' g/cm\eqn{^3}.
#'
#' @format A data frame with one row per lithology category and the
#' following columns:
#' \describe{
#'   \item{\code{Lithology}}{Character. Lithology category name from
#'     Enkin (2018). Must be matched exactly by the \code{litLith} column
#'     of input sample dataframes (e.g. \code{"granodiorite"},
#'     \code{"orthogneiss"}).}
#'   \item{\code{num}}{Integer. Number of samples in the original CRPP database contributing to this lithology group's distributions.}
#'   \item{\code{porMin}}{Numeric. Minimum porosity in the lithology group (\%).}
#'   \item{\code{porMax}}{Numeric. Maximum porosity in the lithology group (\%).}
#'   \item{\code{porMean}}{Numeric. Mean porosity of the lithology group (\%).}
#'   \item{\code{porSD}}{Numeric. Standard deviation of porosity in the lithology group (\%).}
#'   \item{\code{porQ25}}{Numeric. 25th percentile of porosity in the lithology group (\%).}
#'   \item{\code{porQ50}}{Numeric. 50th percentile (median) of porosity in the lithology group (\%).}
#'   \item{\code{porQ75}}{Numeric. 75th percentile of porosity in the lithology group (\%).}
#'
#'   \item{\code{rockDenMin}}{Numeric. Minimum rock density in the lithology group (g/cm\eqn{^3}).}
#'   \item{\code{rockDenMax}}{Numeric. Maximum rock density in the lithology group (g/cm\eqn{^3}).}
#'   \item{\code{rockDenMean}}{Numeric. Mean rock density of the lithology group (g/cm\eqn{^3}).}
#'   \item{\code{rockDenSD}}{Numeric. Standard deviation of rock density in the lithology group (g/cm\eqn{^3}).}
#'   \item{\code{rockDenQ25}}{Numeric. 25th percentile of rock density in the lithology group (g/cm\eqn{^3}).}
#'   \item{\code{rockDenQ50}}{Numeric. 50th percentile (median) of rock density in the lithology group (g/cm\eqn{^3}).}
#'   \item{\code{rockDenQ75}}{Numeric. 75th percentile of rock density in the lithology group (g/cm\eqn{^3}).}
#' }
#'
#' @seealso \code{\link{joinLitProps}} for the function that queries this
#'   dataset, \code{\link{monteProd}} for the main Monte Carlo workflow,
#'   \code{\link{structuredDF}} for an example input dataset using
#'   lithology-based rock properties.
#'
#' @references
#' Enkin, R.J. (2018). The Canadian Rock Physical Property Database: first
#' public release. Geological Survey of Canada, Open File 8460, 68 p.
#' Natural Resources Canada.
#' \url{https://ostrnrcan-dostrncan.canada.ca/entities/publication/c4c0cede-365c-4c87-8077-8e045e874de6}
#'
#' @docType data
#' @name CRPPData
#' @usage data(CRPPData)
#' @keywords datasets
NULL
