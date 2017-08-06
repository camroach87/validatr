#' Initialise validatr
#'
#' Initialises a validatr object.
#'
#' The type of data being tested influences how the validatr and it's methods
#' respond. The following types are supported:
#'
#' * __regression__ regression data (default).
#' * __ts__ time-series data (`ts` argument specified).
#' * __classification__ classification data (`y` variable character, factor or
#' logical).
#'
#' The type of cross-validation and accuracy measures to be calculated are
#' influenced by this parameter. For regression, k-fold cross-validation is
#' carried out and requires the number of folds `k` to be specified. Leave one
#' out cross-validation can easily be accomplished by setting `k` equal to the
#' number of observations.
#'
#' For time-series, time-series cross-validation takes place. This requires the
#' `start`, `horizon`, `shift` and `ts` arguments to be specified:
#'
#' * `start` is the start of the first fold.
#' * `horizon` is the length of the fold.
#' * `shift` is the length of time to move forward.
#' * `ts` is the name of the variable containing time-series data.
#'
#' If `start` is numeric, then `horizon` and `shift` are also numeric. If
#' `start` is date or POSIX, then `horizon` and `shift` follow the same
#' convention as for `seq.Date` and `seq.POSIXt`. Hence, they are a character
#' string, containing one of "sec", "min", "hour", "day", "DSTday", "week",
#' "month", "quarter" or "year".
#'
#' Finally, classification carries out k-fold cross validation as well, but its
#' accruacy measures will be different to regression.
#'
#' @param data data frame containing variables for modelling.
#' @param y dependent variable name. Non-standard evaluation.
#' @param k integer. Number of folds.
#' @param start numeric, date or POSIX object specifying the start date for
#'   time-series validation folds.
#' @param horizon forecast horizon to evaluate.
#' @param shift length of time to move forward for each new fold.
#' @param ts time-series variable name. Non-standard evaluation.
#'
#' @return
#'
#' `validatr` returns an initial validatr object. This object contains cross
#' validation folds and validation parameters.
#'
#' @export
#'
#' @examples
#'
#' validatr_obj <- validatr(iris, y = Sepal.Length, k = 5)
#' head(validatr_obj$folds[[5]]$train)
#' head(validatr_obj$folds[[5]]$validation)
validatr <- function(data, y, k = 10, ts = NULL, start = NULL,
                     horizon = NULL, shift = NULL) {
  UseMethod("validatr")
}

#' @export
validatr.data.frame <- function(data, y, k = 10, ts = NULL, start = NULL,
                                horizon = NULL, shift = NULL) {

  y <- deparse(substitute(y))
  ts <- deparse(substitute(ts))

  if (ts != "NULL") {
    data_type = "ts"
  } else if (any(is.character(data[1,y]),
                 is.factor(data[1,y]),
                 is.logical(data[1,y]))) {
    data_type = "classification"
  } else {
    data_type = "regression"
  }

  validatr <- list(params = as.list(environment()),
                   folds = list())

  if (data_type %in% c("regression", "classification")) {
    folds <- cut(sample(nrow(data)), breaks = k, labels = FALSE)
    for(iF in 1:k){
      idx <- which(folds==iF, arr.ind=TRUE)
      validatr$folds[[as.character(iF)]] <- list(
        "train" = c(1:nrow(data))[-idx],
        "validation" = idx
      )
    }
  } else if (data_type == "ts") {
    if (!identical(class(start), class(data[1, ts]))) {
      print(class(start))
      print(class(data[1, ts]))
      stop("start is not same class as ts variable.")
    }
    if (length(c(start, horizon, shift, ts)) != 4) {
      stop("a time-series cross-validation parameter has not been entered.")
    }

    end <- max(data[[ts]])
    if (end <= start) stop("Start of fold is later then final ts value.")
    fold_names <- seq(start, end, shift)
    validatr$folds <- lapply(fold_names, function(x) {
      train_idx <- which(data[[ts]] < x, arr.ind = TRUE)
      val_end <- seq(x, length=2, by=horizon)[2]
      val_idx <- which(data[[ts]] >= x & data[[ts]] < val_end,
                              arr.ind = TRUE)
      list(train = train_idx,
           validation = val_idx)
    })
    len_complete <- max(sapply(validatr$folds,
                                  function(x) length(x$validation)))
    idx_complete <- sapply(validatr$folds,
                           function(x) length(x$validation) == len_complete)
    validatr$folds <- validatr$folds[idx_complete]
    names(validatr$folds) <- fold_names[idx_complete]
  }

  class(validatr) <- "validatr"

  return(validatr)
}


#' @export
print.validatr <- function(x, ...) {
  cat("You are working with a validatr object. Good job!\n\n",
      "Number of folds: ", length(x$folds), "\n",
      "Date type: ", x$params$data_type, "\n",
      "Response variable: ", x$params$y, "\n",
      sep = "")

  if (is.null(x$models)) {
    cat("Models not fitted.\n")
  } else {
    cat("Number of models fitted:", length(x$models[[1]]), "\n")
  }

  if (is.null(x$params$models_predicted)) {
    cat("Predictions not calculated.\n")
  } else {
    cat("Predictions have been calculated.\n")
  }

  if (is.null(x$accuracy$average_accuracy)) {
    cat("Accuracy measures not calculated.\n")
  } else {
    cat("\nAverage accuracy:\n\n")
    print(data.frame(x$accuracy$average_accuracy))
  }

  invisible(x)
}

#' Validatr object
#'
#' `is.validatr` tests if its argument is a validatr object.
#'
#' @param x an R object.
#'
#' @export
is.validatr <- function(x) {
  class(x) == "validatr"
}
