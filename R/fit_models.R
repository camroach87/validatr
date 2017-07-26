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
#'   fit_models("Model1 = lm(Sepal.Length ~ ., data = train)",
#'              "Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)")
fit_models <- function(.data, ...) {
  model_spec <- list(...)
  model_list <- list()

  for (iF in 1:length(.data)) {
    model_list[[iF]] <- list()
    for (iM in 1:length(model_spec)) {
      train <- .data[[iF]]$train
      model_list[[iF]][[iM]] <- eval(parse(text = model_spec[[iM]]))
    }
  }

  return(model_list)
}
