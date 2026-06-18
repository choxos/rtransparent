# rtransparent accuracy benchmark

Package version 0.8.3. Detectors run on NCBI PMC full-text XML for the
human-labeled held-out test articles of Serghiou et al. (2021), compared to
the published Fig 2 (XML subset). Bootstrap: 2000 resamples, unweighted
(see data-raw/benchmark/README.md). Current values are point [95% CI].

## COI
Coverage: 153 / 153 articles fetched and scored (100%).

| Metric | Current [95% CI] | Paper Fig 2 (xml) |
|---|---|---|
| Sensitivity | 94.0 [88.8, 98.8] | 99.6 [99.0, 100.0] |
| Specificity | 100.0 [100.0, 100.0] | 100.0 [100.0, 100.0] |
| PPV | 100.0 [100.0, 100.0] | 100.0 [100.0, 100.0] |
| NPV | 93.2 [88.0, 98.6] | 95.9 [90.6, 100.0] |
| Accuracy | 96.7 [94.1, 99.3] | 99.6 [99.1, 100.0] |

## FUND
Coverage: 188 / 188 articles fetched and scored (100%).

| Metric | Current [95% CI] | Paper Fig 2 (xml) |
|---|---|---|
| Sensitivity | 100.0 [100.0, 100.0] | 99.7 [99.3, 100.0] |
| Specificity | 95.7 [91.8, 99.1] | 100.0 [100.0, 100.0] |
| PPV | 93.5 [88.5, 98.6] | 100.0 [100.0, 100.0] |
| NPV | 100.0 [100.0, 100.0] | 98.3 [95.8, 100.0] |
| Accuracy | 97.3 [95.2, 99.5] | 99.8 [99.4, 100.0] |

## REGISTER
Coverage: 214 / 214 articles fetched and scored (100%).

| Metric | Current [95% CI] | Paper Fig 2 (xml) |
|---|---|---|
| Sensitivity | 99.2 [97.4, 100.0] | 96.9 [93.1, 99.4] |
| Specificity | 96.9 [93.0, 100.0] | 99.7 [99.5, 99.9] |
| PPV | 97.5 [94.3, 100.0] | 93.8 [89.2, 97.4] |
| NPV | 98.9 [96.7, 100.0] | 99.9 [99.7, 100.0] |
| Accuracy | 98.1 [96.3, 99.5] | 99.6 [99.3, 99.8] |

