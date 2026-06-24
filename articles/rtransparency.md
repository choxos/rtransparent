# Introduction to rtransparency

``` r

library(rtransparency)
```

## Overview

`rtransparency` identifies and extracts **indicators of transparency**
from the full text of published biomedical articles. It works on two
inputs: plain TXT files (typically converted from PDFs) and PMC XML
files (the JATS XML served by PubMed Central). For each indicator it
returns whether the indicator was found and, when found, the sentence or
statement that triggered the detection.

| Indicator | What it captures | TXT | PMC XML |
|----|----|:--:|:--:|
| Conflicts of interest | A COI / competing-interests disclosure | `rt_coi` | `rt_coi_pmc` |
| Funding | A funding / financial-support statement | `rt_fund` | `rt_fund_pmc` |
| Protocol registration | Registration on a trial / review registry | `rt_register` | `rt_register_pmc` |
| Novelty | Claims of novelty (“for the first time”) | `rt_novelty` | `rt_novelty_pmc` |
| Replication | Replication / independent-validation components | `rt_replication` | `rt_replication_pmc` |
| Data sharing | Data deposited or made openly available | `rt_data_code` | `rt_data_code_pmc` |
| Code sharing | Source code / scripts made available | `rt_data_code` | `rt_data_code_pmc` |
| AI-use disclosure | A statement that generative AI was (or was not) used to prepare the manuscript | `rt_ai` | `rt_ai_pmc` |
| Open-access license | Whether the article is openly licensed, and which license | `rt_oa` | `rt_oa_pmc` |
| Reporting guideline | Whether a reporting guideline was followed, and which one | `rt_reporting` | `rt_reporting_pmc` |

`rt_all_pmc` runs all ten detectors together in a single pass: COI,
funding, registration, novelty, replication, data sharing, code sharing,
AI-use disclosure, open-access licensing and reporting-guideline use.
(`rt_all` covers the first five from TXT; the others also have
standalone TXT detectors, such as `rt_data_code`, `rt_ai`, `rt_oa` and
`rt_reporting`, but are not part of the `rt_all` wrapper.)

AI-use disclosure is the newest indicator. Journals have asked authors
to disclose any use of generative AI (ChatGPT and similar) in preparing
a manuscript only since 2023, so `rt_ai_pmc` evaluates the indicator
only for articles published in 2023 or later and returns `NA` for
earlier ones.

The package and its validation are described in Serghiou et al.,
*Assessment of transparency indicators across the biomedical literature:
How open is open?* (PLOS Biology, 2021,
<doi:10.1371/journal.pbio.3001107>).

## How detection works

### Article parsing

PMC XML is parsed with `xml2`. The XML root is standardized to the
`<article>` node (the package accepts the OAI-PMH, EFetch
`<pmc-articleset>` and bare `<article>` shapes), the namespace is
optionally stripped (`remove_ns = TRUE`), and the text is split into the
sections where each indicator usually appears: acknowledgments,
footnotes / author notes, the body, the methods, the abstract and
supplementary material. TXT files are read whole and split into
paragraphs.

### Rule-based detection

Detection is **rule-based and interpretable**: each indicator is a
curated set of regular expressions applied to the relevant sections,
rather than a machine learning model. This keeps the output auditable
(the matched statement is returned) and reproducible.

- **Conflicts of interest.** Detected from structured COI footnotes
  (`fn-type = "conflict"`), from section titles (“Conflicts of
  interest”, “Competing interests”, “Declaration of interest”, “Duality
  of interest”), and from a set of text patterns covering financial
  relationships, consulting, fees, board membership, patents and
  explicit “no competing interests” declarations. Honoraria-to-subjects
  and reference text are masked to reduce false positives.
- **Funding.** Detected from the XML `<funding-group>` element, from
  funding section titles, and from text patterns such as “supported by”,
  “funded by”, “grant from / number”, named funders and award types.
  Acknowledged funding is required to use explicit funding language (a
  funding verb tied to a funder), so a bare mention of an institution or
  the word “support” is not enough. No-funding declarations are
  excluded.
