# Independent 2023 OA PMC hand-labeled sample

Package version 0.9.2. 385 open-access PMC articles published in 2023, sampled
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
| coi | detector-adjudicated | 385 | 362 | 100.0 |  73.9 |  98.4 |  98.4 |
| fund | detector-adjudicated | 385 | 234 |  89.7 |  94.7 |  96.3 |  91.7 |
| reg | independent | 385 |  30 |  90.0 |  99.2 |  90.0 |  98.4 |
| nov | independent | 385 |  98 |  86.7 |  95.1 |  85.9 |  93.0 |
| rep | independent | 385 |   5 |  80.0 |  97.9 |  33.3 |  97.7 |
| data | detector-adjudicated | 385 |  58 |  86.2 |  98.2 |  89.3 |  96.4 |
| code | independent | 385 |  11 |  90.9 |  99.7 |  90.9 |  99.5 |
| ai | detector-adjudicated | 381 |   4 | 100.0 | 100.0 | 100.0 | 100.0 |
