#!/usr/bin/env Rscript

# External data/code detector check on fresh PMC open-access XML.
#
# This is not a human gold-standard validation. It retrieves a fresh OA sample,
# runs the package detector, and compares it with a separate conservative
# adjudication screen implemented below. The raw XML cache is local-only and
# ignored by git; summarized outputs are written under audit/.

suppressWarnings(suppressMessages({
  ok <- requireNamespace("jsonlite", quietly = TRUE) &&
    requireNamespace("xml2", quietly = TRUE) &&
    requireNamespace("devtools", quietly = TRUE)
}))
if (!ok) stop("This script needs jsonlite, xml2 and devtools.")

find_root <- function() {
  d <- normalizePath(getwd())
  while (!file.exists(file.path(d, "DESCRIPTION"))) {
    parent <- dirname(d)
    if (identical(parent, d)) stop("Run from within the rtransparent repo.")
    d <- parent
  }
  d
}

arg_int <- function(i, default) {
  a <- commandArgs(trailingOnly = TRUE)
  if (length(a) >= i && nzchar(a[[i]])) as.integer(a[[i]]) else default
}

ROOT <- find_root()
N_TARGET <- arg_int(1, 1000L)
POOL_N <- as.integer(Sys.getenv("RTRANSPARENT_OA_POOL_N", "5000"))
BATCH_N <- as.integer(Sys.getenv("RTRANSPARENT_OA_BATCH_N", "50"))
SEED <- as.integer(Sys.getenv("RTRANSPARENT_OA_SEED", "20260617"))
QUERY <- Sys.getenv(
  "RTRANSPARENT_OA_QUERY",
  'open access[filter] AND ("2024/01/01"[PDAT] : "2026/06/17"[PDAT])'
)

CACHE <- file.path(ROOT, "data-raw/external-validation/.cache/xml")
OUT <- file.path(ROOT, "audit/external-validation-oa-1000-2026-06-17")
dir.create(CACHE, recursive = TRUE, showWarnings = FALSE)
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)
suppressMessages(devtools::load_all(ROOT, quiet = TRUE))

has <- function(pattern, x) grepl(pattern, x, perl = TRUE, ignore.case = TRUE)
blank <- function(x) is.null(x) || length(x) == 0 || is.na(x) || !nzchar(x)

download_json <- function(url) {
  jsonlite::fromJSON(url)
}

esearch <- function(query, retmax) {
  url <- paste0(
    "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi",
    "?db=pmc&retmode=json&retmax=", retmax,
    "&sort=pub+date&term=", utils::URLencode(query, reserved = TRUE)
  )
  x <- download_json(url)
  ids <- as.character(x$esearchresult$idlist)
  data.frame(
    pmcid = paste0("PMC", ids),
    numeric_id = ids,
    stringsAsFactors = FALSE
  )
}

write_article_node <- function(article_node, fallback_numeric_id) {
  xml2::xml_ns_strip(article_node)
  pmc <- xml2::xml_text(xml2::xml_find_first(
    article_node, ".//front/article-meta/article-id[@pub-id-type='pmc']"
  ))
  if (blank(pmc)) pmc <- xml2::xml_text(xml2::xml_find_first(
    article_node, ".//front/article-meta/article-id[@pub-id-type='pmc-uid']"
  ))
  if (blank(pmc)) pmc <- fallback_numeric_id
  pmcid <- paste0("PMC", sub("^PMC", "", pmc))
  dest <- file.path(CACHE, paste0(pmcid, ".xml"))
  xml2::write_xml(article_node, dest)
  pmcid
}

fetch_batch <- function(candidates) {
  ids <- candidates$numeric_id
  url <- paste0(
    "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi",
    "?db=pmc&id=", paste(ids, collapse = ","), "&rettype=xml"
  )
  tf <- tempfile(fileext = ".xml")
  ok <- tryCatch({
    utils::download.file(url, tf, quiet = TRUE)
    TRUE
  }, error = function(e) FALSE)
  if (!ok || !file.exists(tf) || file.info(tf)$size == 0) return(character(0))
  doc <- tryCatch(xml2::read_xml(tf), error = function(e) NULL)
  if (is.null(doc)) return(character(0))
  xml2::xml_ns_strip(doc)
  articles <- xml2::xml_find_all(doc, ".//article")
  if (!length(articles)) return(character(0))
  out <- character(0)
  for (i in seq_along(articles)) {
    fallback <- ids[[min(i, length(ids))]]
    out <- c(out, tryCatch(write_article_node(articles[[i]], fallback),
                           error = function(e) NA_character_))
  }
  unique(stats::na.omit(out))
}

extract_title <- function(article_xml) {
  x <- xml2::xml_text(xml2::xml_find_first(
    article_xml, ".//front/article-meta/title-group/article-title"
  ))
  gsub("[[:space:]]+", " ", x)
}

extract_year <- function(article_xml) {
  x <- xml2::xml_text(xml2::xml_find_first(
    article_xml, ".//front/article-meta/pub-date/year"
  ))
  suppressWarnings(as.integer(x))
}

