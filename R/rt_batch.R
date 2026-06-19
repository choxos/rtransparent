#' Identify transparency indicators across many PMC XML files.
#'
#' A batch wrapper around [rt_all_pmc()] for corpus-scale runs over a directory
#' (or an explicit vector) of PMC XML files. It isolates per-file failures so a
#' single malformed file cannot abort the run, shows a progress bar, can resume
#' an interrupted run, and can run in parallel when the \pkg{furrr} package is
#' installed.
#'
#' @details
#' When `output` is supplied, results are written to that CSV in chunks as the
#' run proceeds. Re-running with the same `output` skips files already present
#' in it and appends only the new results, so a long run can be resumed after an
#' interruption. Each file is processed inside [tryCatch()]; a file that errors
#' contributes a row with `is_success = FALSE` rather than stopping the run.
#'
#' Parallelism uses \pkg{furrr}'s `future_map()` and honors whatever
#' `future::plan()` is active (for example `future::plan("multisession")`); with
#' no plan it runs sequentially. Install \pkg{furrr} and \pkg{future} to use it.
#'
#' @param dir A directory containing PMC XML files, or a character vector of
#'   file paths.
#' @param pattern A regular expression for file names, used only when `dir` is a
#'   single existing directory (default `"\\.xml$"`).
#' @param recursive Whether to descend into subdirectories when `dir` is a
#'   directory (default `FALSE`).
#' @param remove_ns,all_meta Passed through to [rt_all_pmc()].
#' @param output Optional path to a CSV file for incremental, resumable output
#'   (see Details). `NULL` (default) keeps results in memory only.
#' @param parallel Whether to process files in parallel via \pkg{furrr}
#'   (default `FALSE`).
#' @param progress Whether to show a progress bar (default `TRUE`).
#' @param chunk_size Number of files per write/flush when `output` is set
#'   (default `200`).
#' @return A [tibble][tibble::tibble] with one row per file, carrying the same
#'   columns as [rt_all_pmc()] (plus any rows read back from a pre-existing
#'   `output`). Files that could not be processed have `is_success = FALSE`.
#' @seealso [rt_all_pmc()] for a single file.
#' @examples
#' \dontrun{
#' # Process every XML in a folder, in parallel, resumably.
#' future::plan("multisession")
#' res <- rt_all_pmc_dir("path/to/xml", remove_ns = TRUE,
#'                       output = "results.csv", parallel = TRUE)
#' }
#' @export
rt_all_pmc_dir <- function(dir, pattern = "\\.xml$", recursive = FALSE,
                           remove_ns = FALSE, all_meta = FALSE,
                           output = NULL, parallel = FALSE, progress = TRUE,
                           chunk_size = 200L) {

  # Resolve the file list: a single existing directory is expanded by pattern;
  # anything else is treated as an explicit vector of file paths.
  if (length(dir) == 1 && dir.exists(dir)) {
    files <- list.files(dir, pattern = pattern, full.names = TRUE,
                        recursive = recursive)
  } else {
    files <- dir
  }

  if (!length(files)) {
    stop("No files to process.", call. = FALSE)
  }

  missing <- !file.exists(files)
  if (any(missing)) {
    stop("File(s) not found: ",
         paste(utils::head(files[missing], 5L), collapse = ", "),
         if (sum(missing) > 5L) ", ..." else "", call. = FALSE)
  }

  if (parallel) {
    rlang::check_installed(c("furrr", "future"),
                           reason = "to process files in parallel")
  }

  to_char <- function(df) {
    dplyr::mutate(df, dplyr::across(dplyr::everything(), as.character))
  }
  reguess <- function(df) suppressMessages(readr::type_convert(df))

  # Resume: read any existing output (forced to character so re-guessed CSV
  # column types cannot clash with freshly computed rows) and drop files already
  # recorded in it.
  done_rows <- NULL
  if (!is.null(output) && file.exists(output) && file.info(output)$size > 0) {
    done_rows <- readr::read_csv(
      output, col_types = readr::cols(.default = readr::col_character()),
      progress = FALSE
    )
    if ("filename" %in% names(done_rows)) {
      files <- files[!files %in% done_rows$filename]
    }
  }

  if (!length(files)) {
    return(if (is.null(done_rows)) tibble::tibble() else reguess(done_rows))
  }

  # Per-file worker: never let one file abort the batch. rt_all_pmc() already
  # returns is_success = FALSE on a parse error; this tryCatch is a backstop for
  # any other failure.
  process_one <- function(f) {
    tryCatch(
      rt_all_pmc(f, remove_ns = remove_ns, all_meta = all_meta),
      error = function(e) tibble::tibble(filename = f, is_success = FALSE)
    )
  }

  mapper <- function(x) {
    if (parallel) {
      furrr::future_map(x, process_one, .progress = progress)
    } else {
      purrr::map(x, process_one, .progress = progress)
    }
  }

  # Process in chunks so progress is flushed to disk periodically (a crash then
  # loses at most one chunk). The whole file is rewritten on each flush; all
  # columns are written as character so a re-read resumes cleanly.
  chunk_size <- max(1L, as.integer(chunk_size))
  chunks <- split(files, ceiling(seq_along(files) / chunk_size))
  new_rows <- vector("list", length(files))
  pos <- 0L

  for (chunk in chunks) {
    res <- mapper(chunk)
    new_rows[seq_along(res) + pos] <- res
    pos <- pos + length(res)

    if (!is.null(output)) {
      combined <- dplyr::bind_rows(done_rows,
                                   to_char(dplyr::bind_rows(new_rows[seq_len(pos)])))
      readr::write_csv(combined, output)
    }
  }

  # Rows freshly computed in this run share rt_all_pmc()'s native column types,
  # so they bind directly. When resuming, reconcile with the character-typed
  # done_rows by re-guessing the combined table's column types uniformly.
  typed <- dplyr::bind_rows(new_rows)
  if (is.null(done_rows)) {
    typed
  } else {
    reguess(dplyr::bind_rows(done_rows, to_char(typed)))
  }
}
