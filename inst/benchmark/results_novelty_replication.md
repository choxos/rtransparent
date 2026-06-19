# Novelty and replication detector benchmark

Package version 0.9.4. Detectors run on PMC full-text XML and compared
to a maintainer-built hand-labeled gold set of open-access PMC articles
(2023-2026); see `data-raw/benchmark/labels_novelty_replication.csv` and the
label definitions at the top of `run_novelty_replication.R`. These indicators
have no gold standard in Serghiou et al. (2021), so this is the reference for
novelty/replication accuracy. Replication has few positives, so its
sensitivity estimate is low-powered; specificity and PPV are more stable.

## Novelty (n = 370)
Sensitivity 83.8, Specificity 95.2, PPV 86.5, NPV 94.2, Accuracy 92.2

## Replication (n = 370)
Sensitivity 80.0, Specificity 97.8, PPV 33.3, NPV 99.7, Accuracy 97.6
