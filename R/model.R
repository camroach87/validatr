#' Fit models to training sets
#'
#' Fits specified models to training sets.
#'
#' @param object a validatr object produced using `validatr()`.
#' @param ... Name-value pairs of expressions. Each value should return a model
#'   when evaluated. Arguments are automatically quoted and evaluated.
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
model <- function(object, ...) {
  UseMethod("model")
}



#' @export
model.validatr <- function(object, ...) {
  model_spec <- eval(substitute(alist(...)))
  model_list <- list()

  object$folds <- object$folds %>%
    dplyr::mutate(models = purrr::map(
      indices, ~ fit_models(., model_spec, data)))

  return(object)
}



#' @export
model.grouped_validatr <- function(object, ...) {
  model_spec <- eval(substitute(alist(...)))
  model_list <- list()

  object$folds <- object$folds %>%
    dplyr::mutate(models = purrr::map(
      indices, ~ fit_models(., model_spec, data)))

  return(object)
}



fit_models <- function(indices, model_spec, data) {
  model_list <- list()
  for (iF in names(indices)) {
    model_list[[iF]] <- list()
    for (iM in names(model_spec)) {
      train <- indices[[iF]]$train
      train <- data[[1]][train,]
      model_list[[iF]][[iM]] <- eval(model_spec[[iM]])
    }
  }
  return(model_list)
}
