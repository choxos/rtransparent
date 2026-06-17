# Accuracy benchmark

Measures the current detectors against the human-labeled gold standard of
Serghiou et al. (2021, PLOS Biology, doi:10.1371/journal.pbio.3001107), so that
every detection change can be checked for regressions rather than guessed at.

## What it does

For the COI, funding, and registration indicators:

1. Reads the validation spreadsheets under
   `paper/osf_data/3_algorithm-validation/data/tidy_data/` (the `*_true.xlsx` /
   `*_false.xlsx` pairs). Human labels are present only on the held-out test
   rows (`is_test == TRUE`); we additionally keep the articles available as XML
   (`is_xml == TRUE`).
2. Fetches each article's **NCBI PubMed Central** full-text JATS XML by PMCID
   (parsed from the `article` field) via `.fetch_pmc_xml()`: EFetch primary,
   PMC OAI-PMH fallback. Downloads are cached under `.cache/` (git-ignored).
3. Runs `rt_all_pmc()` on each article and compares the predictions
   (`is_coi_pred`, `is_fund_pred`, `is_register_pred`) to the human labels
   (`isCOI`, `isFunding`, `is_register`).
4. Computes sensitivity, specificity, PPV, NPV, accuracy and prevalence with a
   stratified bootstrap (2000 resamples), and writes `inst/benchmark/results.csv`
   and `inst/benchmark/results.md` alongside the published Fig 2 numbers.

## Running

From the repo root, with the `readxl` package installed and network access to
NCBI (set `ENTREZ_KEY` to raise the rate limit):

```sh
Rscript data-raw/benchmark/run_all.R        # full labeled test set (~550 articles)
Rscript data-raw/benchmark/run_all.R 30     # quick 30-article smoke run
```

`gen_reference.R` regenerates `inst/benchmark/reference_fig2.csv` from the
paper's serialized outputs (run once; the CSV is committed).

## v1 simplifications

* **Unweighted bootstrap.** The paper reweights each sampling stratum back to
  the population (importance sampling: `est_freq = n / n_s * n_t`). v1 resamples
  within the true/false strata but does not apply those weights, so it reports
  unweighted held-out-test metrics. Rates are comparable to Fig 2; absolute
  counts are not. To add weighting later, multiply each confusion cell by the
  stratum's `n_t / n_s` before summing.
* **Filter.** Evaluated on `is_test & is_xml` rows. The paper applied additional
  `isResearch` / `isExplicit` filters for some variants, so treat Fig 2 as
  context, not a pass/fail gate. The regression gate is the committed
  `results.csv` baseline plus the fixture test in
  `tests/testthat/test-benchmark.R`.
* **Coverage.** Articles that fail to fetch or parse are dropped and counted;
  `results.md` reports `n_eval / n_eligible` so a low fetch rate cannot be
  mistaken for high accuracy.
* **Data and code** indicators are benchmarked separately by `run_data_code.R`
  (results in `inst/benchmark/results_data_code.{csv,md}`); their detection is
  now native (`R/data_code.R`) and needs no `oddpub`. These data/code values
  are reproducible benchmark and regression metrics for the native detector, not
  untouched external-validation estimates.
