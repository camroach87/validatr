#' Initialise validatr object
#'
#' Initialises a validatr object.
#'
#' The type of data being tested influences how the validatr and it's methods
#' respond. The following types are supported and are specified using the type
#' parameter.
#'
#' * __regression__ regression data.
#' * __ts__ time-series data.
#' * __classification__ classification data.
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
#' Finally, classification carries out k-fold cross validation as well, but its
#' accruacy measures will be different to regression.
#'
#' @param y string specifying the dependent variable name.
#' @param data data frame containing variables for modelling.
#' @param type string specify the data structure and cross-validation to be
#'   carried out. Can be one of ts, regression or classification.
#' @param k integer. Number of folds.
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
#' validatr_obj <- validatr(iris, y = Sepal.Length, data_type = "regression", k = 5)
#' head(validatr_obj$folds[[5]]$train)
#' head(validatr_obj$folds[[5]]$validation)
validatr <- function(data,
                     y,
                     data_type = "regression",
                     k = 10,
                     start = NULL,
                     horizon = NULL,
                     shift = NULL,
                     ts = NULL) {

  y <- deparse(substitute(y))
  ts <- deparse(substitute(ts))

  validatr <- list(params = as.list(environment()),
                   folds = list())

  if (data_type %in% c("regression", "classification")) {
    data<-data[sample(nrow(data)),]

    folds <- cut(seq(1, nrow(data)),
                 breaks = k,
                 labels = FALSE)

    for(i in 1:k){
      idx <- which(folds==i, arr.ind=TRUE)
      validatr$folds[[as.character(i)]] <- list(
        "train" = data[-idx, ],
        "validation" = data[idx, ]
      )
    }

  } else if (data_type == "ts") {
    if (class(start) != class(data[1, ts])) {
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
  } else {
    stop("Invalid data_type entered.")
  }

  class(validatr) <- "validatr"

  return(validatr)
}


#' @export
print.validatr <- function(x) {
  cat("You are working with a validatr object. Good job!\n\n",
      "Number of folds: ", length(x$folds), "\n",
      "Date type: ", x$params$data_type, "\n",
      "Response variable: ", x$params$y, "\n",
      sep = "")
  invisible(x)
}


#' @export
is.validatr <- function(x) {
  class(x) == "validatr"
}
