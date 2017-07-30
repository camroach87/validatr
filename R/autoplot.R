#' Plot accuracy measure densities
#'
#' @param object a validatr object produced by `assess()`.
#' @param ...
#'
#' @return
#'
#' A ggplot object.
#'
#' @export
#'
#' @examples
#' validatr(iris, k = 3) %>%
#'   model(LM1 = lm(Sepal.Length ~ ., data = train),
#'         LM2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
#'   predict(LM1 = predict(LM1, newdata = validation),
#'           LM2 = predict(LM2, newdata = validation)) %>%
#'   assess(y = "Sepal.Length") %>%
#'   autoplot()
autoplot <- function(object, ...) {
  UseMethod("autoplot")
}

#' @export
autoplot.validatr <- function(object, ...) {
  object$accuracy$fold_accuracy %>%
    tidyr::gather(Measure, Accuracy, -c(Fold, Model)) %>%
    ggplot2::ggplot(ggplot2::aes(x = Accuracy, fill = Model)) +
    ggplot2::geom_density(alpha = 0.3) +
    ggplot2::facet_wrap(~Measure, scales = "free") +
    ggplot2::labs(title = "Accuracy measures for cross-validation folds")
}
