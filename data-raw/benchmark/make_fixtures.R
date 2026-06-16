#!/usr/bin/env Rscript

# Build the committed benchmark regression fixtures from the cached XML.
#
# Selects a few labeled articles per indicator (a mix of positive and negative
# labels), copies their NCBI PMC XML into tests/testthat/fixtures/benchmark/,
# and records the human labels together with the current per-indicator accuracy
# as the regression baseline. tests/testthat/test-benchmark.R then asserts the
# detectors stay at or above that baseline.
#
# Run from the repo root after data-raw/benchmark/run_all.R has populated the
# cache:  Rscript data-raw/benchmark/make_fixtures.R

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
FX    <- file.path(ROOT, "tests/testthat/fixtures/benchmark")
dir.create(FX, recursive = TRUE, showWarnings = FALSE)
suppressMessages(devtools::load_all(ROOT, quiet = TRUE))

spec <- list(
  coi      = list(true = "coi_true.xlsx",      false = "coi_false.xlsx",
                  label = "isCOI"),
  fund     = list(true = "fund_true.xlsx",     false = "fund_false.xlsx",
                  label = "isFunding"),
  register = list(true = "register_true.xlsx", false = "register_false.xlsx",
                  label = "is_register")
)
label_col <- c(coi = "isCOI", fund = "isFunding", register = "is_register")

as_lgl <- function(x) {
  if (is.logical(x)) return(x)
  if (is.numeric(x)) return(x != 0)
  tolower(trimws(as.character(x))) %in% c("true", "t", "1", "yes")
}

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
  d <- rbind(rd(s$true), rd(s$false))
  keep <- d$is_test & d$is_xml & !is.na(d$label) & !is.na(d$pmcid)
  d <- d[keep, c("pmcid", "label")]
  d[file.exists(file.path(CACHE, paste0(d$pmcid, ".xml"))), ]
}

n_each <- 2L  # positives and negatives per indicator
chosen <- list()
for (k in names(spec)) {
  d <- load_indicator(spec[[k]])
  pos <- utils::head(unique(d$pmcid[d$label]), n_each)
  neg <- utils::head(unique(d$pmcid[!d$label]), n_each)
  chosen[[k]] <- data.frame(
    pmcid = c(pos, neg),
    label = c(rep(TRUE, length(pos)), rep(FALSE, length(neg))),
    indicator = k, stringsAsFactors = FALSE
  )
}
chosen <- do.call(rbind, chosen)

labels <- data.frame(pmcid = unique(chosen$pmcid),
                     isCOI = NA, isFunding = NA, is_register = NA,
                     stringsAsFactors = FALSE)
for (i in seq_len(nrow(chosen))) {
  r <- chosen[i, ]
  labels[labels$pmcid == r$pmcid, label_col[[r$indicator]]] <- r$label
}

for (id in labels$pmcid) {
  file.copy(file.path(CACHE, paste0(id, ".xml")),
            file.path(FX, paste0(id, ".xml")), overwrite = TRUE)
}

g <- function(r, c) if (c %in% names(r)) as.logical(r[[c]][1]) else NA
preds <- do.call(rbind, lapply(labels$pmcid, function(id) {
  r <- rt_all_pmc(file.path(FX, paste0(id, ".xml")), remove_ns = TRUE)
  data.frame(pmcid = id, is_coi_pred = g(r, "is_coi_pred"),
             is_fund_pred = g(r, "is_fund_pred"),
             is_register_pred = g(r, "is_register_pred"))
}))

m <- merge(labels, preds, by = "pmcid")
ind <- list(coi = c("isCOI", "is_coi_pred"),
            fund = c("isFunding", "is_fund_pred"),
            register = c("is_register", "is_register_pred"))
baseline <- list()
for (k in names(ind)) {
  lab <- m[[ind[[k]][1]]]; pr <- m[[ind[[k]][2]]]
  keep <- !is.na(lab) & !is.na(pr)
  baseline[[k]] <- mean(as.logical(lab[keep]) == as.logical(pr[keep]))
}

saveRDS(list(labels = labels, baseline = baseline), file.path(FX, "labels.rds"))
message(sprintf("Wrote %d fixtures to %s", nrow(labels), FX))
message("Baseline accuracy: ",
        paste(names(baseline), sprintf("%.3f", unlist(baseline)), collapse = "  "))
