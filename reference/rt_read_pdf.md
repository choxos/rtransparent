# Convert a PDF file to text.

Takes a path to a PDF file and returns its text content as a single
character string, extracted with the poppler \`pdftotext\` utility (the
same extractor the original \`oddpub\` package relied on, implemented
here as a standard system call). Different extractors format text
differently; the detectors in this package were tuned to the layout
\`pdftotext\` produces. To analyze the result with the plain-text
detectors, write it to a \`.txt\` file first (see Examples).

## Usage

``` r
rt_read_pdf(filepath)
```

## Arguments

- filepath:

  The path to the PDF file as a string (must end in \`.pdf\`).

## Value

A character string with the extracted text.

## Examples

``` r
if (FALSE) { # \dontrun{
# Path to a PDF file.
pdf_path <- system.file(
  "extdata", "PMID32171256-PMC7071725.pdf", package = "rtransparency"
)

# Extract the text, write it to a TXT file, then run the detectors.
article_txt <- rt_read_pdf(pdf_path)
writeLines(article_txt, "article.txt")
rt_coi("article.txt")
} # }
```
