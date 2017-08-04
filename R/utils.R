#' @importFrom magrittr %>%
#' @export
magrittr::`%>%`

#' @importFrom stats var
#' @export
stats::var

# Ignore R CMD check: no visible binding for global variable
utils::globalVariables(c("Model", "Fold", "AE", "TP", "TN", "FP", "FN", ".",
                         "Accuracy", "Precision", "Sensitivity", "Specificity",
                         "Measure", "Statistic", "Value", "y", "yhat"))

