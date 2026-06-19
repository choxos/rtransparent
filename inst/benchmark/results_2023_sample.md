# Independent 2023 OA PMC hand-labeled sample

Package version 0.9.1. 370 open-access PMC articles published in 2023, sampled
and hand-labeled for all eight transparency indicators. This is a modern,
independent companion to the Serghiou et al. (2021) held-out set (which
predates these indicators and the 2023-era reporting conventions).

**Methods note.** Conflicts of interest, funding and data labels were
reconciled against the detector's extracted statement where the author's back
matter was truncated in the labelling view, so those three are *not*
independent of the detector and their agreement is near ceiling by
construction. Novelty, replication, registration and code sharing were
labelled independently and are the meaningful validation.

| Indicator | Labels | n | pos | Sens | Spec | PPV | Acc |
|---|---|---|---|---|---|---|---|
| coi | detector-adjudicated | 370 | 347 | 100.0 |  73.9 |  98.3 |  98.4 |
| fund | detector-adjudicated | 370 | 233 |  89.7 |  91.2 |  94.6 |  90.3 |
| reg | independent | 370 |  30 |  90.0 |  99.1 |  90.0 |  98.4 |
| nov | independent | 370 |  95 |  86.3 |  94.9 |  85.4 |  92.7 |
| rep | independent | 370 |   5 |  80.0 |  97.8 |  33.3 |  97.6 |
| data | detector-adjudicated | 370 |  56 |  85.7 |  98.1 |  88.9 |  96.2 |
| code | independent | 370 |  11 |  90.9 |  99.7 |  90.9 |  99.5 |
| ai | detector-adjudicated | 366 |   4 | 100.0 | 100.0 | 100.0 | 100.0 |
