# validatr

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/camroach87/validatr.svg?branch=master)](https://travis-ci.org/camroach87/validatr)
[![codecov](https://codecov.io/github/camroach87/validatr/branch/master/graphs/badge.svg)](https://codecov.io/github/camroach87/validatr)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/validatr)](https://CRAN.R-project.org/package=validatr)


## Idea

Fits various models on training sets and calculates accuracy measures. Lots of packages have cross-validation functionality, but it's not very useful if you want to compare a model fit with a different package's method. The intention of this package is to allow for all other package methods to be assessed under identical conditions.

## Example

Aiming for ease of use. Note that it is necessary to have the Model and Prediction strings in the same order. While not a big deal, I would like to set things up to be more general and less prone to error in the future.

A contrived, but hopefully illuminating example is given below. Here, four separate models from two different packages are fit to each fold's training data. The accuracy of each measure is then calculated on each fold's validation data.

```{r}
require(randomForest)

kfold_cv(iris, k = 10) %>%
  fit_models(LM1 = lm(Sepal.Length ~ ., data = train),
             LM2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train),
             RF1 = randomForest(Sepal.Length ~ ., data = train, ntree = 10),
             RF2 = randomForest(Sepal.Length ~ ., data = train, ntree = 500)) %>%
  calc_predictions(LM1 = predict(LM1, newdata = validation),
                   LM2 = predict(LM2, newdata = validation),
                   RF1 = predict(RF1, newdata = validation),
                   RF2 = predict(RF2, newdata = validation)) %>%
  calc_accuracy(y = "Sepal.Length", yhat = c("LM1", "LM2", "RF1", "RF2"),
                average_folds = TRUE)
```

Make sure that the model names are consistent all the way through. For example, don't call something `LM1` in the `fit_models` function and then `Prediction_LM1` in the `calc_predictions` function. The code will fail in weird and mysterious ways which I have not yet explored. There are no plans to allow for this functionality as I believe this will make the code more difficult to use without really adding substantial benefits.

## Future improvements

Other improvements planned:

* Remove the need to specify `y = "Sepal.Length"` since we should already know "Sepal.Length" was used as the response. Similarly for `yhat` since the model names have already been input. Haven't bothered moving this function to NSE since these arguments won't be required in the future.
* Different types of cross-validation, e.g. time-series, leave-one-out. Will create a general function `get_folds`.
* Only looking at prediction measures at the moment. Will make the package more general to handle classification models and time-series models. Appropriate accuracy measures will need to be added for these data types.
