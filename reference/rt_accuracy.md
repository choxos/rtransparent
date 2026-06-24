# Detector accuracy estimates

Sensitivity and specificity estimates for each transparency detector,
used by \[rt_summary()\] to correct an apparent prevalence for detector
error (the Rogan-Gladen correction).

## Usage

``` r
rt_accuracy
```

## Format

A tibble with 9 rows and 5 columns:

- variable:

  Indicator column name, as returned by \[rt_all_pmc()\].

- label:

  Human-readable indicator name.

- sensitivity:

  Detector sensitivity (true-positive rate), 0-1.

- specificity:

  Detector specificity (true-negative rate), 0-1.

- source:

  Where the estimate comes from.

## Source

Serghiou S, Contopoulos-Ioannidis DG, Boyack KW, Riedel N, Wallach JD,
Ioannidis JPA (2021). Assessment of transparency indicators across the
biomedical literature: How open is open? *PLOS Biology* 19(3): e3001107.
[doi:10.1371/journal.pbio.3001107](https://doi.org/10.1371/journal.pbio.3001107)
. Data and code values: this package's reproducible benchmark and
regression estimates (\`inst/benchmark/results_data_code.md\`).

## Details

For conflicts of interest, funding and protocol registration these are
the published, importance-weighted validation values of Serghiou et al.
(2021); the detectors for these indicators are essentially those
validated in the paper. For data and code sharing the detector is
implemented natively in this package (it no longer wraps \`oddpub\`), so
the package's reproducible benchmark and regression estimates are used
instead (see \`inst/benchmark\`). These data/code estimates are not an
untouched external validation of the native detector; supply your own
values to \[rt_summary()\] via its \`accuracy\` argument when you have
study-specific or externally validated estimates. Novelty's estimate
comes from a maintainer-built hand-labeled gold set (see
\`inst/benchmark/results_novelty_replication.md\`). Replication's
sensitivity comes from a 111-positive replication-enriched validation
(see \`inst/benchmark/results_replication_enriched.md\`), with the
specificity from the 2023 1000-article sample. AI-use disclosure is not
included (its prevalence is too low in unselected literature for a
stable estimate), so \[rt_summary()\] reports it uncorrected.

## See also

\[rt_summary()\]
