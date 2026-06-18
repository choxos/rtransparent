# Summarizing transparency across a corpus

The detector functions
([`rt_all_pmc()`](https://choxos.github.io/rtransparent/reference/rt_all_pmc.md),
[`rt_data_code_pmc()`](https://choxos.github.io/rtransparent/reference/rt_data_code_pmc.md))
describe **one article at a time**. Most studies of research
transparency instead ask corpus-level questions: across thousands of
articles, how often is each practice present? Is it improving over time?
Does it differ by journal or article type?

This vignette shows how to go from per-article detector output to that
kind of summary, using
[`rt_summary()`](https://choxos.github.io/rtransparent/reference/rt_summary.md),
[`rt_score()`](https://choxos.github.io/rtransparent/reference/rt_score.md)
and
[`rt_plot()`](https://choxos.github.io/rtransparent/reference/rt_plot.md).

## From one article to many

Running a detector on a single article returns a one-row table of
indicators:

``` r

library(rtransparent)
#> rtransparent 0.8.1: identify indicators of transparency (conflicts of interest, funding,
#> protocol registration, novelty, replication, and data and code sharing) in
#> biomedical articles. GitHub: https://github.com/choxos/rtransparent | vignette("rtransparent")

xml <- system.file(
  "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparent"
)
one <- rt_all_pmc(xml, remove_ns = TRUE)
one[, c("pmid", "is_coi_pred", "is_fund_pred", "is_register_pred")]
#> # A tibble: 1 × 4
#>   pmid     is_coi_pred is_fund_pred is_register_pred
#>   <chr>    <lgl>       <lgl>        <lgl>           
#> 1 32171256 TRUE        TRUE         FALSE
```

To study a corpus you run a detector over many files and stack the rows
(for example with
[`rt_data_code_pmc_list()`](https://choxos.github.io/rtransparent/reference/rt_data_code_pmc_list.md),
or `purrr::map_dfr(files, rt_all_pmc)`). The result is one row per
article with the indicator columns `is_coi_pred`, `is_fund_pred`,
`is_register_pred`, `is_open_data`, `is_open_code` (and
`is_novelty_pred`, `is_replication_pred`).

This package ships a small **simulated** table of that shape, `rt_demo`,
so the rest of the vignette runs without downloading anything:

``` r

data(rt_demo)
head(rt_demo)
#> # A tibble: 6 × 10
#>   pmid      year type     is_coi_pred is_fund_pred is_register_pred is_open_data
#>   <chr>    <int> <chr>    <lgl>       <lgl>        <lgl>            <lgl>       
#> 1 38281623  2011 researc… FALSE       TRUE         FALSE            FALSE       
#> 2 35191245  2014 researc… TRUE        FALSE        FALSE            FALSE       
#> 3 37613201  2022 researc… TRUE        TRUE         FALSE            TRUE        
#> 4 27960187  2021 researc… FALSE       FALSE        FALSE            FALSE       
#> 5 27740712  2024 researc… TRUE        TRUE         TRUE             FALSE       
#> 6 26032088  2010 review-… FALSE       FALSE        FALSE            FALSE       
#> # ℹ 3 more variables: is_open_code <lgl>, is_novelty_pred <lgl>,
#> #   is_replication_pred <lgl>
```

## Prevalence of each indicator

[`rt_summary()`](https://choxos.github.io/rtransparent/reference/rt_summary.md)
reports, for each indicator, how many articles were assessed, how many
were positive, the apparent prevalence and its 95% confidence interval:

``` r

s <- rt_summary(rt_demo)
knitr::kable(
  s[, c("label", "n_articles", "n_detected", "percent", "conf_low", "conf_high")],
  digits = 1,
  col.names = c("Indicator", "Assessed", "Detected", "%", "CI low", "CI high")
)
```

| Indicator             | Assessed | Detected |    % | CI low | CI high |
|:----------------------|---------:|---------:|-----:|-------:|--------:|
| Conflicts of interest |     1200 |      835 | 69.6 |   66.9 |    72.1 |
| Funding disclosure    |     1200 |      948 | 79.0 |   76.6 |    81.2 |
| Protocol registration |     1200 |      318 | 26.5 |   24.1 |    29.1 |
| Data sharing          |     1200 |      201 | 16.8 |   14.7 |    19.0 |
| Code sharing          |     1200 |      101 |  8.4 |    7.0 |    10.1 |
| Novelty               |     1200 |      596 | 49.7 |   46.8 |    52.5 |
| Replication           |     1200 |      109 |  9.1 |    7.6 |    10.8 |

### Correcting for detector error

A text-mining detector is not perfect, so the **observed** prevalence is
a biased estimate of the **true** prevalence.
[`rt_summary()`](https://choxos.github.io/rtransparent/reference/rt_summary.md)
corrects for this using each detector’s sensitivity and specificity
estimates (the Rogan-Gladen estimator). The correction is on by default
and adds `adj_percent`, `adj_low` and `adj_high`:

``` r

knitr::kable(
  s[, c("label", "percent", "adj_percent", "adj_low", "adj_high")],
  digits = 1,
  col.names = c("Indicator", "Apparent %", "Corrected %", "CI low", "CI high")
)
```

| Indicator             | Apparent % | Corrected % | CI low | CI high |
|:----------------------|-----------:|------------:|-------:|--------:|
| Conflicts of interest |       69.6 |        70.0 |   67.3 |    72.6 |
| Funding disclosure    |       79.0 |        78.8 |   76.4 |    81.1 |
| Protocol registration |       26.5 |        27.5 |   25.0 |    30.2 |
| Data sharing          |       16.8 |        20.9 |   18.2 |    23.8 |
| Code sharing          |        8.4 |         9.0 |    7.4 |    11.0 |
| Novelty               |       49.7 |          NA |     NA |      NA |
| Replication           |        9.1 |          NA |     NA |      NA |

The accuracy values come from
[`rt_accuracy`](https://choxos.github.io/rtransparent/reference/rt_accuracy.md):

``` r

rt_accuracy
#> # A tibble: 5 × 5
#>   variable         label                 sensitivity specificity source         
#>   <chr>            <chr>                       <dbl>       <dbl> <chr>          
#> 1 is_coi_pred      Conflicts of interest       0.992       0.995 Serghiou et al…
#> 2 is_fund_pred     Funding disclosure          0.997       0.981 Serghiou et al…
#> 3 is_register_pred Protocol registration       0.955       0.997 Serghiou et al…
#> 4 is_open_data     Data sharing                0.765       0.99  rtransparent n…
#> 5 is_open_code     Code sharing                0.881       0.995 rtransparent n…
```

Novelty and replication have no bundled accuracy estimates here, so
their corrected values are `NA`. The data/code values are reproducible
benchmark estimates for the native detector, not untouched
external-validation estimates. To use your own validation (or the
published `oddpub` values for data and code), pass any table with
`variable`, `sensitivity` and `specificity` columns:

``` r

my_acc <- rt_accuracy
my_acc$sensitivity[my_acc$variable == "is_open_data"] <- 0.758
rt_summary(rt_demo, indicators = "is_open_data", accuracy = my_acc)[,
  c("label", "percent", "adj_percent")]
#> # A tibble: 1 × 3
#>   label        percent adj_percent
#>   <chr>          <dbl>       <dbl>
#> 1 Data sharing    16.8        21.1
```

## How many practices per article

[`rt_score()`](https://choxos.github.io/rtransparent/reference/rt_score.md)
adds a per-article count of the openness practices met (conflicts of
interest, funding, registration, data and code). Tabulating it shows how
many articles meet zero, one, two … of the five practices:

``` r

scored <- rt_score(rt_demo)
knitr::kable(
  as.data.frame(table(`Practices met` = scored$n_indicators)),
  col.names = c("Practices met", "Articles")
)
```

| Practices met | Articles |
|:--------------|---------:|
| 0             |       56 |
| 1             |      288 |
| 2             |      530 |
| 3             |      255 |
| 4             |       65 |
| 5             |        6 |

## Subgroups

Pass `by` to summarize within a grouping column, such as article type:

``` r

by_type <- rt_summary(rt_demo, by = "type", adjust = FALSE)
knitr::kable(
  by_type[by_type$indicator == "is_open_data",
          c("type", "label", "n_articles", "percent")],
  digits = 1,
  col.names = c("Type", "Indicator", "Assessed", "%")
)
```

| Type              | Indicator    | Assessed |    % |
|:------------------|:-------------|---------:|-----:|
| research-article  | Data sharing |      854 | 16.2 |
| review-article    | Data sharing |      227 | 18.5 |
| systematic-review | Data sharing |      119 | 17.6 |

## Plots

[`rt_plot()`](https://choxos.github.io/rtransparent/reference/rt_plot.md)
returns a `ggplot`, so it composes with the usual ggplot2 layers. The
default is a prevalence bar chart:

``` r

library(ggplot2)
rt_plot(rt_demo) + ggtitle("Transparency indicators in rt_demo")
```

![Bar chart of the prevalence of each transparency
indicator](transparency-summary_files/figure-html/unnamed-chunk-10-1.png)

Use `type = "trend"` with a year column to see prevalence over time:

``` r

rt_plot(rt_demo, type = "trend", year = "year")
```

![Line chart of each transparency indicator's prevalence by
year](transparency-summary_files/figure-html/unnamed-chunk-11-1.png)

Set `adjusted = TRUE` in either plot to show the error-corrected
prevalence instead of the apparent prevalence.

## Putting it together

A typical analysis is therefore: run a detector over your corpus, stack
the rows, then

``` r

results <- purrr::map_dfr(xml_files, rt_all_pmc, remove_ns = TRUE)
rt_summary(results)                       # prevalence + corrected prevalence
rt_score(results)                         # per-article practice count
rt_plot(results, type = "trend", year = "year")
```

For the per-indicator detection methodology, see
[`vignette("rtransparent")`](https://choxos.github.io/rtransparent/articles/rtransparent.md).
