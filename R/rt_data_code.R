#' Identify and extract Data and Code statements in TXT files.
#'
#' Takes a TXT file and returns data related to the presence of Data and/or Code
#'     statements, including whether Data and/or Code statements exist. If such
#'     statements exist, it extracts them.
#'
#' @param filename The name of the TXT file as a string.
#' @return A dataframe of results. It returns whether text suggesting the
#'     presence of data or code was found, and if so, what this text was.
#' @examples
#' \dontrun{
#' # Path to PMC XML.
#' filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.txt"
#'
#' # Identify and extract meta-data and indicators of transparency.
#' results_table <- rt_data(filepath)
#' }
#' @export
rt_data_code <- function(filename) {

  article <- readr::read_file(filename)
  paragraphs <- unlist(strsplit(article, "\n+"))

  found <- .detect_data_code(paragraphs)

  tibble::tibble(
    article = filename,
    is_open_data = found$is_open_data,
    open_data_statements = found$data_text,
    is_open_code = found$is_open_code,
    open_code_statements = found$code_text
  )
}