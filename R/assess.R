#' Accuracy measures
#'
#' Returns prediction accuracy measures.
#'
#' Accuracy measures returned for regression include:
#'
#' * Absolute error (AE)
#' * Mean absolute error (MAE)
#' * Mean absolute percentage error (MAPE)
#' * Root mean square error (RMSE)
#' * Symmetric mean absolute percentage error (SMAPE)
#'
#' Time-series accuracy measures include the above measures plus:
#'
#' * Mean absolute scaled error (MASE)
#'
#' These regression and time-series accuracy measures are defined as in the paper Hyndman, Rob J., and Anne B. Koehler. 2006. “Another Look at Measures of Forecast Accuracy.” International Journal of Forecasting 22 (4): 679–88.
#'
#' Classification accuracy measures include:
#'
#' * Accuracy
#' * Precision
#' * Sensitivity
#' * Specificity
#' * F-score
#'
#' These measures are defined as in the paper Sokolova, Marina, and Guy Lapalme. 2009. “A Systematic Analysis of Performance Measures for Classification Tasks.” Information Processing & Management 45 (4): 427–37.
#'
#' @param object a `validatr` object containing cross-validation folds and predictions.
#' @param y string. Name of actual column.
#'
#' @return A data frame with the accuracy measures listed above.
#'
#' @export
#'
#' @examples
#' validatr("Sepal.Length", iris, "regression", 3) %>%
#'   model(Model1 = lm(Sepal.Length ~ ., data = train),
#'         Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
#'   predict(Model1 = predict(Model1, newdata = validation),
#'           Model2 = predict(Model2, newdata = validation)) %>%
#'   assess()
assess <- function(object) {
  y <- object$params$y
  yhat <- object$params$models_predicted
  accuracy <- list()

  if (object$params$data_type %in% c("regression", "ts")) {
    for (i in names(object$folds)) {
      accuracy[[i]] <- object$folds[[i]]$validation %>%
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

      if (object$params$data_type == "ts") {
        mean_naive_e <- object$folds[[i]]$train %>%
          dplyr::summarise(mean(abs(get(y) - dplyr::lag(get(y))),
                                na.rm = TRUE)) %>%
          dplyr::pull()

        accuracy[[i]] <- dplyr::mutate(accuracy[[i]], MASE = AE/mean_naive_e)
      }
    }
  } else if (object$params$data_type == "classification") {
    for (i in names(object$folds)) {
      accuracy[[i]] <- object$folds[[i]]$validation %>%
        dplyr::select(y = y, yhat) %>%
        tidyr::gather(Model, yhat, -y) %>%
        dplyr::select(y, yhat, Model) %>%
        table() %>%
        as.data.frame() %>%
        dplyr::group_by(Model) %>%
        dplyr::summarise(TP = sum(Freq[y == yhat]),
                         TN = sum(Freq[y == yhat]),
                         FP = sum(Freq[y != yhat]),
                         FN = sum(Freq[y != yhat]),
                         Accuracy = (TP+TN)/(TP+TN+FP+FN),
                         Precision = TP/(TP+FP),
                         Sensitivity = TP/(TP+FN),
                         Specificity = TN/(FP+TN),
                         `F-score` = 2*TP /(2*TP+FP+FN)) %>%
                         #MCC = TP*TN-FP*FN/sqrt((TP+FP)*(TP+FN)*(TN+FP)*(TN+FN))) %>%
        dplyr::select(-c(TP, TN, FP, FN)) %>%
        dplyr::mutate(Fold = i) %>%
        dplyr::select(Fold, dplyr::everything())
    }
  } else if (object$params$data_type %in% c("quantile")) {

  }

  accuracy <- dplyr::bind_rows(accuracy)

  accuracy_avg <- accuracy %>%
    dplyr::select(-Fold) %>%
    tidyr::gather(Measure, Accuracy, -Model) %>%
    dplyr::group_by(Model, Measure) %>%
    dplyr::summarise(Mean = mean(Accuracy),
                     Variance = var(Accuracy)) %>%
    tidyr::gather(Statistic, Value, -c(Model, Measure)) %>%
    tidyr::spread(Measure, Value) %>%
    dplyr::arrange(Statistic, Model) %>%
    dplyr::ungroup()

  object[["accuracy"]] <- list("fold_accuracy" = accuracy,
                                "average_accuracy" = accuracy_avg)

  return(object)
}




#' Pinball loss function
#'
#' Calculates the pinball loss score for a given quantile.
#'
#' @param tau a vector of integers giving the quantile to calculate the pinball
#'   loss score for.
#' @param y a numeric vector of actual values.
#' @param q a numeric vector of predicted values for quantile `tau`.
#'
#' @return Pinball loss score.
.pinball_loss <- function(tau, y, q) {
  pl_df <- data.frame(tau = tau,
                      y = y,
                      q = q)

  pl_df <- pl_df %>%
    mutate(L = ifelse(y>=q,
                      tau/100 * (y-q),
                      (1-tau/100) * (q-y)))

  return(pl_df)
}
