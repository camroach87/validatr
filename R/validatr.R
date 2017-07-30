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
#' validatr_obj <- validatr(iris, data_type = "regression", k = 5)
#' head(validatr_obj$folds[[5]]$train)
#' head(validatr_obj$folds[[5]]$validation)
validatr <- function(data,
                     data_type = "regression",
                     k = 10,
                     start = NULL,
                     horizon = NULL,
                     shift = NULL,
                     ts = NULL) {

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

    # Ensure time-series is ordered
    data <- dplyr::arrange(data, get(ts))

    while(start < max(data[,ts])) {
      s_str <- as.character(start)
      idx <- which(data[,ts] >= start, arr.ind=TRUE)
      validatr$folds[[s_str]] <- list(
        "train" = data[-idx, ],
        "validation" = data[idx[1:horizon], ]
      )

      start <- start + shift
    }

    # Removes any NAs from final fold
    na_idx <- is.na(validatr$folds[[s_str]]$validation[,ts])
    if (any(na_idx)) {
      #validatr$folds[[s_str]] <- NULL
      validatr$folds[[s_str]]$validation <-
        validatr$folds[[s_str]]$validation[!na_idx,]
    }

  } else {
    stop("Invalid data_type entered.")
  }

  class(validatr) <- "validatr"

  return(validatr)
}
