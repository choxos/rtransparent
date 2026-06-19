#' Covert PDF files into TXT files.
#'
#' Takes a path to a PDF file and returns a TXT file. Note that there are a
#'     number of such converters and different converters return TXT files
#'     formatted differently. The functions within this package were created
#'     to work well with the converter used within this function (poppler).
#'     This function was taken from the package `oddpub` by Nico Riedel and
#'     hereby modified for the purposes of this package.
#'
#' @param filepath The path to the TXT file as a string.
#' @return A character object.
#' @examples
#' \dontrun{
#' # Path to PDF file
#' filepath <- "../inst/extdata/PMID30457984-PMC6245499.txt"
#'
#' # Convert into string
#' article_txt <- rt_read_pdf(filepath)
#' }
#' @export
rt_read_pdf <- function(filepath){

  if (!file.exists(filepath)) {
    stop("The provided filepath does not exist.")
  }

  if (!grepl("\\.pdf$", filepath, ignore.case = T)) {
    stop("The filepath of a PDF file should end in '.pdf'.")
  }

  if (Sys.which("pdftotext") == "") {
    stop("The 'pdftotext' utility (from poppler) was not found on the PATH.")
  }

  # Convert PDF to TXT; pdftotext writes to stdout when the output path is "-".
  txt_as_vector <- tryCatch(
    system2("pdftotext", args = c(shQuote(filepath), "-"), stdout = TRUE),
    error = function(e) stop("Could not convert PDF to text.")
  )

  # Collapse into appropriate format
  txt_as_string <- paste(txt_as_vector, collapse = "\n")

  # Convert character vector into ASCII to ease text processing
  txt <- iconv(txt_as_string, from = 'UTF-8', to = 'ASCII//TRANSLIT', sub = "")
  return(txt)
}
