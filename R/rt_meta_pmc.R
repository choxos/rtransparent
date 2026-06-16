#' Extract article metadata from a PMC XML file.
#'
#' Reads a PMC XML file and returns its metadata as a one-row data frame:
#'     journal, publisher, article title, authors and affiliations, identifiers
#'     (PMID, PMCID, DOI), publication dates, and figure / table / reference
#'     counts.
#'
#' @param filename The path to the PMC XML file as a string.
#' @param remove_ns TRUE if an XML namespace should be removed, else FALSE
#'     (default).
#' @return A one-row tibble of metadata. The column `is_success` indicates
#'     whether the file was parsed successfully.
#' @examples
#' \dontrun{
#' filepath <- system.file(
#'   "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparent"
#' )
#' rt_meta_pmc(filepath, remove_ns = TRUE)
#' }
#' @export
rt_meta_pmc <- function(filename, remove_ns = F) {

  # A lot of the PMC XML files are malformed
  article_xml <- tryCatch(.get_xml(filename, remove_ns), error = function(e) e)

  if (inherits(article_xml, "error")) {

    return(tibble::tibble(filename = filename, is_success = F))

  }

  id_ls <- list(filename = filename)
  meta_ls <- .xml_metadata_c(article_xml, as_list = T)

  status_ls <- list(is_success = T)
  tibble::as_tibble(c(id_ls, meta_ls, status_ls))
}
