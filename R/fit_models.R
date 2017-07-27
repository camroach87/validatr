#' Fit models to training sets
#'
#' Fits specified models to training sets.
#'
#' @param .data
#' @param ...
#'
#' @return
#' @export
#'
#' @examples
#'
#' kfold_cv(iris, k = 3) %>%
#'   fit_models(Model1 = lm(Sepal.Length ~ ., data = train),
#'              Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train))
fit_models <- function(.data, ...) {
  UseMethod("fit_models")
}

#' @export
fit_models.validatr <- function(.data, ...) {
  model_spec <- eval(substitute(alist(...)))
  model_list <- list()

  for (iF in 1:length(.data)) {
    model_list[[iF]] <- list()
    for (iM in names(model_spec)) {
      train <- .data[[iF]]$train
      model_list[[iF]][[iM]] <- eval(model_spec[[iM]])
    }
  }

  validatr_obj <- list("folds" = .data,
                       "models" = model_list)

  class(validatr_obj) <- "validatr"

  return(validatr_obj)
}
