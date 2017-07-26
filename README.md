# validatr

## Idea

Fits various models on training sets and calculates accuracy measures. Lots of packages have cross-validation functionality, but it's not very useful if you want to compare a model fit with a different package's method. The intention of this package is to allow for all other package methods to be assessed under identical conditions.

## Example

Aiming for ease of use. At the moment the goal is to get to something like:

```{r}
kfold_cv(iris, k = 3) %>%
  fit_models("Model1 = lm(Sepal.Length ~ ., data = train)",
             "Model2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)") %>% 
  get_predictions("predict(Model1, newdata = test)",
                  "predict(Model2, newdata = test)") %>% 
  get_accuracy(y = "Sepal.Length")
```
In the future I'd like to

* Remove all those awful quotes
* Make it so that "Model1", "Model2", etc. don't need to be specified. Need it atm as not sure how to add to the `predict` functions since `predict` might not be structured the same in all packages (or even be called that).
* Remove the need to specify `y = "Sepal.Length"` since we should already know "Sepal.Length" was used as the response.
