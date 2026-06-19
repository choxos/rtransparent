#' Identify replication components in PMC XML files.
#'
#' Takes a PMC XML file as a list of article sections and returns data related
#'     to the presence of a replication or validation component. This is the
#'     internal version designed for integration with \code{rt_all_pmc}.
#'
#' @param article_ls A PMC XML as a list of strings (from \code{.get_article_txt}).
#' @return A named list of results.
#' @noRd
.rt_replication_pmc <- function(article_ls) {

  index_any <- list(
    replication_replicat_1    = NA,
    replication_confirm_1     = NA,
    replication_independent_1 = NA,
    replication_reproduced_1  = NA,
    replication_validation_1  = NA
  )

  out <- list(
    is_replication_pred = FALSE,
    replication_text    = ""
  )

  # Search abstract + full body
  abstract <- unlist(article_ls$abstract)
  body     <- unlist(if (!is.null(article_ls$body_all)) article_ls$body_all else article_ls$body)
  article  <- c(abstract, body)

  if (!length(article)) {
    return(c(out, index_any))
  }

  # Quick relevance check
  rel_regex <- paste(
    "replicat",
    "independent(ly)? (confirm|validat|reproduc)",
    "external validation", "internal validation",
    "validation cohort", "validation sample", "validation dataset",
    "training cohort", "confirmatory cohort",
    "reproduced (the|our|their|these) (findings|results)",
    sep = "|"
  )
  is_relevant <- any(grepl(rel_regex, article, ignore.case = TRUE))

  if (!is_relevant) {
    return(c(out, index_any))
  }

  # Preprocess
  article_processed <- .preprocess_txt(article)

  index_any$replication_replicat_1    <- .which_replication_replicat_1(article_processed)
  index_any$replication_confirm_1     <- .which_replication_confirm_1(article_processed)
  index_any$replication_independent_1 <- .which_replication_independent_1(article_processed)
  index_any$replication_reproduced_1  <- .which_replication_reproduced_1(article_processed)
  index_any$replication_validation_1  <- .which_replication_validation_1(article_processed)

  index <- unlist(index_any) %>% unique() %>% sort()

  # Remove negations
  if (!!length(index)) {
    is_negated <- .negate_replication_1(article_processed[index])
    index <- index[!is_negated]
  }

  out$is_replication_pred <- !!length(index)
  out$replication_text    <- article[index] %>% paste(collapse = " ")

  index_any %<>% purrr::map(function(x) !!length(x))

  return(c(out, index_any))
}


#' Identify and extract replication components in PMC XML files.
#'
#' Takes a PMC XML file and returns data related to the presence of a
#'     replication or validation component, including whether such a component
#'     exists and the relevant text. Replication is defined as the study
#'     independently confirming findings from a prior study in a new sample.
#'
#' @param filename The name of the PMC XML as a string.
#' @param remove_ns TRUE if an XML namespace exists, else FALSE (default).
#' @return A tibble of results. It returns the unique identifiers of the
#'     article, whether a replication component was found, the relevant text
#'     and whether each pattern-matching function identified relevant text.
#' @examples
#' \dontrun{
#' # Path to PMC XML.
#' filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.xml"
#'
#' # Identify and extract replication components.
#' results_table <- rt_replication_pmc(filepath, remove_ns = TRUE)
#' }
#' @export
rt_replication_pmc <- function(filename, remove_ns = FALSE) {

  # Identifier columns only; the prediction, extracted text and per-pattern flags
  # are supplied by .rt_replication_pmc() below and must not be duplicated here.
  out <- list(
    pmid      = NA,
    pmcid_pmc = NA,
    pmcid_uid = NA,
    doi       = NA
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
  replication_ls <- .rt_replication_pmc(article_ls)

  tibble::as_tibble(c(out, replication_ls))
}
