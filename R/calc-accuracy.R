#' Accuracy measures
#'
#' Returns prediction accuracy measures.
#'
#' Accuracy measures returned include:
#'
#' * Absolute error (AE)
#' * Mean absolute error (MAE)
#' * Mean absolute percentage error (MAPE)
#' * Root mean square error (RMSE)
#' * Symmetric mean absolute percentage error (SMAPE)
#' * Mean absolute scaled error (MASE)
#'
#' @param .object a `validatr` object containing cross-validation folds and predictions.
#' @param y string. Name of actual column.
#' @param average_folds logical. Should accuracy measures be averaged across all
#'   folds? If `TRUE` one line is returned. If `FALSE` the accuracy measures are
#'   returned for each cross-validation fold.
#'
#' @return A data frame with the accuracy measures listed above.
#'
#' @export
#'
#' @examples
#' validatr(iris, k = 3) %>%
#'   fit_models(Model1 = lm(Sepal.Length ~ ., data = train),
#'              Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
#'   calc_predictions(Model1 = predict(Model1, newdata = validation),
#'                    Model2 = predict(Model2, newdata = validation)) %>%
#'   calc_accuracy(y = "Sepal.Length")
calc_accuracy <- function(.object, y, average_folds = TRUE) {
  yhat <- names(.object$models[[1]])
  accuracy <- list()
  for (i in names(.object$folds)) {
    accuracy[[i]] <- .object$folds[[i]]$validation %>%
      dplyr::select(y = y, yhat) %>%
      tidyr::gather(Model, yhat, -y) %>%
      dplyr::group_by(Model) %>%
      dplyr::summarise(
        AE = sum(abs(y - yhat), na.rm = TRUE),
        MAE = mean(abs(y - yhat), na.rm = TRUE),
        MAPE = mean(abs(y - yhat)/y, na.rm = TRUE)*100,
        RMSE = sqrt(mean((y - yhat)^2, na.rm = TRUE)),
        SMAPE = mean(200*abs(y - yhat)/(y + yhat), na.rm = TRUE)
      ) %>%
      dplyr::mutate(Fold = i) %>%
      dplyr::select(Fold, dplyr::everything())

    if (.object$params$data_type == "ts") {
      mean_naive_e <- .object$folds[[i]]$train %>%
        dplyr::summarise(mean(abs(get(y) - dplyr::lag(get(y))),
                              na.rm = TRUE)) %>%
        dplyr::pull()

      accuracy[[i]] <- dplyr::mutate(accuracy[[i]], MASE = AE/mean_naive_e)
    }
  }

  accuracy <- dplyr::bind_rows(accuracy)

  if (average_folds) {
    accuracy <- accuracy %>%
      dplyr::select(-Fold) %>%
      tidyr::gather(Measure, Accuracy, -Model) %>%
      dplyr::group_by(Model, Measure) %>%
      dplyr::summarise(Mean = mean(Accuracy),
                       Variance = var(Accuracy)) %>%
      tidyr::gather(Statistic, Value, -c(Model, Measure)) %>%
      tidyr::spread(Measure, Value) %>%
      dplyr::arrange(Statistic, Model) %>%
      dplyr::ungroup()
  }

  class(accuracy) <- c("validatr_accuracy", "tbl_df", "tbl", "data.frame")

  return(accuracy)
}
