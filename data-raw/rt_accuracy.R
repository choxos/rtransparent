# Builds data/rt_accuracy.rda: sensitivity and specificity estimates used by
# rt_summary() to correct apparent prevalence.
#
# For conflicts of interest, funding and protocol registration the published,
# importance-weighted validation values of Serghiou et al. (2021) are used; the
# detectors for these indicators are essentially those validated in the paper.
#
# For data and code sharing the detector is now native (it no longer wraps
# oddpub), so the package's reproducible benchmark and regression estimates are used
# instead (see inst/benchmark/results_data_code.md). These are not untouched
# external validation estimates for the native detector. Users who prefer the
# paper's oddpub values, or their own, can pass any data frame with `variable`,
# `sensitivity` and `specificity` columns to rt_summary(accuracy = ).
#
# For novelty the estimate comes from the maintainer's hand-labeled gold set
# (see inst/benchmark/results_novelty_replication.md). For replication the
# sensitivity comes from a 111-positive replication-enriched validation
# (inst/benchmark/results_replication_enriched.md) and the specificity from the
# representative 2023 1000-article sample; earlier releases omitted replication
# for lack of a stable positive sample.

rt_accuracy <- tibble::tibble(
  variable = c(
    "is_coi_pred", "is_fund_pred", "is_register_pred",
    "is_open_data", "is_open_code", "is_novelty_pred", "is_replication_pred"
  ),
  label = c(
    "Conflicts of interest", "Funding disclosure",
    "Protocol registration", "Data sharing", "Code sharing", "Novelty",
    "Replication"
  ),
  sensitivity = c(0.992, 0.997, 0.955, 0.765, 0.881, 0.838, 0.928),
  specificity = c(0.995, 0.981, 0.997, 0.990, 0.995, 0.952, 0.985),
  source = c(
    rep("Serghiou et al. 2021, PLOS Biology (doi:10.1371/journal.pbio.3001107)", 3),
    rep("rtransparent native detector, reproducible benchmark and regression estimate (inst/benchmark)", 2),
    "rtransparent novelty/replication hand-labeled benchmark (inst/benchmark/results_novelty_replication.md)",
    "rtransparent replication-enriched validation, sensitivity n=111 positives; specificity from the 2023 1000-article sample (inst/benchmark/results_replication_enriched.md)"
  )
)

save(rt_accuracy, file = "data/rt_accuracy.rda", version = 2)
