<div align="justify">

# rtransparent 0.9.8

The plain-text detectors now share the PMC detection logic.

* **TXT/PMC parity.** `rt_coi()`, `rt_fund()` and `rt_register()` route their text
  through the same detection helpers as `rt_coi_pmc()`, `rt_fund_pmc()` and
  `rt_register_pmc()`, replacing separate and weaker text logic. (`rt_novelty()`
  and `rt_replication()` already shared their helpers.) Measured on text
  extracted from the 1000-article 2023 validation set (sensitivity /
  specificity): registration 46.2 / 98.7 to 90.4 / 98.4, conflicts of interest
  88.8 / 86.3 to 88.6 / 90.4, funding 79.1 / 89.5 to 79.3 / 90.5. The remaining
  gap to the PMC detectors is the XML-structural routes (tagged funding groups,
  footnote types, section titles) that a plain-text file does not carry.

* **New TXT-parity benchmark** (`data-raw/benchmark/build_txt_parity.R`,
  `inst/benchmark/results_txt_parity.{csv,md}`) measures the TXT detectors
  against the same hand labels as the PMC benchmark.

* The PMC detectors, the held-out Serghiou et al. (2021) benchmarks and the
  novelty/replication gold set are unchanged; only the TXT entry points changed.

# rtransparent 0.9.7

Corpus-scale batch processing.

* **New `rt_all_pmc_dir()`.** Processes every PMC XML in a directory (or a
  vector of paths) through `rt_all_pmc()` in a single call. The run is resumable
  (with `output`, results are written to a CSV in chunks and a re-run skips
  files already recorded), isolates per-file failures (a malformed file yields
  an `is_success = FALSE` row instead of aborting the run), shows a progress
  bar, and can run in parallel via the optional `furrr` package and an active
  `future::plan()`.

* `furrr` and `future` are added to Suggests; they are used only for
  `rt_all_pmc_dir(parallel = TRUE)`.

# rtransparent 0.9.6

The hand-labeled 2023 validation sample reaches 1000 articles.

* **Validation sample reaches 1000.** The final twenty open-access PMC articles
  were hand-labeled for all eight indicators and added to the committed sample,
  bringing it to a round 1000. Metrics (sensitivity / specificity): conflicts of
  interest 100 / 91.8, funding 94.8 / 95.3, registration 84.6 / 99.2, novelty
  90.2 / 93.3, replication 82.4 / 98.5, data 91.1 / 97.8, code 93.9 / 99.0,
  AI 100 / 100.

* **Funding.** The Portuguese no-funding declaration "os autores nao reportam
  qualquer financiamento" ("the authors report no funding") is now read as
  absence of funding.

* The held-out Serghiou et al. (2021) benchmarks and the novelty/replication
  gold set are unchanged.

# rtransparent 0.9.5

The hand-labeled 2023 validation sample is expanded to 980 articles (265 new),
with a focused improvement to replication precision and a further funding fix.

* **Validation sample grows to 980.** Eighteen new batches (265 articles) were
  hand-labeled for all eight indicators and folded into the committed sample.
  Current metrics (sensitivity / specificity): conflicts of interest 100 / 91.7,
  funding 94.8 / 95.2, registration 84.6 / 99.2, novelty 90.1 / 93.4, replication
  81.2 / 98.5, data 90.8 / 97.8, code 93.8 / 98.9, AI 100 / 100.

