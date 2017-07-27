# validatr

## Idea

Fits various models on training sets and calculates accuracy measures. Lots of packages have cross-validation functionality, but it's not very useful if you want to compare a model fit with a different package's method. The intention of this package is to allow for all other package methods to be assessed under identical conditions.

## Example

Aiming for ease of use. Currently the following code works. Note that it is necessary to have the Model and Prediction strings in the same order. While not a big deal, I would like to set things up to be more general and less prone to error in the future.

```{r}
kfold_cv(iris, k = 3) %>%
  fit_models("Model1 = lm(Sepal.Length ~ ., data = train)",
             "Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)") %>%
  calc_predictions("Prediction1 = predict(Model1, newdata = test)",
                   "Prediction2 = predict(Model2, newdata = test)") %>%
  calc_accuracy(y = "Sepal.Length", yhat = c("Prediction1", "Prediction2"))
```
Other improvements planned:

* Remove all those awful quotes - need to learn more about NSE!
* Set up `fit_models` and `calc_predictions` functions so that strings do not need to be in same order. Code should be able to detect which model prediction expressions/strings are referring to. Maybe specify `Model1 = ` instead of `Prediction1 = ` for consistency?
* Remove the need to specify `y = "Sepal.Length"` since we should already know "Sepal.Length" was used as the response. Similarly for `yhat` since the model names have already been input.