sentence_evidence <- function(sentences, pattern, max_n = 6) {
  x <- sentences[has(pattern, sentences)]
  x <- gsub("[[:space:]]+", " ", x)
  paste(utils::head(unique(x), max_n), collapse = " | ")
}

adjudicate_data <- function(sentences) {
  s <- tolower(sentences)
  neg <- paste(
    "upon (reasonable )?request", "from the (corresponding )?authors?",
    "not (publicly )?available", "not be (made )?available",
    "restricted access", "cannot be shared", "data are not",
    sep = "|"
  )
  sharing_context <- paste(
    "data availability", "availability of data", "data and materials availability",
    "all relevant data", "all data", "raw data", "dataset", "datasets",
    "supporting information files?", "supplementary files?",
    sep = "|"
  )
  repository <- paste(
    "figshare", "dryad", "zenodo", "osf", "open science framework",
    "dataverse", "mendeley data", "gene expression omnibus", "\\bgeo\\b",
    "sequence read archive", "\\bsra\\b", "genbank", "bioproject",
    "biosample", "protein data bank", "\\bpdb\\b", "pride", "arrayexpress",
    "metabolights", "github", "doi\\.org", "10\\.5061", "10\\.5281",
    "10\\.6084", "10\\.7910", "10\\.17632", "accession",
    sep = "|"
  )
  in_article <- "all relevant data (are|is) within the (paper|manuscript|article)"
  available <- paste(
    "available", "accessible", "deposited", "uploaded", "submitted",
    "provided", "hosted", "archived", "included",
    sep = "|"
  )
  boilerplate <- paste(
    "supplementary data are available at (bioinformatics|nar) online",
    "values? of .{0,80}(calculated|interaction energy).{0,80}(data set|dataset).{0,80}supplementary table",
    sep = "|"
  )
  hit <- !has(neg, s) & !has(boilerplate, s) &
    (
      has(in_article, s) |
        (has(sharing_context, s) & has(available, s) &
           (has(repository, s) | has("supporting information|supplementary files?", s))) |
        (has(repository, s) & has(available, s) &
           has("data|dataset|raw|sequence|accession|files?", s))
    )
  list(
    label = any(hit),
    text = paste(sentences[hit], collapse = " | ")
  )
}

adjudicate_code <- function(sentences) {
  s <- tolower(sentences)
  neg <- paste(
    "upon (reasonable )?request", "from the (corresponding )?authors?",
    "not (publicly )?available", "not be (made )?available",
    "restricted access", "cannot be shared", "code is not",
    sep = "|"
  )
  code_term <- paste(
    "source code", "\\bcode\\b", "\\bcodes\\b", "scripts?", "software",
    "package", "pipeline", "algorithm", "tool", "implementation",
    "r syntax", "matlab", "python script", "supplemental script",
    sep = "|"
  )
  share <- paste(
    "available", "accessible", "download", "downloaded", "provided",
    "shared", "hosted", "released", "archived", "open[- ]source",
    "freely available", "can be installed", "installed from",
    "github", "gitlab", "bitbucket", "sourceforge", "code ocean",
    "cran", "bioconductor", "zenodo", "figshare",
    sep = "|"
  )
  use_only <- paste(
    "performed in r", "performed using", "using the .* package",
    "imported into .* package", "software was used", "used .* software",
    "server provides ready-made scripts",
    sep = "|"
  )
  explicit <- paste(
    "data availability.{0,80}(all files|model data files).{0,80}github",
    "facets \\(https://github\\.com/[^)]+\\).{0,80}can be .*used",
    "software program, spik(esorter|sorter)",
    "(python )?scripts? \\(supplemental script\\)",
    sep = "|"
  )
  hit <- !has(neg, s) &
    ((has(code_term, s) & has(share, s) & !has(use_only, s)) | has(explicit, s))
  list(
    label = any(hit),
    text = paste(sentences[hit], collapse = " | ")
  )
}

eval_metrics <- function(pred, ref) {
  tp <- sum(pred & ref)
  fn <- sum(!pred & ref)
  fp <- sum(pred & !ref)
  tn <- sum(!pred & !ref)
  pct <- function(x) round(100 * x, 1)
  data.frame(
    TP = tp, FN = fn, FP = fp, TN = tn,
    sensitivity = if ((tp + fn) > 0) pct(tp / (tp + fn)) else NA_real_,
    specificity = if ((tn + fp) > 0) pct(tn / (tn + fp)) else NA_real_,
    ppv = if ((tp + fp) > 0) pct(tp / (tp + fp)) else NA_real_,
    npv = if ((tn + fn) > 0) pct(tn / (tn + fn)) else NA_real_,
    accuracy = pct((tp + tn) / (tp + fn + fp + tn))
  )
}

