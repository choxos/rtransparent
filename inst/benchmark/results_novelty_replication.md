# Novelty and replication detector benchmark

Package version 0.8.9. Detectors run on PMC full-text XML and compared
to a maintainer-built hand-labeled gold set of open-access PMC articles
(2023-2026); see `data-raw/benchmark/labels_novelty_replication.csv` and the
label definitions at the top of `run_novelty_replication.R`. These indicators
have no gold standard in Serghiou et al. (2021), so this is the reference for
novelty/replication accuracy. Replication has few positives, so its
sensitivity estimate is low-powered; specificity and PPV are more stable.

## Novelty (n = 160)
Sensitivity 81.0, Specificity 93.2, PPV 81.0, NPV 93.2, Accuracy 90.0

## Replication (n = 160)
Sensitivity 75.0, Specificity 96.8, PPV 37.5, NPV 99.3, Accuracy 96.2
