#!/usr/bin/env Rscript

# Accuracy benchmark for the novelty and replication detectors.
#
# Unlike COI/funding/registration/data/code, the novelty and replication
# indicators have no gold standard in Serghiou et al. (2021). This benchmark
# uses a hand-labeled gold set built by the maintainer from a fresh sample of
# open-access PMC articles (2023-2026), stored in
# `data-raw/benchmark/labels_novelty_replication.csv`. The labels follow the
# detectors' intent:
#   * Novelty TRUE  = the article claims its OWN work is novel / first / fills a
#     stated gap ("to our knowledge the first study to ...", "we present a novel
#     ...", "X has not been investigated"). Historical firstness about others
#     ("first reported in 1882 by ..."), enumeration ("the first step is ..."),
#     and generic "novel <compound/device>" descriptors are FALSE.
#   * Replication TRUE = a replication / external-or-independent validation
#     component is reported as performed (or a prior published finding was
#     reproduced). Future "should be validated", an internal train/test split
#     alone, "reproducible methods", and figure "reproduced with permission" are
#     FALSE.
#
# Fetches the PMC XML by id (cached), runs rt_all_pmc(), and compares
# is_novelty_pred / is_replication_pred to the gold labels. Writes
# inst/benchmark/results_novelty_replication.{csv,md}.
#
# Usage (from the repo root, needs network to NCBI/Europe PMC for the first run):
#   Rscript data-raw/benchmark/run_novelty_replication.R

suppressWarnings(suppressMessages({
  ok <- requireNamespace("devtools", quietly = TRUE)
}))
if (!ok) stop("This benchmark needs the 'devtools' package.")

find_root <- function() {
  d <- normalizePath(getwd())
  while (!file.exists(file.path(d, "DESCRIPTION"))) {
    parent <- dirname(d)
    if (identical(parent, d)) stop("Run from within the rtransparent repo.")
    d <- parent
  }
  d
}

ROOT   <- find_root()
LABELS <- file.path(ROOT, "data-raw/benchmark/labels_novelty_replication.csv")
CACHE  <- file.path(ROOT, "data-raw/benchmark/.cache")
OUT    <- file.path(ROOT, "inst/benchmark")
dir.create(CACHE, recursive = TRUE, showWarnings = FALSE)
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
suppressMessages(devtools::load_all(ROOT, quiet = TRUE))

as_lgl <- function(x) tolower(trimws(as.character(x))) %in% c("true", "t", "1", "yes")

d <- utils::read.csv(LABELS, stringsAsFactors = FALSE)
d$is_novelty <- as_lgl(d$is_novelty)
d$is_replication <- as_lgl(d$is_replication)
message(sprintf("Gold articles: %d (novelty positives %d, replication positives %d)",
                nrow(d), sum(d$is_novelty), sum(d$is_replication)))

pn <- pr <- rep(NA, nrow(d))
for (i in seq_len(nrow(d))) {
  dest <- file.path(CACHE, paste0(d$pmcid[i], ".xml"))
  was_cached <- file.exists(dest) && file.info(dest)$size > 0
  path <- tryCatch(.fetch_pmc_xml(d$pmcid[i], dest), error = function(e) NULL)
  if (!was_cached && !is.null(path)) Sys.sleep(0.34)
  if (is.null(path)) next
  res <- tryCatch(rt_all_pmc(path, remove_ns = TRUE), error = function(e) NULL)
  if (is.null(res) || isFALSE(res$is_success)) next
  pn[i] <- isTRUE(res$is_novelty_pred)
  pr[i] <- isTRUE(res$is_replication_pred)
  if (i %% 50 == 0) message(sprintf("  %d/%d", i, nrow(d)))
}

ev <- function(pred, lab) {
  k <- !is.na(pred) & !is.na(lab)
  .eval_metrics(pred[k], lab[k])
}
mn <- ev(pn, d$is_novelty)
mr <- ev(pr, d$is_replication)

results <- rbind(
  data.frame(indicator = "novelty", metric = .benchmark_metric_names,
             value = round(as.numeric(mn[.benchmark_metric_names]), 1), n = mn$n),
  data.frame(indicator = "replication", metric = .benchmark_metric_names,
             value = round(as.numeric(mr[.benchmark_metric_names]), 1), n = mr$n)
)
utils::write.csv(results, file.path(OUT, "results_novelty_replication.csv"),
                 row.names = FALSE)

con <- file(file.path(OUT, "results_novelty_replication.md"), open = "w")
writeLines(c(
  "# Novelty and replication detector benchmark",
  "",
  sprintf("Package version %s. Detectors run on PMC full-text XML and compared",
          as.character(utils::packageVersion("rtransparent"))),
  "to a maintainer-built hand-labeled gold set of open-access PMC articles",
  "(2023-2026); see `data-raw/benchmark/labels_novelty_replication.csv` and the",
  "label definitions at the top of `run_novelty_replication.R`. These indicators",
  "have no gold standard in Serghiou et al. (2021), so this is the reference for",
  "novelty/replication accuracy. Replication has few positives, so its",
  "sensitivity estimate is low-powered; specificity and PPV are more stable.",
  "",
  sprintf("## Novelty (n = %d)", mn$n),
  sprintf("Sensitivity %.1f, Specificity %.1f, PPV %.1f, NPV %.1f, Accuracy %.1f",
          mn$Sensitivity, mn$Specificity, mn$PPV, mn$NPV, mn$Accuracy),
  "",
  sprintf("## Replication (n = %d)", mr$n),
  sprintf("Sensitivity %.1f, Specificity %.1f, PPV %.1f, NPV %.1f, Accuracy %.1f",
          mr$Sensitivity, mr$Specificity, mr$PPV, mr$NPV, mr$Accuracy)
), con)
close(con)
message("Wrote ", file.path(OUT, "results_novelty_replication.md"))
