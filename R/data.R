#' Detector accuracy estimates
#'
#' Sensitivity and specificity estimates for each transparency detector, used by
#' [rt_summary()] to correct an apparent prevalence for detector error
#' (the Rogan-Gladen correction).
#'
#' For conflicts of interest, funding and protocol registration these are the
#' published, importance-weighted validation values of Serghiou et al. (2021);
#' the detectors for these indicators are essentially those validated in the
#' paper. For data and code sharing the detector is implemented natively in this
#' package (it no longer wraps `oddpub`), so the package's reproducible
#' benchmark and regression estimates are used instead (see `inst/benchmark`).
#' These data/code estimates are not an untouched external validation of the
#' native detector; supply your own values to [rt_summary()] via its `accuracy`
#' argument when you have study-specific or externally validated estimates.
#' Novelty's estimate comes from a maintainer-built hand-labeled gold set
#' (see `inst/benchmark/results_novelty_replication.md`). Replication's
#' sensitivity comes from a 111-positive replication-enriched validation
#' (see `inst/benchmark/results_replication_enriched.md`), with the specificity
#' from the 2023 1000-article sample. AI-use disclosure is not included (its
#' prevalence is too low in unselected literature for a stable estimate), so
#' [rt_summary()] reports it uncorrected.
#'
#' @format A tibble with 7 rows and 5 columns:
#' \describe{
#'   \item{variable}{Indicator column name, as returned by [rt_all_pmc()].}
#'   \item{label}{Human-readable indicator name.}
#'   \item{sensitivity}{Detector sensitivity (true-positive rate), 0-1.}
#'   \item{specificity}{Detector specificity (true-negative rate), 0-1.}
#'   \item{source}{Where the estimate comes from.}
#' }
#' @source Serghiou S, Contopoulos-Ioannidis DG, Boyack KW, Riedel N, Wallach JD,
#'   Ioannidis JPA (2021). Assessment of transparency indicators across the
#'   biomedical literature: How open is open? \emph{PLOS Biology} 19(3):
#'   e3001107. \doi{10.1371/journal.pbio.3001107}. Data and code values: this
#'   package's reproducible benchmark and regression estimates
#'   (`inst/benchmark/results_data_code.md`).
#' @seealso [rt_summary()]
"rt_accuracy"


#' Simulated transparency indicators for a corpus of articles
#'
#' A small, simulated set of detector output, with one row per article, used to
#' illustrate [rt_summary()], [rt_score()] and [rt_plot()]. The values are
#' \strong{simulated}, not real detector output: prevalences and their trends
#' over time are chosen to resemble published findings (frequent conflict-of-
#' interest and funding disclosure, less frequent protocol registration, low but
#' rising data sharing, rare code sharing, and a recent, fast-rising disclosure
#' of generative-AI use) so the illustrations are realistic.
#'
#' @format A tibble with 1200 rows and 11 columns:
#' \describe{
#'   \item{pmid}{A made-up PubMed identifier (character).}
#'   \item{year}{Publication year, 2010-2026.}
#'   \item{type}{Article type (research-article, review-article,
#'     systematic-review).}
#'   \item{is_coi_pred}{Conflict-of-interest statement detected.}
#'   \item{is_fund_pred}{Funding statement detected.}
#'   \item{is_register_pred}{Protocol registration detected.}
#'   \item{is_open_data}{Data sharing detected.}
#'   \item{is_open_code}{Code sharing detected.}
#'   \item{is_novelty_pred}{Novelty claim detected.}
#'   \item{is_replication_pred}{Replication component detected.}
#'   \item{is_ai_pred}{Disclosure of generative-AI use detected. `NA` before
#'     2023, when the practice did not yet exist (see [rt_ai_pmc()]).}
#' }
#' @seealso [rt_summary()], [rt_score()], [rt_plot()]
"rt_demo"
