context("accuracy")

test_that("accuracy output is tibble", {
  validatr_obj <- validatr(iris, k = 10) %>%
    fit_models(LM1 = lm(Sepal.Length ~ ., data = train),
               LM2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
    calc_predictions(LM1 = predict(LM1, newdata = validation),
                     LM2 = predict(LM2, newdata = validation)) %>%
    calc_accuracy(y = "Sepal.Length")

  #expect_equal(is.tibble(accuracy_df), TRUE)
  expect_is(validatr_obj, "validatr")
  #expect_output(str(accuracy_df),
  #              "Classes ‘tbl_df’, ‘tbl’ and 'data.frame'")
  expect_equal(names(validatr_obj$accuracy$average_accuracy),
               c("Model", "Statistic", "AE", "MAE", "MAPE", "RMSE", "SMAPE"))
})
