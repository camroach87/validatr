context("accuracy")

test_that("accuracy output is tibble", {
  accuracy_df <- kfold_cv(iris, k = 10) %>%
    fit_models("LM1 = lm(Sepal.Length ~ ., data = train)",
               "LM2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)") %>%
    calc_predictions("LM1 = predict(LM1, newdata = validation)",
                     "LM2 = predict(LM2, newdata = validation)") %>%
    calc_accuracy(y = "Sepal.Length", yhat = c("LM1", "LM2"),
                  average_folds = TRUE)

  #expect_equal(is.tibble(accuracy_df), TRUE)
  expect_is(accuracy_df, "tbl_df")
  #expect_output(str(accuracy_df),
  #              "Classes ‘tbl_df’, ‘tbl’ and 'data.frame'")
  expect_equal(names(accuracy_df),
               c("Model", "Statistic", "AE", "MAE", "MAPE", "RMSE", "SMAPE1",
                 "SMAPE2"))
})
