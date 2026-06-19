# rtransparency

<div align="justify">

## Overview

`rtransparency` is an R package that automatically identifies and extracts
**indicators of transparency** from the full text of published biomedical
articles, in both plain-text (PDF-derived) and PubMed Central XML form. For each
indicator it returns whether the indicator was found and, when found, the
statement that triggered the detection, so the output is auditable.

It detects eight indicators:

- **Conflicts of interest** (`rt_coi`, `rt_coi_pmc`)
- **Funding** (`rt_fund`, `rt_fund_pmc`)
- **Protocol registration** (`rt_register`, `rt_register_pmc`)
- **Novelty** claims (`rt_novelty`, `rt_novelty_pmc`)
- **Replication** / external validation (`rt_replication`, `rt_replication_pmc`)
- **Data sharing** and **code sharing** (`rt_data_code`, `rt_data_code_pmc`)
- **AI disclosure** (`rt_ai_pmc`): disclosure of generative-AI use in writing the
  manuscript, evaluated only for articles published in 2023 or later

`rt_all_pmc()` runs all eight indicators on one PMC XML file; `rt_all()` does the
same for a plain-text file; `rt_all_pmc_dir()` processes a whole directory
(resumable, optionally parallel). Conflict-of-interest and funding statements are
also detected in Spanish, Portuguese, French, German and Italian.

Detection is rule-based and interpretable (curated regular expressions over the
relevant article sections), so the output is auditable and reproducible. See the
vignettes for the methodology and the package website at
<https://choxos.github.io/rtransparency/> for full documentation.

## Authors and lineage

This package builds on the original **`rtransparent`** tool of Stylianos
(Stelios) Serghiou. It is an enhanced, renamed fork maintained by Ahmad
Sofi-Mahmudi ([ORCID 0000-0001-6829-0823](https://orcid.org/0000-0001-6829-0823),
GitHub [@choxos](https://github.com/choxos)), with four added indicators
(novelty, replication, AI disclosure, and a natively re-implemented data/code
detector), multilingual conflict-of-interest and funding detection, plain-text
parity, and corpus-scale batch processing. Serghiou is credited as an author;
please cite the foundational paper below.

## Publication

The original `rtransparent` was validated and used to measure transparency across
the open-access literature in PubMed Central: Serghiou et al., *Assessment of
transparency indicators across the biomedical literature: How open is open?*
PLOS Biology, 2021,
[doi:10.1371/journal.pbio.3001107](https://doi.org/10.1371/journal.pbio.3001107).
Run `citation("rtransparency")` for the package and paper references.

## Installation

```r
# install.packages("remotes")
remotes::install_github("choxos/rtransparency", build_vignettes = TRUE)
```

No GitHub-only or AGPL dependencies are required; data and code detection is
native. `rt_read_pdf()` (PDF to text) additionally needs the poppler
`pdftotext` utility on your system.

## Usage

```r
library(rtransparency)

# A bundled example PMC XML file
xml <- system.file("extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency")

# All eight indicators in one pass
rt_all_pmc(xml, remove_ns = TRUE)

# A whole directory (resumable; optionally parallel via furrr + future)
# rt_all_pmc_dir("path/to/xml", remove_ns = TRUE, output = "results.csv")
```

The best way to learn the package is the introduction vignette,
`vignette("rtransparency")`, and the scope-and-limitations vignette.

## Summarizing a corpus

```r
data(rt_demo)            # a small simulated example shipped with the package

rt_summary(rt_demo)      # prevalence of each indicator, with a confidence
                         # interval and a sensitivity/specificity-corrected
                         # (Rogan-Gladen) prevalence
rt_score(rt_demo)        # add a per-article count of openness practices met
rt_plot(rt_demo)         # prevalence bar chart
```

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

The newer indicators (novelty, replication, AI disclosure) and the multilingual
detectors are validated against maintainer-built, hand-labeled benchmarks in
`inst/benchmark/`, including a 1000-article 2023 open-access sample and a
replication-enriched validation.

## Getting help

Please file bugs or questions as issues at
<https://github.com/choxos/rtransparency/issues> with a minimal reproducible
example.

</div>
