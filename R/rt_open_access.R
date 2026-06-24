# Detect the open-access status and reuse license of an article.
#
# The reuse-relevant transparency signal is not merely whether an article is
# open access (close to tautological for the PMC open-access subset) but the
# LICENSE under which it is released: a permissive Creative Commons license
# (CC BY, CC0) allows text and data mining and redistribution, whereas a
# restrictive license (NC / ND) or retained copyright does not. This is the
# reuse ("R") dimension of FAIR, at the article level.


# Canonical license identifier from a license URL and/or license text. Returns
# "" when no recognizable open license is present.
.classify_license <- function(x) {
  if (!length(x)) return("")
  s <- tolower(paste(x, collapse = " "))
  s <- gsub("[[:space:]]+", " ", s)
  if (!nzchar(trimws(s))) return("")

  # 1) A Creative Commons "licenses/<elems>/<version>" URL is the actual article
  # license. Read it FIRST, before any CC0 check: many CC-BY articles also carry
  # a boilerplate CC0 public-domain waiver for the data, which must not override
  # the article's own license.
  m <- regmatches(s, regexpr("creativecommons\\.org/licenses/[a-z-]+(/[0-9]\\.[0-9])?", s))
  if (length(m)) {
    elems <- sub(".*licenses/([a-z-]+).*", "\\1", m[1])
    ver <- regmatches(m[1], regexpr("[0-9]\\.[0-9]", m[1]))
    return(paste0("CC-", toupper(elems), if (length(ver)) paste0("-", ver) else ""))
  }

  # 2) CC0 / public-domain dedication (only when there is no by-family license).
  if (grepl("creativecommons\\.org/publicdomain/zero|\\bcc0\\b|public domain dedication", s)) {
    return("CC0-1.0")
  }

  # 3) Infer a Creative Commons license from the prose when no URL is present.
  if (grepl("creative commons|\\bcc[ -]?by\\b", s)) {
    elems <- "by"
    if (grepl("non[ -]?commercial|\\bby[ -]?nc\\b", s)) elems <- paste0(elems, "-nc")
    if (grepl("no[ -]?deriv|\\bnd\\b", s))               elems <- paste0(elems, "-nd")
    if (grepl("share[ -]?alike|\\bsa\\b", s))            elems <- paste0(elems, "-sa")
    ver <- regmatches(s, regexpr("[0-9]\\.[0-9]", s))
    return(paste0("CC-", toupper(elems), if (length(ver)) paste0("-", ver) else ""))
  }

  ""
}


# Detect open-access status and license from text and an optional license URL.
.detect_open_access <- function(text, license_url = character(0)) {
  out <- list(is_open_access = FALSE, oa_license = "", oa_text = "")

  txt <- paste(c(text, license_url), collapse = " ")
  if (!nzchar(trimws(txt))) return(out)

  license <- .classify_license(c(text, license_url))
  low <- tolower(txt)

  # An explicit ARTICLE-level open-access declaration, even without a named CC
  # license. This must describe the article's own license, not data/code/
  # supplement availability ("freely available") or open-access *funding* (an
  # article-processing-charge / Projekt DEAL / read-and-publish statement), both
  # of which are common in otherwise copyrighted articles.
  declared_oa <- grepl(
    paste(
      "this is an open[ -]access article",
      "open[ -]access article (that is |which is )?(been )?distributed under",
      "(article|work) is (made )?(freely )?(available as|published) open[ -]access under",
      "under (a|the) creative commons",
      sep = "|"
    ),
    low, perl = TRUE
  )
  oa_funding <- grepl(
    paste(
      "open[ -]access (funding|fee|fees|charge|charges|publication (charge|fee)|costs?)",
      "article[ -]processing[ -]charge", "\\bapc\\b", "projekt deal",
      "read[ -]and[ -]publish", "transformative agreement",
      sep = "|"
    ),
    low, perl = TRUE
  )

  # A permissive CC / CC0 license is open access; a strict article-level OA
  # declaration also counts. Open-access *funding* language alone does not, and
  # retained-copyright text with no open license is not.
  out$is_open_access <- nzchar(license) || (declared_oa && !oa_funding)
  out$oa_license <- license

  if (out$is_open_access) {
    # Prefer the licensing sentence(s) as the returned text.
    out$oa_text <- trimws(paste(text, collapse = " "))
    if (!nzchar(out$oa_text)) out$oa_text <- paste(license_url, collapse = " ")
  }
  out
}


