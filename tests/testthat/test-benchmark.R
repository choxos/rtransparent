# Benchmark engine unit tests -------------------------------------------------

test_that(".eval_metrics computes a known confusion matrix", {
  pred  <- c(TRUE, TRUE, FALSE, FALSE, TRUE)
  label <- c(TRUE, FALSE, FALSE, FALSE, TRUE)
  m <- rtransparent:::.eval_metrics(pred, label)

  expect_equal(c(m$TP, m$FP, m$TN, m$FN), c(2, 1, 2, 0))
  expect_equal(m$Sensitivity, 100)
  expect_equal(round(m$Specificity, 1), 66.7)
  expect_equal(round(m$PPV, 1), 66.7)
  expect_equal(m$NPV, 100)
  expect_equal(m$Accuracy, 80)
})

test_that(".eval_metrics drops NA pairs", {
  m <- rtransparent:::.eval_metrics(c(TRUE, NA, FALSE), c(TRUE, TRUE, NA))
  expect_equal(m$n, 1)
})

test_that(".eval_boot is reproducible and .eval_summarize returns valid CIs", {
  p <- rep(c(TRUE, FALSE), 25)
  l <- p
  l[1:5] <- !l[1:5]

  b1 <- rtransparent:::.eval_boot(p, l, n_boot = 200, seed = 1306)
  b2 <- rtransparent:::.eval_boot(p, l, n_boot = 200, seed = 1306)
  expect_identical(b1, b2)

  s <- rtransparent:::.eval_summarize(b1)
  expect_true(all(c("metric", "median", "lo", "hi") %in% names(s)))
  expect_true(all(s$lo <= s$median & s$median <= s$hi, na.rm = TRUE))
})


# Fixture integration: regression guard against the committed baseline --------

test_that("detectors meet the benchmark baseline on cached fixtures", {
  skip_on_cran()

  fx <- test_path("fixtures", "benchmark")
  skip_if(!file.exists(file.path(fx, "labels.rds")), "no benchmark fixtures")

  meta <- readRDS(file.path(fx, "labels.rds"))
  labels <- meta$labels
  baseline <- meta$baseline

  preds <- do.call(rbind, lapply(labels$pmcid, function(id) {
    r <- rtransparent::rt_all_pmc(file.path(fx, paste0(id, ".xml")), remove_ns = TRUE)
    getp <- function(col) if (col %in% names(r)) as.logical(r[[col]][1]) else NA
    data.frame(pmcid = id, is_coi_pred = getp("is_coi_pred"),
               is_fund_pred = getp("is_fund_pred"),
               is_register_pred = getp("is_register_pred"))
  }))

  m <- merge(labels, preds, by = "pmcid")
  ind <- list(coi = c("isCOI", "is_coi_pred"),
              fund = c("isFunding", "is_fund_pred"),
              register = c("is_register", "is_register_pred"))

  for (k in names(ind)) {
    lab <- m[[ind[[k]][1]]]
    pr <- m[[ind[[k]][2]]]
    keep <- !is.na(lab) & !is.na(pr)
    if (sum(keep) == 0 || is.null(baseline[[k]])) next
    acc <- mean(as.logical(lab[keep]) == as.logical(pr[keep]))
    expect_gte(acc, baseline[[k]])
  }
})
