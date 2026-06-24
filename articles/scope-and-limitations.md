# Scope and limitations

`rtransparency` is a pattern-based detector. It is designed for high
precision on the statements it targets, and its predictions come with
the exact text that triggered them so they can be audited. This vignette
describes what each indicator does and does not capture, so results are
interpreted correctly.

## What the indicators mean

| Indicator | Detects | Does **not** mean |
|----|----|----|
| Conflicts of interest | A COI **disclosure is present** (including “the authors declare no competing interests”) | That a conflict exists |
| Funding | A statement that funding **was received** | Presence of a funding *section* (a “no funding” section is read as absence) |
| Registration | A protocol/trial **registration identifier or statement** | Ethics/IRB approval numbers |
| Novelty | The article **claims** its own work is novel or first | That the work is objectively novel |
| Replication | A replication or external/independent validation was **performed** | An internal train/test split, or future/recommended validation |
| Data sharing | The authors’ **own data are made available** (repository, accession, or in-article) | Data merely reused, cited, or available “upon request” |
| Code sharing | The authors’ **own analysis code is shared** | Use of third-party software/tools |
| AI disclosure | A statement **discloses** generative-AI use in manuscript preparation (including “no AI was used”) | Use of AI as a research method |
| Open-access license | The article is **openly licensed** (Creative Commons / CC0), and which license | That every reader has full reuse rights (NC / ND licenses restrict reuse) |
| Reporting guideline | The authors **state they followed** a reporting guideline, and which one | That the study fully complied, or that a cited/animal-welfare/clinical guideline counts |

Conflicts of interest and AI disclosure are **disclosure-based**: a
statement addressing the topic counts as present, whether the disclosure
is positive or negative. This mirrors how these are reported and counted
in the literature.

## Known limitations

- **Language.** Detection is strongest in English. Conflict-of-interest
  and funding statements are also detected in Spanish, Portuguese,
  French, German and Italian; other indicators and other languages are
  not yet covered.
- **Data availability “upon request”.** Data offered only on request are
  **not** counted as shared, reflecting the modern open-data standard.
  This is stricter than some earlier definitions and will report lower
  data-sharing prevalence than tools that count availability-on-request.
- **Novelty and replication are claim detection.** They identify what
  authors *state*, not whether a study is truly novel or a replication
  succeeded. The replication indicator in particular is
  precision-limited because validation language (“validation cohort”,
  “independent”) is heavily overloaded; see the replication-enriched
  benchmark in `inst/benchmark/`.
- **Plain text vs XML.** The plain-text detectors share the same logic
  as the PMC XML detectors but cannot use XML-structural cues (tagged
  funding groups, conflict footnotes, section types), so a few
  statements detectable in XML are not detectable in plain text. The
  plain-text AI detector
  [`rt_ai()`](https://choxos.github.io/rtransparency/reference/rt_ai.md)
  is a special case: with no publication date and no section structure
  available, it applies **no 2023 year gate** (it never returns `NA`)
  and scans the whole document, so the caller must restrict it to
  2023-or-later articles and tolerate a higher false-positive rate on
  AI-method papers than
  [`rt_ai_pmc()`](https://choxos.github.io/rtransparency/reference/rt_ai_pmc.md).
- **Reporting guideline is claim detection.** It identifies a stated
  adherence to a reporting guideline, not whether the study fully
  complied. It is tuned for precision (validated 93.8% sensitivity /
  99.0% specificity on a hand-labeled 1000-article sample); the residual
  misses are mostly non-English statements, and residual false positives
  are guidelines named but not actually followed by the article.
- **Open-access licensing is XML-structural.** It reads the JATS
  `<license>` element, so it is near-deterministic for PMC XML but, in
  plain text, depends on a license statement being present in the
  extracted text.
- **Accuracy correction.**
  [`rt_summary()`](https://choxos.github.io/rtransparency/reference/rt_summary.md)
  can correct apparent prevalence using bundled sensitivity/specificity
  estimates (`rt_accuracy`). These derive from the validation
  benchmarks; supply your own via `rt_summary(accuracy = )` when you
  have study-specific estimates. AI disclosure is reported uncorrected
  (its prevalence is too low in unselected literature for a stable
  estimate).

## Output schema

Every per-article detector returns the prediction columns `is_coi_pred`,
`is_fund_pred`, `is_register_pred`, `is_novelty_pred`,
`is_replication_pred`, `is_open_data`, `is_open_code`, the year-gated
`is_ai_pred` (`NA` before 2023), `is_open_access` (with `oa_license`)
and `is_reporting_pred` (with `reporting_guideline`), each paired with
the extracted text or value.
[`rt_all_pmc()`](https://choxos.github.io/rtransparency/reference/rt_all_pmc.md)
returns all ten for one file;
[`rt_all_pmc_dir()`](https://choxos.github.io/rtransparency/reference/rt_all_pmc_dir.md)
runs a whole directory.

``` r

library(rtransparency)

res <- rt_all_pmc("article.xml", remove_ns = TRUE)
res[, c("is_coi_pred", "is_fund_pred", "is_open_data", "is_open_code")]
```

## Linking to FAIR assessment

The data- and code-availability links the detector extracts
(`open_data_links`, `open_code_links`) can be passed to FAIR-assessment
tooling such as [`rfair`](https://github.com/choxos/rfair), a native R
implementation of FAIR data and software assessment, to score the
findability and accessibility of the shared resources.

``` r

res <- rt_all_pmc("article.xml", remove_ns = TRUE)
links <- strsplit(res$open_data_links, " ; ")[[1]]
# rfair::assess_fair(links)
```
