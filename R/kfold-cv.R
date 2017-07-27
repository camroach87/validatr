#' K-fold cross validation
#'
#' __TODO: Change to get_folds(data, method = "kfold-cv", k = 10)__
#'
#' Performs k-fold cross validation. A list with k elements is returned. Each
#' element contains a train and validation element, both of which are data frames.
#'
#' @param data a data frame containing relevant variables for modelling.
#' @param k integer. Number of folds.
#'
#' @return
#'
#' `kfold_cv` returns a list of train and validation data frames. Each element of the
#' list corresponds to a fold.
#'
#' @export
#'
#' @examples
#'
#' kfold_data <- kfold_cv(iris, k = 5)
#' head(kfold_data[[5]]$train)
#' head(kfold_data[[5]]$validation)
kfold_cv <- function(data, k = 10) {
  data<-data[sample(nrow(data)),]

  folds <- cut(seq(1, nrow(data)),
               breaks = k,
               labels = FALSE)

  fold_list <- list()
  for(i in 1:k){
    idx <- which(folds==i, arr.ind=TRUE)
    fold_list[[i]] <- list("train" = data[-idx, ],
                           "validation" = data[idx, ])
  }

  class(fold_list) <- "validatr"

  return(fold_list)
}
