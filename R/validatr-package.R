#' validatr package
#'
#' validatr package for assessing predictions.
#'
#' @importFrom stats var
#' @importFrom ggplot2 autoplot fortify
#' @importFrom magrittr %>%
NULL

#' @export
magrittr::`%>%`

#' @export
ggplot2::autoplot

# Ignore R CMD check: no visible binding for global variable
utils::globalVariables(c("Model", "Fold", "AE", "TP", "TN", "FP", "FN", ".",
                         "Accuracy", "Precision", "Sensitivity", "Specificity",
                         "Measure", "Statistic", "Value", "y", "yhat"))
