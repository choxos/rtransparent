# Native data and code sharing detector benchmark

Package version 0.6.1. Native detector vs the human-labeled XML benchmark
articles of Serghiou et al. (2021). These are reproducible benchmark and
regression metrics for the native detector, not untouched external-validation
estimates. The published paper reports data
sensitivity ~76% and code sensitivity ~59%; the original oddpub algorithm
scores ~84% / ~97% (sensitivity / specificity) against `isData` on this set.

## Data (n = 216)
Sensitivity 72.2, Specificity 99.0, PPV 98.8, NPV 75.8, Accuracy 84.7

## Code (n = 324)
Sensitivity 83.5, Specificity 99.5, PPV 98.9, NPV 92.2, Accuracy 94.1
