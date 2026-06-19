## Submission

This is a new submission of `rtransparency`, a renamed and substantially extended
fork of the (CRAN-unpublished) `rtransparent` tool of Serghiou et al. (2021).
Stylianos Serghiou is credited as an author, and the foundational paper is cited
in the Description field and in `inst/CITATION`.

## R CMD check results

0 errors | 0 warnings | 1 note

* The note is the standard "New submission" note.

## Test environments

* local macOS, R 4.x (0 errors, 0 warnings, 1 note)
* win-builder and R-hub: to be run before final submission.

## Notes for CRAN

* Examples that require network access (NCBI fetch) or the external `pdftotext`
  utility are wrapped in `\dontrun{}`.
* The package is self-contained: data and code sharing detection is implemented
  natively and does not depend on the GitHub-only / AGPL `oddpub` package.
