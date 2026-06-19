#' Identify and extract Conflicts of Interest (COI) statements in TXT files.
#'
#' Takes a TXT file and returns data related to the presence of a COI
#'     statement, including whether a COI statement exists. If a COI statement
#'     exists, it extracts it. Detection runs through the same text helpers as
#'     [rt_coi_pmc()], so a plain-text article is scored with the same logic as
#'     a PMC XML one (only the XML-structural routes, which need tags a TXT file
#'     does not have, are unavailable).
#'
#' @param filename The name of the TXT file as a string.
#' @return A dataframe of results. It returns the filename, PMID (if it was part
#'     of the file name), whether a COI was found and the text identified.
#' @examples
#' \dontrun{
#' # Path to a TXT file (PMID in the name is parsed out).
#' filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.txt"
#'
#' # Identify and extract the COI statement.
#' results_table <- rt_coi(filepath)
#' }
#' @export
rt_coi <- function(filename) {

  dict <- .create_synonyms()

  paper_text <- readr::read_file(filename)
  paragraphs <- strsplit(paper_text, "\n")[[1]]
  paragraphs <- paragraphs[nzchar(trimws(paragraphs))]

  # A TXT file carries no XML structure, so all text goes to the body and the
  # XML-structural route is disabled (pmc_coi_ls reports nothing found).
  # Detection then runs through the same text-regex helpers as rt_coi_pmc().
  article_ls <- list(ack = character(0), body = paragraphs,
                     footnotes = character(0))
  pmc_coi_ls <- list(is_coi_pred = FALSE, coi_text = "")

  res <- .rt_coi_pmc(article_ls, pmc_coi_ls, dict)

  article <- basename(filename)
  pmid <- gsub("^.*PMID([0-9]+).*$", "\\1", filename)

  data.frame(
    article,
    pmid,
    is_coi_pred = res$is_coi_pred,
    coi_text = res$coi_text,
    stringsAsFactors = FALSE
  )
}
