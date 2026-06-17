#!/usr/bin/env Rscript

# Accuracy benchmark for the native data and code sharing detector.
#
# Fetches the NCBI PMC XML of the human-labeled data/code benchmark articles of
# Serghiou et al. (2021), runs the native detector (`.detect_data_code` on the
# text from `.dc_article_text`), and compares to the human labels `isData` /
# `isCode`. Writes inst/benchmark/results_data_code.{csv,md}. These are
# reproducible benchmark and regression metrics for the native detector, not
# untouched external-validation estimates.
#
# Usage (from the repo root, needs readxl + network to NCBI):
#   Rscript data-raw/benchmark/run_data_code.R
#
# Notes on the gold labels: an article is data-positive (`isData`) only in the
# data validation files; code_true contributes `isCode` but its `isData` is NA
# (never assessed). Aggregation therefore preserves NA so unlabeled articles are
# excluded from the relevant metric.

suppressWarnings(suppressMessages({
  ok <- requireNamespace("readxl", quietly = TRUE) &&
    requireNamespace("devtools", quietly = TRUE)
}))
if (!ok) stop("This benchmark needs the 'readxl' and 'devtools' packages.")

find_root <- function() {
  d <- normalizePath(getwd())
  while (!file.exists(file.path(d, "DESCRIPTION"))) {
    parent <- dirname(d)
    if (identical(parent, d)) stop("Run from within the rtransparent repo.")
    d <- parent
  }
  d
}

ROOT  <- find_root()
TIDY  <- file.path(ROOT, "paper/osf_data/3_algorithm-validation/data/tidy_data")
CACHE <- file.path(ROOT, "data-raw/benchmark/.cache")
OUT   <- file.path(ROOT, "inst/benchmark")
dir.create(CACHE, recursive = TRUE, showWarnings = FALSE)
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
suppressMessages(devtools::load_all(ROOT, quiet = TRUE))

as_lgl <- function(x) {
  if (is.logical(x)) return(x)
  if (is.numeric(x)) return(x != 0)
  tolower(trimws(as.character(x))) %in% c("true", "t", "1", "yes")
}

load_file <- function(f) {
  d <- as.data.frame(readxl::read_excel(file.path(TIDY, f)))
  data.frame(
    pmcid  = stringr::str_extract(d[["article"]], "PMC[0-9]+"),
    isData = if ("isData" %in% names(d)) as_lgl(d$isData) else NA,
    isCode = if ("isCode" %in% names(d)) as_lgl(d$isCode) else NA,
    is_test = as_lgl(d$is_test),
    stringsAsFactors = FALSE
  )
}

d <- rbind(load_file("data_true.xlsx"), load_file("data_false.xlsx"),
           load_file("code_true.xlsx"))
d <- d[d$is_test & !is.na(d$pmcid), ]

agg_lab <- function(x) if (all(is.na(x))) NA else any(x, na.rm = TRUE)
pid <- unique(d$pmcid)
d <- data.frame(
  pmcid  = pid,
  isData = vapply(pid, function(p) agg_lab(d$isData[d$pmcid == p]), logical(1)),
  isCode = vapply(pid, function(p) agg_lab(d$isCode[d$pmcid == p]), logical(1)),
  stringsAsFactors = FALSE
)
message(sprintf("Articles: %d (data labeled %d, code labeled %d)",
                nrow(d), sum(!is.na(d$isData)), sum(!is.na(d$isCode))))

pd <- pc <- rep(NA, nrow(d))
for (i in seq_len(nrow(d))) {
  dest <- file.path(CACHE, paste0(d$pmcid[i], ".xml"))
  was_cached <- file.exists(dest) && file.info(dest)$size > 0
  path <- .fetch_pmc_xml(d$pmcid[i], dest)
  if (!was_cached && !is.null(path)) Sys.sleep(0.34)
  if (is.null(path)) next
  ax <- tryCatch(.get_xml(path, remove_ns = TRUE), error = function(e) NULL)
  if (is.null(ax)) next
  found <- .detect_data_code(.dc_article_text(ax))
  pd[i] <- found$is_open_data
  pc[i] <- found$is_open_code
  if (i %% 50 == 0) message(sprintf("  %d/%d", i, nrow(d)))
}

ev <- function(pred, lab) {
  k <- !is.na(pred) & !is.na(lab)
  .eval_metrics(pred[k], lab[k])
}
md <- ev(pd, d$isData)
mc <- ev(pc, d$isCode)

results <- rbind(
  data.frame(indicator = "data", metric = .benchmark_metric_names,
             value = round(as.numeric(md[.benchmark_metric_names]), 1),
             n = md$n),
  data.frame(indicator = "code", metric = .benchmark_metric_names,
             value = round(as.numeric(mc[.benchmark_metric_names]), 1),
             n = mc$n)
)
utils::write.csv(results, file.path(OUT, "results_data_code.csv"), row.names = FALSE)

con <- file(file.path(OUT, "results_data_code.md"), open = "w")
writeLines(c(
  "# Native data and code sharing detector benchmark",
  "",
  sprintf("Package version %s. Native detector vs the human-labeled XML benchmark",
          as.character(utils::packageVersion("rtransparent"))),
  "articles of Serghiou et al. (2021). These are reproducible benchmark and",
  "regression metrics for the native detector, not untouched external-validation",
  "estimates. The published paper reports data",
  "sensitivity ~76% and code sensitivity ~59%; the original oddpub algorithm",
  "scores ~84% / ~97% (sensitivity / specificity) against `isData` on this set.",
  "",
  sprintf("## Data (n = %d)", md$n),
  sprintf("Sensitivity %.1f, Specificity %.1f, PPV %.1f, NPV %.1f, Accuracy %.1f",
          md$Sensitivity, md$Specificity, md$PPV, md$NPV, md$Accuracy),
  "",
  sprintf("## Code (n = %d)", mc$n),
  sprintf("Sensitivity %.1f, Specificity %.1f, PPV %.1f, NPV %.1f, Accuracy %.1f",
          mc$Sensitivity, mc$Specificity, mc$PPV, mc$NPV, mc$Accuracy)
), con)
close(con)
message("Wrote ", file.path(OUT, "results_data_code.md"))