- **Protocol registration.** Detected from registry identifiers
  (ClinicalTrials.gov `NCT`, PROSPERO `CRD`, ISRCTN, ANZCTR `ACTRN`,
  DRKS, IRCT, UMIN, ChiCTR) and from registration phrasing in the
  methods or footnotes.
- **Novelty and replication.** Detected from claim patterns such as “for
  the first time”, “to our knowledge”, “novel finding” (novelty) and
  “replicate”, “independently validated”, “confirmatory cohort”
  (replication), with negation filters (“failed to replicate”).
- **Data and code sharing.** Detected by a native detector
  (`.detect_data_code`) built from public repository facts and curated
  benchmark statements: field-specific accession schemes (GEO `GSE`, SRA
  / BioProject `PRJNA`, PDB, ArrayExpress, dbGaP, ProteomeXchange, Dryad
  / Zenodo / figshare DOIs, …), repository URLs and names, deposit /
  availability / data-availability-statement language, and supplement
  and file-format signals. Crucially it distinguishes **sharing** (“data
  were deposited in GEO”) from **reuse** (“data were downloaded from
  GEO”) and excludes “available on request”. Code repositories (GitHub,
  GitLab, Bitbucket) only count as data when paired with a data noun, so
  a code-only GitHub link is not mistaken for data sharing.
- **AI-use disclosure.** Detected from a “Declaration of generative AI”
  type section title, and from text that names a generative-AI tool
  (ChatGPT, GPT-4, Copilot, Gemini, an LLM, …) in a
  manuscript-preparation context (“used ChatGPT to improve the
  readability”) or in an explicit negation (“no generative AI was
  used”). A negative lookahead keeps the tool sense of “large language
  model” out of the writing-object pattern, and AI used purely as a
  research method (not for writing) is not counted. Only evaluated for
  2023 onward.
