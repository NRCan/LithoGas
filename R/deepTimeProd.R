#' Deep-time production of H2 and He following radioactive decay and average
#' rate of serpentinization
#'
#' For radiolysis models, present-day measured concentrations of uranium, thorium,
#' and potassium, are back calucualted to deep-time concentrations at specified ages
#' by reversing the radioactive decay equations for each relevant isotope (²³⁸U, ²³⁵U, ²³²Th, ⁴⁰K).
#' These deep-time concentrations are then used to calculate H2 and He production rates
#' via radiolysis.
#'
#' For serpentinization models the average rate of H2 generation by serpentinization
#' that is established by \code{\link{monteProd}} is used.
#'
#' @param monteProdDF  Dataframe. A data frame returned by \code{\link{monteProd}}.
#' Long-dataframe including all trial of input Monte Carlo.
#' @param startAge_Ma Numeric. Geologic age in millions of years (Ma) for the
#' model to start at (youngest age). startAge_Ma must be less than endAge_Ma.
#' @param endAge_Ma   Numeric. Geologic age in millions of years (Ma) for the
#' model to end at (oldest age). endAge_Ma must be greater than start.
#' @param stepAge_Ma   Numeric. Geologic duration of each step in the age model
#' in millions of years (My). Must be positive.
#' @param rad   Logic. If true, back calculation of radiolysis using radioactive
#' decay will be computed. This is explained below in.
#' @param serp   Logic. If true, back calculation of serpentinization rate
#' will be computed.
#'
#' @details
#' The back-projection uses the standard radioactive decay law in reverse:
#'
#' \deqn{N_{\text{past}} = N_{\text{now}} \cdot e^{+\lambda t}}
#'
#' where \eqn{\lambda} is the decay constant for a given isotope and \eqn{t}
#' is the elapsed time in years.
#'
#' **Decay constants and half-lives used:**
#' \tabular{lll}{
#'   Isotope \tab Half-life \tab Assumed abundance    \cr
#'   \eqn{{}^{238}}U  \tab 4.468 Ga \tab  99.2745\%   \cr
#'   \eqn{{}^{235}}U  \tab 703.8 Ma \tab  0.7204\%    \cr
#'   \eqn{{}^{232}}Th \tab 14.05 Ga \tab  100\%       \cr
#'   \eqn{{}^{40}}K   \tab 1248 Ma  \tab  0.01167\%   \cr
#' }
#'
#' @return A the input dataframe repeated for each time step. All Monte Carlo trials from monteProd() back
#' calculated at each time step. If \code{rad==True}, additional columns will be added:
#' \describe{
#'   \item{\code{timeStep_Ma}}{The time step of the model in millions of years (Ma).}
#'   \item{\code{stepDur_Ma}}{The duration of the time step, millions of years (Ma). Same as input \code{stepAge_Ma}}
#'   \item{\code{Uppm}}{Total uranium concentration at time \code{timeStep_Ma} (ppm).}
#'   \item{\code{Thppm}}{Total thorium concentration at time \code{timeStep_Ma} (ppm).}
#'   \item{\code{Kpct}}{Total potassium concentration at time \code{timeStep_Ma} (wt\%).}
#'   \item{\code{Kppm}}{Total potassium concentration at time \code{timeStep_Ma} (wt\%).}
#'   \item{\code{U238ppm}}{²³⁸U concentration at time \code{timeStep_Ma} (ppm).}
#'   \item{\code{U235ppm}}{²³⁵U concentration at time  \code{timeStep_Ma} (ppm).}
#'   \item{\code{RadH2Rate_molm3yr}}{H2 generation rate (mol/m3/year), back calculated at time \code{timeStep_Ma}}
#'   \item{\code{RadHeRate_molm3yr}}{He generation rate (mol/m3/year), back calculated at time \code{timeStep_Ma}}
#'   \item{\code{RadH2_molm3}}{Cumulative volume of H2 generated over the \code{timeStep_Ma} in mols H2 per m3. Calculated by \code{RadH2Rate_molm3yr} * \code{timeStep_Ma}}
#'   \item{\code{RadHe_molm3}}{Cumulative volume of He generated over the \code{timeStep_Ma} in mols He per m3. Calculated by \code{RadHeRate_molm3yr} * \code{timeStep_Ma} }
#' }
#'
#' If \code{serp==True}, additional columns will be added:
#' \describe{
#'   \item{\code{timeStep_Ma}}{The input time in Ma (returned for reference).}
#'   \item{\code{SerpH2Rate_molm3yr}}{H2 generation rate (mol/m3/year), back calculated at time \code{timeStep_Ma}}
#' }
#'
#' @examples
#' data("structuredDF")
#' monteProdDF <- monteProd(structuredDF,50, rad=TRUE, serp=TRUE, allowTotalFeSerp =TRUE)
#' deepDF <- deepTimeProd(monteProdDF,0,2000,100,rad=TRUE)
#'
#' library(ggplot2)
#' ggplot(deepDF) + geom_boxplot(mapping=aes(x=as.factor(timeStep_Ma),y=Uppm, fill=Sample)) +labs(x="Age (Ma)",y="U (ppm)", title="Decrease in U by decay law")
#'
#' ggplot(deepDF) + geom_boxplot(mapping=aes(x=as.factor(timeStep_Ma),y=RadHeRate_molm3yr, fill=Sample)) +labs(x="Age (Ma)",y="He generation rate (mol/m3/yr)", title="Decrease in He generation rate by decay law")
#'
#' @importFrom dplyr %>% mutate bind_rows rename_with ends_with
#'
#' @export
deepTimeProd <- function(monteProdDF, startAge_Ma, endAge_Ma, stepAge_Ma, rad=FALSE, serp=FALSE){
  #Add any missing columns to the monte carlo results
  desired_cols <- c("Uppm", "Thppm", "Kpct", "rockDen", "porosity", "fluDen",
                    "sysDen", "W", "EKA", "EKB", "EKG", "EThA", "EThB", "EThG",
                    "EUA", "EUB", "EUG", "ENetA", "ENetB", "ENetG", "YH2A", "YH2B",
                    "YH2G", "RadH2Rate_molm3yr", "RadHeRate_molm3y", "Fe2O3T",
                    "Fe2O3", "FeO", "FeT", "Fe3FeTRatCur", "Fe3FeTInitalRat", "Fe3FeTRatDiff",
                    "Fe3O4Diff_wt", "molFe3O4", "SerpH2_molm3", "SerpH2Rate_molm3yr",
                    "SerpModel") #these are the columns we need for the code to run

  missing_cols <- setdiff(desired_cols, names(monteProdDF))  # find cols in desired but not in A
  monteProdDF[missing_cols] <- NA #set any of the missing columns to NA

  #Constants that  are used explicitly (not as parts of distributions) just set here for easier programming
  #Energies used for H2 radiolysis (see Warr et al., 2023)
  SA <- 1.5
  SB <- 1.25
  SG <- 1.14
  GH2A <- 1.32
  GH2B <- 0.6
  GH2G <- 0.25
  AConstant <- 6.023E23

  #Decay constants (per year)
  lambda_U238  <- log(2) / 4.468e9   # 238U half-life: 4.468 Ga
  lambda_U235  <- log(2) / 703.8e6   # 235U half-life: 703.8 Ma
  lambda_Th232 <- log(2) / 14.05e9   # 232Th half-life: 14.05 Ga
  lambda_K40   <- log(2) / 1248e6    # 40K half-life:  1.248 Ga

  #Natural isotopic abundances
  abund_U238 <- 0.992745   # fraction of total U
  abund_U235 <- 0.007204   # fraction of total U
  abund_K40  <- 1.167e-4   # fraction of total K

  #Set up model objects
  deepTimeProdDF <- NULL #final dataframe that will write to
  modelSteps <- seq(from=startAge_Ma,to=endAge_Ma,by=stepAge_Ma)

  #Go into for loop for each model step
  for (t_Ma in modelSteps){
    print(t_Ma)
    stepDF <- monteProdDF #sub-dataframe that each time step will write to

    if(rad==TRUE){
      stepDF <- stepDF %>%
        mutate(
          U238ppm_T = (Uppm*abund_U238) * exp(lambda_U238 * (t_Ma*1000000)),
          U235ppm_T = (Uppm*abund_U235) * exp(lambda_U235 * (t_Ma*1000000)),
          Uppm_T = U238ppm_T + U235ppm_T,
          Thppm_T = Thppm * exp(lambda_Th232 * (t_Ma*1000000)),
          Kpct_T = ((Kpct* 1e4* abund_K40) * exp(lambda_K40 * (t_Ma*1000000))) / 1e4,
          sysDen_T = (rockDen*(1-(porosity/100)))+(fluDen*(porosity/100)),
          W_T = ((porosity/100)*fluDen)/((1-(porosity/100))*rockDen),
          EKA_T = Kpct_T*0 ,
          EKB_T = Kpct_T*4.88085E15,
          EKG_T = Kpct_T*1.51668E15,
          EThA_T = Thppm_T*3.80732E14,
          EThB_T = Thppm_T*1.7039E14,
          EThG_T = Thppm_T*2.93351E14,
          EUA_T = Uppm_T*1.3065E15,
          EUB_T = Uppm_T*9.11259E14,
          EUG_T = Uppm_T*7.0529E14,
          ENetA_T = ((EKA_T+EThA_T+EUA_T)*W_T*SA)/(1+W_T*SA),
          ENetB_T = ((EKB_T+EThB_T+EUB_T)*W_T*SB)/(1+W_T*SB),
          ENetG_T = ((EKG_T+EThG_T+EUG_T)*W_T*SG)/(1+W_T*SG),
          YH2A_T = ((ENetA_T*GH2A)/AConstant)*sysDen_T*10,
          YH2B_T = ((ENetB_T*GH2B)/AConstant)*sysDen_T*10,
          YH2G_T = ((ENetG_T*GH2G)/AConstant)*sysDen_T*10,
          RadH2Rate_molm3yr_T = (YH2A_T + YH2B_T + YH2G_T),  #H2 generation rate at time t_Ma - because U, Th, and K concentrations were back calculated to time t_Ma, this is accurate for time t_Ma
          RadHeRate_molm3yr_T = ((((3.115E6+1.272E5)*Uppm_T+7.71E5*Thppm_T)/AConstant)*sysDen_T*1E6), #He generation rate at time t_Ma - because U, Th, and K concentrations were back calculated to time t_Ma, this is accurate for time t_Ma
          RadH2_molm3 = RadH2Rate_molm3yr_T * (stepAge_Ma*1000000), #number of mols H2 created in that model step assuming H2 generation rate at time t_Ma for the entire step
          RadHe_molm3 = RadHeRate_molm3yr_T * (stepAge_Ma*1000000), #number of mols He created in that model step assuming He generation rate at time t_Ma for the entire step
          timeStep_Ma=t_Ma,
          stepDur_Ma = stepAge_Ma)
      stepDF <- stepDF %>%
        select(-sysDen,-W,-EKA,-EKB,-EKG,-EThA,-EThB,-EThG,-EUA, -EUB,-EUG,
               -ENetA,-ENetB,-ENetG,-YH2A,-YH2B,-YH2G, -RadH2Rate_molm3yr,
               -RadHeRate_molm3yr, -RadHeRate_molm3y, -Thppm, -Kpct,
               -Uppm ) #Drop some original columns calculation variables

      stepDF <- stepDF %>%
        rename_with(~ sub("_T$", "", .x), ends_with("_T")) #rename current columns of calculation variables

      #stepDF <- cbind(stepDF,radDF)
    } else {
      stepDF <- stepDF %>%
        select(-Uppm, -Thppm, -Kpct, -sysDen,
               -W, -EKA, -EKB, -EKG, -EThA, -EThB, -EThG, -EUA,
               -EUB, -EUG, -ENetA, -ENetB, -ENetG, -YH2A, -YH2B,
               -YH2G, -RadH2Rate_molm3yr, -RadHeRate_molm3yr, -RadModel,
               -RadHe_molm3, -RadH2_molm3, -fluDen)
    }

    if(serp==TRUE){
      stepDF$SerpH2Rate_molm3yr_T <-  stepDF$SerpH2Rate_molm3yr  #This is the already averaged rate of generation, so every step is the
      stepDF$SerpH2_molm3_T <-  stepDF$SerpH2Rate_molm3yr*(stepAge_Ma*1000000) #this will produce the same amount of H2 per step
      stepDF$timeStep_Ma <- t_Ma
      stepDF$stepDur_Ma <- stepAge_Ma
      stepDF <- stepDF %>%
        select(-SerpH2Rate_molm3yr,-SerpH2_molm3,-Fe2O3T, -molFe3O4)
      stepDF <- stepDF %>%
        rename_with(~ sub("_T$", "", .x), ends_with("_T")) #rename current columns of calculation variables
    }else {
      stepDF <- stepDF %>%
        select(-Fe2O3T, -Fe2O3, -FeO, -FeT, -Fe3FeTRatCur, -Fe3FeTInitalRat, -Fe3FeTRatDiff,
               -Fe3O4Diff_wt, -molFe3O4, -SerpH2_molm3, -SerpH2Rate_molm3yr,
               -SerpModel)
    }

    deepTimeProdDF <- bind_rows(deepTimeProdDF,stepDF)

  }#next time step

  return(deepTimeProdDF)
}
