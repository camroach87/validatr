# validatr <img src="man/figures/logo.png" align="right" width="140" />

[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](http://www.repostatus.org/badges/latest/active.svg)](http://www.repostatus.org/#active)
[![Build Status](https://travis-ci.org/camroach87/validatr.svg?branch=master)](https://travis-ci.org/camroach87/validatr)
[![codecov](https://codecov.io/github/camroach87/validatr/branch/master/graphs/badge.svg)](https://codecov.io/github/camroach87/validatr)
[![CRAN_Status_Badge](http://www.r-pkg.org/badges/version/validatr)](https://CRAN.R-project.org/package=validatr)


Fits various models on training sets and calculates accuracy measures. Lots of packages have cross-validation functionality, but it's not very useful if you want to compare a model fit with a different package's method. The intention of this package is to allow for all other package methods to be assessed under identical conditions.

## Installation

From your R console, simply run:

```{r}
install.packages("devtools")
require(devtools)
devtools::install_github("camroach87/validatr")
```

## Examples

__Important:__ Make sure that the model names are consistent all the way through. For example, don't call something `LM1` in the `fit_models` function and then `Prediction_LM1` in the `calc_predictions` function. The code will fail in weird and mysterious ways which I have not yet explored. There are no plans to allow for this functionality as I believe this will make the code more difficult to use without really adding substantial benefits.

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
  calc_accuracy(y = "Sepal.Length", average_folds = TRUE)
```

Gives the following output:

|Model |Statistic |        AE|       MAE|      MAPE|      RMSE|    SMAPE1|    SMAPE2|
|:-----|:---------|---------:|---------:|---------:|---------:|---------:|---------:|
|LM1   |Mean      | 3.7746483| 0.2516432| 4.3374769| 0.3078372| 4.3187187| 4.3187187|
|LM2   |Mean      | 5.2568465| 0.3504564| 5.8724142| 0.4471111| 5.8449199| 5.8449199|
|RF1   |Mean      | 4.5588906| 0.3039260| 5.2419599| 0.3785653| 5.1898804| 5.1898804|
|RF2   |Mean      | 4.4240861| 0.2949391| 5.0584428| 0.3649202| 5.0241899| 5.0241899|
|LM1   |Variance  | 0.7355174| 0.0032690| 0.8938284| 0.0032226| 0.9062686| 0.9062686|
|LM2   |Variance  | 1.1270407| 0.0050091| 1.1159420| 0.0095126| 1.0907444| 1.0907444|
|RF1   |Variance  | 0.4662113| 0.0020721| 0.7750321| 0.0025859| 0.7230052| 0.7230052|
|RF2   |Variance  | 0.6056114| 0.0026916| 0.7217327| 0.0034664| 0.7250793| 0.7250793|


The parameter `average_folds` can be set to `FALSE` if you wish to see the accuracy measures calculated on the validation set of each fold:

| Fold|Model |       AE|       MAE|     MAPE|      RMSE|   SMAPE1|   SMAPE2|
|----:|:-----|--------:|---------:|--------:|---------:|--------:|--------:|
|    1|LM1   | 3.919532| 0.2613022| 4.269307| 0.3514990| 4.306895| 4.306895|
|    1|LM2   | 4.950871| 0.3300581| 5.351763| 0.4282582| 5.344440| 5.344440|
|    1|RF1   | 5.175918| 0.3450612| 5.625830| 0.4082264| 5.701605| 5.701605|
|    1|RF2   | 4.654162| 0.3102775| 5.089117| 0.3784462| 5.138789| 5.138789|
|    2|LM1   | 5.365251| 0.3576834| 6.095026| 0.4004286| 6.061043| 6.061043|
|    2|LM2   | 6.582182| 0.4388121| 7.227009| 0.5320266| 7.288201| 7.288201|
|    2|RF1   | 5.611479| 0.3740986| 6.432847| 0.4086647| 6.378851| 6.378851|
|    2|RF2   | 5.591229| 0.3727486| 6.351772| 0.4054762| 6.311282| 6.311282|
|    3|LM1   | 3.233553| 0.2155702| 3.460180| 0.2723689| 3.511033| 3.511033|
|    3|LM2   | 5.370469| 0.3580312| 5.760624| 0.4500886| 5.815435| 5.815435|
|  ...|   ...|      ...|       ...|      ...|       ...|      ...|      ...|


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
               LM = lm(Temp ~ Year, data = train)) %>% 
    calc_predictions(ARIMA = as.numeric(forecast(ARIMA, h = nrow(validation))$mean),
                     LM = predict(LM, newdata = validation)) %>% 
    calc_accuracy(y = "Temp", average_folds = FALSE) %>% 
    autoplot()
```

If `average_folds` is set to `FALSE` we can use the `autoplot()` function to produce density plots of each accuracy measure using the results from each fold. An example of the plot is given below:

![](man/figures/autoplot-example.png)

### Classification

__TODO__

## Future improvements

Other improvements planned:

* Remove the need to specify `y = "Sepal.Length"` since we should already know "Sepal.Length" was used as the response.
* Still need to add assessment/model fitting for classification models.
* Quantile forecast assessments, i.e., pinball loss.
* An `autoplot` function that uses ggplot2 to visualise accuracy.
