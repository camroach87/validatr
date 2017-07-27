#' Predict on validation set
#'
#' __TODO: at the moment the prediction strings for each model must be in the
#' same order as in the__ `fit_models` __function. Fix so that order does not
#' need to be preserved to avoid potential bugs. Might need to learn a bit more
#' about NSE.__
#'
#' Carries out prediction on validation set for each model.
#'
#' @param .object a `validatr`` object produced by `fit_models`.
#' @param ... strings specifying what predictions are needed.
#'
#' @return
#' @export
#'
#' @examples
#'
#' kfold_cv(iris, k = 3) %>%
#'   fit_models(Model1 = lm(Sepal.Length ~ ., data = train),
#'              Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
#'   calc_predictions(Model1 = predict(Model1, newdata = validation),
#'                    Model2 = predict(Model2, newdata = validation))
calc_predictions <- function(.object, ...) {
  UseMethod("calc_predictions")
}

#' @export
calc_predictions.validatr <- function(.object, ...) {
  predict_spec <- eval(substitute(alist(...)))

  for (iF in 1:length(.object$folds)) {
    for (iP in names(predict_spec)) {
      assign(iP, .object$models[[iF]][[iP]])
      validation <- .object$folds[[iF]]$validation
      eval(parse(text = paste0(".object$folds[[iF]]$validation$",iP,"=",
                               predict_spec[iP])))
    }
  }

  class(.object) <- "validatr"

  return(.object)
}
