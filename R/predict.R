#' Predict on validation set
#'
#' Carries out prediction on validation set for each model.
#'
#' @param object a `validatr` object produced by `model()`.
#' @param ... Name-value pairs of expressions. Each value should return a vector
#'   of predictions when evaluated. Arguments are automatically quoted and
#'   evaluated.
#'
#' @return
#'
#' A `validatr` object with predictions element.
#'
#' @export
#'
#' @examples
#' iris %>%
#'   validatr(Sepal.Length, k = 3) %>%
#'   model(Model1 = lm(Sepal.Length ~ ., data = train),
#'         Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
#'   predict(Model1 = predict(Model1, newdata = validation),
#'           Model2 = predict(Model2, newdata = validation))
predict.validatr <- function(object, ...) {
  predict_spec <- eval(substitute(alist(...)))
  object$predictions <- lapply(
    object$folds,
    function(x) {
      data.frame(y = with(object$params, data[x$validation, y]))
    })
  names(object$predictions) <- names(object$folds)

  for (iF in names(object$folds)) {
    list2env(object$models[[iF]], envir = environment())
    list2env(object$folds[[iF]], envir = environment())
    train <- object$params$data[train,]
    validation <- object$params$data[validation,]
    for (iP in names(predict_spec)) {
      eval(parse(text = paste0("object$predictions[[iF]]$",iP,"=",
                               predict_spec[iP])))
    }
  }

  object$params$models_predicted <- names(predict_spec)

  return(object)
}
