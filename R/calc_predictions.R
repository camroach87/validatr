#' Predict on test set
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
#'   fit_models("Model1 = lm(Sepal.Length ~ ., data = train)",
#'              "Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)") %>%
#'   calc_predictions("Prediction1 = predict(Model1, newdata = test)",
#'                    "Prediction2 = predict(Model2, newdata = test)")
calc_predictions <- function(.object, ...) {
  UseMethod("calc_predictions")
}

#' @export
calc_predictions.validatr <- function(.object, ...) {
  predict_spec <- list(...)

  for (iF in 1:length(.object$folds)) {
    for (iP in 1:length(predict_spec)) {
      assign(names(.object$models[[iF]])[iP], .object$models[[iF]][[iP]])
      test <- .object$folds[[iF]]$test
      eval(parse(text = paste0(".object$folds[[iF]]$test$",
                               predict_spec[[iP]])))
    }
  }

  class(.object) <- "validatr"

  return(.object)
}
