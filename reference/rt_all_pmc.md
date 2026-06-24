# Identify and extract all transparency indicators from a PMC XML.

Takes a PMC XML and returns relevant meta-data, as well as whether the
article carries each of the ten transparency indicators: Conflicts of
Interest (COI), Funding, Protocol Registration, Novelty, Replication,
Data sharing, Code sharing, disclosure of generative-AI use, Open-access
licensing and Reporting-guideline use. Where a statement is found, the
relevant text is also extracted. This is the single-call entry point; it
covers the same data and code detection as \[rt_data_code_pmc()\], the
same AI detection as \[rt_ai_pmc()\], the same licensing detection as
\[rt_oa_pmc()\] and the same reporting-guideline detection as
\[rt_reporting_pmc()\].

## Usage

``` r
rt_all_pmc(filename, remove_ns = F, all_meta = F)
```

## Arguments

- filename:

  The name of the PMC XML as a string.

- remove_ns:

  TRUE if an XML namespace exists, else FALSE (default).

- all_meta:

  TRUE extracts all meta-data, FALSE extracts some (default).

## Value

A dataframe of results. It returns the unique identifiers of the
article, whether each indicator of transparency was identified
(\`is_coi_pred\`, \`is_fund_pred\`, \`is_register_pred\`,
\`is_novelty_pred\`, \`is_replication_pred\`, \`is_open_data\`,
\`is_open_code\`, the year-gated \`is_ai_pred\`, \`is_open_access\` with
the \`oa_license\`, and \`is_reporting_pred\` with the named
\`reporting_guideline\`), the relevant text identified, whether it was
identified through a dedicated XML tag (such variables include "pmc" in
their name, e.g. “fund_pmc_source”) and whether each labelling function
identified relevant text or not. The labeling functions are returned to
add flexibility in how this package is used; for example, future
definitions of Registration may differ from the one we used. If a
labelling function returns NA it means that it was not run.
\`is_ai_pred\` is \`NA\` for articles published before 2023 (see
\[rt_ai_pmc()\]).

## Examples

``` r
if (FALSE) { # \dontrun{
# Path to PMC XML.
filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.xml"

# Identify and extract meta-data and indicators of transparency.
results_table <- rt_all_pmc(filepath, remove_ns = T, all_meta = T)
} # }
```
