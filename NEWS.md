<div align="justify">

# rtransparent 0.4.2

* Added a pkgdown documentation website at <https://choxos.github.io/rtransparent>.
* Corrected the `rt_data_code_pmc_list()` documentation example.


# rtransparent 0.4.1

* Fixed the exported `rt_fund_pmc()`. It previously predicted funding `TRUE` for no-funding articles with empty evidence text; it now delegates to the same detection path as `rt_all_pmc()` so the two agree, and a positive prediction always carries evidence. Added regression tests.
* Exported and documented `rt_meta_pmc()` (article metadata from a PMC XML file), which the README advertised but which was not exported.
* Generated the missing help pages for the novelty and replication functions. `R CMD check` now passes with no errors or warnings.
* Rewrote the vignette to be self-contained (it runs on a bundled example XML, with the PDF and download steps shown but not executed) and to describe the package and its methodology; removed stale `oddpub` / `metareadr` instructions.
* Updated the README and benchmark documentation for native data and code detection, pointed URLs at the maintained fork, and regenerated the committed benchmark results under the current version.
* Added a package startup message and removed the stale packrat configuration.


# rtransparent 0.4.0

* Data and code sharing detection is now implemented natively (`R/data_code.R`) and no longer requires the `oddpub` package at runtime. On the held-out validation set the native detector scores data 64% sensitivity / 95% specificity and code 68% sensitivity / 94% specificity (the published paper reports about 76% and 59% sensitivity). Code detection already exceeds the paper's sensitivity and the data precision matches the original oddpub; data sensitivity is being improved toward oddpub's ~84%.
* `rt_data_code`, `rt_data_code_pmc` and `rt_data_code_pmc_list` were rewritten to use the native detector and return `is_open_data` / `is_open_code` with the matched statement text. They no longer depend on `oddpub` or `tokenizers`.
* Added a data/code benchmark (`data-raw/benchmark/run_data_code.R`, `inst/benchmark/results_data_code.md`).


# rtransparent 0.3.4

* Ported the PROSPERO detection fix from the quest-bih fork: the registration regex now matches PROSPERO identifiers of 5 to 11 digits (`CRD` numbers exceed 5 digits), in both the TXT and PMC detectors. No change on the benchmark (the held-out set has no PROSPERO-only cases). The fork's other commits were assessed and deferred: "coi update" is TXT-only (not exercised by the PMC benchmark) and "pipe update" is a cosmetic reformat that conflicts with this line's changes.


# rtransparent 0.3.3

* Improved funding specificity from 78% to 96% on the held-out XML test set (accuracy 86% to 97%) by tightening `get_fund_acknow_new()`. It previously flagged any acknowledgment that merely named an institution or used the word "support", so competing-interest statements, generic thanks, data-availability statements and affiliations were misread as funding. It now requires explicit funding language: a funding verb directed at a funder, an institutional "support/funding of the ...", a grant or award identifier, or a named award. Sensitivity is unchanged at 100% on the test set.


# rtransparent 0.3.2

* Added a reproducible accuracy benchmark (`data-raw/benchmark/`, `inst/benchmark/`) that scores the detectors against the human-labeled gold standard of Serghiou et al. (2021) and reports sensitivity, specificity, PPV, NPV and accuracy with bootstrap confidence intervals, alongside the published Fig 2 numbers.
* Fixed `.reroot_xml()` to handle bare `<article>` and NCBI EFetch `<pmc-articleset>` roots. Previously it returned an empty document for anything other than the PMC OAI-PMH format, which silently suppressed all detection.
* Fixed unqualified `str_detect()`/`regex()` calls in the funding detector that errored on articles lacking a structured funding statement.


# rtransparent 0.3.1

* Data and code detection dependencies (`oddpub`, `tokenizers`) are now optional (moved to `Suggests`); the package loads and every other indicator runs without them. The data and code functions raise a clear, actionable error when these packages are absent.
* Added an internal PMC full-text XML fetch helper for the accuracy benchmark, backed by NCBI E-utilities (EFetch) with a PMC OAI-PMH fallback (adapted from `metareadr`, GPL-3).


# rtransparent 0.3.0

* `rt_novelty` and `rt_novelty_pmc` added: detect claims of novelty ("for the first time") in TXT and PMC XML files.
* `rt_replication` and `rt_replication_pmc` added: detect replication/validation components in TXT and PMC XML files.
* `rt_register` and `rt_register_pmc` expanded: now detect registrations on ISRCTN, ANZCTR (ACTRN), DRKS, IRCT, and UMIN in addition to NCT and PROSPERO.
* `rt_all` and `rt_all_pmc` updated to include novelty and replication indicators.
* A formal testthat test suite has been added (`tests/testthat/`).


# rtransparent 0.2.5

* A vignette has been added to help illustrate how to use the package.


# rtransparent 0.2

* `rt_coi` now searches for Conflicts of interest statements within text files.
* `rt_fund` now searches for Funding statements within text files.
* `rt_register` now searches for Registration statements within text files.
* `rt_all` now searches for many indicators within text files.
* `rt_read_pdf` now converts PDF files into TXT using poppler.


# rtransparent 0.1

* Initial commit of functions to analyze PMC XML files for indicators.


</div>