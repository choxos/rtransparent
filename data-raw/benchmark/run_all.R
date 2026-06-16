#!/usr/bin/env Rscript

# Accuracy benchmark for rtransparent (COI, funding, registration).
#
# Reproduces the validation approach of Serghiou et al. (2021, PLOS Biology,
# doi:10.1371/journal.pbio.3001107): for each human-labeled validation article,
# fetch its NCBI PMC full-text XML, run the current detectors, and compare the
# predictions to the human labels. Writes inst/benchmark/results.csv and
# inst/benchmark/results.md.
#
# Usage (from the repo root):
#   Rscript data-raw/benchmark/run_all.R          # full labeled test set
#   Rscript data-raw/benchmark/run_all.R 30       # quick 30-article smoke run
#
# Requirements:
#   * the validation xlsx under paper/osf_data/3_algorithm-validation/...
#   * the readxl package
#   * network access to NCBI (set the ENTREZ_KEY env var to raise the rate limit)
#
# Downloaded XML and detector predictions are cached under
# data-raw/benchmark/.cache/ (git-ignored), so re-runs are fast and offline.

suppressWarnings(suppressMessages({
  ok <- requireNamespace("readxl", quietly = TRUE) &&
    requireNamespace("devtools", quietly = TRUE)
}))
if (!ok) stop("This benchmark needs the 'readxl' and 'devtools' packages.")

args <- commandArgs(trailingOnly = TRUE)
sample_n <- if (length(args) >= 1) suppressWarnings(as.integer(args[[1]])) else NA_integer_

# ---- paths -----------------------------------------------------------------

