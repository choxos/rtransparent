# Novelty and replication detector benchmark

Package version 0.9.0. Detectors run on PMC full-text XML and compared
to a maintainer-built hand-labeled gold set of open-access PMC articles
(2023-2026); see `data-raw/benchmark/labels_novelty_replication.csv` and the
label definitions at the top of `run_novelty_replication.R`. These indicators
have no gold standard in Serghiou et al. (2021), so this is the reference for
novelty/replication accuracy. Replication has few positives, so its
sensitivity estimate is low-powered; specificity and PPV are more stable.

## Novelty (n = 370)
Sensitivity 76.5, Specificity 90.8, PPV 75.0, NPV 91.5, Accuracy 87.0

## Replication (n = 370)
Sensitivity 80.0, Specificity 97.8, PPV 33.3, NPV 99.7, Accuracy 97.6
