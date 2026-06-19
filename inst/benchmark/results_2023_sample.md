# Independent 2023 OA PMC hand-labeled sample

Package version 0.9.4. 715 open-access PMC articles published in 2023, sampled
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
| coi | detector-adjudicated | 715 | 656 | 100.0 |  89.8 |  99.1 |  99.2 |
| fund | detector-adjudicated | 715 | 382 |  93.2 |  95.5 |  96.0 |  94.3 |
| reg | independent | 715 |  36 |  88.9 |  99.6 |  91.4 |  99.0 |
| nov | independent | 715 | 156 |  89.1 |  94.5 |  81.8 |  93.3 |
| rep | independent | 715 |  13 |  84.6 |  98.0 |  44.0 |  97.8 |
| data | detector-adjudicated | 715 |  88 |  90.9 |  97.9 |  86.0 |  97.1 |
| code | independent | 715 |  25 |  92.0 |  99.7 |  92.0 |  99.4 |
| ai | detector-adjudicated | 707 |   9 | 100.0 | 100.0 | 100.0 | 100.0 |
