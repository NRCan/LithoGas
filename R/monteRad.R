#' @title monteRad
#'
#' @description
#' Computes hydrogen and helium production rates via water radiolysis for a
#' set of Monte Carlo trials, using the methods of Warr et al. (2023).
#' Generates distributions of fluid density, uranium, thorium, and potassium
#' concentrations from truncated normal distributions, then calculates
#' radiolytic production rates for each trial.
#'
#' @details
#' The function implements the energy-partitioning radiolysis model of
#' Warr et al. (2023). For each Monte Carlo trial, fluid density
#' (\code{fluDen}), uranium (\code{Uppm}), thorium (\code{Thppm}), and
#' potassium (\code{Kpct}) are sampled from truncated normal distributions
#' parameterised by the min/max/mean/SD columns in \code{DF}.
#'
#' Energy deposition is calculated separately for alpha (\eqn{\alpha}),
#' beta (\eqn{\beta}), and gamma (\eqn{\gamma}) radiation from U, Th, and K
#' decay chains. Net energy delivered to pore water (\code{ENetA},
#' \code{ENetB}, \code{ENetG}) accounts for stopping power ratios
#' (\code{SA}, \code{SB}, \code{SG}) and the water-to-rock mass ratio
#' (\code{W}). Hydrogen and helium production rates are then derived using
#' G-values (radiolytic yields) and Avogadro's constant.
#'
#' Output columns include per-trial rates and cumulative production over the
#' sample age. All rate outputs are in mol gas / m\eqn{^3} rock / year.
#' Cumulative outputs are in mol gas / m\eqn{^3} rock over the full age
#' span (\code{Age} in Ma).
#'
#' This function is called internally by \code{\link{monteProd}} when
#' \code{rad = TRUE} and all required radiolysis input columns are present.
#'
#' @param DF A data frame of Monte Carlo trials (\code{numGen} rows) for a
#'   single sample, as produced by \code{\link{monteProd}}. Must contain
#'   columns for fluid density, U, Th, K, rock distributions (min/max/mean/SD).
#'   The population of rock density (\code{rockDen}) , porosity
#'   (\code{porosity}), and age (\code{Age}) from input distributions is handled
#'   prior, in \code{\link{monteProd}}.
#' @param numGen Integer. Number of Monte Carlo simulations. Must match
#'   \code{nrow(DF)}, generally passed from \code{\link{monteProd}}.
#'
#' @return A data frame with \code{numGen} rows containing computed
#'   radiolysis variables. Input columns from \code{DF} are removed; only
#'   newly computed columns are returned for binding by \code{\link{monteProd}}.
#'   Key output columns include:
#'   \describe{
#'     \item{\code{RadMolsH2Rate}}{Hydrogen production rate (mol H\eqn{_2} / m\eqn{^3} rock / year).}
#'     \item{\code{RadMolsHeRate}}{Helium production rate (mol He / m\eqn{^3} rock / year).}
#'     \item{\code{RadMassH2Rate}}{Hydrogen production rate (kg H\eqn{_2} / m\eqn{^3} rock / year).}
#'     \item{\code{RadMassHeRate}}{Helium production rate (kg He / m\eqn{^3} rock / year).}
#'     \item{\code{RadMolH2}}{Cumulative hydrogen production (mol H\eqn{_2} / m\eqn{^3} rock) over sample age.}
#'     \item{\code{RadMolHe}}{Cumulative helium production (mol He / m\eqn{^3} rock) over sample age.}
#'     \item{\code{RadModel}}{Character label: \code{"Rad"} representing that it was produced
#'     by the radiolysis model.}
#'   }
#'
#' @references
#' Warr, O., Song, M., Sherwood Lollar, B. (2023). The application of Monte
#' Carlo modelling to quantify in situ hydrogen and associated element
#' production in the deep subsurface. Frontiers in Earth Science, v.11.
#'
#' @seealso \code{\link{monteProd}}, \code{\link{rtrunc}}
#'
#' @examples
#' data("structuredDF")
#' monteProd(structuredDF[1,],50,rad=TRUE)
#'
#' @export
monteRad <- function(DF, numGen){

    initColnames <- colnames(DF)
    #Constants that  are used explicitly (not as parts of distributions) just set here for easier programming
    SA <- 1.5
    SB <- 1.25
    SG <- 1.14

    GH2A <- 1.32
    GH2B <- 0.6
    GH2G <- 0.25
    AConstant <- 6.023E23

    fluDen <- as.data.frame(rtrunc(numGen,
                                   "norm",
                                   lower=unique(DF$fluDenMin),
                                   upper=unique(DF$fluDenMax),
                                   mean=unique(DF$fluDenMean),
                                   sd=unique(DF$fluDenSD))) #Generate the fluid density
    colnames(fluDen) <- "fluDen"

    Uppm <- as.data.frame(rtrunc(numGen,
                                 "norm",
                                 lower=unique(DF$uMin),
                                 upper=unique(DF$uMax),
                                 mean=as.numeric(unique(DF$uMean)),
                                 sd=unique(DF$uSD))) #Generate the uranium distirbution
    colnames(Uppm) <- "Uppm"

    Thppm <- as.data.frame(rtrunc(numGen,
                                  "norm",
                                  lower=unique(DF$thMin),
                                  upper=unique(DF$thMax),
                                  mean=as.numeric(unique(DF$thMean)),
                                  sd=unique(DF$thSD))) #Generate the thorium distribution
    colnames(Thppm) <- "Thppm"

    Kpct <- as.data.frame(rtrunc(numGen,"norm",
                                 lower=unique(DF$kMin),
                                 upper=unique(DF$kMax),
                                 mean=unique(DF$kMean),
                                 sd=unique(DF$kSD))) #generate the potassium distribution
    colnames(Kpct) <- "Kpct"


    DF <- cbind(DF,fluDen,Uppm,Thppm,Kpct) #bind all information into one dataframe

    #main calculations as one big mutate that calculates per mol/m3/year
    DF <- DF %>% mutate(
      sysDen = (rockDen*(1-(porosity/100)))+(fluDen*(porosity/100)),
      W = ((porosity/100)*fluDen)/((1-(porosity/100))*rockDen),
      EKA = Kpct*0, #this is correct, because potassium does not decay through alpha decay
      EKB = Kpct*4.88085E15,
      EKG = Kpct*1.51668E15,
      EThA = Thppm*3.80732E14,
      EThB = Thppm*1.7039E14,
      EThG = Thppm*2.93351E14,
      EUA = Uppm*1.3065E15,
      EUB = Uppm*9.11259E14,
      EUG = Uppm*7.0529E14,
      ENetA = ((EKA+EThA+EUA)*W*SA)/(1+W*SA),
      ENetB = ((EKB+EThB+EUB)*W*SB)/(1+W*SB),
      ENetG = ((EKG+EThG+EUG)*W*SG)/(1+W*SG),
      YH2A = ((ENetA*GH2A)/AConstant)*sysDen*10,
      YH2B = ((ENetB*GH2B)/AConstant)*sysDen*10,
      YH2G = ((ENetG*GH2G)/AConstant)*sysDen*10,
      RadMolH2Rate = YH2A + YH2B + YH2G,  #hydrogen production
      RadMolHeRate = (((3.115E6+1.272E5)*Uppm+7.71E5*Thppm)/AConstant)*sysDen*1E6, #helium production
      RadMassH2Rate = RadMolH2Rate * 2.016 / 1000,
      RadMassHeRate = RadMolHeRate * 4.0026 / 1000,
      RadMolH2 = RadMolH2Rate * (Age*1000000),
      RadMolHe = RadMolHeRate * (Age*1000000),
      RadMassH2 = RadMassH2Rate * (Age * 1000000),
      RadMassHe = RadMassHeRate * (Age * 1000000)
    )
    DF$RadModel <- "Rad"
    DF <- DF %>% select(-initColnames)
    return(DF)

  }
