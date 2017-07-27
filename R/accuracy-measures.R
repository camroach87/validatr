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
#' * Symmetric mean absolute percentage error (SMAPE1 and SMAPE2 - see
#' discussion)
#'
#' @param .object a `validatr` object containing cross-validation folds and predictions.
#' @param y string. Name of actual column.
#' @param yhat string. Name of prediction column.
#' @param average_folds logical. Should accuracy measures be averaged across all
#'   folds? If `TRUE` one line is returned. If `FALSE` the accuracy measures are
#'   returned for each cross-validation fold.
#'
#' @return A data frame with the accuracy measures listed above.
#'
#' @export
#'
#' @examples
#' kfold_cv(iris, k = 3) %>%
#'   fit_models("Model1 = lm(Sepal.Length ~ ., data = train)",
#'              "Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)") %>%
#'   calc_predictions("Prediction1 = predict(Model1, newdata = test)",
#'                    "Prediction2 = predict(Model2, newdata = test)") %>%
#'   calc_accuracy(y = "Sepal.Length",
#'                     yhat = c("Prediction1", "Prediction2"))
calc_accuracy <- function(.object, y, yhat, average_folds = TRUE) {
  accuracy <- list()
  for (i in 1:length(.object$folds)) {
    # mean_naive_e <- .object[[i]]$train %>%
    #   dplyr::summarise(mean(abs(get(y) - lag(get(y))), na.rm = TRUE)) %>%
    #   dplyr::pull()

    accuracy[[i]] <- .object$folds[[i]]$test %>%
      dplyr::select(y = y, yhat) %>%
      tidyr::gather(Model, yhat, -y) %>%
      dplyr::group_by(Model) %>%
      dplyr::summarise(
        AE = sum(abs(y - yhat), na.rm = TRUE),
        MAE = mean(abs(y - yhat), na.rm = TRUE),
        MAPE = mean(abs(y - yhat)/y, na.rm = TRUE)*100,
        RMSE = sqrt(mean((y - yhat)^2, na.rm = TRUE)),
        SMAPE1 = mean(200*abs(y - yhat)/(y + yhat), na.rm = TRUE),
        SMAPE2 = mean(200*abs(y - yhat)/abs(y + yhat), na.rm = TRUE)
      ) %>%
      #              na.rm = TRUE),
      #MASE = AE/mean_naive_e) %>%
      dplyr::mutate(Fold = i) %>%
      dplyr::select(Fold, dplyr::everything())
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

  return(accuracy)
}
