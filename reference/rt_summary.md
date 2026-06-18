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
#> # A tibble: 8 × 10
#>   indicator   label n_articles n_detected percent conf_low conf_high adj_percent
#>   <chr>       <chr>      <int>      <int>   <dbl>    <dbl>     <dbl>       <dbl>
#> 1 is_coi_pred Conf…       1200        845   70.4     67.8       72.9       70.8 
#> 2 is_fund_pr… Fund…       1200        955   79.6     77.2       81.8       79.4 
#> 3 is_registe… Prot…       1200        356   29.7     27.2       32.3       30.8 
#> 4 is_open_da… Data…       1200        245   20.4     18.2       22.8       25.7 
#> 5 is_open_co… Code…       1200        102    8.5      7.05      10.2        9.13
#> 6 is_novelty… Nove…       1200        653   54.4     51.6       57.2       NA   
#> 7 is_replica… Repl…       1200        113    9.42     7.89      11.2       NA   
#> 8 is_ai_pred  AI d…        282         71   25.2     20.5       30.6       NA   
#> # ℹ 2 more variables: adj_low <dbl>, adj_high <dbl>

# Apparent prevalence only, no accuracy correction
rt_summary(rt_demo, adjust = FALSE)
#> # A tibble: 8 × 7
#>   indicator           label     n_articles n_detected percent conf_low conf_high
#>   <chr>               <chr>          <int>      <int>   <dbl>    <dbl>     <dbl>
#> 1 is_coi_pred         Conflict…       1200        845   70.4     67.8       72.9
#> 2 is_fund_pred        Funding …       1200        955   79.6     77.2       81.8
#> 3 is_register_pred    Protocol…       1200        356   29.7     27.2       32.3
#> 4 is_open_data        Data sha…       1200        245   20.4     18.2       22.8
#> 5 is_open_code        Code sha…       1200        102    8.5      7.05      10.2
#> 6 is_novelty_pred     Novelty         1200        653   54.4     51.6       57.2
#> 7 is_replication_pred Replicat…       1200        113    9.42     7.89      11.2
#> 8 is_ai_pred          AI discl…        282         71   25.2     20.5       30.6

# By article type
rt_summary(rt_demo, by = "type")
#> # A tibble: 24 × 11
#>    type         indicator label n_articles n_detected percent conf_low conf_high
#>    <chr>        <chr>     <chr>      <int>      <int>   <dbl>    <dbl>     <dbl>
#>  1 review-arti… is_coi_p… Conf…        241        174   72.2     66.2       77.5
#>  2 review-arti… is_fund_… Fund…        241        192   79.7     74.1       84.3
#>  3 review-arti… is_regis… Prot…        241         81   33.6     27.9       39.8
#>  4 review-arti… is_open_… Data…        241         47   19.5     15.0       25.0
#>  5 review-arti… is_open_… Code…        241         21    8.71     5.77      13.0
#>  6 review-arti… is_novel… Nove…        241        120   49.8     43.5       56.1
#>  7 review-arti… is_repli… Repl…        241         22    9.13     6.11      13.4
#>  8 review-arti… is_ai_pr… AI d…         66         14   21.2     13.1       32.5
#>  9 systematic-… is_coi_p… Conf…        132         82   62.1     53.6       69.9
#> 10 systematic-… is_fund_… Fund…        132        109   82.6     75.2       88.1
#> # ℹ 14 more rows
#> # ℹ 3 more variables: adj_percent <dbl>, adj_low <dbl>, adj_high <dbl>
```
