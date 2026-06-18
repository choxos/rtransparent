#' Identify novelty claims in PMC XML files.
#'
#' Takes a PMC XML file as a list of article sections and returns data related
#'     to the presence of novelty claims. This is the internal version designed
#'     for integration with \code{rt_all_pmc}.
#'
#' @param article_ls A PMC XML as a list of strings (from \code{.get_article_txt}).
#' @return A named list of results.
#' @noRd
.rt_novelty_pmc <- function(article_ls) {

  index_any <- list(
    novelty_first_time_1 = NA,
    novelty_first_time_2 = NA,
    novelty_first_to_1   = NA,
    novelty_previously_1 = NA,
    novelty_novel_1       = NA,
    novelty_knowledge_1   = NA
  )

  out <- list(
    is_novelty_pred = FALSE,
    novelty_text    = ""
  )

  # Search abstract and full body. The external XML validation found many
  # explicit first-time claims in results and conclusion paragraphs, not only
  # in the introduction/discussion zones.
  abstract <- unlist(article_ls$abstract)
  body     <- unlist(if (!is.null(article_ls$body_all)) article_ls$body_all else article_ls$body)
  article <- c(abstract, body)

  if (!length(article)) {
    return(c(out, index_any))
  }

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
  is_relevant <- any(grepl(rel_regex, article, ignore.case = TRUE))

  if (!is_relevant) {
    return(c(out, index_any))
  }

  # Preprocess
  article_processed <- .preprocess_txt(article)

  index_any$novelty_first_time_1 <- .which_novelty_first_time_1(article_processed)
  index_any$novelty_first_time_2 <- .which_novelty_first_time_2(article_processed)
  index_any$novelty_first_to_1   <- .which_novelty_first_to_1(article_processed)
  index_any$novelty_previously_1 <- .which_novelty_previously_1(article_processed)
  index_any$novelty_novel_1       <- .which_novelty_novel_1(article_processed)
  index_any$novelty_knowledge_1   <- .which_novelty_knowledge_1(article_processed)

  index <- unlist(index_any) %>% unique() %>% sort()

  # Drop cues attributed to a cited study or ordinal/temporal "first".
  if (!!length(index)) {
    is_negated <- .negate_novelty_1(article_processed[index])
    index <- index[!is_negated]
  }

  out$is_novelty_pred <- !!length(index)
  out$novelty_text    <- article[index] %>% paste(collapse = " ")

  index_any %<>% purrr::map(function(x) !!length(x))

  return(c(out, index_any))
}


#' Identify and extract novelty claims in PMC XML files.
#'
#' Takes a PMC XML file and returns data related to the presence of novelty
#'     claims, including whether such claims exist and the relevant text.
#'     Novelty is defined as the study claiming to report something
#'     "for the first time."
#'
#' @param filename The name of the PMC XML as a string.
#' @param remove_ns TRUE if an XML namespace exists, else FALSE (default).
#' @return A tibble of results. It returns the unique identifiers of the
#'     article, whether a novelty claim was found, the relevant text and
#'     whether each pattern-matching function identified relevant text.
#' @examples
#' \dontrun{
#' # Path to PMC XML.
#' filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.xml"
#'
#' # Identify and extract novelty claims.
#' results_table <- rt_novelty_pmc(filepath, remove_ns = TRUE)
#' }
#' @export
rt_novelty_pmc <- function(filename, remove_ns = FALSE) {

  index_any <- list(
    novelty_first_time_1 = NA,
    novelty_first_time_2 = NA,
    novelty_first_to_1   = NA,
    novelty_previously_1 = NA,
    novelty_novel_1       = NA,
    novelty_knowledge_1   = NA
  )

  out <- list(
    pmid            = NA,
    pmcid_pmc       = NA,
    pmcid_uid       = NA,
    doi             = NA,
    is_novelty_pred = FALSE,
    novelty_text    = ""
  )

  # Parse XML
  article_xml <- tryCatch(.get_xml(filename, remove_ns), error = function(e) e)

  if (inherits(article_xml, "error")) {
    return(tibble::tibble(filename, is_success = FALSE))
  }

  # Extract IDs
  xpath <- c(
    "front/article-meta/article-id[@pub-id-type = 'pmid']",
    "front/article-meta/article-id[@pub-id-type = 'pmc']",
    "front/article-meta/article-id[@pub-id-type = 'pmc-uid']",
    "front/article-meta/article-id[@pub-id-type = 'doi']"
  )

  out %<>% purrr::list_modify(!!!purrr::map(xpath, ~ .get_text(article_xml, .x, TRUE)))

  # Extract text
  article_ls <- .get_article_txt(article_xml)
  novelty_ls <- .rt_novelty_pmc(article_ls)

  tibble::as_tibble(c(out, novelty_ls))
}
