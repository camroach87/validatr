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
#' These regression and time-series accuracy measures are defined as in the
#' paper Hyndman, Rob J., and Anne B. Koehler. 2006. “Another Look at Measures
#' of Forecast Accuracy.” International Journal of Forecasting 22 (4): 679–88.
#'
#' Classification accuracy measures include:
#'
#' * Accuracy
#' * Precision
#' * Sensitivity
#' * Specificity
#' * F-score
#'
#' These measures are defined as in Sokolova, Marina, and Guy Lapalme. 2009. “A
#' Systematic Analysis of Performance Measures for Classification Tasks.”
#' Information Processing & Management 45 (4): 427–37. For multi-class
#' classification problems, macro-averaging is used to ensure large classes are
#' not favoured. Macro-averaging averages the performance of each class. Most of
#' these are defined in Table 3 of the paper. Since the multi-class
#' measures do not reduce to the binary measures when the number of classes is
#' equal to two the binary classification accuracy measures in Table 2 have also
#' been included and are activated when the response variable in the input data is
#' Boolean.
#'
#' @param object a `validatr` object containing cross-validation folds and predictions.
#' @param y string. Name of actual column.
#'
#' @return A data frame with the accuracy measures listed above.
#'
#' @export
#'
#' @examples
#' iris %>%
#'   validatr(Sepal.Length, "regression", 3) %>%
#'   model(Model1 = lm(Sepal.Length ~ ., data = train),
#'         Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
#'   predict(Model1 = predict(Model1, newdata = validation),
#'           Model2 = predict(Model2, newdata = validation)) %>%
#'   assess()
assess <- function(object) {
  yhat <- object$params$models_predicted
  accuracy <- list()

  if (object$params$data_type %in% c("regression", "ts")) {
    for (iF in names(object$folds)) {
      accuracy[[iF]] <- object$predictions[[iF]] %>%
        tidyr::gather(Model, yhat, -y) %>%
        dplyr::group_by(Model) %>%
        dplyr::summarise(
          AE = sum(abs(y - yhat), na.rm = TRUE),
          MAE = mean(abs(y - yhat), na.rm = TRUE),
          MAPE = mean(abs(y - yhat)/y, na.rm = TRUE)*100,
          RMSE = sqrt(mean((y - yhat)^2, na.rm = TRUE)),
          SMAPE = mean(200*abs(y - yhat)/(y + yhat), na.rm = TRUE)
        ) %>%
        dplyr::mutate(Fold = iF) %>%
        dplyr::select(Fold, dplyr::everything())

      if (object$params$data_type == "ts") {
        mean_naive_e <- object$folds[[iF]]$train %>%
          dplyr::summarise(mean(abs(get(y) - dplyr::lag(get(y))),
                                na.rm = TRUE)) %>%
          dplyr::pull()

        accuracy[[iF]] <- dplyr::mutate(accuracy[[iF]], MASE = AE/mean_naive_e)
      }
    }
  } else if (object$params$data_type == "classification") {
    for (iF in names(object$folds)) {
      if (all(is.logical(object$params$data[,y]))) {
        accuracy[[iF]] <- object$predictions[[iF]] %>%
          tidyr::gather(Model, yhat, -y) %>%
          dplyr::summarise(TP = sum(y == TRUE & yhat == TRUE),
                           TN = sum(y == FALSE & yhat == FALSE),
                           FP = sum(y == FALSE & yhat == TRUE),
                           FN = sum(y == TRUE & yhat == FALSE)) %>%
          dplyr::mutate(Accuracy = (TP+TN)/(TP+TN+FP+FN),
                        Precision = TP/(TP+FP),
                        Sensitivity = TP/(TP+FN),
                        Specificity = TN/(FP+TN),
                        `F-score` = 2*TP/(2*TP+FN+FP)) %>% # beta = 1
          dplyr::select(-c(TP, TN, FP, FN)) %>%
          dplyr::mutate(Fold = iF) %>%
          dplyr::select(Fold, dplyr::everything())
      } else if (length(unique(object$params$data[,y])) >= 2) {
        accuracy[[iF]] <- object$predictions[[iF]] %>%
          tidyr::gather(Model, yhat, -y) %>%
          dplyr::group_by(Model) %>%
          dplyr::do(calc_tp_tn_fp_fn(.)) %>%
          dplyr::mutate(Accuracy = (TP+TN)/(TP+TN+FP+FN),
                        Precision = TP/(TP+FP),
                        Sensitivity = TP/(TP+FN),
                        Specificity = TN/(FP+TN)) %>%
          dplyr::summarise(Accuracy = mean(Accuracy),
                           Precision = mean(Precision),
                           Sensitivity = mean(Sensitivity),
                           Specificity = mean(Specificity)) %>%
          dplyr::mutate(`F-score` = 2*Precision*Sensitivity/
                          (Precision + Sensitivity)) %>% # beta = 1
          dplyr::mutate(Fold = iF) %>%
          dplyr::select(Fold, dplyr::everything())
      } else {
        stop(paste0("Either less than three classes in response variable or ",
                    "binary response has not been input as Boolean."))
      }
    }
  }

  accuracy <- dplyr::bind_rows(accuracy)

  accuracy_avg <- accuracy %>%
    dplyr::select(-Fold) %>%
    tidyr::gather(Measure, Accuracy, -Model, factor_key = TRUE) %>%
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



#' Calculate confusion matrix statistics
#'
#' Calculates true positive, true negative, false positive and false negatives.
#'
#' @param x data frame with y and yhat columns.
#'
#' @return data frame with confusion matrix statistics.
calc_tp_tn_fp_fn <- function(x) {
  tp_tn_fp_fn <- NULL
  for (iC in unique(x$y)) {
    tp_tn_fp_fn[[iC]] <- x %>%
      dplyr::summarise(TP = sum(y == iC & yhat == iC),
                       FP = sum(y == iC & yhat != iC),
                       TN = sum(y != iC & yhat != iC),
                       FN = sum(y != iC & yhat == iC)) %>%
      dplyr::mutate(y = iC) %>%
      dplyr::select(y, dplyr::everything())
  }
  tp_tn_fp_fn <- dplyr::bind_rows(tp_tn_fp_fn)
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
pinball_loss <- function(tau, y, q) {
  pl_df <- data.frame(tau = tau,
                      y = y,
                      q = q)

  pl_df <- pl_df %>%
    mutate(L = ifelse(y>=q,
                      tau/100 * (y-q),
                      (1-tau/100) * (q-y)))

  return(pl_df)
}
