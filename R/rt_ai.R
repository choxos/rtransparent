# Detect disclosure of generative-AI / large-language-model use.
#
# Since 2023, journals and publishers (ICMJE, COPE, Elsevier, Springer Nature,
# Frontiers, ...) ask authors to disclose whether generative AI or AI-assisted
# tools were used in preparing a manuscript. This indicator detects the presence
# of such a disclosure (positive "we used ChatGPT ..." or negative "no
# generative AI was used ..."). Because the practice did not exist before 2023,
# the indicator is only evaluated for articles published in 2023 or later;
# earlier articles return NA.


# Generative-AI tools and an AI-disclosure / manuscript-preparation context, in
# the same sentence; an abbreviation-list / method veto removes papers that
# merely study or use AI as their method.
.detect_ai_disclosure <- function(text) {

  out <- list(is_ai_disclosed = FALSE, ai_text = "")
  if (!length(text)) return(out)

  s <- .dc_split(text)
  s <- s[nchar(trimws(s)) > 0]
  if (!length(s)) return(out)

  ai_term <- paste(
    "generative (ai|artificial intelligence)", "\\bgen-?ai\\b",
    "chatgpt", "\\bgpt-?[0-9]", "gpt-4o", "\\bllms?\\b",
    "large language models?",
    "ai-(assisted|generated|based) (tool|technolog|writ|languag|imag|content)",
    "ai-assisted technolog", "\\bcopilot\\b", "\\bclaude\\b", "\\bgemini\\b",
    "\\bbard\\b", "dall-?e", "midjourney", "stable diffusion", "\\bgrok\\b",
    "deepseek", "\\bllama\\b", "mistral", "mixtral", "\\bperplexity\\b",
    "\\bqwen\\b", "\\bgemma\\b", "\\bllm-?[0-9]", "\\bpalm 2\\b",
    "pathways language model", "ernie bot", "\\bdeepl\\b", "paperpal",
    "quillbot", "writefull", "wordtune", "jasper ai", "writesonic",
    "\\bsora\\b",
    # Bare "AI tool" / "artificial intelligence" only matters here because the
    # extracted text is restricted to declaration / acknowledgment sections,
    # where these refer to manuscript-preparation AI use, not a research method.
    "\\bai tools?\\b", "\\bartificial intelligence\\b", "\\bai\\b (was|were) (not )?used",
    sep = "|"
  )

  ctx <- paste(
    # AI used/using/refined/etc. tied to a manuscript / writing / figure object.
    paste0("(used|using|utiliz(ed|ing)|employ(ed|ing)|adopt(ed|ing)|",
           "assisted by|with the (help|aid|assistance|use) of|",
           "created (with|using)|generated (with|using)|refined|edited|",
           "improved|enhanced|polished|proofread|paraphrased|checked)",
           "[^.]{0,75}",
           "(manuscript|text|language(?!s? ?model)|writing|written|readabilit|",
           "grammar|grammatic|wording|clarity|concise|editing|proofread|english|",
           "paraphras|figure|image|illustration|graphic|abstract|translation)"),
    # explicit declaration / negation forms.
    "declaration of (generative )?ai", "declared that",
    "authors? (used|declare|confirm|did not)",
    "did not use", "\\buse of\\b",
    "(no|not|never) [^.]{0,25}(ai|generative|llm)[^.]{0,25}(used|tool|technolog|declared)",
    "(was|were) (not )?used in[^.]{0,40}(manuscript|writing|preparation|creation|work)",
    "(generative ai|ai-assisted technolog|ai-generated (image|content))[^.]{0,40}(was|were) (not )?used",
    "in the (writing|preparation|creation|production|editing|drafting) of (this|the)",
    "(preparation|creation|production) of (this|the) (manuscript|work|paper)",
    "ai-generated (image|figure|content)",
    sep = "|"
  )

  # Abbreviation lists ("AI, artificial intelligence; LLM, large language
  # model") and similar appear in AI-method papers, not as disclosures.
  veto <- paste(
    "\\bai, artificial intelligence\\b",
    "llm,? large language model",
    ", large language model;",
    "artificial intelligence \\(ai\\),",
    sep = "|"
  )

  hit <- grepl(ai_term, s, ignore.case = TRUE, perl = TRUE) &
    grepl(ctx, s, ignore.case = TRUE, perl = TRUE) &
    !grepl(veto, s, ignore.case = TRUE, perl = TRUE)

  if (any(hit)) {
    out$is_ai_disclosed <- TRUE
    out$ai_text <- paste(s[hit], collapse = " | ")
  }
  out
}