message("Searching PMC: ", QUERY)
pool <- esearch(QUERY, POOL_N)
if (nrow(pool) < N_TARGET) {
  stop("ESearch returned fewer articles than requested: ", nrow(pool))
}
set.seed(SEED)
pool <- pool[sample.int(nrow(pool)), ]
pool <- pool[seq_len(min(nrow(pool), N_TARGET + 250L)), ]
utils::write.csv(pool, file.path(OUT, "candidate_pool.csv"), row.names = FALSE)

cached <- sub("[.]xml$", "", basename(list.files(CACHE, pattern = "^PMC[0-9]+[.]xml$")))
todo <- pool[!pool$pmcid %in% cached, ]
message(sprintf("Candidates: %d; cached: %d; to fetch: %d",
                nrow(pool), length(cached), nrow(todo)))

fetched <- cached
if (length(fetched) < N_TARGET && nrow(todo)) {
  starts <- seq(1, nrow(todo), by = BATCH_N)
  for (j in seq_along(starts)) {
    i <- starts[[j]]
    batch <- todo[i:min(i + BATCH_N - 1L, nrow(todo)), ]
    got <- fetch_batch(batch)
    fetched <- unique(c(fetched, got))
    if (j %% 5 == 0) {
      message(sprintf("  fetched batches %d/%d; xml files available %d",
                      j, length(starts), length(fetched)))
    }
    if (length(fetched) >= N_TARGET) break
    Sys.sleep(if (nzchar(Sys.getenv("ENTREZ_KEY"))) 0.12 else 0.34)
  }
}

xml_files <- list.files(CACHE, pattern = "^PMC[0-9]+[.]xml$", full.names = TRUE)
pmcids <- sub("[.]xml$", "", basename(xml_files))
keep <- pool$pmcid[pool$pmcid %in% pmcids]
keep <- utils::head(keep, N_TARGET)
if (length(keep) < N_TARGET) {
  stop("Only fetched ", length(keep), " usable XML files; requested ", N_TARGET)
}

message("Scoring ", length(keep), " XML files")
rows <- vector("list", length(keep))
for (i in seq_along(keep)) {
  pmcid <- keep[[i]]
  path <- file.path(CACHE, paste0(pmcid, ".xml"))
  article <- tryCatch(.get_xml(path, remove_ns = TRUE), error = function(e) NULL)
  if (is.null(article)) next
  sentences <- .dc_split(.dc_article_text(article))
  alg <- .detect_data_code(sentences)
  man_data <- adjudicate_data(sentences)
  man_code <- adjudicate_code(sentences)
  rows[[i]] <- data.frame(
    pmcid = pmcid,
    title = extract_title(article),
    year = extract_year(article),
    detector_data = alg$is_open_data,
    adjudicated_data = man_data$label,
    detector_code = alg$is_open_code,
    adjudicated_code = man_code$label,
    detector_data_text = alg$data_text,
    adjudicated_data_text = man_data$text,
    detector_code_text = alg$code_text,
    adjudicated_code_text = man_code$text,
    evidence_snippets = sentence_evidence(
      sentences,
      "data availability|availability of data|source code|scripts?|software|github|gitlab|figshare|dryad|zenodo|osf|open science framework|supplementary data|supporting information|accession"
    ),
    stringsAsFactors = FALSE
  )
  if (i %% 100 == 0) message("  scored ", i, "/", length(keep))
}

res <- do.call(rbind, rows[!vapply(rows, is.null, logical(1))])
utils::write.csv(res, file.path(OUT, "article_adjudication.csv"), row.names = FALSE)

md <- eval_metrics(res$detector_data, res$adjudicated_data)
mc <- eval_metrics(res$detector_code, res$adjudicated_code)
summary <- rbind(
  data.frame(indicator = "data", n = nrow(res), md),
  data.frame(indicator = "code", n = nrow(res), mc)
)
utils::write.csv(summary, file.path(OUT, "comparison_summary.csv"), row.names = FALSE)

dis <- res[
  res$detector_data != res$adjudicated_data |
    res$detector_code != res$adjudicated_code,
]
utils::write.csv(dis, file.path(OUT, "disagreements.csv"), row.names = FALSE)

con <- file(file.path(OUT, "README.md"), open = "w")
writeLines(c(
  "# External PMC OA data/code screen",
  "",
  sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  "",
  sprintf("Query: `%s`", QUERY),
  sprintf("Seed: `%d`; target XML files: `%d`; evaluated XML files: `%d`.", SEED, N_TARGET, nrow(res)),
  "",
  "The `adjudicated_*` columns come from a conservative independent screen in",
  "`data-raw/external-validation/run_oa_data_code.R`. They are not a human",
  "gold standard, but they are intentionally separate from `.detect_data_code()`",
  "and use the article snippets saved in `article_adjudication.csv`.",
  "",
  "## Detector vs independent screen",
  "",
  paste(capture.output(print(summary, row.names = FALSE)), collapse = "\n"),
  "",
  sprintf("Disagreement rows: `%d`.", nrow(dis))
), con)
close(con)

print(summary, row.names = FALSE)
message("Wrote ", OUT)
