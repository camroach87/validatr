# validatr <img src="man/figures/logo.png" align="right" width="140" />

[![Project Status: WIP – Initial development is in progress, but there has not yet been a stable, usable release suitable for the public.](http://www.repostatus.org/badges/latest/wip.svg)](http://www.repostatus.org/#wip)
[![Build Status](https://travis-ci.org/camroach87/validatr.svg?branch=master)](https://travis-ci.org/camroach87/validatr)
[![codecov](https://codecov.io/github/camroach87/validatr/branch/master/graphs/badge.svg)](https://codecov.io/github/camroach87/validatr)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/validatr)](https://CRAN.R-project.org/package=validatr)


Fits various models on training sets and calculates accuracy measures. Lots of packages have cross-validation functionality, but it's not very useful if you want to compare a model fit with a different package's method. The intention of this package is to allow for all other package methods to be assessed under identical conditions.


# Table of contents

* [Installation](#installation)
* [Usage](#usage)
* [Examples](#examples)
    * [Regression](#regression)
    * [Time-series](#time-series)
    * [Classification](#classification)
* [Future development](#future-development)

## Installation

From your R console, simply run:

```{r}
install.packages("devtools")
require(devtools)
devtools::install_github("camroach87/validatr")
```

## Usage

Essentially, validatr works by first creating a `validatr` object which contains the cross-validation data. Next, models are fit to each training data set using `fit_models()`. Predictions are then calculated for each validation dataset using `calc_predictions()`. Finally, accuracy measures are calculated using the `calc_accuracy()` function.

```{r}
validatr(data) %>% 
  fit_models(<First model name> = <Code to fit first model on train data>,
             <Second model name> = <Code to fit another model on train data>) %>% 
  calc_predictions(<First model name> = <Code to return vector of predictions>,
                   <Second model name> = <Code to return vector of predictions>) %>% 
  calc_accuracy(y = <Dependent variable name>)
```

__Important:__ Make sure that the model names are consistent all the way through. For example, don't call something `LM1` in the `fit_models` function and then `Prediction_LM1` in the `calc_predictions` function. The code will fail in weird and mysterious ways which I have not yet explored. There are no plans to allow for this functionality as I believe this will make the code more difficult to use without really adding substantial benefits.

## Examples

Examples for regression, time-series and classification analysis are given below. 

### Regression

A contrived, but hopefully illuminating example is given below. Here, four separate models from two different packages are fit to each fold's training data. The accuracy of each measure is then calculated on each fold's validation data.


```{r}
require(validatr)
require(randomForest)

validatr(iris, k = 10) %>%
  fit_models(LM1 = lm(Sepal.Length ~ ., data = train),
             LM2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train),
             RF1 = randomForest(Sepal.Length ~ ., data = train, ntree = 10),
             RF2 = randomForest(Sepal.Length ~ ., data = train, ntree = 500)) %>%
  calc_predictions(LM1 = predict(LM1, newdata = validation),
                   LM2 = predict(LM2, newdata = validation),
                   RF1 = predict(RF1, newdata = validation),
                   RF2 = predict(RF2, newdata = validation)) %>%
  calc_accuracy(y = "Sepal.Length")
```

Gives a list containing accuracy measures in the `accuracy` attribute. The element `accuracy$average_accuracy` contains the following output:

|Model |Statistic |        AE|       MAE|      MAPE|      RMSE|     SMAPE|
|:-----|:---------|---------:|---------:|---------:|---------:|---------:|
|LM1   |Mean      | 3.7950136| 0.2530009| 4.3516055| 0.3106914| 4.3318653|
|LM2   |Mean      | 5.2279834| 0.3485322| 5.8394677| 0.4438729| 5.8149103|
|RF1   |Mean      | 4.6498967| 0.3099931| 5.3175795| 0.3797383| 5.2790324|
|RF2   |Mean      | 4.4009540| 0.2933969| 5.0240645| 0.3626210| 4.9876589|
|LM1   |Variance  | 0.2791718| 0.0012408| 0.3347331| 0.0020096| 0.3032631|
|LM2   |Variance  | 2.0361152| 0.0090494| 2.8960415| 0.0101204| 2.5389126|
|RF1   |Variance  | 0.4620071| 0.0020534| 0.7933737| 0.0032892| 0.6486826|
|RF2   |Variance  | 0.6232808| 0.0027701| 1.0119045| 0.0047078| 0.8710760|

### Time-series

This approach can be adopted for time-series forecasting. If `data_type` is set to "ts", time-series cross-validation will be carried out. Additionally, the Mean Absolute Scaled Error (MASE) is also calculated. The time-series cross-validation parameters are:

* `start` is the start of the first fold.
* `horizon` is the length of the fold. 
* `shift` is the length of time to move forward.
* `ts` is the name of the variable containing time-series data.

Note that in `calc_predictions` a bit of work needs to be done to ensure `Arima()` returns a numeric vector of predictions. Since the number of rows in the final fold may be less than the horizon value of three, we specify `h = nrow(validation)` rather than setting it to 3.

__Important:__ have not tested this for ts variables that are of type POSIX or date yet.

```{r}
require(datasets)
require(forecast)

data = data.frame(Year = time(nhtemp),
                  Temp = nhtemp)

validatr(data, data_type = "ts", start = 1960, horizon = 3, shift = 1,
         ts = "Year") %>% 
    fit_models(ARIMA = Arima(train$Temp),
               Auto_ARIMA = auto.arima(train$Temp),
               LM = lm(Temp ~ Year, data = train)) %>% 
    calc_predictions(ARIMA = as.numeric(forecast(ARIMA, h = nrow(validation))$mean),
                     Auto_ARIMA = as.numeric(forecast(Auto_ARIMA, h = nrow(validation))$mean),
                     LM = predict(LM, newdata = validation)) %>% 
    calc_accuracy(y = "Temp") %>% 
    autoplot()
```

![](man/figures/autoplot-example.png)

### Classification

```{r}
require(validatr)
require(MASS)
require(randomForest)

validatr(iris, data_type = "classification", k = 5) %>%
  fit_models(LDA = lda(Species ~ ., data = train),
             QDA = qda(Species ~ ., data = train),
             RF = randomForest(Species ~ ., data = train)) %>%
  calc_predictions(LDA = predict(LDA, newdata = validation)$class,
                   QDA = predict(QDA, newdata = validation)$class,
                   RF = predict(RF, newdata = validation)) %>%
  calc_accuracy(y = "Species") %>% 
  autoplot()
```

## Future development

Other improvements planned:

* Remove the need to specify `y = "Sepal.Length"` since we should already know "Sepal.Length" was used as the response.
* Accuracy measures for classification models.
* Quantile forecast assessments, i.e., pinball loss.
* Parallelisation. Embarrassingly parallel. Just send every list element/model to a separate cpu.
