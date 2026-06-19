# Independent 2023 OA PMC hand-labeled sample

Package version 0.9.3. 505 open-access PMC articles published in 2023, sampled
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
| coi | detector-adjudicated | 505 | 474 | 100.0 |  80.6 |  98.8 |  98.8 |
| fund | detector-adjudicated | 505 | 293 |  91.8 |  95.3 |  96.4 |  93.3 |
| reg | independent | 505 |  34 |  88.2 |  99.4 |  90.9 |  98.6 |
| nov | independent | 505 | 122 |  87.7 |  95.8 |  87.0 |  93.9 |
| rep | independent | 505 |  11 |  81.8 |  98.0 |  47.4 |  97.6 |
| data | detector-adjudicated | 505 |  70 |  88.6 |  97.7 |  86.1 |  96.4 |
| code | independent | 505 |  17 |  94.1 |  99.6 |  88.9 |  99.4 |
| ai | detector-adjudicated | 500 |   9 | 100.0 | 100.0 | 100.0 | 100.0 |
