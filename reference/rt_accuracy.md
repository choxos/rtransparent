# Validated detector accuracy

Sensitivity and specificity of each transparency detector, used by
\[rt_summary()\] to correct an apparent prevalence for detector error
(the Rogan-Gladen correction).

## Usage

``` r
rt_accuracy
```

## Format

A tibble with 5 rows and 5 columns:

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
. Data and code values: this package's held-out validation
(\`inst/benchmark/results_data_code.md\`).

## Details

For conflicts of interest, funding and protocol registration these are
the published, importance-weighted validation values of Serghiou et al.
(2021); the detectors for these indicators are essentially those
validated in the paper. For data and code sharing the detector is
implemented natively in this package (it no longer wraps \`oddpub\`), so
the package's own held-out validation estimates are used instead (see
\`inst/benchmark\`). Supply your own values to \[rt_summary()\] via its
\`accuracy\` argument to override these.

## See also

\[rt_summary()\]
