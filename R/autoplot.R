#' Plot accuracy measure densities
#'
#' @param object a data frame produced by `calc_accuracy()`.
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
#'   fit_models(Model1 = lm(Sepal.Length ~ ., data = train),
#'              Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
#'   calc_predictions(Model1 = predict(Model1, newdata = validation),
#'                    Model2 = predict(Model2, newdata = validation)) %>%
#'   calc_accuracy(y = "Sepal.Length", average_folds = FALSE) %>%
#'   autoplot()
autoplot.validatr_accuracy <- function(object, ...) {
  .object %>%
    tidyr::gather(Measure, Accuracy, -c(Fold, Model)) %>%
    ggplot2::ggplot(ggplot2::aes(x = Accuracy, fill = Model)) +
    ggplot2::geom_density(alpha = 0.3) +
    ggplot2::facet_wrap(~Measure) +
    ggplot2::labs(title = "Accuracy measures for cross-validation folds")
}
