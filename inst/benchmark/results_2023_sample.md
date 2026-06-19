# Independent 2023 OA PMC hand-labeled sample

Package version 0.9.6. 1000 open-access PMC articles published in 2023, sampled
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
| coi | detector-adjudicated | 1000 | 927 | 100.0 |  91.8 |  99.4 |  99.4 |
| fund | detector-adjudicated | 1000 | 535 |  94.8 |  95.3 |  95.8 |  95.0 |
| reg | independent | 1000 |  52 |  84.6 |  99.2 |  84.6 |  98.4 |
| nov | independent | 1000 | 205 |  90.2 |  93.3 |  77.7 |  92.7 |
| rep | independent | 1000 |  17 |  82.4 |  98.5 |  48.3 |  98.2 |
| data | detector-adjudicated | 1000 | 123 |  91.1 |  97.8 |  85.5 |  97.0 |
| code | independent | 1000 |  33 |  93.9 |  99.0 |  75.6 |  98.8 |
| ai | detector-adjudicated |  986 |   9 | 100.0 | 100.0 | 100.0 | 100.0 |
