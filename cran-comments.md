## Submission

This is a new submission of `rtransparency`, a renamed and substantially extended
fork of the (CRAN-unpublished) `rtransparent` tool of Serghiou et al. (2021).
Stylianos Serghiou is credited as an author, and the foundational paper is cited
in the Description field and in `inst/CITATION`.

## R CMD check results

0 errors | 0 warnings | 1 note

* The note is the standard "New submission" note.

## Test environments

* local macOS, R 4.6.0 (0 errors, 0 warnings, 1 note)
* GitHub Actions (r-lib/actions, full `R CMD check`): macOS-release,
  windows-release, ubuntu-devel, ubuntu-release, ubuntu-oldrel-1; all passing.
* win-builder (devel) recommended at submission via `devtools::check_win_devel()`.

## Notes for CRAN

* Examples that require network access (NCBI fetch) or the external `pdftotext`
  utility are wrapped in `\dontrun{}`.
* The package is self-contained: data and code sharing detection is implemented
  natively and does not depend on (or contain code from) the GitHub-only / AGPL
  `oddpub` package. `rt_read_pdf()` is an original wrapper around the poppler
  `pdftotext` command-line utility. The only adapted code is an internal,
  benchmark-only NCBI OAI fallback derived from `metareadr::mt_read_pmcoa()`
  (GPL-3); its author, Stylianos Serghiou, is credited in `Authors@R`.