# Earliest publication year (epub/ppub/collection) as an integer, or NA.
.get_pub_year <- function(article_xml) {
  yrs <- article_xml %>%
    xml2::xml_find_all(".//front/article-meta//pub-date//year | .//front/article-meta//pub-date/year") %>%
    xml2::xml_text() %>%
    as.integer()
  yrs <- yrs[!is.na(yrs) & yrs > 1900 & yrs < 2100]
  if (!length(yrs)) return(NA_integer_)
  min(yrs)
}


# Sections where an AI-use disclosure is found: back matter, footnotes,
# acknowledgments, author notes, custom-meta and declaration/AI sections. The
# main body is deliberately excluded to avoid AI-method articles.
.ai_article_text <- function(article_xml) {
  lc <- function(kw) {
    paste0(".//sec[contains(translate(title,",
           "'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'),",
           "'", kw, "')]//p")
  }
  # Back matter, footnotes, acknowledgments and any section whose title marks it
  # as a declaration/disclosure of AI use. The main body is excluded so that
  # articles which use AI as their research method are not flagged.
  sec_kw <- c("declaration", "disclosure", "generative",
              "artificial intelligence", "ai-assisted", "ai-generated")
  xp <- paste(
    c(".//back//p", ".//back//fn", ".//fn", ".//author-notes", ".//ack",
      ".//notes", ".//custom-meta", vapply(sec_kw, lc, character(1))),
    collapse = " | "
  )
  nodes <- tryCatch(xml2::xml_find_all(article_xml, xp), error = function(e) NULL)
  if (is.null(nodes) || !length(nodes)) return(character(0))
  xml2::xml_text(nodes)
}


#' Identify disclosure of generative-AI use from a PMC XML file.
#'
#' Detects whether an article discloses the use (or non-use) of generative AI or
#' AI-assisted tools in preparing the manuscript, as required of articles since
#' 2023. The indicator is only evaluated for articles published in 2023 or
#' later; for earlier articles `is_ai_pred` is `NA`.
#'
#' @param filename The filename of the PMC XML file to analyze.
#' @param remove_ns TRUE if an XML namespace exists, else FALSE (default).
#' @return A tibble with the article IDs, the publication `year`, whether an AI
#'   disclosure was found (`is_ai_pred`, `NA` before 2023), the matched
#'   statement (`ai_text`) and `is_success`.
#' @examples
#' \dontrun{
#' filepath <- system.file(
#'   "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency"
#' )
#' rt_ai_pmc(filepath, remove_ns = TRUE)
#' }
#' @export
rt_ai_pmc <- function(filename, remove_ns = F) {

  article_xml <- tryCatch(.get_xml(filename, remove_ns), error = function(e) e)
  if (inherits(article_xml, "error")) {
    return(tibble::tibble(filename = filename, is_success = FALSE))
  }

  id_ls <- .get_ids(article_xml)
  id_ls$filename <- filename
  year <- .get_pub_year(article_xml)

  ai <- .get_ai_pmc(article_xml, year)

  tibble::as_tibble(c(id_ls, ai, list(is_success = TRUE)))
}


