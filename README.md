# validatr <img src="man/figures/logo.png" align="right" width="140" />

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.org/camroach87/validatr.svg?branch=master)](https://travis-ci.org/camroach87/validatr)
[![codecov](https://codecov.io/github/camroach87/validatr/branch/master/graphs/badge.svg)](https://codecov.io/github/camroach87/validatr)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/validatr)](https://CRAN.R-project.org/package=validatr)

_Development note:_ I've been playing around a bit with Hadley's `purrr` and `modelr` packages. After a bit of a learning process, I've come to the opinion that they offer a better and more flexible approach to modelling. I'm going to stop developing this package for the moment, but may come back to it in time. It may work nicely as a package that wraps up some of the `modelr` and `purrr` functionality into easy to use modelling functions.

----------

validatr streamlines your modelling and validation process. It provides a consistent and easy to use framework of cross-validation techniques and model accuracy measures. It is structured to allow modelling methods from base R and external packages to be easily assessed against one another.

# Table of contents

* [Installation](#installation)
* [Usage](#usage)
* [Examples](#examples)
    * [Regression](#regression)
    * [Time-series](#time-series)
    * [Classification](#classification)
* [Benchmark models](#benchmark-models)
* [Future development](#future-development)
* [Caveat](#caveat)

## Installation

From your R console, simply run:

```{r}
install.packages("devtools")
require(devtools)
devtools::install_github("camroach87/validatr")
```

## Usage

Essentially, validatr works by first creating a `validatr` object which contains the cross-validation data. Three verbs are then used to carry out regression, time-series or classification analysis:

* `model()` fits models to each training set.
* `predict()` calculates predictions on each validation dataset.
* `assess()` calculates accuracy measures.

Furthermore, the accuracy measures can be visualised using the `autoplot()` function.

## Examples

Examples for regression, time-series and classification analysis are given below. 

### Regression

A simple, but hopefully illuminating example is given below. Here, four separate models from two different packages are fit to each fold's training data. The accuracy of each measure is then calculated on each fold's validation data.

_Note that the model names must remain consistent in the `model` and `predict` functions. This is because each expression is acting as a name-value pair. Names are used internally to reference the correct model._

```{r}
require(validatr)
require(randomForest)

iris %>% 
  validatr(y = Sepal.Length, k = 10) %>%
  model(LM1 = lm(Sepal.Length ~ ., data = train),
        LM2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train),
        RF1 = randomForest(Sepal.Length ~ ., data = train, ntree = 10),
        RF2 = randomForest(Sepal.Length ~ ., data = train, ntree = 500)) %>%
  predict(LM1 = predict(LM1, newdata = validation),
          LM2 = predict(LM2, newdata = validation),
          RF1 = predict(RF1, newdata = validation),
          RF2 = predict(RF2, newdata = validation)) %>%
  assess()
  
# You are working with a validatr object. Good job!
# 
# Number of folds: 10
# Data type: regression
# Response variable: Sepal.Length
# Number of models fitted: 4 
# Predictions have been calculated.
# 
# Average accuracy:
# 
#   Model Statistic        AE         MAE      MAPE        RMSE     SMAPE
# 1   LM1      Mean 3.7662149 0.251080990 4.3219608 0.303915240 4.3049808
# 2   LM2      Mean 5.2790426 0.351936176 5.9033353 0.449414980 5.8767418
# 3   RF1      Mean 4.8564885 0.323765901 5.5838847 0.394873241 5.5468520
# 4   RF2      Mean 4.5779121 0.305194137 5.2230515 0.372648201 5.1918307
# 5   LM1  Variance 0.5261686 0.002338527 0.6338516 0.003889852 0.6283416
# 6   LM2  Variance 1.2710720 0.005649209 1.7488574 0.006824456 1.6076113
# 7   RF1  Variance 1.1414609 0.005073160 1.8047881 0.008140036 1.6727531
# 8   RF2  Variance 0.8276550 0.003678467 1.3378194 0.005479340 1.2292094
```

### Time-series

This approach can be adopted for time-series forecasting. If the `ts` argument is populated, time-series cross-validation will be carried out. Additionally, the Mean Absolute Scaled Error (MASE) is also calculated. Time-series cross-validation parameters are:

* `start` is the start of the first fold.
* `horizon` is the length of the fold. 
* `shift` is the length of time to move forward.
* `ts` is the name of the variable containing time-series data.

Note that in `predict` a bit of work needs to be done to ensure `Arima()` returns a numeric vector of predictions.

```{r}
require(forecast)
require(lubridate)

data <- data.frame(Date = dmy(paste("1/1/", as.numeric(time(nhtemp)))),
                   Temperature = as.numeric(nhtemp))

data %>% 
  validatr(y = Temperature, ts = Date, start = dmy("1/1/1960"),
           horizon = "3 years", shift = "1 year") %>% 
  model(ARIMA = Arima(train$Temperature),
        AA = auto.arima(train$Temperature),
        LM = lm(Temperature ~ Date, data = train)) %>% 
  predict(ARIMA = as.numeric(forecast(ARIMA, h = nrow(validation))$mean),
          AA = as.numeric(forecast(AA, h = 3)$mean),
          LM = predict(LM, newdata = validation),
          Benchmark = mean(train$Temperature)) %>% 
  assess() %>% 
  autoplot()
```

![](man/figures/autoplot-example.png)

### Classification

If the response variable `y` is either a character, factor or Boolean, classification accuracy measures will be calculated.

Binary and multi-class models can be assessed. If the response variable is a Boolean binary classification measures will be calculated by `assess()`. Positives are denoted by `TRUE` and negatives by `FALSE`. Otherwise, as long as three or more classes are present multi-class measures are calculated.

```{r}
require(validatr)
require(MASS)
require(randomForest)

iris %>% 
  validatr(y = Species, k = 5) %>%
  model(LDA = lda(Species ~ ., data = train),
        QDA = qda(Species ~ ., data = train),
        RF = randomForest(Species ~ ., data = train)) %>%
  predict(LDA = predict(LDA, newdata = validation)$class,
          QDA = predict(QDA, newdata = validation)$class,
          RF = predict(RF, newdata = validation)) %>%
  assess() %>% 
  autoplot()
```

## Benchmark models

Benchmark models can also be included by adding them in the `predict()` function and using the `train` dataset.

```{r}
iris %>% 
  validatr(Sepal.Length, k = 3) %>%
  model(Model1 = lm(Sepal.Length ~ ., data = train),
        Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
  predict(Model1 = predict(Model1, newdata = validation),
          Model2 = predict(Model2, newdata = validation),
          Benchmark_median = median(train$Sepal.Length),
          Benchmark_mean = mean(train$Sepal.Length)) %>% 
  assess() %>% 
  autoplot()
```


## Future development

* Quantile forecast accuracy measures, e.g., pinball loss.
* Parallelisation. Embarrassingly parallel. Just send every list element/model to a separate cpu.
* Allow greater verb flexibility. `assess()` should behave differently if it is used after `validatr()` or `model()` functions. If used after `validatr()` maybe it can assess the data for null values or any other issues. Not sure what it could do after `model()`, but something to think about.
* Better integration with `dplyr`. For example, if data is grouped then each group should be modelled and assessed. Can work around this by using loops and then concatenating the `object$accuracy$average_accuracy` elements, but would be cool to be able to use `group_by` instead.


## Caveat

As this package is in early development there may be errors and bugs that render your analysis invalid. The irony is not lost on the author.
