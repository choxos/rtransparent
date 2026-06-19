# TXT-parity benchmark

Derived from the 1000 hand-labeled 2023 PMC XML articles: each article's text is extracted and written to a plain-text file, the TXT detectors are run on it, and the predictions are compared to the same hand labels used for the PMC benchmark. Because a TXT file carries no XML structure, the XML-structural detection routes are unavailable; the TXT detectors share the same text helpers as the PMC ones, so the gap to the PMC numbers reflects the value of those XML-only routes rather than a difference in logic.

| Indicator | TXT sens | TXT spec | TXT PPV | PMC sens | PMC spec |
|---|---|---|---|---|---|
| coi | 88.6 | 90.4 | 99.2 | 100.0 | 91.8 |
| fund | 79.3 | 90.5 | 90.6 |  94.8 | 95.3 |
| reg | 90.4 | 98.4 | 75.8 |  84.6 | 99.2 |
| nov | 89.3 | 93.5 | 77.9 |  90.2 | 93.3 |
| rep | 82.4 | 98.4 | 46.7 |  82.4 | 98.5 |

