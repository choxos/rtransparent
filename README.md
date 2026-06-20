# rtransparency

<!-- badges: start -->
[![R-CMD-check](https://github.com/choxos/rtransparency/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/choxos/rtransparency/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/choxos/rtransparency/actions/workflows/pkgdown.yaml/badge.svg)](https://choxos.github.io/rtransparency/)
[![Lifecycle: stable](https://img.shields.io/badge/lifecycle-stable-brightgreen.svg)](https://lifecycle.r-lib.org/articles/stages.html#stable)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.20775089.svg)](https://doi.org/10.5281/zenodo.20775089)
<!-- badges: end -->

<div align="justify">

`rtransparency` automatically identifies and extracts **indicators of research
transparency** from the full text of biomedical articles, in both PubMed Central
(PMC) JATS XML and plain-text (PDF-derived) form. Every prediction comes with the
exact statement that triggered it, so results are auditable rather than a black
box. Detection is rule-based (curated regular expressions over the relevant
article sections), self-contained (no GitHub-only or AGPL dependencies), and
ships with reproducible accuracy benchmarks.

## The eight indicators

| Indicator | Detects | XML function | Text function |
|---|---|---|---|
| **Conflicts of interest** | A COI disclosure is present (including "no competing interests") | `rt_coi_pmc` | `rt_coi` |
| **Funding** | A statement that funding was received | `rt_fund_pmc` | `rt_fund` |
| **Protocol registration** | A trial/protocol registration identifier or statement (NCT, ISRCTN, PROSPERO, OSF, CHiCTR, DRKS, ANZCTR, IRCT, UMIN, ...) | `rt_register_pmc` | `rt_register` |
| **Novelty** | The article claims its own work is novel or first | `rt_novelty_pmc` | `rt_novelty` |
| **Replication** | A replication or external/independent validation was performed | `rt_replication_pmc` | `rt_replication` |
| **Data sharing** | The authors' own data are made available (repository, accession, or in-article) | `rt_data_code_pmc` | `rt_data_code` |
| **Code sharing** | The authors' own analysis code is shared | `rt_data_code_pmc` | `rt_data_code` |
| **AI disclosure** | A statement discloses generative-AI use in manuscript preparation (2023+) | `rt_ai_pmc` | `rt_ai` |

Conflicts of interest and AI disclosure are **disclosure-based**: a statement on
the topic counts whether the disclosure is positive or negative. Conflict-of-
interest and funding statements are detected not only in English but also in
**Spanish, Portuguese, French, German and Italian**.

## Installation

```r
# From CRAN (when available)
install.packages("rtransparency")

# Development version from GitHub
# install.packages("remotes")
remotes::install_github("choxos/rtransparency", build_vignettes = TRUE)
```

No GitHub-only or AGPL dependencies are required; data and code detection is
native (it no longer wraps `oddpub`). `rt_read_pdf()` (PDF to text) additionally
needs the poppler `pdftotext` utility on your system. The optional `furrr` and
`future` packages enable parallel corpus processing; `ggplot2` enables plotting.

## Quick start: all eight indicators in one call

```r
library(rtransparency)

xml <- system.file("extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency")

res <- rt_all_pmc(xml, remove_ns = TRUE)

# The predictions, one column per indicator:
res[, c("is_coi_pred", "is_fund_pred", "is_register_pred", "is_novelty_pred",
        "is_replication_pred", "is_open_data", "is_open_code", "is_ai_pred")]

# Each prediction is paired with the text that triggered it, e.g.:
res$coi_text
res$fund_text
res$open_data_statements
```

`rt_all_pmc()` returns one row with the eight predictions, the extracted
statement for each, article identifiers and metadata, the year, and
`is_success`. `is_ai_pred` is `NA` for articles published before 2023.

## Per-indicator functions

Each indicator can be run on its own, for a PMC XML file or a plain-text file:

```r
rt_coi_pmc(xml, remove_ns = TRUE)        # conflicts of interest
rt_fund_pmc(xml, remove_ns = TRUE)       # funding
rt_register_pmc(xml, remove_ns = TRUE)   # protocol registration
rt_novelty_pmc(xml, remove_ns = TRUE)    # novelty claims
rt_replication_pmc(xml, remove_ns = TRUE)# replication / external validation
rt_data_code_pmc(xml, remove_ns = TRUE)  # data AND code sharing (+ extracted links)
rt_ai_pmc(xml, remove_ns = TRUE)         # generative-AI-use disclosure (2023+)
rt_meta_pmc(xml, remove_ns = TRUE)       # article metadata
```

## Corpus-scale processing

`rt_all_pmc_dir()` runs all eight indicators over an entire directory (or a
vector of paths). It is built for large corpora:

```r
res <- rt_all_pmc_dir(
  "path/to/xml",          # a directory, or a character vector of file paths
  remove_ns = TRUE,
  output    = "results.csv",  # resumable: re-running skips files already recorded
  parallel  = TRUE,           # via furrr + an active future::plan()
  progress  = TRUE
)
```

- **Resumable**: with `output`, results are written to a CSV in chunks; a re-run
  skips files already recorded and appends only the new ones.
- **Failure-isolated**: a malformed file yields an `is_success = FALSE` row
  instead of aborting the run.
- **Parallel**: set `future::plan("multisession")` and `parallel = TRUE`.

## Plain-text input

The same detectors run on plain-text (PDF-derived) articles. `rt_read_pdf()`
returns the extracted text as a character string; write it to a `.txt` file,
then point the text detectors (which share the PMC detection logic) at that file:

```r
article_txt <- rt_read_pdf("article.pdf")   # needs poppler's pdftotext; returns text
writeLines(article_txt, "article.txt")      # the detectors take a file path

rt_all("article.txt")                       # COI, funding, registration, novelty, replication
rt_coi("article.txt")                       # or one indicator at a time
rt_ai("article.txt")                        # generative-AI-use disclosure
```

`rt_ai()` is the plain-text counterpart of `rt_ai_pmc()`. Because a text file
carries no reliable publication date, it applies **no 2023 year gate** (it
returns `TRUE`/`FALSE`, never `NA`) and cannot confine the scan to back-matter
sections, so restrict its use to 2023-or-later articles and expect a slightly
higher false-positive rate on papers that use AI as a research method.

## Summarizing a corpus

Once you have one row per article, summarize the corpus:

```r
data(rt_demo)            # a small simulated example shipped with the package

rt_summary(rt_demo)      # per-indicator prevalence with a Wilson confidence
                         # interval and a sensitivity/specificity-corrected
                         # (Rogan-Gladen) prevalence

rt_summary(rt_demo, by = "year")   # subgroup summaries

rt_score(rt_demo)        # add a per-article count of openness practices met

rt_plot(rt_demo)                                  # prevalence bar chart
rt_plot(rt_demo, type = "trend", year = "year")   # prevalence over time
```

The accuracy correction uses the bundled `rt_accuracy` table (detector
sensitivity and specificity for seven indicators). Supply your own estimates:

```r
rt_accuracy                              # the bundled estimates
my_acc <- data.frame(variable = "is_open_data", sensitivity = 0.84, specificity = 0.97)
rt_summary(rt_demo, accuracy = my_acc)   # correct with your own values
```

## Linking to FAIR assessment

The data- and code-availability links the detector extracts (`open_data_links`,
`open_code_links`) can be passed to FAIR-assessment tooling such as
[`rfair`](https://github.com/choxos/rfair) to score the findability and
accessibility of the shared resources.

## Validation

Benchmarked against the human-labeled XML benchmark of Serghiou et al. (2021),
reproducible under `data-raw/benchmark/`, with results in `inst/benchmark/`:

| Indicator | Sensitivity | Specificity |
|---|---|---|
| Conflicts of interest | 94.0% | 100% |
| Funding | 100% | 95.7% |
| Protocol registration | 99.2% | 96.9% |
| Data sharing | 76.5% | 99.0% |
| Code sharing | 88.1% | 99.5% |

Registration and code in the Serghiou benchmark table above are labeled
independently of the detector; COI, funding and data labels in the 1000-article 2023 sample were
reconciled against detector-extracted statements (detector-adjudicated), so their
agreement is not a fully independent estimate. Data sharing is deliberately
precision-favoring: its 76.5% sensitivity trades recall for 99.0% specificity
(the original `oddpub` algorithm scores about 84%/97% on this set).

The newer indicators are validated against maintainer-built, hand-labeled
benchmarks in `inst/benchmark/`:

| Indicator | Sensitivity | Specificity | Basis |
|---|---|---|---|
| Novelty | 83.8% | 95.2% | hand-labeled novelty/replication gold set |
| Replication | 92.8% | 98.5% | replication-enriched sample (111 positives); correction is approximate |
| AI-use disclosure | not accuracy-corrected | — | experimental; only 9 positives in the 2023 sample |

Replication's correction mixes designs (sensitivity from the enriched sample,
specificity from the representative 2023 sample), so it is less clean than the
single-design corrections above. AI-use disclosure is reported uncorrected and is
excluded from `rt_accuracy` until a larger labeled post-2022 sample exists. Two
further benchmarks live in `inst/benchmark/`: a **five-language sample** for
multilingual COI and funding, and a **TXT-parity benchmark** comparing the text
and XML detectors.

See `vignette("rtransparency")` for the methodology and `vignette("scope-and-limitations")`
for what each indicator does and does not capture.

## Documentation

- `vignette("rtransparency")` — introduction and methodology
- `vignette("transparency-summary")` — corpus prevalence, scoring and plotting
- `vignette("ai-disclosure")` — the AI-use disclosure indicator in depth
- `vignette("scope-and-limitations")` — indicator semantics, limitations, output schema
- Package website: <https://choxos.github.io/rtransparency/>

## Lineage and citation

This package builds on the original **`rtransparent`** tool of Stylianos
(Stelios) Serghiou, an enhanced, renamed fork maintained by Ahmad Sofi-Mahmudi
([ORCID 0000-0001-6829-0823](https://orcid.org/0000-0001-6829-0823), GitHub
[@choxos](https://github.com/choxos)). It adds four indicators (novelty,
replication, AI disclosure, and a natively re-implemented data/code detector),
multilingual COI and funding detection, plain-text parity, and corpus-scale
batch processing. Serghiou is credited as an author.

The foundational paper: Serghiou et al., *Assessment of transparency indicators
across the biomedical literature: How open is open?* PLOS Biology, 2021,
[doi:10.1371/journal.pbio.3001107](https://doi.org/10.1371/journal.pbio.3001107).
Run `citation("rtransparency")` for both references.

## Getting help

Please file bugs or questions as issues at
<https://github.com/choxos/rtransparency/issues> with a minimal reproducible
example.

</div>