find_root <- function() {
  d <- normalizePath(getwd())
  while (!file.exists(file.path(d, "DESCRIPTION"))) {
    parent <- dirname(d)
    if (identical(parent, d)) stop("Run this script from within the rtransparent repo.")
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

# ---- indicator specification ----------------------------------------------

spec <- list(
  coi      = list(true = "coi_true.xlsx",      false = "coi_false.xlsx",
                  label = "isCOI",       pred = "is_coi_pred"),
  fund     = list(true = "fund_true.xlsx",     false = "fund_false.xlsx",
                  label = "isFunding",   pred = "is_fund_pred"),
  register = list(true = "register_true.xlsx", false = "register_false.xlsx",
                  label = "is_register", pred = "is_register_pred")
)

as_lgl <- function(x) {
  if (is.logical(x)) return(x)
  if (is.numeric(x)) return(x != 0)
  tolower(trimws(as.character(x))) %in% c("true", "t", "1", "yes")
}

# Read one indicator's labeled, XML-available, held-out test rows.
load_indicator <- function(s) {
  rd <- function(f) {
    d <- readxl::read_excel(file.path(TIDY, f))
    data.frame(
      pmcid   = stringr::str_extract(d[["article"]], "PMC[0-9]+"),
      label   = as_lgl(d[[s$label]]),
      is_test = as_lgl(d[["is_test"]]),
      is_xml  = as_lgl(d[["is_xml"]]),
      stringsAsFactors = FALSE
    )
  }
  d <- rbind(
    transform(rd(s$true),  stratum = "true"),
    transform(rd(s$false), stratum = "false")
  )
  keep <- d$is_test & d$is_xml & !is.na(d$label) & !is.na(d$pmcid)
  d[keep, c("pmcid", "label", "stratum")]
}

indicators <- lapply(spec, load_indicator)
for (k in names(indicators)) {
  message(sprintf("  %-9s eligible test articles: %d", k, nrow(indicators[[k]])))
}

# ---- fetch + detect (cached) ----------------------------------------------

pmcids <- unique(unlist(lapply(indicators, function(d) d$pmcid)))
if (!is.na(sample_n)) pmcids <- utils::head(pmcids, sample_n)
message(sprintf("Articles to process: %d", length(pmcids)))

pred_cache_path <- file.path(CACHE, "predictions.rds")
preds <- if (file.exists(pred_cache_path)) readRDS(pred_cache_path) else NULL

getp <- function(r, col) if (col %in% names(r)) as.logical(r[[col]][1]) else NA

detect_one <- function(pmcid) {
  dest <- file.path(CACHE, paste0(pmcid, ".xml"))
  was_cached <- file.exists(dest) && file.info(dest)$size > 0
  path <- .fetch_pmc_xml(pmcid, dest)
  if (!was_cached && !is.null(path)) Sys.sleep(0.34)  # be polite to NCBI on live calls
  if (is.null(path)) {
    return(data.frame(pmcid = pmcid, is_success = FALSE,
                      is_coi_pred = NA, is_fund_pred = NA, is_register_pred = NA))
  }
  r <- tryCatch(rt_all_pmc(path, remove_ns = TRUE), error = function(e) NULL)
  if (is.null(r) || !isTRUE(r$is_success[1])) {
    return(data.frame(pmcid = pmcid, is_success = FALSE,
                      is_coi_pred = NA, is_fund_pred = NA, is_register_pred = NA))
  }
  data.frame(pmcid = pmcid, is_success = TRUE,
             is_coi_pred = getp(r, "is_coi_pred"),
             is_fund_pred = getp(r, "is_fund_pred"),
             is_register_pred = getp(r, "is_register_pred"))
}

todo <- setdiff(pmcids, preds$pmcid)
message(sprintf("Need to fetch/detect: %d (cached: %d)",
                length(todo), length(pmcids) - length(todo)))

for (i in seq_along(todo)) {
  preds <- rbind(preds, detect_one(todo[i]))
  if (i %% 25 == 0 || i == length(todo)) {
    saveRDS(preds, pred_cache_path)
    message(sprintf("  processed %d/%d", i, length(todo)))
  }
}
if (length(todo)) saveRDS(preds, pred_cache_path)

# ---- evaluate --------------------------------------------------------------

reference <- tryCatch(
  utils::read.csv(file.path(OUT, "reference_fig2.csv"), stringsAsFactors = FALSE),
  error = function(e) NULL
)

pkg_version <- as.character(utils::packageVersion("rtransparent"))

results <- list()
for (k in names(indicators)) {
  d <- indicators[[k]]
  d <- d[d$pmcid %in% pmcids, ]
  m <- merge(d, preds, by = "pmcid", all.x = TRUE)
  ev <- m[m$is_success %in% TRUE & !is.na(m[[spec[[k]]$pred]]), ]

  n_eligible <- nrow(d)
  n_eval <- nrow(ev)
  metrics <- .benchmark_metrics(ev[[spec[[k]]$pred]], ev$label, strata = ev$stratum)
  metrics$indicator <- k
  metrics$subset <- "xml"
  metrics$n_eval <- n_eval
  metrics$n_eligible <- n_eligible
  metrics$coverage <- round(n_eval / n_eligible, 3)
  metrics$pkg_version <- pkg_version
  results[[k]] <- metrics
  message(sprintf("  %-9s evaluated %d/%d (coverage %.0f%%)",
                  k, n_eval, n_eligible, 100 * n_eval / n_eligible))
}

results_df <- do.call(rbind, results)
results_df <- results_df[, c("indicator", "subset", "metric", "point",
                             "median", "lo", "hi", "n_eval", "n_eligible",
                             "coverage", "pkg_version")]
write.csv(results_df, file.path(OUT, "results.csv"), row.names = FALSE)
message("Wrote ", file.path(OUT, "results.csv"))

# ---- markdown report -------------------------------------------------------

fmt <- function(x) ifelse(is.na(x), "NA", sprintf("%.1f", x))
ref_val <- function(ind, met) {
  if (is.null(reference)) return(NA_real_)
  r <- reference[reference$indicator == ind & reference$subset == "xml" &
                   reference$metric == met, ]
  if (!nrow(r)) NA_real_ else r$median[1]
}
ref_ci <- function(ind, met) {
  if (is.null(reference)) return("")
  r <- reference[reference$indicator == ind & reference$subset == "xml" &
                   reference$metric == met, ]
  if (!nrow(r)) "" else sprintf("%s [%s, %s]", fmt(r$median[1]), fmt(r$lo[1]), fmt(r$hi[1]))
}

headline <- c("Sensitivity", "Specificity", "PPV", "NPV", "Accuracy")

con <- file(file.path(OUT, "results.md"), open = "w")
writeLines(c(
  "# rtransparent accuracy benchmark",
  "",
  sprintf("Package version %s. Detectors run on NCBI PMC full-text XML for the",
          pkg_version),
  "human-labeled held-out test articles of Serghiou et al. (2021), compared to",
  "the published Fig 2 (XML subset). Bootstrap: 2000 resamples, unweighted",
  "(see data-raw/benchmark/README.md). Current values are point [95% CI].",
  ""
), con)

for (k in names(results)) {
  m <- results[[k]]
  cov <- m$coverage[1]; ne <- m$n_eval[1]; nel <- m$n_eligible[1]
  writeLines(c(
    sprintf("## %s", toupper(k)),
    sprintf("Coverage: %d / %d articles fetched and scored (%.0f%%).", ne, nel, 100 * cov),
    "",
    "| Metric | Current [95% CI] | Paper Fig 2 (xml) |",
    "|---|---|---|"
  ), con)
  for (met in headline) {
    row <- m[m$metric == met, ]
    cur <- sprintf("%s [%s, %s]", fmt(row$point), fmt(row$lo), fmt(row$hi))
    writeLines(sprintf("| %s | %s | %s |", met, cur, ref_ci(k, met)), con)
  }
  writeLines("", con)
}
close(con)
message("Wrote ", file.path(OUT, "results.md"))
