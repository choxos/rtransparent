#' Identify whether a study claims novelty in TXT files.
#'
#' Takes a TXT file and returns data related to the presence of novelty claims,
#'     including whether a novelty claim exists. If a novelty claim exists, it
#'     extracts the relevant text. Novelty is defined as the study claiming to
#'     report something "for the first time."
#'
#' @param filename The name of the TXT file as a string.
#' @return A tibble of results. It returns the filename, PMID (if it was part
#'     of the file name), whether a novelty claim was found, the text
#'     identified, and whether each pattern-matching function identified
#'     relevant text or not.
#' @examples
#' \dontrun{
#' # Path to TXT file.
#' filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.txt"
#'
#' # Identify and extract novelty claims.
#' results_table <- rt_novelty(filepath)
#' }
#' @export
rt_novelty <- function(filename) {

  article <- basename(filename)
  pmid <- gsub("^.*PMID([0-9]+).*$", "\\1", filename)

  is_novelty_pred <- FALSE
  novelty_text <- ""

  index_any <- list(
    novelty_first_time_1 = NA,
    novelty_first_time_2 = NA,
    novelty_first_to_1 = NA,
    novelty_previously_1 = NA,
    novelty_novel_1 = NA,
    novelty_knowledge_1 = NA
  )

  paper_text <- readr::read_file(filename)

  # Quick relevance check
  rel_regex <- paste(
    "first time", "first study", "first to ", "first report",
    "first demonstration", "first study comparing", "first study of",
    "among the first", "novel finding", "novel observation",
    "novel approach", "novel method", "novel technique",
    "novel evidence", "novel aspect", "novel role",
    "novel mechanism", "novel target", "novel treatment",
    "novel therapy", "novel association", "novel result",
    "novel perspective", "novel pathway", "novel insight",
    "previously unknown", "previously unreported",
    "previously uncharacterized", "previously undescribed",
    "previously unidentified", "previously unrecognized",
    "previously unappreciated",
    "not been reported previously", "has not been reported",
    "has not been studied", "has not been examined",
    "to our knowledge", "to the best of our knowledge",
    sep = "|"
  )
  is_relevant <- grepl(rel_regex, paper_text, ignore.case = TRUE)

  if (!is_relevant) {
    return(tibble::as_tibble(c(
      list(article = article, pmid = pmid,
           is_novelty_pred = is_novelty_pred,
           novelty_text = novelty_text),
      index_any
    )))
  }

  # Split into paragraphs
  broken_1 <- "([a-z]+)-\n+([a-z]+)"
  broken_2 <- "([a-z]+)(|,|;)\n+([a-z]+)"
  splitted <-
    paper_text %>%
    purrr::map(gsub, pattern = broken_1, replacement = "\\1\\2") %>%
    purrr::map(gsub, pattern = broken_2, replacement = "\\1\\3") %>%
    purrr::map(strsplit, "\n| \\*") %>%
    unlist() %>%
    utf8::utf8_encode()

  # Novelty claims frequently occur in abstracts, introductions and discussion,
  # but the external XML validation also found many explicit first-time claims
  # in results/conclusion paragraphs. Scan the full article and rely on the
  # specific phrase rules below for precision.
  article_scan <- splitted

  index_any$novelty_first_time_1 <- .which_novelty_first_time_1(article_scan)
  index_any$novelty_first_time_2 <- .which_novelty_first_time_2(article_scan)
  index_any$novelty_first_to_1   <- .which_novelty_first_to_1(article_scan)
  index_any$novelty_previously_1 <- .which_novelty_previously_1(article_scan)
  index_any$novelty_novel_1       <- .which_novelty_novel_1(article_scan)
  index_any$novelty_knowledge_1   <- .which_novelty_knowledge_1(article_scan)

  index <- unlist(index_any) %>% unique() %>% sort()

  is_novelty_pred <- !!length(index)
  novelty_text <- article_scan[index] %>% paste(collapse = " ")

  index_any %<>% purrr::map(function(x) !!length(x))

  tibble::as_tibble(c(
    list(article = article, pmid = pmid,
         is_novelty_pred = is_novelty_pred,
         novelty_text = novelty_text),
    index_any
  ))
}


#' Identify "for the first time" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_first_time_1 <- function(article) {

  grep("\\bfor the first time\\b", article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "first time that" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_first_time_2 <- function(article) {

  grep("\\bfirst time (that|to|we|this)\\b", article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "first to show/report/demonstrate" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_first_to_1 <- function(article) {

  verbs <- "(show|report|demonstrate|identify|describe|establish|characterize|reveal|document|observe|detect|assess|evaluate|examine|investigate|analy[sz]e|elucidate|introduce|compare|address|understand)"
  nouns <- "study|report|trial|analysis|investigation|paper|work|time|demonstration|case|description|survey|scoping review|systematic review|meta-analysis"
  ing <- "(compar|evaluat|examin|investigat|analy[sz]|describ|report|demonstrat|assess|identif|address|understand)"
  pattern <- paste(
    paste0("\\bfirst (to date |to our knowledge |ever |so far |yet |in the literature )?((",
           nouns, ") )?to ", verbs),
    paste0("\\b(this is |our report is |our cohort is )?(the )?first (", nouns,
           ")( of its kind)?\\b.{0,90}\\b", ing),
    "\\bthis is the first report that (we know of|to our knowledge)\\b",
    "\\bour report first reported a case\\b",
    "\\bas the first study of its kind\\b",
    sep = "|"
  )

  grep(pattern, article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "previously unknown/unreported" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_previously_1 <- function(article) {

  grep(paste(
    "\\bpreviously (unknown|unreported|uncharacterized|undescribed|unidentified|unrecognized|unappreciated)\\b",
    "\\bnot been (reported|studied|examined|evaluated|assessed|investigated) (previously|before)\\b",
    "\\bhas not been (reported|studied|examined|evaluated|assessed|investigated)\\b",
    sep = "|"
  ),
       article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "novel finding/approach" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_novel_1 <- function(article) {

  term <- "\\bnovel (finding|observation|approach|method|technique|insight|evidence|aspect|role|mechanism|target|treatment|therapy|association|result|perspective|pathway)\\b"
  self <- "\\b(this|the|our|current) (study|work|research|analysis|paper|report|findings?|results?|model|method|approach)\\b"
  author_verb <- "\\b(we|here,? we|this study|this work|our study|our findings|our results)\\b.{0,80}\\b(provide|present|propose|develop|identify|report|describe|reveal|demonstrate|introduce|show|offer|construct|suggest|highlight)"
  pattern <- paste(
    paste0(self, ".{0,120}", term),
    paste0(author_verb, ".{0,120}", term),
    paste0("\\b(provide|provides|provided|offer|offers|offered|reveal|reveals|revealed|highlight|highlights|highlighted|suggest|suggests|suggested)\\b.{0,60}", term),
    "\\bthis novel (finding|observation|approach|method|technique|insight|evidence|aspect|role|mechanism|target|treatment|therapy|association|result|perspective|pathway)\\b",
    "\\brevealing a novel (mechanism|role|axis|target|pathway|association|finding)\\b",
    sep = "|"
  )

  grep(pattern,
       article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "to our knowledge" novelty claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_knowledge_1 <- function(article) {

  grep("\\bto (our|the best of our|the best of my) knowledge\\b",
       article, ignore.case = TRUE, perl = TRUE)

}
