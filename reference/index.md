# Package index

## Run all detectors

Detect every indicator in one pass.

- [`rt_all()`](https://choxos.github.io/rtransparent/reference/rt_all.md)
  : Identify and extract statements of COI, Funding and Registration.
- [`rt_all_pmc()`](https://choxos.github.io/rtransparent/reference/rt_all_pmc.md)
  : Identify and extract statements of COI, Funding and Registration.

## Individual indicators (PMC XML)

One detector per indicator, for PMC JATS XML files.

- [`rt_coi_pmc()`](https://choxos.github.io/rtransparent/reference/rt_coi_pmc.md)
  : Identify and extract Conflicts of Interest (COI) statements in PMC
  XML files.
- [`rt_fund_pmc()`](https://choxos.github.io/rtransparent/reference/rt_fund_pmc.md)
  : Identify and extract Funding statements in PMC XML files.
- [`rt_register_pmc()`](https://choxos.github.io/rtransparent/reference/rt_register_pmc.md)
  : Identify and extract Conflicts of Interest statements in PMC XML
  files.
- [`rt_novelty_pmc()`](https://choxos.github.io/rtransparent/reference/rt_novelty_pmc.md)
  : Identify and extract novelty claims in PMC XML files.
- [`rt_replication_pmc()`](https://choxos.github.io/rtransparent/reference/rt_replication_pmc.md)
  : Identify and extract replication components in PMC XML files.
- [`rt_data_code_pmc()`](https://choxos.github.io/rtransparent/reference/rt_data_code_pmc.md)
  : Identify and extract Data and Code sharing from PMC XML files.
- [`rt_data_code_pmc_list()`](https://choxos.github.io/rtransparent/reference/rt_data_code_pmc_list.md)
  : Identify and extract Data and Code sharing from a list of PMC XML
  files.

## Individual indicators (text)

One detector per indicator, for plain-text (PDF-derived) files.

- [`rt_coi()`](https://choxos.github.io/rtransparent/reference/rt_coi.md)
  : Identify and extract Conflicts of Interest (COI) statements in TXT
  files.
- [`rt_fund()`](https://choxos.github.io/rtransparent/reference/rt_fund.md)
  : Identify and extract Funding statements in TXT files.
- [`rt_register()`](https://choxos.github.io/rtransparent/reference/rt_register.md)
  : Identify and extract Registration statements in TXT files.
- [`rt_novelty()`](https://choxos.github.io/rtransparent/reference/rt_novelty.md)
  : Identify whether a study claims novelty in TXT files.
- [`rt_replication()`](https://choxos.github.io/rtransparent/reference/rt_replication.md)
  : Identify whether a study includes a replication component in TXT
  files.
- [`rt_data_code()`](https://choxos.github.io/rtransparent/reference/rt_data_code.md)
  : Identify and extract Data and Code statements in TXT files.

## Metadata and input

Article metadata and PDF-to-text conversion.

- [`rt_meta_pmc()`](https://choxos.github.io/rtransparent/reference/rt_meta_pmc.md)
  : Extract article metadata from a PMC XML file.
- [`rt_read_pdf()`](https://choxos.github.io/rtransparent/reference/rt_read_pdf.md)
  : Covert PDF files into TXT files.

## Summarize and visualize

Corpus-level prevalence, per-article scores and plots.

- [`rt_summary()`](https://choxos.github.io/rtransparent/reference/rt_summary.md)
  : Summarize transparency indicators across a corpus of articles
- [`rt_score()`](https://choxos.github.io/rtransparent/reference/rt_score.md)
  : Count the transparency indicators met by each article
- [`rt_plot()`](https://choxos.github.io/rtransparent/reference/rt_plot.md)
  : Plot transparency indicators

## Datasets

- [`rt_accuracy`](https://choxos.github.io/rtransparent/reference/rt_accuracy.md)
  : Validated detector accuracy
- [`rt_demo`](https://choxos.github.io/rtransparent/reference/rt_demo.md)
  : Simulated transparency indicators for a corpus of articles
