test_that("rt_summary reports apparent prevalence and Wilson CI", {
  df <- data.frame(
    is_coi_pred = c(TRUE, TRUE, FALSE, FALSE, TRUE),
    is_fund_pred = c(TRUE, TRUE, TRUE, TRUE, FALSE)
  )
  s <- rt_summary(df, adjust = FALSE)

  expect_s3_class(s, "tbl_df")
  expect_setequal(s$indicator, c("is_coi_pred", "is_fund_pred"))
  coi <- s[s$indicator == "is_coi_pred", ]
  expect_equal(coi$n_articles, 5)
  expect_equal(coi$n_detected, 3)
  expect_equal(coi$percent, 60)
  # Wilson interval is inside [0, 100] and brackets the point estimate.
  expect_gte(coi$conf_low, 0)
  expect_lte(coi$conf_high, 100)
  expect_lt(coi$conf_low, 60)
  expect_gt(coi$conf_high, 60)
})

test_that("rt_accuracy carries a novelty estimate so novelty is corrected", {
  utils::data("rt_accuracy", package = "rtransparent")
  expect_true("is_novelty_pred" %in% rt_accuracy$variable)
  nov <- rt_accuracy[rt_accuracy$variable == "is_novelty_pred", ]
  expect_true(nov$sensitivity > 0 && nov$sensitivity <= 1)
  expect_true(nov$specificity > 0 && nov$specificity <= 1)
  # rt_summary therefore returns a non-NA corrected novelty prevalence.
  df <- data.frame(is_novelty_pred = c(TRUE, FALSE, TRUE, FALSE, FALSE))
  s <- rt_summary(df, adjust = TRUE)
  expect_false(is.na(s$adj_percent[s$indicator == "is_novelty_pred"]))
})

test_that("NA indicator values are excluded from the denominator", {
  df <- data.frame(is_open_data = c(TRUE, FALSE, NA, NA, TRUE))
  s <- rt_summary(df, adjust = FALSE)
  expect_equal(s$n_articles, 3)
  expect_equal(s$n_detected, 2)
  expect_equal(round(s$percent, 1), 66.7)
})

test_that("indicator columns are validated before summarizing or scoring", {
  expect_equal(
    rt_summary(data.frame(is_open_data = c(1, 0, NA)), adjust = FALSE)$percent,
    50
  )
  expect_error(
    rt_summary(data.frame(is_open_data = c(1, 2)), adjust = FALSE),
    "0/1"
  )
  expect_error(
    rt_summary(data.frame(is_open_data = c("TRUE", "FALSE")), adjust = FALSE),
    "logical or numeric"
  )
  expect_error(
    rt_score(data.frame(is_open_data = c(1, 2))),
    "0/1"
  )
})

test_that("the Rogan-Gladen correction recovers a known prevalence", {
  # If apparent = 0.6, se = 0.9, sp = 0.8, true = (0.6 + 0.8 - 1)/(0.9 + 0.8 - 1)
  acc <- data.frame(
    variable = "is_coi_pred", sensitivity = 0.9, specificity = 0.8
  )
  df <- data.frame(is_coi_pred = rep(c(TRUE, FALSE), c(60, 40)))
  s <- rt_summary(df, accuracy = acc)
  expect_equal(s$percent, 60)
  expect_equal(round(s$adj_percent, 4), round(100 * (0.6 + 0.8 - 1) / 0.7, 4))
})

test_that("uninformative detectors give NA corrected prevalence", {
  acc <- data.frame(
    variable = "is_coi_pred", sensitivity = 0.5, specificity = 0.5
  )
  df <- data.frame(is_coi_pred = c(TRUE, FALSE, TRUE))
  s <- rt_summary(df, accuracy = acc)
  expect_true(is.na(s$adj_percent))
})

test_that("rt_summary groups by a column", {
  df <- data.frame(
    is_coi_pred = c(TRUE, FALSE, TRUE, TRUE),
    grp = c("a", "a", "b", "b")
  )
  s <- rt_summary(df, by = "grp", adjust = FALSE)
  expect_true("grp" %in% names(s))
  expect_equal(nrow(s), 2)
  expect_equal(s$percent[s$grp == "a"], 50)
  expect_equal(s$percent[s$grp == "b"], 100)
})

test_that("rt_summary errors on bad input", {
  expect_error(rt_summary(1:10), "data frame")
  expect_error(rt_summary(data.frame(x = 1)), "indicator columns")
  expect_error(rt_summary(data.frame(is_coi_pred = TRUE), conf_level = 2),
               "conf_level")
  expect_error(rt_summary(data.frame(is_coi_pred = TRUE), by = "nope"), "`by`")
})

test_that("rt_score counts the five openness practices by default", {
  df <- data.frame(
    is_coi_pred = c(TRUE, TRUE, FALSE),
    is_fund_pred = c(TRUE, FALSE, FALSE),
    is_register_pred = c(TRUE, FALSE, FALSE),
    is_open_data = c(TRUE, FALSE, FALSE),
    is_open_code = c(TRUE, FALSE, FALSE),
    is_novelty_pred = c(TRUE, TRUE, TRUE)  # excluded from the default count
  )
  scored <- rt_score(df)
  expect_equal(scored$n_indicators, c(5L, 1L, 0L))

  # Including novelty explicitly raises the first article's count to 6.
  scored2 <- rt_score(df, indicators = grep("^is_", names(df), value = TRUE))
  expect_equal(scored2$n_indicators[1], 6L)
})

test_that("rt_score distinguishes unassessed rows from true zero scores", {
  df <- data.frame(
    is_open_data = c(TRUE, NA, FALSE),
    is_open_code = c(NA, NA, FALSE)
  )
  scored <- rt_score(df)
  expect_equal(scored$n_indicators, c(1L, NA_integer_, 0L))
})

test_that("rt_plot returns ggplot objects", {
  skip_if_not_installed("ggplot2")
  data(rt_demo)
  expect_s3_class(rt_plot(rt_demo), "ggplot")
  expect_s3_class(rt_plot(rt_demo, type = "trend", year = "year"), "ggplot")
  # A prevalence plot can be built from an existing summary.
  expect_s3_class(rt_plot(rt_summary(rt_demo)), "ggplot")
  # Trend needs article-level data, not a summary.
  expect_error(rt_plot(rt_summary(rt_demo), type = "trend"), "article-level")
})

test_that("bundled datasets have the documented shape", {
  data(rt_demo)
  data(rt_accuracy)
  expect_equal(nrow(rt_demo), 1200)
  expect_true(all(c("is_coi_pred", "is_open_code", "year", "type") %in% names(rt_demo)))
  expect_setequal(
    names(rt_accuracy),
    c("variable", "label", "sensitivity", "specificity", "source")
  )
  expect_true(all(rt_accuracy$sensitivity > 0 & rt_accuracy$sensitivity <= 1))
})
