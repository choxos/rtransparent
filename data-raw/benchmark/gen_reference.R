#!/usr/bin/env Rscript

# Regenerate inst/benchmark/reference_fig2.csv from the paper's serialized
# evaluation outputs. Run from the repo root. Requires the bundled (git-ignored)
# paper/ directory. The resulting CSV is committed so the benchmark can show the
# published Fig 2 numbers without depending on paper/.

find_root <- function() {
  d <- normalizePath(getwd())
  while (!file.exists(file.path(d, "DESCRIPTION"))) {
    parent <- dirname(d)
    if (identical(parent, d)) stop("Run from within the rtransparent repo.")
    d <- parent
  }
  d
}

ROOT <- find_root()
DOUT <- file.path(ROOT, "paper/osf_data/3_algorithm-validation/output/data_output")

load_one <- function(f) {
  e <- new.env()
  load(file.path(DOUT, f), envir = e)
  get(ls(e)[1], envir = e)
}

out_coi  <- load_one("coi-eval-out_coi.RData")
out_fund <- load_one("fund-eval-out_fund.RData")
out_reg  <- load_one("register-eval-out_reg.RData")

add <- function(indicator, subset, df) {
  df <- as.data.frame(df)
  data.frame(indicator = indicator, subset = subset, metric = df$metric,
             median = round(df$median, 2), lo = round(df$lo, 2),
             hi = round(df$hi, 2), stringsAsFactors = FALSE)
}

reference <- rbind(
  add("coi", "any", out_coi$coi_eval_any),
  add("coi", "xml", out_coi$coi_eval_xml),
  add("fund", "any", out_fund$fund_eval_any),
  add("fund", "xml", out_fund$fund_eval_xml),
  add("register", "any", out_reg$reg_eval_any),
  add("register", "xml", out_reg$reg_eval_xml)
)

dir.create(file.path(ROOT, "inst/benchmark"), recursive = TRUE, showWarnings = FALSE)
write.csv(reference, file.path(ROOT, "inst/benchmark/reference_fig2.csv"),
          row.names = FALSE)
message("Wrote inst/benchmark/reference_fig2.csv (", nrow(reference), " rows)")
