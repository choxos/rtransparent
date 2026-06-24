# Reproducible validation of the open-access-licensing and reporting-guideline
# indicators against the 1000-article 2023 sample.
#
# Ground truth: data-raw/benchmark/labels_oa_reporting.csv, in which every article
# was read and hand-labeled by the maintainer (columns is_open_access_label,
# oa_license_label, is_reporting_label, reporting_guideline_label).
#
# The PMC XML is read from $RT_XML_DIR (default /tmp/newcache/xml); files are
# fetched by PMCID with the package's internal NCBI EFetch helper if absent.
# Re-run with:  Rscript data-raw/benchmark/run_oa_reporting.R

suppressMessages(devtools::load_all(quiet = TRUE))

labels <- read.csv("data-raw/benchmark/labels_oa_reporting.csv", stringsAsFactors = FALSE)
xml_dir <- Sys.getenv("RT_XML_DIR", "/tmp/newcache/xml")
dir.create(xml_dir, recursive = TRUE, showWarnings = FALSE)

get_xml <- function(id) {
  f <- file.path(xml_dir, paste0(id, ".xml"))
  if (!file.exists(f) || file.size(f) < 800) {
    doc <- tryCatch(rtransparency:::.fetch_pmc_doc_efetch(rtransparency:::.normalize_pmcid(id)),
                    error = function(e) NULL)
    if (!is.null(doc)) tryCatch(xml2::write_xml(doc, f), error = function(e) NULL)
    Sys.sleep(0.34)
  }
  if (!file.exists(f)) return(NULL)
  tryCatch(rtransparency:::.get_xml(f, remove_ns = TRUE), error = function(e) NULL)
}

pred <- do.call(rbind, lapply(labels$pmcid, function(id) {
  ax <- get_xml(id)
  if (is.null(ax)) return(data.frame(pmcid = id, oa = NA, oa_license = NA, rep = NA, guideline = NA))
  oa <- rtransparency:::.get_oa_pmc(ax); rp <- rtransparency:::.get_reporting_pmc(ax)
  data.frame(pmcid = id, oa = oa$is_open_access, oa_license = oa$oa_license,
             rep = rp$is_reporting_pred, guideline = rp$reporting_guideline, stringsAsFactors = FALSE)
}))

m <- merge(labels, pred, by = "pmcid")
asl <- function(x) { x <- toupper(trimws(as.character(x)))
  ifelse(x %in% c("T", "TRUE"), TRUE, ifelse(x %in% c("F", "FALSE"), FALSE, NA)) }
met <- function(truth, p) { ok <- !is.na(truth) & !is.na(p); truth <- truth[ok]; p <- p[ok]
  TP <- sum(truth & p); FN <- sum(truth & !p); TN <- sum(!truth & !p); FP <- sum(!truth & p)
  c(n = length(truth), pos = sum(truth), sens = 100*TP/(TP+FN), spec = 100*TN/(TN+FP),
    ppv = 100*TP/(TP+FP), acc = 100*(TP+TN)/length(truth)) }
boot <- function(truth, p, B = 2000, seed = 1306) { set.seed(seed)
  ok <- !is.na(truth) & !is.na(p); truth <- truth[ok]; p <- p[ok]
  pos <- which(truth); neg <- which(!truth); o <- matrix(NA_real_, B, 2)
  for (b in seq_len(B)) { idx <- c(sample(pos, length(pos), TRUE), sample(neg, length(neg), TRUE))
    tt <- truth[idx]; pp <- p[idx]; o[b,1] <- 100*sum(tt&pp)/sum(tt); o[b,2] <- 100*sum(!tt&!pp)/sum(!tt) }
  list(sens = quantile(o[,1], c(.025,.975), na.rm = TRUE), spec = quantile(o[,2], c(.025,.975), na.rm = TRUE)) }

oa <- met(asl(m$is_open_access_label), asl(m$oa));  oab <- boot(asl(m$is_open_access_label), asl(m$oa))
rp <- met(asl(m$is_reporting_label), m$rep);        rpb <- boot(asl(m$is_reporting_label), m$rep)
oaok <- asl(m$is_open_access_label) %in% TRUE
lic <- 100*mean(toupper(gsub("[^A-Za-z0-9.]","",m$oa_license_label[oaok])) ==
                toupper(gsub("[^A-Za-z0-9.]","",m$oa_license[oaok])), na.rm = TRUE)

res <- data.frame(
  indicator = c("Open-access license", "Reporting guideline"),
  n = c(oa["n"], rp["n"]), positives = c(oa["pos"], rp["pos"]), negatives = c(oa["n"]-oa["pos"], rp["n"]-rp["pos"]),
  sensitivity = round(c(oa["sens"], rp["sens"]), 1), specificity = round(c(oa["spec"], rp["spec"]), 1),
  ppv = round(c(oa["ppv"], rp["ppv"]), 1), accuracy = round(c(oa["acc"], rp["acc"]), 1),
  sens_lo = round(c(oab$sens[1], rpb$sens[1]),1), sens_hi = round(c(oab$sens[2], rpb$sens[2]),1),
  spec_lo = round(c(oab$spec[1], rpb$spec[1]),1), spec_hi = round(c(oab$spec[2], rpb$spec[2]),1))
write.csv(res, "inst/benchmark/results_oa_reporting.csv", row.names = FALSE)
cat(sprintf("OA        : Sens %.1f Spec %.1f (neg=%d) license-type %.1f%%\n", oa["sens"], oa["spec"], oa["n"]-oa["pos"], lic))
cat(sprintf("REPORTING : Sens %.1f [%.1f,%.1f]  Spec %.1f [%.1f,%.1f]  PPV %.1f\n",
            rp["sens"], rpb$sens[1], rpb$sens[2], rp["spec"], rpb$spec[1], rpb$spec[2], rp["ppv"]))
