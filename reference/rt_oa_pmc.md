# Identify the open-access status and reuse license of a PMC XML file.

Detects whether an article is openly licensed and, when it is, the
canonical license identifier (for example \`CC-BY-4.0\`,
\`CC-BY-NC-4.0\`, \`CC0-1.0\`). The license is read from the JATS
\`\<permissions\>\`/\`\<license\>\` element and its license reference
URL. This is the article-level reuse signal (the "R" in FAIR): a
permissive license (CC BY, CC0) allows redistribution and text and data
mining, whereas a restrictive license (NC / ND) or retained copyright
does not.

## Usage

``` r
rt_oa_pmc(filename, remove_ns = F)
```

## Arguments

- filename:

  The filename of the PMC XML file to analyze.

- remove_ns:

  TRUE if an XML namespace exists, else FALSE (default).

## Value

A tibble with the article IDs, whether the article is openly licensed
(\`is_open_access\`), the canonical license (\`oa_license\`, \`""\` when
none is found), the license statement (\`oa_text\`) and \`is_success\`.

## Examples

``` r
if (FALSE) { # \dontrun{
filepath <- system.file(
  "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency"
)
rt_oa_pmc(filepath, remove_ns = TRUE)
} # }
```
