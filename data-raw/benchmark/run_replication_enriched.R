# Replication detector validation on a replication-enriched sample.
#
# The general 2023 sample has too few replication positives (about 17) for a
# stable sensitivity estimate. This benchmark uses 250 open-access PMC articles
# selected for external-validation / replication language (PubMed [tiab] search)
# and hand-labeled for the replication indicator: TRUE when a replication or an
# external/independent validation is reported as PERFORMED (internal train/test
# splits, future/recommended validation, review discussion, and assay/instrument
# validation are FALSE). It gives a large positive sample for sensitivity.
#
# Run from the repo root: Rscript data-raw/benchmark/run_replication_enriched.R
# Reads /tmp/pr4/rep/<pmcid>.xml (set RT_REP_XML to override). Writes
# inst/benchmark/results_replication_enriched.{csv,md}.

suppressMessages(devtools::load_all("."))
lab <- read.csv("data-raw/benchmark/labels_replication_enriched.csv",
                stringsAsFactors = FALSE)
lab$is_replication <- toupper(trimws(lab$is_replication)) == "TRUE"
xml_dir <- Sys.getenv("RT_REP_XML", "/tmp/pr4/rep")

pred <- rep(NA, nrow(lab))
for (i in seq_len(nrow(lab))) {
  f <- file.path(xml_dir, paste0(lab$pmcid[i], ".xml"))
  if (!file.exists(f)) next
  x <- tryCatch(rtransparent:::.get_xml(f, TRUE), error = function(e) NULL); if (is.null(x)) next
  als <- tryCatch(rtransparent:::.get_article_txt(x), error = function(e) NULL); if (is.null(als)) next
  rl <- tryCatch(rtransparent:::.rt_replication_pmc(als), error = function(e) NULL); if (is.null(rl)) next
  pred[i] <- isTRUE(rl$is_replication_pred)
}

k <- !is.na(pred); g <- lab$is_replication[k]; p <- pred[k]
TP <- sum(g & p); FP <- sum(!g & p); FN <- sum(g & !p); TN <- sum(!g & !p)
res <- data.frame(indicator = "replication", n = sum(k), pos = sum(g),
                  sens = round(100 * TP / (TP + FN), 1),
                  spec = round(100 * TN / (TN + FP), 1),
                  ppv  = round(100 * TP / (TP + FP), 1))
print(res)
write.csv(res, "inst/benchmark/results_replication_enriched.csv", row.names = FALSE)

writeLines(c(
  "# Replication detector validation (replication-enriched sample)",
  "",
  sprintf("Package version %s. %d open-access PMC articles selected for external-",
          as.character(utils::packageVersion("rtransparent")), res$n),
  "validation / replication language (PubMed [tiab] search) and hand-labeled for",
  "the replication indicator (a replication or external/independent validation",
  "reported as PERFORMED). The general 2023 sample has too few replication",
  "positives for a stable sensitivity estimate; this enriched sample provides one.",
  "",
  sprintf("Positives: %d. Sensitivity %.1f, Specificity %.1f, PPV %.1f.",
          res$pos, res$sens, res$spec, res$ppv),
  "",
  "Specificity and PPV here are not representative of unselected literature: the",
  "sample is deliberately rich in validation language, which is the detector's",
  "hardest discrimination, so it concentrates false positives (internal splits",
  "and reviews that discuss validation). The 2023 1000-article sample gives the",
  "representative specificity (98.5). Sensitivity, estimated on the large positive",
  "set, is the stable quantity this benchmark contributes."
), "inst/benchmark/results_replication_enriched.md")
cat("wrote inst/benchmark/results_replication_enriched.{csv,md}\n")
