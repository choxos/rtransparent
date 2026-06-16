<div align="justify">

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