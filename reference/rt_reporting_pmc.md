# Identify use of a reporting guideline from a PMC XML file.

Detects whether an article states that it followed a reporting guideline
(the EQUATOR-network checklists such as CONSORT, PRISMA, STROBE, ARRIVE,
STARD, TRIPOD, COREQ, SQUIRE, CHEERS) and which one. Detection is
precision-first: a guideline acronym is counted only when it appears in
a reporting context (a reporting or adherence verb, or a guideline noun
such as "statement", "checklist" or "guideline"), so a bare citation
does not count.

## Usage

``` r
rt_reporting_pmc(filename, remove_ns = F)
```

## Arguments

- filename:

  The filename of the PMC XML file to analyze.

- remove_ns:

  TRUE if an XML namespace exists, else FALSE (default).

## Value

A tibble with the article IDs, whether a reporting-guideline statement
was found (\`is_reporting_pred\`), the guideline(s) named
(\`reporting_guideline\`), the matched statement (\`reporting_text\`)
and \`is_success\`.

## Examples

``` r
if (FALSE) { # \dontrun{
filepath <- system.file(
  "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency"
)
rt_reporting_pmc(filepath, remove_ns = TRUE)
} # }
```
