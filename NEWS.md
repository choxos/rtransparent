<div align="justify">

# rtransparent 0.8.3

Further fixes from the manual validation on a fresh sample of 1,000 open-access PMC articles from 2023:

* Data sharing: recognize a repository deposit when a superscript reference number is glued to the repository name during text extraction (for example "the database was stored on Mendeley Data20"). The "data" token was no longer recognized once a digit was attached to it, so the deposit was missed. The data-noun pattern now tolerates a trailing reference number. The change does not match the unrelated word "database". The held-out data benchmark is unchanged (sensitivity 76.5%, specificity 99.0%).
* Registration: detect a PROSPERO registration that does not quote the CRD identifier (for example "the review protocol was registered in PROSPERO", "Registered to PROSPERO"). The detector previously required a CRD number. It now also flags the past-tense verb "registered" next to PROSPERO, while still not matching the registry's own name ("International Prospective Register of Systematic Reviews") or a "not registered" statement. The registration benchmark is unchanged at 98.1%.
* Added regression tests for both.


# rtransparent 0.8.2

* Code sharing: detect repository-hosted code when the same sentence also offers the data on request. A single availability statement sometimes reads "the pipeline is available on GitHub, and sample data are available upon request"; the data-delivery wording ("upon request", "from the corresponding author") was vetoing the whole sentence, so the openly hosted code was missed. The data-delivery negations no longer veto code that is concretely hosted on a public repository, while genuine non-availability ("the source code is not publicly available") and request-only code with no repository are still not counted. The held-out code benchmark is unchanged (sensitivity 88.1%, specificity 99.5%). Added regression tests.


# rtransparent 0.8.1

Fixes from a manual validation on a fresh, disjoint sample of 1,000 open-access PMC articles from 2023:

* Registration: detect more ClinicalTrials.gov phrasings. The detector previously required "registered at ClinicalTrials.gov" and missed common forms such as "the RCT is registered with ClinicalTrials.gov (NCT...)" and "trial registration number NCT...". It now flags an NCT identifier that co-occurs with a registration verb or ClinicalTrials.gov, while still not flagging a trial merely cited by its identifier. Registration benchmark accuracy is unchanged at 98.1%.
* Code sharing: recognize code shared on the Open Science Framework. OSF was already a recognized data repository but not a code repository, so "data and code are available on the OSF" was counted for data but not code. Data on OSF without a code mention is still not counted as code.
* Added regression tests for both.


# rtransparent 0.8.0

* New **AI-disclosure** indicator. `rt_ai_pmc()` detects whether an article discloses the use (or non-use) of generative AI or AI-assisted tools in preparing the manuscript, as journals have asked of authors since 2023. It recognizes positive disclosures ("the authors used ChatGPT to improve the readability of the manuscript"), negative disclosures ("no generative AI was used in the preparation of this work") and dedicated "Declaration of generative AI" sections, while not flagging articles that merely use AI as their research method. Because the practice did not exist before 2023, the indicator is only evaluated for articles published in 2023 or later; earlier articles return `NA` (`is_ai_pred`), and the publication `year` is reported. The indicator is included in `rt_all_pmc()` and recognized by `rt_summary()`. On the 1,000-article open-access validation set (almost all published 2024-2026) it flags about 16% of articles, with high precision on inspection.


# rtransparent 0.7.1

* Code sharing recall improved. The detector now recognizes analysis code shared in supplementary or additional files ("the Matlab code can be found in the Supplementary Methods", "R code is contained in Additional file 7", "Source code 1") and explicit "Availability of source code" sections. On the held-out benchmark of Serghiou et al. (2021), code sensitivity rises from 83.5% to 88.1% with specificity unchanged at 99.5% (PPV 99.0%); `rt_accuracy` was updated. The patterns are gated on a language prefix or the word "script" so non-analysis "codes" (ICD, diagnosis, qualitative) are not matched. Added regression tests.


# rtransparent 0.7.0

Improvements from a large audit: the tool was run over 1,000 cached open-access PMC articles and a sample was hand-checked against the human-labeled benchmark.

* Data sharing recall improved. The detector now recognizes "the data supporting the findings are included within the article / within the manuscript" availability statements (previously only the "in the article" wording was matched). On the held-out benchmark of Serghiou et al. (2021), data sensitivity rises from 72.2% to 76.5% with specificity unchanged at 99.0% (PPV 98.9%); `rt_accuracy` was updated.
* Replication precision improved. Future or required validation framed as not-yet-done ("external validation is essential/needed before clinical implementation", "this finding requires validation in independent cohorts") is no longer counted as replication. Validation that was actually performed (external or independent) still counts. The change is gated on a modal or need word so performed validation is preserved.
* Added regression tests for both changes.


# rtransparent 0.6.1

Precision and recall fixes from an independent manual review of a sample of open-access PMC articles:

