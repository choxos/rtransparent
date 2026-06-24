# Identify the open-access status and reuse license from a TXT file.

The plain-text counterpart of \[rt_oa_pmc()\]. It detects an open-access
declaration and a Creative Commons license from the article text (for
example a "This is an open access article distributed under the terms of
the Creative Commons Attribution License" statement). Plain text lacks
the structured JATS \`\<license\>\` element, so detection relies on the
prose and any license URL it contains.

## Usage

``` r
rt_oa(filename)
```

## Arguments

- filename:

  The name of the TXT file as a string.

## Value

A tibble with the filename, the PMID (if present in the file name),
whether the article is openly licensed (\`is_open_access\`), the
canonical license (\`oa_license\`) and the license statement
(\`oa_text\`).

## See also

\[rt_oa_pmc()\] for the PMC XML detector.

## Examples

``` r
if (FALSE) { # \dontrun{
rt_oa("article.txt")
} # }
```
