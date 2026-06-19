# Independent 2023 OA PMC hand-labeled sample

Package version 0.9.5. 980 open-access PMC articles published in 2023, sampled
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
| coi | detector-adjudicated | 980 | 908 | 100.0 |  91.7 |  99.3 |  99.4 |
| fund | detector-adjudicated | 980 | 521 |  94.8 |  95.2 |  95.7 |  95.0 |
| reg | independent | 980 |  52 |  84.6 |  99.2 |  86.3 |  98.5 |
| nov | independent | 980 | 203 |  90.1 |  93.4 |  78.2 |  92.8 |
| rep | independent | 980 |  16 |  81.2 |  98.5 |  48.1 |  98.3 |
| data | detector-adjudicated | 980 | 120 |  90.8 |  97.8 |  85.2 |  96.9 |
| code | independent | 980 |  32 |  93.8 |  98.9 |  75.0 |  98.8 |
| ai | detector-adjudicated | 969 |   9 | 100.0 | 100.0 | 100.0 | 100.0 |
