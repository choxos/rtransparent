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

  # Drop cues attributed to a cited study or ordinal/temporal "first".
  if (!!length(index)) {
    is_negated <- .negate_novelty_1(article_scan[index])
    index <- index[!is_negated]
  }

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

  verbs <- paste0("(show|report|demonstrate|identify|describe|establish|characteri[sz]e|",
    "reveal|document|observe|detect|assess|evaluate|examine|investigate|analy[sz]e|",
    "elucidate|introduce|compare|address|understand|isolate|generate|provide|present|",
    "develop|propose|design|create|apply|combine|summari[sz]e|attenuate|construct|",
    "derive|formulate|achieve|obtain|map|quantify|uncover|link|relate|integrate)")
  nouns <- "study|report|trial|analysis|investigation|paper|work|time|demonstration|case|description|survey|scoping review|systematic review|meta-analysis"
  ing <- "(compar|evaluat|examin|investigat|analy[sz]|describ|report|demonstrat|assess|identif|address|understand|isolat|generat|provid|present|develop|propos|summari[sz]|attenuat|character)"
  # Author voice claiming priority with an adverbial "first": "our study first
  # provided evidence", "we first demonstrated".
  self_first <- paste0("\\b(we|our (study|work|report|group|analysis)|this (study|work|report))\\b",
    ".{0,30}\\bfirst (", verbs, ")")
  pattern <- paste(
    paste0("\\bfirst (to date |to our knowledge |ever |so far |yet |in the literature )?((",
           nouns, ") )?to ", verbs),
    paste0("\\b(this is |our report is |our cohort is )?(the )?first (", nouns,
           ")( of its kind)?\\b.{0,90}\\b", ing),
    self_first,
    "\\b(present|presents|presented|report|reports|reported|describe|describes|described) (the |a )?first (reported |documented |known )?case\\b",
    "\\bfirst (reported |documented |known )?case (of|report)\\b",
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

  # "novel"/"new"/"innovative" applied to a research object the authors claim.
  nv <- "(novel|new|innovative|unprecedented)"
  term <- paste0("(finding|observation|approach|method|methodology|technique|",
    "insight|evidence|aspect|role|mechanism|target|treatment|therapy|association|",
    "result|perspective|pathway|model|framework|tool|device|strategy|system|assay|",
    "algorithm|sequence|index|score|metric|procedure|biomarker|signature|classifier|",
    "agent|compound|inhibitor|variant|subtype|isolate|strain|concept|paradigm|",
    "hypothesis|data ?set|application|pipeline|platform|protocol|formulation|material)s?")
  self <- "\\b(this|the present|the current|our) (study|work|research|analysis|paper|report|investigation)\\b"
  # Author voice immediately followed by a development/presentation verb: the
  # authors' own claim, not an attribution to a cited study.
  author_verb <- paste0("\\b(we|here,? we|in (this|the present) (study|work|paper|analysis))\\b.{0,90}",
    "\\b(provide|present|propose|develop|design|construct|create|identif|report|describe|reveal|demonstrate|introduce|establish|discover|generate|offer)")
  pattern <- paste(
    paste0(self, ".{0,120}\\b", nv, " ", term, "\\b"),
    paste0(author_verb, "[a-z]*.{0,50}(a |an |the )?", nv, " ", term, "\\b"),
    paste0(author_verb, "[a-z]*.{0,40}(a |an |the )", nv, " [a-z]"),
    paste0("(a |an |the )", nv, " [a-z][a-z -]{2,40}(is|was|are|were|has been|have been) ",
      "(developed|presented|introduced|proposed|described|reported|identified|established|designed|created|constructed|generated|discovered|demonstrated)\\b"),
    paste0("\\bthis ", nv, " ", term, "\\b"),
    sep = "|"
  )

  grep(pattern, article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "to our knowledge" novelty claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_knowledge_1 <- function(article) {

  # "to our knowledge" only counts when it introduces a first/gap claim, not a
  # bare hedge ("to our knowledge, the data are consistent with ...").
  grep(paste0(
    "\\bto (our|the best of our|the best of my) knowledge\\b",
    ".{0,90}(\\bfirst\\b|",
    "\\bno (other |previous |prior |published |existing )?",
    "(stud|report|work|data|research|investigation|paper|trial|evidence|literature|one |article)|",
    "\\bnot (yet )?been\\b|\\bnever been\\b|\\bhas not\\b|\\bhave not\\b|\\bhas yet to\\b|",
    "\\bremains? (un|to be|largely un)|\\bunknown\\b|\\bunreported\\b|\\bunexplored\\b|",
    "\\bunexamined\\b|\\buninvestigated\\b|\\black(s|ing)?\\b)"),
       article, ignore.case = TRUE, perl = TRUE)

}


#' Suppress non-self or non-research uses of first/novel cues
#'
#' Removes paragraphs whose novelty cue is attributed to a cited study, or is an
#' ordinal/temporal "first" (first day, first-time transplant) rather than a
#' priority claim, or names an entity ("the novel coronavirus").
#'
#' @param article A character vector of paragraphs.
#' @return Logical vector, TRUE where the cue should be suppressed.
#' @noRd
.negate_novelty_1 <- function(article) {

  # NB: do not suppress the bare phrase "first time"; "for the first time we
  # reveal ..." is the canonical priority claim. Only its ordinal/attributed
  # uses are removed.
  pattern <- paste(
    # Firstness/novelty attributed to a cited study (an author + et al near the
    # cue). Author voice ("we ... for the first time") is never written this way.
    "\\b[A-Z][a-zA-Z'-]+ et al\\b.{0,55}(for the )?\\bfirst\\b",
    "\\b[A-Z][a-zA-Z'-]+ et al\\b.{0,55}\\b(novel|previously un)\\b",
    "\\b[A-Z][a-zA-Z'-]+ (and colleagues|and co-?workers)\\b.{0,55}\\b(first|novel)\\b",
    # Historical "first" (a dated prior event), not the present study's priority.
    "\\bfor the first time in (1[0-9]|20)[0-9][0-9]\\b",
    "\\b(used|introduced|invented|described|reported|developed) (for the )?first time in (1[0-9]|20)[0-9][0-9]",
    # Ordinal / temporal "first" (hyphenated adjective or an enumerated count),
    # not a priority claim. "time" is deliberately excluded.
    "\\bfirst-time\\b",
    paste0("\\bfirst (day|days|week|weeks|month|months|year|years|trimester|hour|hours|",
      "stage|phase|wave|visit|line|step|passage|generation|episode|dose|cycle|",
      "quarter|round|edition|postoperative|post-operative|trimesters?|",
      "two|three|four|five|six|seven|eight|nine|ten|few|several|couple)\\b"),
    paste0("\\bfirst time [a-z]+ (transplant|surgery|underwent|received|presented|admi",
      "(tted|ssion)|diagnos(is|ed)|pregnancy|birth|dose|exposure|episode)\\b"),
    "\\bfor the first [0-9]",
    "\\bthe novel (coronavirus|severe acute|sars|influenza|virus\\b)",
    sep = "|"
  )

  grepl(pattern, article, perl = TRUE)

}