- **Open-access licensing.** Read from the JATS `<license>` element and
  its license-reference URL, and classified to a canonical identifier
  (`CC-BY-4.0`, `CC-BY-NC-ND-4.0`, `CC0-1.0`, …). A Creative Commons or
  CC0 license (or an explicit open-access declaration) sets
  `is_open_access`; a CC0 data-waiver is not mistaken for the article
  license. This is the reuse (“R”) dimension of FAIR and feeds the
  [`rfair`](https://github.com/choxos/rfair) assessment.
- **Reporting-guideline use.** Detected when authors state they followed
  a reporting guideline (the EQUATOR checklists: CONSORT, PRISMA and its
  extensions, STROBE, ARRIVE, STARD, TRIPOD, COREQ, SQUIRE, CHEERS,
  CARE, and the wider reportilo list), returning which one. Detection is
  precision-first: a guideline counts only in a reporting context;
  common-word acronyms (ARRIVE, CARE, RECORD, …) require the upper-case
  form beside a guideline noun; and animal-welfare (“Care and Use of
  Laboratory Animals”), clinical-practice and non-adherence mentions are
  excluded.

### Languages

Conflict-of-interest and funding statements are detected not only in
English but also in **Spanish, Portuguese, French, German and Italian**,
using language-distinctive patterns matched on transliterated
(accent-stripped) text. The German conflict-of-interest detection rate,
for example, rose from 33% to 97% once these were added. The other
indicators are English-only for now.

## Usage: PMC XML

The package ships an example PMC XML file. We use it below; replace the
path with your own file to analyze a different article.

``` r

xml_path <- system.file(
  "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency"
)
```

### All indicators at once

`rt_all_pmc` returns all ten indicators in one call, together with the
matched statement text, the publication `year` and article metadata.

``` r

all_indicators <- rt_all_pmc(xml_path, remove_ns = TRUE)

dplyr::glimpse(
  all_indicators[, c("pmid", "year", "is_coi_pred", "is_fund_pred",
                     "is_register_pred", "is_novelty_pred", "is_replication_pred",
                     "is_open_data", "is_open_code", "is_ai_pred",
                     "is_open_access", "is_reporting_pred")]
)
#> Rows: 1
#> Columns: 12
#> $ pmid                <chr> "32171256"
#> $ year                <int> 2020
#> $ is_coi_pred         <lgl> TRUE
#> $ is_fund_pred        <lgl> FALSE
#> $ is_register_pred    <lgl> FALSE
#> $ is_novelty_pred     <lgl> FALSE
#> $ is_replication_pred <lgl> FALSE
#> $ is_open_data        <lgl> TRUE
#> $ is_open_code        <lgl> FALSE
#> $ is_ai_pred          <lgl> NA
#> $ is_open_access      <lgl> TRUE
#> $ is_reporting_pred   <lgl> FALSE
```

`is_ai_pred` is `NA` here because this example article predates 2023;
for a 2023 or later article it would be `TRUE` or `FALSE`.

### Individual indicators

``` r

coi <- rt_coi_pmc(xml_path, remove_ns = TRUE)
c(is_coi = coi$is_coi_pred, text = substr(coi$coi_text, 1, 120))
#>                                                                                                                     is_coi 
#>                                                                                                                     "TRUE" 
#>                                                                                                                       text 
#> "Competing interests In the past 36 months, J.D.W. received research support through the Collaboration for Research Integ"
```

``` r

fund <- rt_fund_pmc(xml_path, remove_ns = TRUE)
c(is_fund = fund$is_fund_pred, text = substr(fund$fund_text, 1, 120))
#> is_fund    text 
#> "FALSE"      ""
```

``` r

register <- rt_register_pmc(xml_path, remove_ns = TRUE)
register$is_register_pred
#> [1] FALSE
```

### Data and code sharing

`rt_all_pmc` already reports `is_open_data` and `is_open_code`;
`rt_data_code_pmc` is the focused view that also returns the matched
statements. Detection is native and needs no external packages.

``` r

data_code <- rt_data_code_pmc(xml_path, remove_ns = TRUE)

dplyr::glimpse(
  data_code[, c("is_open_data", "open_data_statements",
                "is_open_code", "open_code_statements")]
)
#> Rows: 1
#> Columns: 4
#> $ is_open_data         <lgl> TRUE
#> $ open_data_statements <chr> "Availability of data and materialsData will be s…
#> $ is_open_code         <lgl> FALSE
#> $ open_code_statements <chr> ""
```

`rt_all_pmc` and `rt_data_code_pmc` also return `open_data_links` and
`open_code_links`: the repository and accession URLs extracted from the
statements, ready to pass to FAIR-assessment tooling such as
[`rfair`](https://github.com/choxos/rfair). Article metadata (title,
journal, identifiers, dates) is available separately via `rt_meta_pmc`.

``` r

meta <- rt_meta_pmc(xml_path, remove_ns = TRUE)
dplyr::glimpse(meta[, c("pmid", "doi")])
#> Rows: 1
#> Columns: 2
#> $ pmid <chr> "32171256"
#> $ doi  <chr> "10.1186/s12874-020-0914-6"
```

### AI-use disclosure

`rt_ai_pmc` reports the publication `year`, the year-gated prediction
`is_ai_pred` (`NA` before 2023) and the matched text. The
`ai-disclosure` vignette covers this indicator in depth.

``` r

ai <- rt_ai_pmc(xml_path, remove_ns = TRUE)
c(year = ai$year, is_ai = ai$is_ai_pred)
#>  year is_ai 
#>  2020    NA
```

## Usage: TXT files

To analyze a PDF, first convert it to TXT with `rt_read_pdf` (this needs
the poppler `pdftotext` utility installed), then run the TXT detectors.
The chunks below are illustrative and are not executed when the vignette
is built.

``` r

pdf_path <- system.file(
  "extdata", "PMID32171256-PMC7071725.pdf", package = "rtransparency"
)
article <- rt_read_pdf(pdf_path)
writeLines(article, "article.txt")

rt_coi("article.txt")
rt_fund("article.txt")
rt_register("article.txt")
rt_data_code("article.txt")
rt_ai("article.txt")    # generative-AI-use disclosure
rt_all("article.txt")   # COI, funding, registration, novelty, replication
```

`rt_ai` is the plain-text counterpart of `rt_ai_pmc`. A text file
carries no reliable publication date, so `rt_ai` applies no 2023 year
gate (`is_ai_pred` is always `TRUE` or `FALSE`, never `NA`) and cannot
confine the scan to back-matter sections the way the XML detector does.
Restrict it to articles published in 2023 or later, and expect a
slightly higher false-positive rate on papers that use AI as a research
method.

## Processing many articles

[`rt_all_pmc_dir()`](https://choxos.github.io/rtransparency/reference/rt_all_pmc_dir.md)
runs all ten indicators over an entire directory (or a vector of file
paths) in one call, designed for corpus-scale analysis.

``` r

# Sequential, in memory
res <- rt_all_pmc_dir("path/to/xml", remove_ns = TRUE)

# Resumable and parallel: results are written to a CSV in chunks, a re-run skips
# files already recorded, and a malformed file yields an is_success = FALSE row
# instead of aborting the run.
future::plan("multisession")
res <- rt_all_pmc_dir(
  "path/to/xml", remove_ns = TRUE, output = "results.csv", parallel = TRUE
)
```

## Summarizing a corpus

With one row per article,
[`rt_summary()`](https://choxos.github.io/rtransparency/reference/rt_summary.md)
reports per-indicator prevalence with a Wilson confidence interval and a
sensitivity/specificity-corrected (Rogan-Gladen) prevalence;
[`rt_score()`](https://choxos.github.io/rtransparency/reference/rt_score.md)
adds a per-article count of openness practices; and
[`rt_plot()`](https://choxos.github.io/rtransparency/reference/rt_plot.md)
draws prevalence bars and yearly trends. The `transparency-summary`
vignette covers this in depth.

``` r

data(rt_demo)            # a small simulated example shipped with the package
rt_summary(rt_demo)[, c("indicator", "percent", "adj_percent")]
#> # A tibble: 8 × 3
#>   indicator           percent adj_percent
#>   <chr>                 <dbl>       <dbl>
#> 1 is_coi_pred           70.4        70.8 
#> 2 is_fund_pred          79.6        79.4 
#> 3 is_register_pred      29.7        30.8 
#> 4 is_open_data          20.4        25.7 
#> 5 is_open_code           8.5         9.13
#> 6 is_novelty_pred       54.4        62.8 
#> 7 is_replication_pred    9.42        8.67
#> 8 is_ai_pred            25.2        NA
```

## Downloading PMC XML

PMC full-text XML can be downloaded by PMCID. The package exposes
nothing for this, but the `europepmc` (CRAN) or `metareadr` packages
work well; the following is illustrative.

``` r

# europepmc::epmc_ftxt("PMC7071725")            # returns the XML document
# metareadr::mt_read_pmcoa("7071725", "article.xml")
```

## Validation

The detectors were benchmarked against the human-labeled XML benchmark
of Serghiou et al. (2021). The current package reaches roughly: COI 97%
accuracy, funding 97%, protocol registration 98%. The native data/code
detector reaches code 88% sensitivity / 99% specificity and data 77%
sensitivity / 99% specificity (see `inst/benchmark/` and
`data-raw/benchmark/` in the source repository for the reproducible
benchmark). The native data/code values are reproducible benchmark and
regression estimates, not untouched external-validation estimates.

## Naming convention and dependencies

Functions that operate on TXT files do not end in `_pmc`; functions that
operate on PMC XML end in `_pmc`. Data and code detection is implemented
natively and no longer requires the `oddpub` or `tokenizers` packages.