* Replication: a bare internal training/validation split (a single dataset divided into a training cohort and a validation cohort) is no longer counted as replication, since it is model development rather than an independent confirmation in a new sample. External or independent validation still counts.
* Novelty: firstness claims that carry an adverbial are now detected, for example "the first to date to report ..." and "the first ever study to characterize ...".
* Data: the generic publisher line "The online version contains supplementary material available at <doi>", which appears in every article of some journals, is no longer treated as a data-availability statement on its own.


# rtransparent 0.6.0

* Substantially improved detector recall, guided by an external validation set of 1,000 open-access PMC articles:
  * Novelty and replication detection now scan the full article body and recognize many more phrasings (firstness and knowledge-gap claims for novelty; internal, external and independent-validation claims for replication), while new suppressors keep generic "validation" and future-work wording out.
  * Data and code sharing detection gained high-specificity patterns for in-article and supplement availability statements, repository-hosted data, and explicit code-availability wording, and new vetoes for supplement boilerplate, result tables, local file paths and tool/package-use mentions.
  * Registration detection added negation guards ("not registered", "not applicable", IRB-only numbers) and broader registry coverage.
* The reproducible data/code benchmark now gives data 71.3% sensitivity / 99.0% specificity and code 83.5% sensitivity / 99.5% specificity; `rt_accuracy` was updated to these estimates.
* Internal helper functions are now marked `@noRd`, so the manual and the pkgdown reference present only the public API.
* Hardened `rt_summary()` and `rt_score()` so indicator columns must be logical or numeric 0/1 values, with `NA` allowed.
* Added a reproducible external validation harness under `data-raw/external-validation/`.


# rtransparent 0.5.1

* Corrected the license declaration from `GPL-3 + file LICENSE` to `GPL-3`. The package is plain GPL-3 with no additional terms, so the `+ file LICENSE` form (which signals extra restrictions in the `LICENSE` file) was misleading; the full GPL-3 text is still provided in `LICENSE` for reference.


# rtransparent 0.5.0

* New corpus-level summary tools, for turning per-article detector output into the kind of figures and tables used in meta-research studies of transparency:
  * `rt_summary()` reports each indicator's prevalence with a Wilson confidence interval and, by default, a prevalence corrected for the detector's sensitivity and specificity (the Rogan-Gladen estimator). It can summarize within groups via `by`.
  * `rt_score()` adds a per-article count of the openness practices met.
  * `rt_plot()` draws a prevalence bar chart or a prevalence-over-time line chart (requires `ggplot2`).
* New datasets: `rt_accuracy` (detector sensitivity and specificity estimates, used by `rt_summary()`) and `rt_demo` (a small simulated corpus for the examples).
* New vignette, `vignette("transparency-summary")`, illustrating the output: from one article to a corpus prevalence table, an accuracy-corrected prevalence, a practice-count distribution, subgroup summaries and plots.


# rtransparent 0.4.3

* Removed the unused legacy data and code helper functions that still referenced `oddpub` and `tokenizers`. The native detector (added in 0.4.0) is the only data and code path; `oddpub`, `tokenizers` and `metareadr` have been dropped from `Suggests`, so the package and its CRAN-style check no longer reference any GitHub-only packages.
* Resolved the `R CMD check` note about the undefined `.` global variable.
* Polished release metadata: the `DESCRIPTION` `Title` is now in title case and the pkgdown URL carries its trailing slash.
* The pkgdown reference index now groups the exported functions by purpose and collapses internal helpers, so the website presents the public API rather than every internal helper.
* Regenerated the committed benchmark artifacts under the current package version.


# rtransparent 0.4.2

* Added a pkgdown documentation website at <https://choxos.github.io/rtransparent/>.
* Corrected the `rt_data_code_pmc_list()` documentation example.


# rtransparent 0.4.1

* Fixed the exported `rt_fund_pmc()`. It previously predicted funding `TRUE` for no-funding articles with empty evidence text; it now delegates to the same detection path as `rt_all_pmc()` so the two agree, and a positive prediction always carries evidence. Added regression tests.
* Exported and documented `rt_meta_pmc()` (article metadata from a PMC XML file), which the README advertised but which was not exported.
* Generated the missing help pages for the novelty and replication functions. `R CMD check` now passes with no errors or warnings.
* Rewrote the vignette to be self-contained (it runs on a bundled example XML, with the PDF and download steps shown but not executed) and to describe the package and its methodology; removed stale `oddpub` / `metareadr` instructions.
* Updated the README and benchmark documentation for native data and code detection, pointed URLs at the maintained fork, and regenerated the committed benchmark results under the current version.
* Added a package startup message and removed the stale packrat configuration.


# rtransparent 0.4.0

* Data and code sharing detection is now implemented natively (`R/data_code.R`) and no longer requires the `oddpub` package at runtime. On the XML benchmark used at the time, the native detector scored data 64% sensitivity / 95% specificity and code 68% sensitivity / 94% specificity (the published paper reports about 76% and 59% sensitivity). Code detection already exceeded the paper's sensitivity and the data precision matched the original `oddpub`; data sensitivity was being improved toward `oddpub`'s ~84%.
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