* **Replication precision.** The replication detector previously fired on several
  non-replication contexts. It now suppresses: limitations and strengths
  discussion paragraphs ("a third limitation concerns the validity of ..."),
  editorial statements about reproducibility as a value ("reproducibility is the
  cornerstone of scientific integrity"), reviews assessing the "validity of" a
  method or algorithm, lists of machine-learning evaluation metrics, results
  reproduced only within the arms of a single trial, and negative results
  ("not always replicated"). Replication PPV rose from 33.3 to 40.0 on the
  novelty/replication gold set and to 48.1 on the larger 2023 sample (with
  specificity 98.5); replication positives are still few, so PPV remains modest.

* **Funding.** "The authors did not receive any external financial support for
  this work" is now read as absence of funding.

* The held-out Serghiou et al. (2021) benchmarks and the novelty gold set are
  unchanged.

# rtransparent 0.9.4

The hand-labeled 2023 validation sample is expanded to 715 articles (210 new),
with three small detector fixes surfaced by the new batches.

* **Validation sample grows to 715.** Fourteen new batches (210 articles) were
  hand-labeled for all eight indicators and folded into
  `data-raw/benchmark/labels_2023_sample.csv` and
  `inst/benchmark/results_2023_sample.md`. Current independent metrics:
  registration 88.9 / 99.6, novelty 89.1 / 94.5, code 92.0 / 99.7, replication
  84.6 / 98.0; detector-adjudicated funding 93.2 / 95.5 and data 90.9 / 97.9.

* **Funding: more no-funding declarations recognized.** "There are no source of
  support", "not supported by any organizations", "no external sources of
  funding" and "conducted without the receipt of any dedicated grant or
  financial support" are now read as absence of funding rather than disclosed
  funding (these otherwise leaked through the funding-title route).

* **Novelty recall.** "previously unobserved" is added to the gap-claim cues
  ("we identify a previously unobserved ..."), and "undertake" to the priority
  verbs ("the first to undertake a comprehensive review").

* The held-out Serghiou et al. (2021) benchmarks and the novelty/replication
  gold set are unchanged (the new funding phrases are absence-of-funding
  declarations that cannot drop a funded positive).

# rtransparent 0.9.3

The hand-labeled 2023 validation sample is expanded to 505 articles (120 new),
with three small detector fixes surfaced by the new batches.

* **Validation sample grows to 505.** Eight new batches (120 articles) were
  hand-labeled for all eight indicators and folded into
  `data-raw/benchmark/labels_2023_sample.csv` and
  `inst/benchmark/results_2023_sample.md`. Current independent metrics:
  registration 88.2 / 99.4, novelty 87.7 / 95.8, code 94.1 / 99.6, replication
  81.8 / 98.0; detector-adjudicated funding 91.8 / 95.3 and data 88.6 / 97.7.

* **Funding: more no-funding declarations recognized.** "The authors were not
  financially supported by any funding or institutions" (the adverb "financially"
  previously broke the match) and non-English declarations (Portuguese "nao teve
  fontes de financiamento", Spanish "no recibio financiacion" / "sin
  financiacion") are now read as absence of funding rather than disclosed funding.

* **AI: disclosure-section titles broadened.** A section titled "Statement on the
  use of artificial intelligence" (and similar "... on the use of AI / generative
  AI / LLMs" headings) is now recognized as an AI-use disclosure, matching the
  existing "Declaration of generative AI" handling.

* The held-out Serghiou et al. (2021) benchmarks are unchanged: the new funding
  phrases are absence-of-funding declarations (which cannot drop a funded
  positive and do not occur in that English, pre-2021 set), and the AI indicator
  is not part of it.

# rtransparent 0.9.2

A precision release from the next round of hand-label review (2023 sample grown
to 385 articles).

* **Funding: no-funding declarations no longer leak.** The BMJ standard
  statement "The authors have not declared a specific grant for this research
  from any funding agency in the public, commercial or not-for-profit sectors"
  sits under a section titled "Funding", so it was counted as disclosed funding.
  It is now recognized as an absence-of-funding declaration. Three 2023-sample
  articles were relabeled to FALSE accordingly (their only funding statement is
  this declaration; one also cites historical NIH funding of unrelated past
  research, which is not the article's own funding).

* **Novelty precision.** Active-voice disease surveillance ("the country
  recorded its first case of COVID-19 on 27 February 2020") is now suppressed,
  matching the existing passive-voice rule; genuine case-report novelty ("we
  report the first case of ...") is preserved.

* **Novelty recall.** The explicit self-assertion "the novelty of our study ..."
  is now recognized.

* **Measured effect.** On the 2023 sample, funding specificity rose from 91.2 to
  94.7 and PPV from 94.6 to 96.3 (sensitivity unchanged); novelty holds at 86.7
  / 95.1. The held-out Serghiou et al. (2021) benchmarks and the
  novelty/replication gold set are unchanged (the new funding phrase appears only
  in modern articles, and an absence-of-funding rule cannot drop a funded
  positive).

# rtransparent 0.9.1

This release overhauls the novelty detector for both recall and precision, fixes
two long-standing bugs in the public PMC entry points, and corrects mislabeled
articles in the 2023 validation sample.

* **Novelty recall.** Fixed a core gap: the "first to &lt;verb&gt;" rule was
  missing many common verbs (confirm, validate, find, discover, prove, predict
  and others), so canonical claims such as "the first study to confirm ..." went
  undetected. The relevance pre-filter was also widened to a cheap superset of
  the pattern cues, so genuine claims placed in results or discussion sections
  are no longer discarded before the precise rules run. New patterns recognize
  "first &lt;research object&gt; to &lt;verb&gt;" (technology, technique,
  approach, method, tool, model and similar), the author-voice idiom "we provide
  the first evidence that ...", superlative and "fails to"/"no such study" gaps
  introduced by "to our knowledge" (whether the gap precedes or follows the
  phrase), and the passive "a novel &lt;object&gt; was developed/detected".

* **Novelty precision.** Bare "new" is no longer treated as a novelty cue (it is
  far too frequent in non-priority contexts such as "a new model" or "new
  insights"); procedural "we first &lt;verb&gt; ..., then ..." no longer counts
  as a priority claim; and the weak "this novel &lt;term&gt;" pattern was
  removed. Gap claims ("previously un...", "has not been studied") must now be
  tied to the present study rather than to background or a cited work. New
  suppression rules drop firstness that is attributed ("not the first", an author
  + "et al" near the cue), historical (a past year), epidemiological ("the first
  case of X was confirmed in ..."), an enumeration ("first time point", "the
  first method involves ..."), or a personal or specimen encounter ("captured
  for the first time").

* **Measured effect.** On the independent 2023 sample, novelty rose from
  sensitivity 77.2 / specificity 89.6 (PPV 71.0) to 86.3 / 94.9 (PPV 85.4). On
  the novelty/replication gold set it rose from 76.5 / 90.8 to 83.8 / 95.2; the
  `rt_accuracy` novelty estimate used by `rt_summary()` was updated accordingly
  (0.765/0.908 to 0.838/0.952). Replication is unchanged.

* **Bug fix: duplicated columns.** `rt_novelty_pmc()` and `rt_replication_pmc()`
  raised "Column names ... must not be duplicated" because their identifier
  output duplicated the prediction and text columns supplied by the internal
  detector. Both now return a single, well-formed row. (`rt_all_pmc()`, which
  calls the internal detectors directly, was never affected.)

* **Validation labels.** Corrected eleven novelty labels in the 2023 sample that
  were assigned in error during fast batch labeling: seven clear author priority
  claims had been marked FALSE, and four enumeration, ordinal or "new method"
  mentions with no priority claim had been marked TRUE. The committed benchmark
  and the novelty/replication gold set were rebuilt from the corrected labels.

* The held-out Serghiou et al. (2021) conflicts-of-interest, funding,
  registration, data and code benchmarks are unchanged; no detector other than
  novelty was modified.

# rtransparent 0.9.0

This is a feature release centered on the novelty and replication detectors and
a second, independent validation set.

* **Independent 2023 validation sample.** Added a held-out set of 370 open-access
  PMC articles published in 2023, hand-labeled for all eight transparency
  indicators (`data-raw/benchmark/labels_2023_sample.csv`,
  `inst/benchmark/results_2023_sample.md`). It is a modern companion to the
  Serghiou et al. (2021) held-out set, which predates these indicators and the
  2023-era reporting conventions. The conflicts-of-interest, funding and data
  labels were reconciled against the detector's extracted statement where the
  author's back matter was truncated during labeling, so those three are not
  independent of the detector; novelty, replication, registration and code
  sharing were labeled independently and are the meaningful test.

* **Novelty detector improvements.** Recall was broadened to recognize "new" and
  "innovative" (not only "novel"), a much wider set of research objects
  (device, sequence, model, tool, assay, algorithm, variant, isolate, ...),
  passive claims ("a novel X is developed"), an adverbial "first" ("our study
  first provided evidence"), more "first to <verb>" verbs, and "first reported
  case". A new negation step (`.negate_novelty_1`) removes firstness attributed
  to a cited study ("Smith et al. demonstrated for the first time"),
  ordinal/temporal "first" (first-time transplant, first day/week/stage) while
  preserving the priority phrase "for the first time, we ...", and historical
  dates ("used for the first time in 1993"). On the 2023 sample, novelty
  sensitivity rose from 72.8% to 77.2% and specificity from 87.8% to 89.6%.

* **Replication detector.** Future/conditional replication proposed for later
  work ("this study can be replicated with a larger sample") is now treated as
  not performed. The replication gold set remains small (few positives), so its
  estimates are reported as low-power.

* The novelty/replication gold set was expanded from 160 to 370 articles, and
  the novelty accuracy used by `rt_summary(accuracy = TRUE)` was updated
  accordingly.


# rtransparent 0.8.16

* Funding: a "Funding Statement" section that declares no funding is no longer counted as funding. When the section label ("Funding Statement", "Funding Information") and its content ("None") sit in separate nodes, only the label is recovered, so the no-funding content could not be seen and the section's presence leaked through as a funding disclosure. These labels are now treated like the bare "Funding" label already was: an uninformative tag that does not by itself indicate funding, while still allowing a funding statement elsewhere in the article to be detected. The held-out funding benchmark is unchanged (sensitivity 100%, specificity 95.7%). Added regression tests.


# rtransparent 0.8.15

* Funding: treat "was not supported by any funding" as the absence of funding. A funding section can be titled "Funding" yet declare no funding ("The study was not supported by any funding."); the funding-title route counted the section's presence as a funding disclosure because this phrasing was missing from the no-funding negation. It is now recognized alongside the other no-funding statements. The held-out funding benchmark is unchanged (sensitivity 100%, specificity 95.7%). Added regression tests.


# rtransparent 0.8.14

* Funding: do not read an author conflict-of-interest disclosure as research funding. Sports-medicine journals (AOSSM titles such as the American Journal of Sports Medicine and the Orthopaedic Journal of Sports Medicine) introduce author disclosures with a fixed preamble, "One or more of the authors has declared the following potential conflict of interest or source of funding:", followed by industry relationships ("received research support from <company>", royalties, consultancy, speaking fees). These are the authors' industry ties, not funding for the study, but the "received research support from ..." wording registered as a funding acknowledgment. The disclosure clause is now removed before funding is scanned, so a separate Funding statement in the same article is still detected. The held-out funding benchmark is unchanged (sensitivity 100%, specificity 95.7%). Added regression tests.


# rtransparent 0.8.13

* Code sharing: do not mistake a "Web Resources" / "URLs" list for shared code. Genomics papers commonly list the external tools and databases they used as "Name: URL, Name: URL, ..." (for example ANNOVAR, BWA, GATK and third-party GitHub tools such as Delly, Lumpy and Manta). Such a resource list cites software the authors used, not code they released, but the GitHub URLs made it register as code sharing. A list of three or more "label: URL" entries is now vetoed. The held-out code benchmark is unchanged (sensitivity 88.1%, specificity 99.5%).

* Funding: do not count an open-access publishing arrangement as research funding. Statements such as "Open Access funding enabled and organized by Projekt DEAL" (or by CAUL, IReL and similar library consortia) pay the article-processing charge and are not a research-funding disclosure, but the "funding ... by <consortium>" wording in the acknowledgments was registering as funding. The open-access funding noun phrase is now stripped before funding acknowledgments are scanned, so a genuine grant declared in the same statement is still detected. The held-out funding benchmark is unchanged (sensitivity 100%, specificity 95.7%). Added regression tests.


# rtransparent 0.8.12

* Funding: detect funding declared only through the structured `<funding-group>`. When an article's funding-group named a funder (`<funding-source>`) and award identifier but carried no narrative `<funding-statement>` and no funding section title, the funding was missed. The named funder is now treated as a funding disclosure (and returned as the funding text). The held-out funding benchmark is unchanged (sensitivity 100%, specificity 95.7%). Added regression tests.


# rtransparent 0.8.11

* Code sharing: do not mistake medical billing codes for software. A statement such as "generate a list of CPT billing codes" (Current Procedural Terminology) was counted as code sharing because of the word "codes"; CPT, billing, procedural and reimbursement codes are now vetoed, alongside the ICD and diagnosis codes already handled. The held-out code benchmark is unchanged (sensitivity 88.1%, specificity 99.5%). Added regression tests.


# rtransparent 0.8.10

* Funding: do not count common "no funding" declarations as a funding disclosure. The no-funding negation already covered many phrasings but missed several frequent ones, most importantly "(this research) received no specific grant from any funding agency", as well as "no funds, grants or other support were received", "no funds have been received" and "(authors) have not received any funding". These are now treated as the absence of funding, matching the detector's handling of the other no-funding statements. The held-out funding benchmark is unchanged (sensitivity 100%, specificity 95.7%). Added regression tests.


# rtransparent 0.8.9

* `rt_data_code_pmc()` and `rt_all_pmc()` now also return the identifiers of the shared data and code, not just whether sharing occurred. New columns `open_data_links` and `open_code_links` hold the DOIs (as `doi.org` URLs), repository URLs and database accessions extracted from the detected availability statements, with accessions normalized to identifiers.org `prefix:accession` form (for example `geo:GSE12345`, `bioproject:PRJEB51269`); multiple identifiers are separated by `" ; "`. Identifiers are taken only from the availability statements, so a reused accession cited in the methods is not collected. Added regression tests.


# rtransparent 0.8.8

* New accuracy benchmark for the **novelty** and **replication** detectors, which had no gold standard in Serghiou et al. (2021). A hand-labeled gold set of 160 open-access PMC articles (`data-raw/benchmark/labels_novelty_replication.csv`, with the label definitions documented in `run_novelty_replication.R`) is scored by `data-raw/benchmark/run_novelty_replication.R`; results are in `inst/benchmark/results_novelty_replication.md`. Novelty scores sensitivity 81.0%, specificity 93.2% (n = 160, 42 positives); replication has too few positives for a stable sensitivity estimate (specificity 96.8%).
* `rt_accuracy` now includes novelty (sensitivity 0.810, specificity 0.932), so `rt_summary()` reports an error-corrected novelty prevalence. Replication and AI-use disclosure remain uncorrected.


# rtransparent 0.8.7

Fixes for genome data-papers (Darwin Tree of Life and similar), found during the manual validation of 1,000 open-access PMC articles:

* Data sharing: recognize a named data repository paired with an explicit accession identifier as a deposit, even without a separate availability verb. This catches the structured form "European Nucleotide Archive: <species>. Accession number PRJEB#####", which the detector previously missed because the availability heading is in a different element from the accession. Reuse of an existing accession ("obtained from … under accession") is still not counted. The held-out data benchmark is unchanged (sensitivity 76.5%, specificity 99.0%).
* Code sharing: do not treat a sequencing consortium's author list as code. The genome-data-paper boilerplate "Members of the … DNA Pipelines collective are listed here: <Zenodo DOI>" was flagged as code because of the word "pipelines"; it is now vetoed. The held-out code benchmark is unchanged (sensitivity 88.1%, specificity 99.5%).
* Added regression tests for both.


# rtransparent 0.8.6

* Data sharing: detect the Frontiers default data-availability statement when it has no supplement clause. "The original contributions presented in the study are included in the article/Supplementary Material" was recognized, but the same statement ending "... included in the article" (for an article with no supplement) was missed. Both mean the data are in the article, so both now count; the highly specific phrasing keeps generic "included in the article" sentences from matching. The held-out data benchmark is unchanged (sensitivity 76.5%, specificity 99.0%). Added a regression test.


# rtransparent 0.8.5

* `rt_all_pmc()` now returns all eight transparency indicators in a single call. It previously returned six (COI, funding, registration, novelty, replication and AI-use disclosure) and data and code sharing had to be obtained separately from `rt_data_code_pmc()`; the output now also carries `is_open_data`, `is_open_code` and their matched statements (`open_data_statements`, `open_code_statements`). The detection is the same native detector as `rt_data_code_pmc()`, so the two agree exactly. The change is additive: existing columns are unchanged, and the COI, funding and registration benchmarks are unaffected. The vignettes are updated to reflect the single-call workflow.


# rtransparent 0.8.4

Documentation and example data, so the package website showcases every indicator:

* New vignette, `vignette("ai-disclosure")`, on the AI-use disclosure indicator: what `rt_ai_pmc()` detects, why it is gated to 2023 onward, and how to chart its adoption across a corpus.
* The introduction vignette now covers all of the indicators, including AI-use disclosure, and the corpus-summary vignette plots the AI indicator alongside the others.
* The pkgdown website now links the articles (vignettes) from the navbar, so the corpus-summary and plotting walkthroughs are reachable again, not just the introduction.
* `rt_demo` gains an `is_ai_pred` column (`NA` before 2023) and now spans 2010-2026, so `rt_summary()` and `rt_plot()` examples can show the AI indicator and its time trend. The data remain simulated.


# rtransparent 0.8.3

Further fixes from the manual validation on a fresh sample of 1,000 open-access PMC articles from 2023:

* Data sharing: recognize a repository deposit when a superscript reference number is glued to the repository name during text extraction (for example "the database was stored on Mendeley Data20"). The "data" token was no longer recognized once a digit was attached to it, so the deposit was missed. The data-noun pattern now tolerates a trailing reference number. The change does not match the unrelated word "database". The held-out data benchmark is unchanged (sensitivity 76.5%, specificity 99.0%).
* Registration: detect a PROSPERO registration that does not quote the CRD identifier (for example "the review protocol was registered in PROSPERO", "Registered to PROSPERO"). The detector previously required a CRD number. It now also flags the past-tense verb "registered" next to PROSPERO, while still not matching the registry's own name ("International Prospective Register of Systematic Reviews") or a "not registered" statement. The registration benchmark is unchanged at 98.1%.
* Added regression tests for both.


# rtransparent 0.8.2

* Code sharing: detect repository-hosted code when the same sentence also offers the data on request. A single availability statement sometimes reads "the pipeline is available on GitHub, and sample data are available upon request"; the data-delivery wording ("upon request", "from the corresponding author") was vetoing the whole sentence, so the openly hosted code was missed. The data-delivery negations no longer veto code that is concretely hosted on a public repository, while genuine non-availability ("the source code is not publicly available") and request-only code with no repository are still not counted. The held-out code benchmark is unchanged (sensitivity 88.1%, specificity 99.5%). Added regression tests.


# rtransparent 0.8.1

Fixes from a manual validation on a fresh, disjoint sample of 1,000 open-access PMC articles from 2023:

* Registration: detect more ClinicalTrials.gov phrasings. The detector previously required "registered at ClinicalTrials.gov" and missed common forms such as "the RCT is registered with ClinicalTrials.gov (NCT...)" and "trial registration number NCT...". It now flags an NCT identifier that co-occurs with a registration verb or ClinicalTrials.gov, while still not flagging a trial merely cited by its identifier. Registration benchmark accuracy is unchanged at 98.1%.
* Code sharing: recognize code shared on the Open Science Framework. OSF was already a recognized data repository but not a code repository, so "data and code are available on the OSF" was counted for data but not code. Data on OSF without a code mention is still not counted as code.
* Added regression tests for both.


# rtransparent 0.8.0

* New **AI-disclosure** indicator. `rt_ai_pmc()` detects whether an article discloses the use (or non-use) of generative AI or AI-assisted tools in preparing the manuscript, as journals have asked of authors since 2023. It recognizes positive disclosures ("the authors used ChatGPT to improve the readability of the manuscript"), negative disclosures ("no generative AI was used in the preparation of this work") and dedicated "Declaration of generative AI" sections, while not flagging articles that merely use AI as their research method. Because the practice did not exist before 2023, the indicator is only evaluated for articles published in 2023 or later; earlier articles return `NA` (`is_ai_pred`), and the publication `year` is reported. The indicator is included in `rt_all_pmc()` and recognized by `rt_summary()`. On the 1,000-article open-access validation set (almost all published 2024-2026) it flags about 16% of articles, with high precision on inspection.


# rtransparent 0.7.1

* Code sharing recall improved. The detector now recognizes analysis code shared in supplementary or additional files ("the Matlab code can be found in the Supplementary Methods", "R code is contained in Additional file 7", "Source code 1") and explicit "Availability of source code" sections. On the held-out benchmark of Serghiou et al. (2021), code sensitivity rises from 83.5% to 88.1% with specificity unchanged at 99.5% (PPV 99.0%); `rt_accuracy` was updated. The patterns are gated on a language prefix or the word "script" so non-analysis "codes" (ICD, diagnosis, qualitative) are not matched. Added regression tests.


# rtransparent 0.7.0

Improvements from a large audit: the tool was run over 1,000 cached open-access PMC articles and a sample was hand-checked against the human-labeled benchmark.

* Data sharing recall improved. The detector now recognizes "the data supporting the findings are included within the article / within the manuscript" availability statements (previously only the "in the article" wording was matched). On the held-out benchmark of Serghiou et al. (2021), data sensitivity rises from 72.2% to 76.5% with specificity unchanged at 99.0% (PPV 98.9%); `rt_accuracy` was updated.
* Replication precision improved. Future or required validation framed as not-yet-done ("external validation is essential/needed before clinical implementation", "this finding requires validation in independent cohorts") is no longer counted as replication. Validation that was actually performed (external or independent) still counts. The change is gated on a modal or need word so performed validation is preserved.
* Added regression tests for both changes.


# rtransparent 0.6.1

Precision and recall fixes from an independent manual review of a sample of open-access PMC articles:

* Replication: a bare internal training/validation split (a single dataset divided into a training cohort and a validation cohort) is no longer counted as replication, since it is model development rather than an independent confirmation in a new sample. External or independent validation still counts.
* Novelty: firstness claims that carry an adverbial are now detected, for example "the first to date to report ..." and "the first ever study to characterize ...".
* Data: the generic publisher line "The online version contains supplementary material available at <doi>", which appears in every article of some journals, is no longer treated as a data-availability statement on its own.


# rtransparent 0.6.0

* Substantially improved detector recall, guided by an external validation set of 1,000 open-access PMC articles:
  * Novelty and replication detection now scan the full article body and recognize many more phrasings (firstness and knowledge-gap claims for novelty; internal, external and independent-validation claims for replication), while new suppressors keep generic "validation" and future-work wording out.
  * Data and code sharing detection gained high-specificity patterns for in-article and supplement availability statements, repository-hosted data, and explicit code-availability wording, and new vetoes for supplement boilerplate, result tables, local file paths and tool/package-use mentions.
  * Registration detection added negation guards ("not registered", "not applicable", IRB-only numbers) and broader registry coverage.
* The reproducible data/code benchmark now gives data 71.3% sensitivity / 99.0% specificity and code 83.5% sensitivity / 99.5% specificity; `rt_accuracy` was updated to these estimates.
* Internal helper functions are now marked `@noRd`, so the manual and the pkgdown reference present only the public API.
* Hardened `rt_summary()` and `rt_score()` so indicator columns must be logical or numeric 0/1 values, with `NA` allowed.
* Added a reproducible external validation harness under `data-raw/external-validation/`.


# rtransparent 0.5.1

* Corrected the license declaration from `GPL-3 + file LICENSE` to `GPL-3`. The package is plain GPL-3 with no additional terms, so the `+ file LICENSE` form (which signals extra restrictions in the `LICENSE` file) was misleading; the full GPL-3 text is still provided in `LICENSE` for reference.


# rtransparent 0.5.0

* New corpus-level summary tools, for turning per-article detector output into the kind of figures and tables used in meta-research studies of transparency:
  * `rt_summary()` reports each indicator's prevalence with a Wilson confidence interval and, by default, a prevalence corrected for the detector's sensitivity and specificity (the Rogan-Gladen estimator). It can summarize within groups via `by`.
  * `rt_score()` adds a per-article count of the openness practices met.
  * `rt_plot()` draws a prevalence bar chart or a prevalence-over-time line chart (requires `ggplot2`).
* New datasets: `rt_accuracy` (detector sensitivity and specificity estimates, used by `rt_summary()`) and `rt_demo` (a small simulated corpus for the examples).
* New vignette, `vignette("transparency-summary")`, illustrating the output: from one article to a corpus prevalence table, an accuracy-corrected prevalence, a practice-count distribution, subgroup summaries and plots.


# rtransparent 0.4.3

* Removed the unused legacy data and code helper functions that still referenced `oddpub` and `tokenizers`. The native detector (added in 0.4.0) is the only data and code path; `oddpub`, `tokenizers` and `metareadr` have been dropped from `Suggests`, so the package and its CRAN-style check no longer reference any GitHub-only packages.
* Resolved the `R CMD check` note about the undefined `.` global variable.
* Polished release metadata: the `DESCRIPTION` `Title` is now in title case and the pkgdown URL carries its trailing slash.
* The pkgdown reference index now groups the exported functions by purpose and collapses internal helpers, so the website presents the public API rather than every internal helper.
* Regenerated the committed benchmark artifacts under the current package version.


# rtransparent 0.4.2

* Added a pkgdown documentation website at <https://choxos.github.io/rtransparent/>.
* Corrected the `rt_data_code_pmc_list()` documentation example.


# rtransparent 0.4.1

* Fixed the exported `rt_fund_pmc()`. It previously predicted funding `TRUE` for no-funding articles with empty evidence text; it now delegates to the same detection path as `rt_all_pmc()` so the two agree, and a positive prediction always carries evidence. Added regression tests.
* Exported and documented `rt_meta_pmc()` (article metadata from a PMC XML file), which the README advertised but which was not exported.
* Generated the missing help pages for the novelty and replication functions. `R CMD check` now passes with no errors or warnings.
* Rewrote the vignette to be self-contained (it runs on a bundled example XML, with the PDF and download steps shown but not executed) and to describe the package and its methodology; removed stale `oddpub` / `metareadr` instructions.
* Updated the README and benchmark documentation for native data and code detection, pointed URLs at the maintained fork, and regenerated the committed benchmark results under the current version.
* Added a package startup message and removed the stale packrat configuration.


# rtransparent 0.4.0

* Data and code sharing detection is now implemented natively (`R/data_code.R`) and no longer requires the `oddpub` package at runtime. On the XML benchmark used at the time, the native detector scored data 64% sensitivity / 95% specificity and code 68% sensitivity / 94% specificity (the published paper reports about 76% and 59% sensitivity). Code detection already exceeded the paper's sensitivity and the data precision matched the original `oddpub`; data sensitivity was being improved toward `oddpub`'s ~84%.
* `rt_data_code`, `rt_data_code_pmc` and `rt_data_code_pmc_list` were rewritten to use the native detector and return `is_open_data` / `is_open_code` with the matched statement text. They no longer depend on `oddpub` or `tokenizers`.
* Added a data/code benchmark (`data-raw/benchmark/run_data_code.R`, `inst/benchmark/results_data_code.md`).


# rtransparent 0.3.4

* Ported the PROSPERO detection fix from the quest-bih fork: the registration regex now matches PROSPERO identifiers of 5 to 11 digits (`CRD` numbers exceed 5 digits), in both the TXT and PMC detectors. No change on the benchmark (the held-out set has no PROSPERO-only cases). The fork's other commits were assessed and deferred: "coi update" is TXT-only (not exercised by the PMC benchmark) and "pipe update" is a cosmetic reformat that conflicts with this line's changes.


# rtransparent 0.3.3

* Improved funding specificity from 78% to 96% on the held-out XML test set (accuracy 86% to 97%) by tightening `get_fund_acknow_new()`. It previously flagged any acknowledgment that merely named an institution or used the word "support", so competing-interest statements, generic thanks, data-availability statements and affiliations were misread as funding. It now requires explicit funding language: a funding verb directed at a funder, an institutional "support/funding of the ...", a grant or award identifier, or a named award. Sensitivity is unchanged at 100% on the test set.


# rtransparent 0.3.2

* Added a reproducible accuracy benchmark (`data-raw/benchmark/`, `inst/benchmark/`) that scores the detectors against the human-labeled gold standard of Serghiou et al. (2021) and reports sensitivity, specificity, PPV, NPV and accuracy with bootstrap confidence intervals, alongside the published Fig 2 numbers.
* Fixed `.reroot_xml()` to handle bare `<article>` and NCBI EFetch `<pmc-articleset>` roots. Previously it returned an empty document for anything other than the PMC OAI-PMH format, which silently suppressed all detection.
* Fixed unqualified `str_detect()`/`regex()` calls in the funding detector that errored on articles lacking a structured funding statement.


# rtransparent 0.3.1

* Data and code detection dependencies (`oddpub`, `tokenizers`) are now optional (moved to `Suggests`); the package loads and every other indicator runs without them. The data and code functions raise a clear, actionable error when these packages are absent.
* Added an internal PMC full-text XML fetch helper for the accuracy benchmark, backed by NCBI E-utilities (EFetch) with a PMC OAI-PMH fallback (adapted from `metareadr`, GPL-3).


# rtransparent 0.3.0

* `rt_novelty` and `rt_novelty_pmc` added: detect claims of novelty ("for the first time") in TXT and PMC XML files.
* `rt_replication` and `rt_replication_pmc` added: detect replication/validation components in TXT and PMC XML files.
* `rt_register` and `rt_register_pmc` expanded: now detect registrations on ISRCTN, ANZCTR (ACTRN), DRKS, IRCT, and UMIN in addition to NCT and PROSPERO.
* `rt_all` and `rt_all_pmc` updated to include novelty and replication indicators.
* A formal testthat test suite has been added (`tests/testthat/`).


# rtransparent 0.2.5

* A vignette has been added to help illustrate how to use the package.


# rtransparent 0.2

* `rt_coi` now searches for Conflicts of interest statements within text files.
* `rt_fund` now searches for Funding statements within text files.
* `rt_register` now searches for Registration statements within text files.
* `rt_all` now searches for many indicators within text files.
* `rt_read_pdf` now converts PDF files into TXT using poppler.


# rtransparent 0.1

* Initial commit of functions to analyze PMC XML files for indicators.


</div>
