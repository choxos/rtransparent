# Accuracy benchmark engine.
#
# Reproduces the operating-characteristic metrics of Serghiou et al. (2021,
# PLOS Biology, doi:10.1371/journal.pbio.3001107) for the current detectors.
# These are internal helpers used by data-raw/benchmark/run_all.R and by the
# benchmark regression test; they take a logical prediction vector (the current
# package output) and a logical label vector (human ground truth).
#
# v1 reports unweighted held-out-test metrics. The paper additionally reweights
# each sampling stratum back to the population (importance sampling); that
# weighting is intentionally omitted here (see data-raw/benchmark/README.md), so
# absolute counts differ from Fig 2 while the rates remain comparable.


# Confusion-matrix metrics from paired logical vectors. Returns a one-row data
# frame of counts and percentages, with the same metric names as the paper.
.eval_metrics <- function(pred, label) {

  pred <- as.logical(pred)
  label <- as.logical(label)
  keep <- !is.na(pred) & !is.na(label)
  pred <- pred[keep]
  label <- label[keep]

  TP <- sum(pred & label)
  FP <- sum(pred & !label)
  TN <- sum(!pred & !label)
  FN <- sum(!pred & label)
  n <- TP + FP + TN + FN

  pct <- function(num, den) if (den > 0) 100 * num / den else NA_real_

  Sensitivity <- pct(TP, TP + FN)
  Specificity <- pct(TN, TN + FP)

  data.frame(
    TP = TP, FP = FP, TN = TN, FN = FN, n = n,
    Sensitivity = Sensitivity,
    Specificity = Specificity,
    PPV = pct(TP, TP + FP),
    NPV = pct(TN, TN + FN),
    Accuracy = pct(TP + TN, n),
    AUROC = mean(c(Sensitivity, Specificity)),
    P_true = pct(TP + FN, n),
    P_pred = pct(TP + FP, n),
    P_error = pct(FN - FP, n)
  )
}


# The rate metrics summarized by the bootstrap (raw counts are excluded).
.benchmark_metric_names <- c(
  "Sensitivity", "Specificity", "PPV", "NPV", "Accuracy",
  "AUROC", "P_true", "P_pred", "P_error"
)


# Stratified bootstrap. `strata` assigns each observation to a resampling group
# (e.g. the validation file it came from); resampling is with replacement within
# each stratum, preserving stratum sizes. Returns a data frame with one row per
# bootstrap replicate and one column per rate metric.
.eval_boot <- function(pred, label, strata = NULL, n_boot = 2000L, seed = 1306L) {

  pred <- as.logical(pred)
  label <- as.logical(label)
  if (is.null(strata)) {
    strata <- rep(1L, length(pred))
  }

  idx_by_stratum <- split(seq_along(pred), strata)

  set.seed(seed)
  reps <- vector("list", n_boot)
  for (b in seq_len(n_boot)) {
    samp <- unlist(
      lapply(idx_by_stratum, function(ix) {
        if (length(ix) <= 1L) ix else sample(ix, length(ix), replace = TRUE)
      }),
      use.names = FALSE
    )
    reps[[b]] <- .eval_metrics(pred[samp], label[samp])[.benchmark_metric_names]
  }
  do.call(rbind, reps)
}


# Summarize bootstrap replicates into median and 95% percentile interval (long).
.eval_summarize <- function(boot_df) {

  do.call(rbind, lapply(names(boot_df), function(m) {
    v <- boot_df[[m]]
    data.frame(
      metric = m,
      median = stats::median(v, na.rm = TRUE),
      lo = stats::quantile(v, 0.025, na.rm = TRUE, names = FALSE),
      hi = stats::quantile(v, 0.975, na.rm = TRUE, names = FALSE),
      stringsAsFactors = FALSE
    )
  }))
}


# Point estimate plus bootstrap CI for one indicator. Returns a long data frame:
# metric, point, median, lo, hi.
.benchmark_metrics <- function(pred, label, strata = NULL, n_boot = 2000L,
                               seed = 1306L) {

  point <- .eval_metrics(pred, label)
  ci <- .eval_summarize(.eval_boot(pred, label, strata, n_boot, seed))
  ci$point <- as.numeric(point[ci$metric])
  ci[, c("metric", "point", "median", "lo", "hi")]
}
