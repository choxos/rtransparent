# Native data and code sharing detector benchmark

Package version 0.8.7. Native detector vs the human-labeled XML benchmark
articles of Serghiou et al. (2021). These are reproducible benchmark and
regression metrics for the native detector, not untouched external-validation
estimates. The published paper reports data
sensitivity ~76% and code sensitivity ~59%; the original oddpub algorithm
scores ~84% / ~97% (sensitivity / specificity) against `isData` on this set.

## Data (n = 216)
Sensitivity 76.5, Specificity 99.0, PPV 98.9, NPV 78.7, Accuracy 87.0

## Code (n = 324)
Sensitivity 88.1, Specificity 99.5, PPV 99.0, NPV 94.3, Accuracy 95.7
