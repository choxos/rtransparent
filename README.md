# rtransparent

<div align="justify">

## Overview

`rtransparent` is an R package that automatically identifies and extracts
**indicators of transparency** from the full text of published biomedical
articles, in both TXT (PDF-derived) and PMC XML form. For each indicator it
returns whether the indicator was found and, when found, the statement that
triggered the detection.

It detects seven indicators:

- **Conflicts of interest** (`rt_coi`, `rt_coi_pmc`)
- **Funding** (`rt_fund`, `rt_fund_pmc`)
- **Protocol registration** (`rt_register`, `rt_register_pmc`)
- **Novelty** claims (`rt_novelty`, `rt_novelty_pmc`)
- **Replication** components (`rt_replication`, `rt_replication_pmc`)
- **Data sharing** and **code sharing** (`rt_data_code`, `rt_data_code_pmc`)

`rt_all` / `rt_all_pmc` run COI, funding, registration, novelty and replication
together; `rt_meta_pmc` returns article metadata from a PMC XML file.

Detection is rule-based and interpretable (curated regular expressions over the
relevant article sections), so the output is auditable and reproducible. See the
vignette (`vignette("rtransparent")`) for the methodology, and the package
website at <https://choxos.github.io/rtransparent/> for full documentation.

## Authors

Original package by Stylianos (Stelios) Serghiou. This enhanced fork is
maintained by Ahmad Sofi-Mahmudi
([ORCID 0000-0001-6829-0823](https://orcid.org/0000-0001-6829-0823), GitHub
[@choxos](https://github.com/choxos)). The original data and code detection
relied on the `oddpub` package of Nico Riedel; data and code detection is now
implemented natively and no longer requires `oddpub`.

## Publication

`rtransparent` was validated and used to extract indicators of transparency
across the open access literature in PubMed Central: Serghiou et al.,
*Assessment of transparency indicators across the biomedical literature: How
open is open?* PLOS Biology, 2021,
[doi:10.1371/journal.pbio.3001107](https://doi.org/10.1371/journal.pbio.3001107).

## Installation

```r
# install.packages("remotes")
remotes::install_github("choxos/rtransparent", build_vignettes = TRUE)
```

No GitHub-only or AGPL dependencies are required; data and code detection is
native. `rt_read_pdf()` (PDF to TXT) additionally needs the poppler
`pdftotext` utility on your system.

## Usage

```r
library(rtransparent)

# A bundled example PMC XML file
xml <- system.file("extdata", "PMID32171256-PMC7071725.xml", package = "rtransparent")

# COI, funding, registration, novelty and replication in one pass
rt_all_pmc(xml, remove_ns = TRUE)

# Data and code sharing
rt_data_code_pmc(xml, remove_ns = TRUE)

# Article metadata
rt_meta_pmc(xml, remove_ns = TRUE)
```

Naming convention: functions that operate on TXT files do not end in `_pmc`;
functions that operate on PMC XML end in `_pmc`. The best way to learn the
package is the vignette: `vignette("rtransparent")`.

## Summarizing a corpus

The detectors describe one article at a time. To study a whole corpus, stack
the per-article rows and summarize them:

```r
# results: one row per article (e.g. purrr::map_dfr(files, rt_all_pmc))
data(rt_demo)            # a small simulated example shipped with the package

rt_summary(rt_demo)      # prevalence of each indicator, with a confidence
                         # interval and a sensitivity/specificity-corrected
                         # (Rogan-Gladen) prevalence

rt_score(rt_demo)        # add a per-article count of openness practices met

rt_plot(rt_demo)                              # prevalence bar chart
rt_plot(rt_demo, type = "trend", year = "year")  # prevalence over time
```

The accuracy correction uses the bundled `rt_accuracy` table (detector
sensitivity and specificity estimates), which you can override. See
`vignette("transparency-summary")` for a full walk-through.

## Validation

Benchmarked against the human-labeled XML benchmark of Serghiou et al. (2021)
(reproducible under `data-raw/benchmark/`, results in `inst/benchmark/`):

| Indicator | Accuracy | Sensitivity | Specificity |
|---|---|---|---|
| Conflicts of interest | 96.7% | 94.0% | 100% |
| Funding | 97.3% | 100% | 95.7% |
| Protocol registration | 98.1% | 99.2% | 96.9% |
| Data sharing | 84.3% | 71.3% | 99.0% |
| Code sharing | 94.1% | 83.5% | 99.5% |

The native code detector exceeds the paper's reported sensitivity and the data
detector's specificity remains high. The native **data sensitivity (71%) is
still below `oddpub`'s ~84%** on this set, on a tail of supplement-only data,
reused public-source statements and rare phrasings; treat the native data
detector as high-precision but not yet a complete sensitivity replacement. The
data/code values are reproducible benchmark and regression estimates for the native
detector, not untouched external validation estimates.

## Getting help

Please file bugs or questions as issues at
<https://github.com/choxos/rtransparent/issues> with a minimal reproducible
example.

</div>
