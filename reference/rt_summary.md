# Summarize transparency indicators across a corpus of articles

Takes a data frame with one row per article (such as the output of
\[rt_all_pmc()\] joined with \[rt_data_code_pmc()\], stacked over many
articles) and returns the prevalence of each transparency indicator. For
each indicator it reports the number of articles assessed, the number in
which the indicator was detected, the apparent prevalence and its Wilson
confidence interval and, optionally, a prevalence corrected for the
detector's sensitivity and specificity (the Rogan-Gladen estimator).

## Usage

``` r
rt_summary(
  data,
  indicators = NULL,
  by = NULL,
  adjust = TRUE,
  accuracy = NULL,
  conf_level = 0.95
)
```

## Arguments

- data:

  A data frame with one row per article. Indicator columns must be
  logical or numeric 0/1 and named as in \[rt_all_pmc()\]:
  \`is_coi_pred\`, \`is_fund_pred\`, \`is_register_pred\`,
  \`is_open_data\`, \`is_open_code\`, \`is_novelty_pred\`,
  \`is_replication_pred\`. \`NA\` marks an article that was not assessed
  for that indicator and is excluded from its denominator. Other values
  are rejected rather than silently coerced.

- indicators:

  Optional character vector of indicator columns to summarize. Defaults
  to every recognized indicator present in \`data\`.

- by:

  Optional name of a grouping column (for example a publication year,
  journal or article type); the summary is then computed within each
  group.

- adjust:

  If \`TRUE\` (default), add a prevalence corrected for detector
  sensitivity and specificity using \`accuracy\`. Indicators absent from
  \`accuracy\` receive \`NA\` corrected values.

- accuracy:

  A data frame of detector accuracy with columns \`variable\`,
  \`sensitivity\` and \`specificity\`. Defaults to \[rt_accuracy\].

- conf_level:

  Confidence level for the intervals (default \`0.95\`).

## Value

A tibble with one row per indicator (per group, if \`by\` is given): the
grouping column (when \`by\` is used), \`indicator\`, \`label\`,
\`n_articles\`, \`n_detected\`, \`percent\`, \`conf_low\`, \`conf_high\`
and, when \`adjust = TRUE\`, \`adj_percent\`, \`adj_low\` and
\`adj_high\`. Percentages and interval bounds are on the 0-100 scale.

## See also

\[rt_score()\], \[rt_plot()\], \[rt_accuracy\]

## Examples

``` r
data(rt_demo)
rt_summary(rt_demo)
#> # A tibble: 7 × 10
#>   indicator   label n_articles n_detected percent conf_low conf_high adj_percent
#>   <chr>       <chr>      <int>      <int>   <dbl>    <dbl>     <dbl>       <dbl>
#> 1 is_coi_pred Conf…       1200        835   69.6     66.9       72.1       70.0 
#> 2 is_fund_pr… Fund…       1200        948   79       76.6       81.2       78.8 
#> 3 is_registe… Prot…       1200        318   26.5     24.1       29.1       27.5 
#> 4 is_open_da… Data…       1200        201   16.8     14.7       19.0       20.9 
#> 5 is_open_co… Code…       1200        101    8.42     6.98      10.1        9.04
#> 6 is_novelty… Nove…       1200        596   49.7     46.8       52.5       NA   
#> 7 is_replica… Repl…       1200        109    9.08     7.59      10.8       NA   
#> # ℹ 2 more variables: adj_low <dbl>, adj_high <dbl>

# Apparent prevalence only, no accuracy correction
rt_summary(rt_demo, adjust = FALSE)
#> # A tibble: 7 × 7
#>   indicator           label     n_articles n_detected percent conf_low conf_high
#>   <chr>               <chr>          <int>      <int>   <dbl>    <dbl>     <dbl>
#> 1 is_coi_pred         Conflict…       1200        835   69.6     66.9       72.1
#> 2 is_fund_pred        Funding …       1200        948   79       76.6       81.2
#> 3 is_register_pred    Protocol…       1200        318   26.5     24.1       29.1
#> 4 is_open_data        Data sha…       1200        201   16.8     14.7       19.0
#> 5 is_open_code        Code sha…       1200        101    8.42     6.98      10.1
#> 6 is_novelty_pred     Novelty         1200        596   49.7     46.8       52.5
#> 7 is_replication_pred Replicat…       1200        109    9.08     7.59      10.8

# By article type
rt_summary(rt_demo, by = "type")
#> # A tibble: 21 × 11
#>    type         indicator label n_articles n_detected percent conf_low conf_high
#>    <chr>        <chr>     <chr>      <int>      <int>   <dbl>    <dbl>     <dbl>
#>  1 research-ar… is_coi_p… Conf…        854        598   70.0     66.9       73.0
#>  2 research-ar… is_fund_… Fund…        854        680   79.6     76.8       82.2
#>  3 research-ar… is_regis… Prot…        854        219   25.6     22.8       28.7
#>  4 research-ar… is_open_… Data…        854        138   16.2     13.8       18.8
#>  5 research-ar… is_open_… Code…        854         77    9.02     7.27      11.1
#>  6 research-ar… is_novel… Nove…        854        425   49.8     46.4       53.1
#>  7 research-ar… is_repli… Repl…        854         73    8.55     6.85      10.6
#>  8 review-arti… is_coi_p… Conf…        227        155   68.3     62.0       74.0
#>  9 review-arti… is_fund_… Fund…        227        172   75.8     69.8       80.9
#> 10 review-arti… is_regis… Prot…        227         69   30.4     24.8       36.7
#> # ℹ 11 more rows
#> # ℹ 3 more variables: adj_percent <dbl>, adj_low <dbl>, adj_high <dbl>
```
