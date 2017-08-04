context("accuracy")

test_that("accuracy output is tibble", {
  validatr_obj <- iris %>%
    validatr(Sepal.Length) %>%
    model(LM1 = lm(Sepal.Length ~ ., data = train),
          LM2 = lm(Sepal.Length ~ Sepal.Width + Petal.Width, data = train)) %>%
    predict(LM1 = predict(LM1, newdata = validation),
            LM2 = predict(LM2, newdata = validation)) %>%
    assess()

  #expect_equal(is.tibble(accuracy_df), TRUE)
  expect_is(validatr_obj, "validatr")
  #expect_output(str(accuracy_df),
  #              "Classes ‘tbl_df’, ‘tbl’ and 'data.frame'")
  expect_equal(names(validatr_obj$accuracy$average_accuracy),
               c("Model", "Statistic", "AE", "MAE", "MAPE", "RMSE", "SMAPE"))
})
