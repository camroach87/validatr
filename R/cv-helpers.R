get_indices <- function(data, data_type, k, ts, start, horizon, shift) {
  if (data_type %in% c("regression", "classification")) {
    data <- data %>%
      dplyr::mutate(indices = purrr::map(data, ~ get_kfold_indices(., k)))
  } else if (data_type == "ts") {
    if (length(c(start, horizon, shift, ts)) != 4) {
      stop("a time-series cross-validation parameter has not been entered.")
    }
    if (!identical(class(start), class(data$data[[1]][[1, ts]]))) {
      print(class(start))
      print(class(data[[1]][1, ts]))
      stop("start is not same class as ts variable.")
    }

    data <- data %>%
      dplyr::mutate(indices = purrr::map(
        data, ~ get_ts_indices(., ts, start, horizon, shift)))
  }
  return(data)
}



get_kfold_indices <- function(data, k) {
  folds <- cut(sample(nrow(data)), breaks = k, labels = FALSE)
  fold_list <- list()
  for(iF in 1:k){
    idx <- which(folds==iF, arr.ind=TRUE)
    fold_list[[as.character(iF)]] <- list(
      "train" = c(1:nrow(data))[-idx],
      "validation" = idx
    )
  }
  return(fold_list)
}



get_ts_indices <- function(data, ts, start, horizon, shift) {
  fold_list <- list()
  end <- max(data[[ts]])
  if (end <= start) stop("Start of fold is later then final ts value.")
  fold_names <- seq(start, end, shift)
  fold_list <- lapply(fold_names, function(x) {
    train_idx <- which(data[[ts]] < x, arr.ind = TRUE)
    val_end <- seq(x, length=2, by=horizon)[2]
    val_idx <- which(data[[ts]] >= x & data[[ts]] < val_end,
                     arr.ind = TRUE)
    list(train = train_idx,
         validation = val_idx)
  })
  len_complete <- max(sapply(fold_list, function(x) length(x$validation)))
  idx_complete <- sapply(fold_list,
                         function(x) length(x$validation) == len_complete)
  fold_list <- fold_list[idx_complete]
  names(fold_list) <- fold_names[idx_complete]
  return(fold_list)
}
