#' Identify and extract Data and Code sharing from PMC XML files.
#'
#' Takes a PMC XML file and returns data related to the presence of Data or
#'     Code, including whether Data or Code have been shared. If Data or Code
#'     exist, it will extract the relevant text for each. Detection is performed
#'     by the native detector (\code{.detect_data_code}); the package no longer
#'     depends on \code{oddpub} or \code{tokenizers}.
#'
#' @param filename The filename of the XML file to be analyzed as a string.
#' @param remove_ns TRUE if an XML namespace exists, else FALSE (default).
#' @param specificity Retained for backward compatibility; it no longer changes
#'     the result. The native detector extracts a fixed, broad set of article
#'     text (body paragraphs and titles, back matter, footnotes and supplements)
#'     and applies repository, accession and availability-statement patterns.
#' @return A dataframe of results: the unique IDs of the article, whether data or
#'     code sharing was found (\code{is_open_data}, \code{is_open_code}), the
#'     statement text that triggered each detection
#'     (\code{open_data_statements}, \code{open_code_statements}) and the
#'     persistent identifiers and URLs of what was shared
#'     (\code{open_data_links}, \code{open_code_links}). The links are the DOIs
#'     (as \code{doi.org} URLs), repository URLs and database accessions (as
#'     identifiers.org \code{prefix:accession}) extracted from the statements,
#'     separated by \code{" ; "}.
#' @examples
#' \dontrun{
#' # Path to PMC XML
#' filepath <- system.file(
#'   "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparent"
#' )
#'
#' # Identify and extract indicators of data and code sharing
#' results_table <- rt_data_code_pmc(filepath, remove_ns = TRUE)
#' }
#' @export
rt_data_code_pmc <- function(filename, remove_ns = T, specificity = "low") {

  # A lot of the PMC XML files are malformed
  article_xml <- tryCatch(.get_xml(filename, remove_ns), error = function(e) e)

  if (inherits(article_xml, "error")) {

    return(tibble::tibble(filename = filename, is_success = FALSE))

  }

  # Extract IDs
  id_ls <- .get_ids(article_xml)
  id_ls$filename <- filename

  # Detect data and code sharing in the relevant article text
  found <- .detect_data_code(.dc_article_text(article_xml))

  data_links <- if (isTRUE(found$is_open_data))
    .extract_data_code_links(found$data_text) else character(0)
  code_links <- if (isTRUE(found$is_open_code))
    .extract_data_code_links(found$code_text) else character(0)

  tibble::as_tibble(c(
    id_ls,
    list(
      is_open_data = found$is_open_data,
      open_data_statements = found$data_text,
      open_data_links = paste(data_links, collapse = " ; "),
      is_open_code = found$is_open_code,
      open_code_statements = found$code_text,
      open_code_links = paste(code_links, collapse = " ; "),
      is_success = TRUE
    )
  ))
}


#' Identify and extract Data and Code sharing from a list of PMC XML files.
#'
#' Takes a list of PMC XML files and returns data related to the presence of
#'     Data or Code, including whether Data or Code have been shared. If Data
#'     or Code exist, it will extract the relevant text for each.
#'
#' @param filenames A list of the PMC XML filenames as strings.
#' @param remove_ns TRUE if an XML namespace exists, else FALSE (default).
#' @param specificity Retained for backward compatibility; see
#'     \code{\link{rt_data_code_pmc}}.
#' @return A dataframe of results, one row per file.
#' @examples
#' \dontrun{
#' # Paths to PMC XML files
#' filepath <- system.file(
#'   "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparent"
#' )
#' filepaths <- list(filepath)
#'
#' # Identify and extract indicators of data and code sharing
#' results_table <- rt_data_code_pmc_list(filepaths, remove_ns = TRUE)
#' }
#' @export
rt_data_code_pmc_list <- function(filenames, remove_ns = T, specificity = "low") {

  purrr::map_dfr(filenames, function(f) {
    rt_data_code_pmc(f, remove_ns = remove_ns, specificity = specificity)
  })
}