#' Identify disclosure of generative-AI use from a TXT file.
#'
#' Detects whether an article discloses the use (or non-use) of generative AI or
#' AI-assisted tools in preparing the manuscript, from a plain-text (typically
#' PDF-derived) file. Unlike [rt_ai_pmc()] it applies **no publication-year
#' gate**: a plain-text file carries no reliable publication date, so `is_ai_pred`
#' is always `TRUE` or `FALSE` (never `NA`). AI-use disclosure became an expected
#' practice only in 2023, so the caller is responsible for restricting analysis
#' to articles from 2023 onward. Plain text also lacks the section structure the
#' PMC detector uses to confine the scan to back matter, acknowledgments and
#' declaration sections, so an article that uses AI purely as a research method
#' is more likely to be flagged than under [rt_ai_pmc()].
#'
#' @param filename The name of the TXT file as a string.
#' @return A tibble with the filename, the PMID (if present in the file name),
#'   whether an AI-use disclosure was found (`is_ai_pred`) and the matched
#'   statement (`ai_text`).
#' @examples
#' \dontrun{
#' # Path to a TXT file.
#' filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.txt"
#'
#' # Identify and extract an AI-use disclosure.
#' rt_ai(filepath)
#' }
#' @seealso [rt_ai_pmc()] for the PMC XML detector, which applies the 2023
#'   publication-year gate.
#' @export
rt_ai <- function(filename) {

  article <- basename(filename)
  pmid <- gsub("^.*PMID([0-9]+).*$", "\\1", filename)

  paper_text <- .read_txt(filename)

  # Rejoin words hyphenated across a line break ("Chat-\nGPT" -> "ChatGPT") so a
  # tool name split by the PDF-to-text conversion is still matched; .dc_split
  # collapses the remaining whitespace before sentence-splitting.
  paper_text <- gsub("([A-Za-z0-9])-\\s*\n\\s*([A-Za-z0-9])", "\\1\\2", paper_text)

  found <- .detect_ai_disclosure(paper_text)

  tibble::as_tibble(list(
    article = article,
    pmid = pmid,
    is_ai_pred = found$is_ai_disclosed,
    ai_text = found$ai_text
  ))
}


# A section titled as a generative-AI declaration is itself a disclosure, even
# when the body is minimal ("Not applicable", "no AI was used") or garbled.
.ai_declaration_section <- function(article_xml) {
  titles <- article_xml %>%
    xml2::xml_find_all(".//sec/title | .//boxed-text/caption/title") %>%
    xml2::xml_text() %>%
    tolower()
  if (!length(titles)) return("")
  pat <- paste(
    # Unconditional disclosure-section headers.
    "(declaration|disclosure|statement) of (generative )?(ai|artificial intelligence|large language model)",
    # A section explicitly titled as a statement on the use of AI is itself a
    # disclosure ("Statement on the use of artificial intelligence").
    paste0("(statement|declaration|note|section) on (the )?use of (generative )?",
           "(ai|artificial intelligence|large language models?|llms?|chatgpt|ai-assisted)"),
    "generative ai (and|in|use|statement)",
    "ai(-| )assisted (technolog|tool)",
    "ai (use )?(statement|disclosure|declaration)",
    # "use of AI" only when tied to writing / the manuscript (a disclosure),
    # not as an AI-method topic section.
    paste0("(use of|using) (large language models?|llms?|generative ai|",
           "ai|artificial intelligence|chatgpt)[^.]{0,40}",
           "(writ|manuscript|language|preparation|assist|editing|grammar|readabilit)"),
    "(generative )?ai[^.]{0,30}(in (the )?writing|writing process|manuscript preparation)",
    sep = "|"
  )
  hit <- grepl(pat, titles, perl = TRUE)
  if (any(hit)) titles[hit][1] else ""
}


# Internal: compute the AI-disclosure fields, applying the 2023 year gate.
.get_ai_pmc <- function(article_xml, year = NULL) {
  if (is.null(year)) year <- .get_pub_year(article_xml)
  found <- .detect_ai_disclosure(.ai_article_text(article_xml))
  sec_title <- .ai_declaration_section(article_xml)
  is_disclosed <- found$is_ai_disclosed || nchar(sec_title) > 0
  ai_text <- if (nchar(found$ai_text) > 0) found$ai_text else sec_title
  is_ai_pred <- if (is.na(year) || year < 2023) NA else is_disclosed
  list(year = year, is_ai_pred = is_ai_pred, ai_text = ai_text)
}
