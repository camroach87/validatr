% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/assess.R
\name{calc_tp_tn_fp_fn}
\alias{calc_tp_tn_fp_fn}
\title{Calculate confusion matrix statistics}
\usage{
calc_tp_tn_fp_fn(x)
}
\arguments{
\item{x}{data frame with y and yhat columns.}
}
\value{
data frame with confusion matrix statistics.
}
\description{
Calculates true positive, true negative, false positive and false negatives.
}
