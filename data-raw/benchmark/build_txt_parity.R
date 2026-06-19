# TXT-parity benchmark.
#
# The TXT detectors (rt_coi/rt_fund/rt_register/rt_novelty/rt_replication) have
# no gold standard of their own, which historically blocked improving them. This
# script derives one from the 1000 hand-labeled 2023 PMC XMLs: it extracts the
# same article text the PMC path sees, writes it to a plain-text file (as a
# PDF-derived TXT would look), runs the TXT detectors on it, and compares the
# predictions to the same hand labels used for the PMC benchmark. The gap to the
# PMC numbers is what TXT/PMC parity must close.
#
# Run from the repo root: Rscript data-raw/benchmark/build_txt_parity.R
# Reads /tmp/newcache/xml/<pmcid>.xml (local cache) + the committed labels.
# Writes inst/benchmark/results_txt_parity.{md,csv}.

suppressMessages(devtools::load_all("."))
`%>%` <- magrittr::`%>%`

labels  <- readr::read_csv("data-raw/benchmark/labels_2023_sample.csv",
                           show_col_types = FALSE)
xml_dir <- "/tmp/newcache/xml"
txt_dir <- "/tmp/txt_corpus"
dir.create(txt_dir, showWarnings = FALSE)

# 1. Extract the article text from each XML into a PMID-named TXT file (the TXT
#    detectors parse the PMID out of the file name). Use the same section
#    extractor the PMC path uses, so this isolates detector LOGIC parity.
extract_one <- function(pmcid) {
  f <- file.path(xml_dir, paste0(pmcid, ".xml"))
  if (!file.exists(f)) return(NA_character_)
  # Resume: a non-empty extracted file is reused (extraction is the slow step).
  done <- list.files(txt_dir, pattern = sprintf("-%s\\.txt$", pmcid),
                     full.names = TRUE)
  if (length(done) && file.info(done[1])$size > 0) return(done[1])
  xml <- tryCatch(rtransparent:::.get_xml(f, TRUE), error = function(e) NULL)
  if (is.null(xml)) return(NA_character_)
  secs <- tryCatch(rtransparent:::.get_article_txt(xml), error = function(e) NULL)
  if (is.null(secs)) return(NA_character_)
  txt  <- paste(unlist(secs), collapse = "\n")
  pmid <- rtransparent:::.get_ids(xml)$pmid
  if (length(pmid) == 0 || is.na(pmid[1]) || !nzchar(pmid[1])) pmid <- "0"
  dest <- file.path(txt_dir, sprintf("PMID%s-%s.txt", pmid[1], pmcid))
  writeLines(txt, dest)
  dest
}

message("Extracting text from ", nrow(labels), " XMLs ...")
labels$txt <- vapply(labels$pmcid, extract_one, character(1))
message("  wrote ", sum(!is.na(labels$txt)), " TXT files; ",
        sum(is.na(labels$txt)), " missing/failed.")

# 2. Run the TXT detectors. Pull the is_*_pred column robustly.
pred_of <- function(df) {
  col <- grep("^is_.*_pred$", names(df), value = TRUE)
  if (!length(col)) return(NA)
  as.logical(df[[col[1]]][1])
}
run_txt <- function(path) {
  if (is.na(path)) return(c(coi = NA, fund = NA, reg = NA, nov = NA, rep = NA))
  c(
    coi  = tryCatch(pred_of(rt_coi(path)),         error = function(e) NA),
    fund = tryCatch(pred_of(rt_fund(path)),        error = function(e) NA),
    reg  = tryCatch(pred_of(rt_register(path)),    error = function(e) NA),
    nov  = tryCatch(pred_of(rt_novelty(path)),     error = function(e) NA),
    rep  = tryCatch(pred_of(rt_replication(path)), error = function(e) NA)
  )
}

message("Running TXT detectors ...")
preds <- t(vapply(labels$txt, run_txt, logical(5)))
colnames(preds) <- c("coi", "fund", "reg", "nov", "rep")
preds <- as.data.frame(preds)

# 3. Metrics: sensitivity / specificity / PPV per indicator.
metric <- function(truth, pred) {
  ok <- !is.na(truth) & !is.na(pred)
  truth <- as.logical(truth[ok]); pred <- pred[ok]
  tp <- sum(truth & pred); fp <- sum(!truth & pred)
  fn <- sum(truth & !pred); tn <- sum(!truth & !pred)
  c(n = length(truth), pos = sum(truth),
    sens = round(100 * tp / (tp + fn), 1),
    spec = round(100 * tn / (tn + fp), 1),
    ppv  = round(100 * tp / (tp + fp), 1))
}

inds <- c(coi = "coi", fund = "fund", reg = "reg", nov = "nov", rep = "rep")
res  <- do.call(rbind, lapply(names(inds), function(k)
  data.frame(indicator = k, t(metric(labels[[inds[k]]], preds[[k]])))))

# PMC reference (results_2023_sample.csv current numbers) for side-by-side.
pmc_ref <- data.frame(
  indicator = c("coi", "fund", "reg", "nov", "rep"),
  pmc_sens  = c(100.0, 94.8, 84.6, 90.2, 82.4),
  pmc_spec  = c(91.8, 95.3, 99.2, 93.3, 98.5)
)
res <- merge(res, pmc_ref, by = "indicator", sort = FALSE)

print(res)
readr::write_csv(res, "inst/benchmark/results_txt_parity.csv")

md <- c(
  "# TXT-parity benchmark",
  "",
  paste0("Derived from the ", nrow(labels), " hand-labeled 2023 PMC XML articles: ",
         "each article's text is extracted and written to a plain-text file, the TXT ",
         "detectors are run on it, and the predictions are compared to the same hand ",
         "labels used for the PMC benchmark. Because a TXT file carries no XML ",
         "structure, the XML-structural detection routes are unavailable; the TXT ",
         "detectors share the same text helpers as the PMC ones, so the gap to the ",
         "PMC numbers reflects the value of those XML-only routes rather than a ",
         "difference in logic."),
  "",
  "| Indicator | TXT sens | TXT spec | TXT PPV | PMC sens | PMC spec |",
  "|---|---|---|---|---|---|",
  apply(res, 1, function(r) sprintf("| %s | %s | %s | %s | %s | %s |",
        r["indicator"], r["sens"], r["spec"], r["ppv"], r["pmc_sens"], r["pmc_spec"])),
  ""
)
writeLines(md, "inst/benchmark/results_txt_parity.md")
message("wrote inst/benchmark/results_txt_parity.{csv,md}")
