# rtransparent enhancement roadmap

Living plan for improving the package. Update it as items ship.

## Principles
- Improve accuracy iteratively, **one PR per improvement**, merged to `master`.
- **Measure every detection change** against the benchmark before and after
  (`Rscript data-raw/benchmark/run_all.R`); merge only if metrics improve and
  sensitivity does not regress. Accuracy over coverage.
- Keep the name `rtransparent` for now (revisit a rename at release).
- Be self-contained: reimplement oddpub's data/code detection natively (GPL-3),
  do not vendor oddpub (it is AGPL-3).
- Fetch article XML from **NCBI PubMed Central** (EFetch + OAI, `R/rt_fetch.R`),
  not Europe PMC (different corpus, incompatible JATS flavor).

## Done (merged)
- **#1** v0.3.0 baseline: novelty/replication detectors, registry expansion
  (ISRCTN/ANZCTR/DRKS/IRCT/UMIN), testthat suite.
- **#2** oddpub/tokenizers made optional (Suggests + guards); NCBI PMC fetch
  helper `R/rt_fetch.R`.
- **#3** accuracy benchmark (`R/benchmark.R`, `data-raw/benchmark/`,
  `inst/benchmark/`); fixed `.reroot_xml` (returned empty for non-OAI XML) and
  unqualified `str_detect` in the funding detector.
- **#4** funding specificity 78% → 96% by tightening `get_fund_acknow_new`.

## Current benchmark baseline (held-out XML test set)
| Indicator | Accuracy | Sensitivity | Specificity |
|---|---|---|---|
| COI | 96.7% | 94.0% | 100% |
| Funding | 97.3% | 100% | 95.7% |
| Registration | 98.1% | 99.2% | 96.9% |

## Next (priority order)

### A. Port quest-bih fork fixes  [done / assessed]
`quest-bih/rtransparent` is ahead 7 commits of `serghiou`.
- **prospero detection fix** — ported (PROSPERO id now 5 to 11 digits, TXT + PMC).
  No benchmark delta (the held-out set has no PROSPERO-only cases).
- **coi update** (TXT `rt_coi`, 75 lines) — deferred: TXT path, not exercised by
  the PMC benchmark; revisit if a TXT benchmark is added.
- **register pipe update** (808 + 686 line reformat of register/xml_utils/utils)
  — skipped: cosmetic, conflicts heavily with this line's divergence.
- "harmonize with new oddpub" — moot once we reimplement data/code (item B).

### B. Reimplement oddpub data/code detection natively (GPL-3)
Clean-room implementation: repository names (GitHub/Zenodo/OSF/Dryad/figshare),
accession-ID patterns (GEO/SRA/PDB/ArrayExpress/...), and data/code
availability-statement language; reuse `.create_synonyms`/`.encase`/`.bound`.
Wire into `rt_data_code`/`rt_data_code_pmc`, remove the dependency guards, drop
`oddpub` + `tokenizers` from `Suggests`. Validate against `data_true/false.xlsx`
(`isData`) and `code_true.xlsx` (`isCode`); extend the benchmark to 5 indicators.

### C. Fix the public `rt_fund_pmc`
The exported `rt_fund_pmc` is broken: it predicts TRUE for essentially all input
with empty text. `rt_all_pmc` does not use it (it uses internal `.get_fund_pmc`
+ `.rt_fund_pmc`). Align the public function with the working internal path, and
add a test so the public API is correct.

### D. Benchmark fidelity v2 (optional)
Add the paper's importance-sampling weights (`est_freq = n / n_s * n_t`) to
`.eval_boot` for exact Fig 2 comparability, and the `isResearch`/`isExplicit`
filters the paper applied per indicator.

## Backlog (low priority / data-limited)
- **COI sensitivity (94%) is data-limited, not a detector defect.** All 5
  held-out false negatives have no COI statement anywhere in the XML (the COI is
  on PubMed/PDF only; the paper's documented limitation). The detector catches
  100% of COI that is actually in the XML. Recovering these needs a PubMed
  `CoiStatement` lookup (a feature, not a detector fix).
- **Funding residual false positives (5/116 negatives).** 3 are a
  `<funding-statement>` naming only an institution (definitional, risk false
  negatives if "fixed"); 1 is "Financial source: none" (negation reaches the
  prediction through a path the current negation steps miss); 1 is an
  author-contributions leak. Low value; defer.
- **CRAN-readiness pass** (Rd/examples/vignette deps, `R CMD check`) before any
  release; decide a possible rename (`rtransparentplus`?) at that point.

## Running the benchmark
```sh
Rscript data-raw/benchmark/run_all.R        # full labeled test set (~550 articles)
Rscript data-raw/benchmark/run_all.R 30     # quick smoke run
Rscript data-raw/benchmark/make_fixtures.R  # rebuild the regression-test fixtures
```
Set `ENTREZ_KEY` to raise the NCBI rate limit. Outputs:
`inst/benchmark/results.{csv,md}`. Cache (git-ignored):
`data-raw/benchmark/.cache/`. The labeled gold data lives under `paper/`
(git-ignored, from the study's OSF repository).
