#' Fit models to training sets
#'
#' Fits specified models to training sets.
#'
#' @param .object a validatr object produced using `validatr()`.
#' @param ...
#'
#' @return
#'
#' A validatr object with models fitted for each fold.
#'
#' @export
#'
#' @examples
#' iris %>%
#'   validatr(Sepal.Length, k = 3) %>%
#'   model(Model1 = lm(Sepal.Length ~ ., data = train),
#'         Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train))
model <- function(.object, ...) {
  UseMethod("model")
}

#' @export
model.validatr <- function(.object, ...) {
  model_spec <- eval(substitute(alist(...)))
  model_list <- list()

  for (iF in names(.object$folds)) {
    model_list[[iF]] <- list()
    for (iM in names(model_spec)) {
      train <- .object$folds[[iF]]$train
      model_list[[iF]][[iM]] <- eval(model_spec[[iM]])
    }
  }

  .object[["models"]] = model_list

  return(.object)
}