# Extract the license statement text and any license-ref URL from a PMC XML.
.get_oa_pmc <- function(article_xml) {
  license_text <- .get_text(article_xml, "front/article-meta//license", FALSE)

  # The license URL lives on the <license> href, a <license-ref>, or an
  # <ext-link> inside the license (namespaces are stripped when remove_ns = TRUE,
  # so xlink:href becomes href; @*[...] also catches the namespaced form).
  url_nodes <- tryCatch(
    xml2::xml_find_all(
      article_xml,
      paste(
        ".//front/article-meta//license/@*[local-name()='href']",
        ".//front/article-meta//license-ref",
        ".//front/article-meta//license//ext-link/@*[local-name()='href']",
        sep = " | "
      )
    ),
    error = function(e) NULL
  )
  license_url <- if (length(url_nodes)) xml2::xml_text(url_nodes) else character(0)

  found <- .detect_open_access(license_text, license_url)
  list(
    is_open_access = found$is_open_access,
    oa_license = found$oa_license,
    oa_text = found$oa_text
  )
}


#' Identify the open-access status and reuse license of a PMC XML file.
#'
#' Detects whether an article is openly licensed and, when it is, the canonical
#' license identifier (for example `CC-BY-4.0`, `CC-BY-NC-4.0`, `CC0-1.0`). The
#' license is read from the JATS `<permissions>`/`<license>` element and its
#' license reference URL. This is the article-level reuse signal (the "R" in
#' FAIR): a permissive license (CC BY, CC0) allows redistribution and text and
#' data mining, whereas a restrictive license (NC / ND) or retained copyright
#' does not.
#'
#' @param filename The filename of the PMC XML file to analyze.
#' @param remove_ns TRUE if an XML namespace exists, else FALSE (default).
#' @return A tibble with the article IDs, whether the article is openly licensed
#'   (`is_open_access`), the canonical license (`oa_license`, `""` when none is
#'   found), the license statement (`oa_text`) and `is_success`.
#' @examples
#' \dontrun{
#' filepath <- system.file(
#'   "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency"
#' )
#' rt_oa_pmc(filepath, remove_ns = TRUE)
#' }
#' @export
rt_oa_pmc <- function(filename, remove_ns = F) {

  article_xml <- tryCatch(.get_xml(filename, remove_ns), error = function(e) e)
  if (inherits(article_xml, "error")) {
    return(tibble::tibble(filename = filename, is_success = FALSE))
  }

  id_ls <- .get_ids(article_xml)
  id_ls$filename <- filename
  oa <- .get_oa_pmc(article_xml)

  tibble::as_tibble(c(id_ls, oa, list(is_success = TRUE)))
}


#' Identify the open-access status and reuse license from a TXT file.
#'
#' The plain-text counterpart of [rt_oa_pmc()]. It detects an open-access
#' declaration and a Creative Commons license from the article text (for example
#' a "This is an open access article distributed under the terms of the Creative
#' Commons Attribution License" statement). Plain text lacks the structured JATS
#' `<license>` element, so detection relies on the prose and any license URL it
#' contains.
#'
#' @param filename The name of the TXT file as a string.
#' @return A tibble with the filename, the PMID (if present in the file name),
#'   whether the article is openly licensed (`is_open_access`), the canonical
#'   license (`oa_license`) and the license statement (`oa_text`).
#' @examples
#' \dontrun{
#' rt_oa("article.txt")
#' }
#' @seealso [rt_oa_pmc()] for the PMC XML detector.
#' @export
rt_oa <- function(filename) {

  article <- basename(filename)
  pmid <- gsub("^.*PMID([0-9]+).*$", "\\1", filename)

  paper_text <- .read_txt(filename)
  found <- .detect_open_access(paper_text)

  tibble::as_tibble(list(
    article = article,
    pmid = pmid,
    is_open_access = found$is_open_access,
    oa_license = found$oa_license,
    oa_text = substr(found$oa_text, 1, 500)
  ))
}
