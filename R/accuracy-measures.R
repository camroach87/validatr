#' Accuracy measures
#'
#' Returns prediction accuracy measures for:
#'
#' * Absolute error (AE)
#' * Mean absolute error (MAE)
#' * Mean absolute percentage error (MAPE)
#' * Root mean square error (RMSE)
#' * Symmetric mean absolute percentage error (SMAPE1 and SMAPE2 - see
#' discussion)
#'
#' @param object an object containing cross-validation folds and predictions.
#' @param y string. Name of actual column.
#' @param yhat string. Name of prediction column.
#' @param average_folds logical. Should accuracy measures be averaged across all
#'   folds? If `TRUE` one line is returned. If `FALSE` the accuracy measures are
#'   returned for each cross-validation fold.
#'
#' @return A data frame with the accuracy measures listed above.
#'
#' @export
#' @importFrom magrittr "%>%"
#'
#' @examples
#' kfold_data <- kfold_cv(iris)
#' # TODO need to figure out how to do the prediction function, might need to be something the user codes since each prediction method is different.
#' kfold_data <- predict(kfold_data)
#' accuracy_measures(kfold_data, y = "Actual", yhat = "Prediction")
accuracy_measures <- function(object, y, yhat, average_folds = TRUE) {
  accuracy <- list()
  for (i in 1:length(object)) {
    # mean_naive_e <- object[[i]]$train %>%
    #   dplyr::summarise(mean(abs(get(y) - lag(get(y))), na.rm = TRUE)) %>%
    #   dplyr::pull()

    accuracy[[i]] <- object[[i]]$test %>%
      dplyr::summarise(
        AE = sum(abs(get(y) - get(yhat)), na.rm = TRUE),
        MAE = mean(abs(get(y) - get(yhat)), na.rm = TRUE),
        MAPE = mean(abs(get(y) - get(yhat))/get(y), na.rm = TRUE)*100,
        RMSE = sqrt(mean((get(y) - get(yhat))^2, na.rm = TRUE)),
        SMAPE1 = mean(200*abs(get(y) - get(yhat))/(get(y) + get(yhat)),
                      na.rm = TRUE),
        SMAPE2 = mean(200*abs(get(y) - get(yhat))/abs(get(y) + get(yhat)),
                      na.rm = TRUE)
      ) %>%
      #              na.rm = TRUE),
      #MASE = AE/mean_naive_e) %>%
      dplyr::mutate(Fold = i) %>%
      dplyr::select(Fold, dplyr::everything())
  }

  accuracy <- dplyr::bind_rows(accuracy)

  if (average_folds) {
    accuracy <- colMeans(accuracy[,-1])
  }

  return(accuracy)
}
