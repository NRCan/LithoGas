#' @title rtrunc
#'
#' @description
#' Generates random samples from a specified distribution truncated to a closed interval \code{[lower, upper]}. Any standard R distribution can be used, provided the corresponding \code{p} and \code{q} functions exist.
#'
#' @details
#' Sampling is performed via the inverse CDF method. The cumulative
#' probabilities at \code{lower} and \code{upper} are computed using the
#' distribution's \code{p}-function, then uniform samples are drawn between
#' those probabilities and transformed back to the original scale using the
#' \code{q}-function. This guarantees all returned values lie within
#' \code{[lower, upper]}.
#'
#' @param n Integer. Number of samples to generate. If a vector is supplied,
#'   \code{length(n)} is used instead.
#' @param distr Character string. The base name of the distribution
#'   (e.g. \code{"norm"}, \code{"exp"}, \code{"gamma"}). The function
#'   constructs calls to \code{p<distr>} and \code{q<distr>} internally.
#' @param lower Numeric. Lower truncation bound. Defaults to \code{-Inf}
#'   (no lower truncation).
#' @param upper Numeric. Upper truncation bound. Defaults to \code{Inf}
#'   (no upper truncation).
#' @param ... Additional arguments passed to the distribution's \code{p}
#'   and \code{q} functions (e.g. \code{mean}, \code{sd} for \code{"norm"}).
#'
#' @examples
#' # 100 samples from a normal(0,1) truncated to [0, 2]
#' rtrunc(100, "norm", lower = 0, upper = 2, mean = 0, sd = 1)
#'
#'#' # 50 samples from an exponential truncated to [0.5, 3]
#' rtrunc(50, "exp", lower = 0.5, upper = 3, rate = 1)
#'
#'
#' @export
rtrunc <- function(n, distr, lower = -Inf, upper = Inf, ...) {
  makefun <- function(prefix, FUN, ...) {
    txt <- paste(prefix, FUN, "(x, ...)", sep = "")
    function(x, ...) eval(parse(text = txt))
  }
  if (length(n) > 1)
    n <- length(n)
  pfun <- makefun("p", distr, ...)
  qfun <- makefun("q", distr, ...)
  lo <- pfun(lower, ...)
  up <- pfun(upper, ...)
  u <- runif(n, lo, up)
  qfun(u, ...)
}
