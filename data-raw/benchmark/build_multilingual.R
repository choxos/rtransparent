# Multilingual detection benchmark.
#
# Measures conflict-of-interest and funding detection on per-language open-access
# corpora (Spanish, French, German, Italian, Portuguese) fetched from PubMed
# Central with the language filter (see /tmp/fetch_mllang.R). Because these
# clinical articles almost all carry a COI disclosure, the COI detection rate
# approximates recall; the funding rate is a detection rate (funded vs
# no-funding is not separately labeled here). Many articles are bilingual (the
# statement is repeated in English, which the English detector already catches),
# so the lift concentrates in monolingual articles, notably German.
#
# Run from the repo root: Rscript data-raw/benchmark/build_multilingual.R
# Reads /tmp/mllang/<code>/*.xml. Writes inst/benchmark/results_multilingual.{csv,md}.

suppressMessages(devtools::load_all("."))
dict <- rtransparent:::.create_synonyms()
detect <- function(f) {
  x <- tryCatch(rtransparent:::.get_xml(f, TRUE), error = function(e) NULL)
  if (is.null(x)) return(c(coi = NA, fund = NA))
  als  <- rtransparent:::.get_article_txt(x)
  coi  <- rtransparent:::.rt_coi_pmc(als, rtransparent:::.get_coi_pmc(x, dict), dict)$is_coi_pred
  fund <- rtransparent:::.rt_fund_pmc(als, rtransparent:::.get_fund_pmc(x, dict))$is_fund_pred
  c(coi = isTRUE(coi), fund = isTRUE(fund))
}

# Detection rates of the previous (English-centric) detectors, for reference.
baseline <- list(es = c(79, 10), fr = c(70, 6), de = c(33, 66),
                 it = c(60, 67), pt = c(64, 19))
lang_name <- c(es = "Spanish", fr = "French", de = "German",
               it = "Italian", pt = "Portuguese")

rows <- list()
for (code in names(lang_name)) {
  fs <- list.files(file.path("/tmp/mllang", code), full.names = TRUE, pattern = "\\.xml$")
  r <- t(vapply(fs, detect, logical(2)))
  rows[[code]] <- data.frame(
    language = lang_name[[code]], n = nrow(r),
    coi_before = baseline[[code]][1], coi_after = round(100 * mean(r[, 1])),
    fund_before = baseline[[code]][2], fund_after = round(100 * mean(r[, 2])))
}
res <- do.call(rbind, rows)
rownames(res) <- NULL
print(res)
readr::write_csv(res, "inst/benchmark/results_multilingual.csv")

md <- c(
  "# Multilingual detection benchmark",
  "",
  paste(nrow(res), "languages,", res$n[1], "open-access articles each, fetched",
        "from PubMed Central with the language filter (2018-2024). The COI",
        "detection rate approximates recall (these clinical articles almost all",
        "carry a disclosure); the funding rate is a detection rate. Many articles",
        "are bilingual, so the English detector already catches some; the lift",
        "concentrates in monolingual articles."),
  "",
  "| Language | n | COI before | COI after | Funding before | Funding after |",
  "|---|---|---|---|---|---|",
  apply(res, 1, function(r) sprintf("| %s | %s | %s%% | %s%% | %s%% | %s%% |",
        trimws(r["language"]), trimws(r["n"]), trimws(r["coi_before"]),
        trimws(r["coi_after"]), trimws(r["fund_before"]), trimws(r["fund_after"]))),
  "")
writeLines(md, "inst/benchmark/results_multilingual.md")
cat("wrote inst/benchmark/results_multilingual.{csv,md}\n")
