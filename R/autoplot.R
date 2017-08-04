#' Plot accuracy measure densities
#'
#' Produces violin plots for accuracy measures. Jittered points are also used
#' to show actual values.
#'
#' @param object a validatr object produced by `assess()`.
#' @param ... other arguments passed.
#'
#' @return
#'
#' A ggplot object.
#'
#' @export
#'
#' @examples
#' iris %>%
#'   validatr(y = Sepal.Length, k = 3) %>%
#'   model(LM1 = lm(Sepal.Length ~ ., data = train),
#'         LM2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
#'   predict(LM1 = predict(LM1, newdata = validation),
#'           LM2 = predict(LM2, newdata = validation)) %>%
#'   assess() %>%
#'   autoplot()
autoplot.validatr <- function(object, ...) {
  object$accuracy$fold_accuracy %>%
    tidyr::gather(Measure, Accuracy, -c(Fold, Model), factor_key = TRUE) %>%
    ggplot2::ggplot(ggplot2::aes(x = Model, y = Accuracy,
                                 fill = Model)) +
    ggplot2::geom_violin(alpha = 0.3, colour = NA) +
    ggplot2::geom_jitter(width = 0.1, height = 0, size = 0.15) +
    ggplot2::facet_wrap(~Measure, scales = "free_x") +
    ggplot2::labs(title = "Accuracy measures for cross-validation folds") +
    ggplot2::theme(legend.position = "none") +
    ggplot2::coord_flip()
}
