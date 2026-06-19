# Extract article metadata from a PMC XML file.

Reads a PMC XML file and returns its metadata as a one-row data frame:
journal, publisher, article title, authors and affiliations, identifiers
(PMID, PMCID, DOI), publication dates, and figure / table / reference
counts.

## Usage

``` r
rt_meta_pmc(filename, remove_ns = F)
```

## Arguments

- filename:

  The path to the PMC XML file as a string.

- remove_ns:

  TRUE if an XML namespace should be removed, else FALSE (default).

## Value

A one-row tibble of metadata. The column \`is_success\` indicates
whether the file was parsed successfully.

## Examples

``` r
if (FALSE) { # \dontrun{
filepath <- system.file(
  "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency"
)
rt_meta_pmc(filepath, remove_ns = TRUE)
} # }
```
