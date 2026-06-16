# Identify and extract Data and Code sharing from PMC XML files.

Takes a PMC XML file and returns data related to the presence of Data or
Code, including whether Data or Code have been shared. If Data or Code
exist, it will extract the relevant text for each. Detection is
performed by the native detector (`.detect_data_code`); the package no
longer depends on `oddpub` or `tokenizers`.

## Usage

``` r
rt_data_code_pmc(filename, remove_ns = T, specificity = "low")
```

## Arguments

- filename:

  The filename of the XML file to be analyzed as a string.

- remove_ns:

  TRUE if an XML namespace exists, else FALSE (default).

- specificity:

  Retained for backward compatibility; it no longer changes the result.
  The native detector extracts a fixed, broad set of article text (body
  paragraphs and titles, back matter, footnotes and supplements) and
  applies repository, accession and availability-statement patterns.

## Value

A dataframe of results: the unique IDs of the article, whether data or
code sharing was found (`is_open_data`, `is_open_code`) and, if so, the
statement text that triggered each detection (`open_data_statements`,
`open_code_statements`).

## Examples

``` r
if (FALSE) { # \dontrun{
# Path to PMC XML
filepath <- system.file(
  "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparent"
)

# Identify and extract indicators of data and code sharing
results_table <- rt_data_code_pmc(filepath, remove_ns = TRUE)
} # }
```
