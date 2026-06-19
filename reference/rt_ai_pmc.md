# Identify disclosure of generative-AI use from a PMC XML file.

Detects whether an article discloses the use (or non-use) of generative
AI or AI-assisted tools in preparing the manuscript, as required of
articles since 2023. The indicator is only evaluated for articles
published in 2023 or later; for earlier articles \`is_ai_pred\` is
\`NA\`.

## Usage

``` r
rt_ai_pmc(filename, remove_ns = F)
```

## Arguments

- filename:

  The filename of the PMC XML file to analyze.

- remove_ns:

  TRUE if an XML namespace exists, else FALSE (default).

## Value

A tibble with the article IDs, the publication \`year\`, whether an AI
disclosure was found (\`is_ai_pred\`, \`NA\` before 2023), the matched
statement (\`ai_text\`) and \`is_success\`.

## Examples

``` r
if (FALSE) { # \dontrun{
filepath <- system.file(
  "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency"
)
rt_ai_pmc(filepath, remove_ns = TRUE)
} # }
```
