% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/model.R
\name{model}
\alias{model}
\title{Fit models to training sets}
\usage{
model(object, ...)
}
\arguments{
\item{object}{a validatr object produced using \code{validatr()}.}

\item{...}{Name-value pairs of expressions. Each value should return a model
when evaluated. Arguments are automatically quoted and evaluated.}
}
\value{
A validatr object with models fitted for each fold.
}
\description{
Fits specified models to training sets.
}
\examples{
iris \%>\%
  validatr(Sepal.Length, k = 3) \%>\%
  model(Model1 = lm(Sepal.Length ~ ., data = train),
        Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train))
}
