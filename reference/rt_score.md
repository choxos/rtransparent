# Count the transparency indicators met by each article

Adds a column giving, for each article (row), how many of the
transparency indicators were detected. This is the per-article
transparency score used to describe how many practices an article
adheres to.

## Usage

``` r
rt_score(data, indicators = NULL, name = "n_indicators")
```

## Arguments

- data:

  A data frame with one row per article and indicator columns named as
  in \[rt_all_pmc()\].

- indicators:

  Optional character vector of indicator columns to count. Defaults to
  the five openness practices present in \`data\` (conflicts of
  interest, funding, registration, data and code); novelty and
  replication are excluded unless requested explicitly, as they are not
  adherence practices.

- name:

  Name of the count column to add (default \`"n_indicators"\`).

## Value

\`data\` as a tibble with the integer count column added. Rows with no
assessed indicators receive \`NA\` for the count. Tabulate it (for
example with \[table()\] or \`dplyr::count()\`) for the distribution of
the number of practices met.

## See also

\[rt_summary()\]

## Examples

``` r
data(rt_demo)
scored <- rt_score(rt_demo)
table(scored$n_indicators)
#> 
#>   0   1   2   3   4   5 
#>  52 288 467 305  74  14 
```
