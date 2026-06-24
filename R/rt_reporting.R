# Detect use of a reporting guideline (reporting transparency).
#
# A reporting guideline (the EQUATOR-network checklists: CONSORT for trials,
# PRISMA for systematic reviews, STROBE for observational studies, ARRIVE for
# animal research, and so on) standardizes what a study reports. Whether authors
# state that they followed one, and which, is a TOP-style transparency signal.
#
# Detection is precision-first: a guideline acronym counts only in a reporting
# context (a reporting/adherence verb or a guideline noun such as "statement",
# "checklist" or "guideline"), so a bare citation is not enough. Acronyms that
# are also common English words (CARE, SPIRIT, RECORD, AGREE, ORION) must sit
# directly next to a guideline noun.


# Full spelled-out guideline names. These are unambiguous on their own, so a
# match counts without any extra context. name = canonical acronym.
.reporting_spelled <- function() {
  c(
    PRISMA  = "preferred reporting items for systematic reviews?",
    CONSORT = "consolidated standards of reporting trials",
    STROBE  = "strengthening the reporting of observational studies|strengthening the reporting of (genetic |molecular )?(genetic )?association",
    COREQ   = "consolidated criteria for reporting qualitative",
    SRQR    = "standards for reporting qualitative research",
    STARD   = "standards for reporting of diagnostic accuracy",
    ARRIVE  = "animal research[ :,.-]{0,4}reporting of in vivo experiments",
    TRIPOD  = "transparent reporting of a multivariable prediction model",
    PROCESS = "preferred reporting of case series in surgery",
    STROCSS = "strengthening the reporting of cohort,? cross-?sectional and case-?control studies in surgery|strengthening the reporting of cohort studies in surgery",
    CHEERS  = "consolidated health economic evaluation reporting standards",
    SQUIRE  = "standards for quality improvement reporting excellence",
    RAMESES = "realist and meta-?narrative evidence syntheses|realist.{0,30}publication standards",
    ENTREQ  = "enhancing transparency in reporting the synthesis of qualitative",
    MOOSE   = "meta-?analysis of observational studies in epidemiology"
  )
}

# Acronyms essentially unique to reporting guidelines (no common-word collision).
# Counted when they co-occur with a reporting context in the same sentence.
.reporting_distinctive <- function() {
  c(
    CONSORT = "consort",
    PRISMA  = "prisma(?:[- ]?(?:p|scr|dta|ipd|nma|a|harms|ema|equity))?",
    STROBE  = "strobe(?:[- ]?mr)?",
    STREGA  = "strega",
    STARD   = "stard",
    SRQR    = "srqr",
    COREQ   = "coreq",
    TRIPOD  = "tripod",
    CHEERS  = "cheers",
    MOOSE   = "moose",
    ENTREQ  = "entreq",
    SQUIRE  = "squire",
    TIDieR  = "tidier",
    CHERRIES = "cherries",
    GRRAS   = "grras",
    MIAME   = "miame",
    ENCePP  = "encepp",
    SAMPL   = "sampl",
    STROCSS = "strocss",
    RAMESES = "rameses"
  )
}

# Acronyms that are also ordinary English words. To avoid false positives they
# are matched CASE-SENSITIVELY (the guideline is written upper-case) AND must sit
# directly beside a guideline noun. AGREE is excluded: it appraises clinical
# guidelines, it is not a study-reporting checklist.
.reporting_overloaded <- function() {
  c("ARRIVE", "CARE", "SPIRIT", "RECORD", "REMARK", "PROCESS", "ORION")
}

# The wider catalogue of EQUATOR reporting guidelines (acronyms five characters
# or longer, sourced from the reportilo guideline list, minus the ones above and
# minus tokens that are common English words / trial names). They are matched by
# the same conservative rule as the overloaded set: the upper-case acronym must
# sit directly beside a guideline noun, so the long tail adds coverage without
# costing precision.
.reporting_extra <- function() {
  strsplit(paste0(
    "ACURATE|ADVISHE|AGREHIIT|AGREMA|APOSTEL|ASTAIRE|BAYESWATCH|BEPRECISE|BIBLIO|",
    "BRISQ|BRIVAC|CARDA|CEDRIC|CHAIRS|CHECKAP|CHECKUP|CIRCLE|CLARIFY|CLIMBR|CLINIC|",
    "CLINPK|CLUDA|COBRA|CONFERD|CONMAPT|CONPHYMP|CONSERVE|CONTES|COPPS|CORDES|",
    "COSMIN|CREDECI|CREDES|CREMAIS|CREMAS|CRISPHE|DECIDE|DELPHISTAR|DELTA2|DEPICT|",
    "DOCTRINE|DOLBAPP|EBPQI|ELEVATE|EMOOD|ENLIGHT|EPACIR|EPIFORGE|GAMER|GIATE|",
    "GNOSIS|GRAMMS|GREENBEAN|GREOM|GRIPP2|GRIPS|GROESBE|GROLTS|GRONC|GUIDE4DBS|",
    "ICARUS|ICHECK|IMPRINT|ITRUSST|MEDINAI|MEDQUARG|MINIMAR|MORECARE|OBSQUAL|",
    "OHSTAT|PACIR|PHELIX|PHYCARE|PICOTS|PLIRT|POSORT|PRECISE|PRIASE|PRIBA|PRICSSA|",
    "PRIDASE|PRIDE|PRIOR|PRIPROID|PRIRATE|PRIRES|RAGEE|RANCARE|READUS|REGEMA|",
    "REHBAR|REPCAN|REPRISE|RIGHTCARE|RIMES|ROSES|RTARG|SAMBR|SIFHR|SONHR|STARBIV|",
    "STARCARDDS|STARDDEM|STARE|STARI|STARLITE|STORMS|STRADAS|STREIS|STRICTA|",
    "STRICTOC|STRICTOM|STRICTOTM|STRIVE|STROBOD|STROMA|STROME|STROND|STROPS|WIDER"
  ), "\\|")[[1]]
}

# A reporting / adherence context.
.reporting_context <- function() {
  paste(
    "report(ed|ing)?", "prepar(ed|ing)", "conduct(ed|ing)", "writ(ten|ing)",
    "present(ed|ing)", "perform(ed|ing)", "follow(ed|ing)", "adher(ed|ing|e|ence)",
    "complian(t|ce)", "conform(ed|ing|s)?", "in accordance with", "according to",
    "in line with", "in keeping with", "consistent with", "guided by",
    "using the", "based on the", "as per",
    "check-?list", "guideline", "statement", "reporting",
    "flow ?(diagram|chart)", "extension", "\\bequator\\b",
    # Spanish / Portuguese reporting cues (the acronyms are language-independent).
    "consistente con", "de acuerdo con", "seg[uu]n", "siguiendo",
    "teniendo en cuenta", "de acordo com", "seguindo", "metodolog",
    "lista de (chequeo|verificaci|checagem)", "segundo a", "conforme",
    sep = "|"
  )
}

# A guideline noun / version marker that an overloaded acronym must sit beside.
.reporting_noun <- function() {
  "(?i:guidelines?|statement|check-?list|criteria|reporting standards?|extension|flow ?(?:diagram|chart)|20[0-2][0-9])"
}

# Sentences that mention a guideline but do NOT mean the authors followed one:
# animal-welfare "care and use", explicit non-use, a need/absence statement, or
# describing the guidelines of the studies being reviewed.
.reporting_veto <- function() {
  paste(
    "care and use of",                                            # animal welfare
    "(could|was|were|is|are|been|cannot|can|did)\\s?n[o']t (be )?(use|used|appl|follow|possible|feasible)",
    "\\bnot (be )?(used|applied|followed|possible|feasible)\\b",
    "reporting (guidelines?|standards?|checklists?) (are|is|were|remain|will|should|may|can|could|might)? ?(be )?(needed|lacking|scarce|absent|important|essential|required|developed|advocated|recommended for future|warranted|improve|enhance|increase|promote|help|exist|provide)",
    # Discourse / background ABOUT a guideline, not the authors following it.
    "(is|are|remains?|was|were|provides?) (a |an |the )?(widely|commonly|frequently|well)[ -]?(used|established|known|accepted|recognized)",
    "^\\s*background\\b", "^\\s*introduction\\b",
    "guidelines? (improve|enhance|increase|promote|aim|help|exist|provide|were developed|are designed|have been)",
    # Assessing / extracting whether OTHER (reviewed) studies followed a guideline.
    "\\b(we|authors?|reviewers?) (extracted|assessed|evaluated|determined|checked|coded|recorded|examined|rated|appraised|judged)\\b[^.]{0,40}\\b(whether|if|adherence|compliance|reporting|completeness|quality|use of)",
    "(included|eligible|reviewed|primary|original|individual|selected|identified|retrieved|each) (studies|trials|articles|papers|reviews|reports|rcts|publications)\\b[^.]{0,60}(adher|follow|conform|comply|report(ed|ing)?|used|use of)",
    "(adherence|compliance|conformity|reporting (quality|completeness)) (to|with|of) .{0,40}(among|across|in|by|of) (the )?(included|eligible|reviewed|primary|original|identified)",
    "(reporting (quality|completeness)|risk of bias)\\b[^.]{0,40}(was|were) (assessed|evaluated|examined|rated|appraised|judged)",
    "(trials|studies) (that )?conform(ed|ing|s)? to",
    "reporting of the (reviewed|included|individual|primary) (trials|studies)",
    sep = "|"
  )
}


# Detect reporting-guideline use in a block of text. Returns whether a reporting
# statement was found, which guideline(s), and the matched sentence(s).
.detect_reporting <- function(text) {
  out <- list(is_reporting_pred = FALSE, reporting_guideline = "", reporting_text = "")
  if (!length(text)) return(out)

  s <- .dc_split(text)
  s <- s[nchar(trimws(s)) > 0]
  if (!length(s)) return(out)

  ctx      <- .reporting_context()
  noun     <- .reporting_noun()
  spelled  <- .reporting_spelled()
  distinct <- .reporting_distinctive()
  overload <- .reporting_overloaded()
  extra    <- .reporting_extra()
  veto     <- .reporting_veto()

  hit_sentences <- character(0)
  guidelines <- character(0)

  for (sent in s) {
    if (grepl(veto, sent, ignore.case = TRUE, perl = TRUE)) next

    matched <- character(0)

    # Full spelled-out names: unambiguous, no extra context required.
    for (nm in names(spelled)) {
      if (grepl(spelled[[nm]], sent, ignore.case = TRUE, perl = TRUE)) {
        matched <- c(matched, nm)
      }
    }

    # Distinctive acronyms: whole-word match plus a reporting context.
    if (grepl(ctx, sent, ignore.case = TRUE, perl = TRUE)) {
      for (nm in names(distinct)) {
        if (grepl(paste0("\\b(", distinct[[nm]], ")\\b"), sent,
                  ignore.case = TRUE, perl = TRUE)) {
          matched <- c(matched, nm)
        }
      }
    }

    # Overloaded acronyms: UPPER-CASE acronym (case-sensitive) directly beside a
    # guideline noun. CARE additionally excludes the animal-welfare phrase.
    for (o in overload) {
      if (grepl(paste0("\\b", o, "\\b[ -]?(?:\\w+ ){0,2}", noun), sent, perl = TRUE)) {
        if (o == "CARE" && grepl("care and use of", sent, ignore.case = TRUE)) next
        matched <- c(matched, o)
      }
    }

    # Wider reportilo catalogue: same upper-case + adjacent guideline-noun rule.
    for (x in extra) {
      if (grepl(paste0("\\b", x, "\\b[ -]?(?:\\w+ ){0,2}", noun), sent, perl = TRUE)) {
        matched <- c(matched, x)
      }
    }

    if (length(matched)) {
      hit_sentences <- c(hit_sentences, trimws(sent))
      guidelines <- c(guidelines, matched)
    }
  }

  if (length(guidelines)) {
    out$is_reporting_pred <- TRUE
    out$reporting_guideline <- paste(unique(guidelines), collapse = "; ")
    out$reporting_text <- paste(unique(hit_sentences), collapse = " | ")
  }
  out
}


# Reporting-guideline fields from a PMC XML. The scan covers the abstract, body
# paragraphs and titles, back matter, footnotes and figure/table captions, since
# the statement (or a named CONSORT/PRISMA flow diagram) can appear in any of
# these.
.get_reporting_pmc <- function(article_xml) {
  xp <- paste(
    ".//abstract//p", ".//body//p", ".//body//title",
    ".//back//p", ".//fn//p",
    ".//caption//p", ".//caption//title", ".//floats-group//p",
    sep = " | "
  )
  nodes <- tryCatch(xml2::xml_find_all(article_xml, xp), error = function(e) NULL)
  text <- if (length(nodes)) xml2::xml_text(nodes) else character(0)
  .detect_reporting(text)
}


#' Identify use of a reporting guideline from a PMC XML file.
#'
#' Detects whether an article states that it followed a reporting guideline (the
#' EQUATOR-network checklists such as CONSORT, PRISMA, STROBE, ARRIVE, STARD,
#' TRIPOD, COREQ, SQUIRE, CHEERS) and which one. Detection is precision-first: a
#' guideline acronym is counted only when it appears in a reporting context (a
#' reporting or adherence verb, or a guideline noun such as "statement",
#' "checklist" or "guideline"), so a bare citation does not count.
#'
#' @param filename The filename of the PMC XML file to analyze.
#' @param remove_ns TRUE if an XML namespace exists, else FALSE (default).
#' @return A tibble with the article IDs, whether a reporting-guideline statement
#'   was found (`is_reporting_pred`), the guideline(s) named
#'   (`reporting_guideline`), the matched statement (`reporting_text`) and
#'   `is_success`.
#' @examples
#' \dontrun{
#' filepath <- system.file(
#'   "extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency"
#' )
#' rt_reporting_pmc(filepath, remove_ns = TRUE)
#' }
#' @export
rt_reporting_pmc <- function(filename, remove_ns = F) {

  article_xml <- tryCatch(.get_xml(filename, remove_ns), error = function(e) e)
  if (inherits(article_xml, "error")) {
    return(tibble::tibble(filename = filename, is_success = FALSE))
  }

  id_ls <- .get_ids(article_xml)
  id_ls$filename <- filename
  rep_ls <- .get_reporting_pmc(article_xml)

  tibble::as_tibble(c(id_ls, rep_ls, list(is_success = TRUE)))
}


#' Identify use of a reporting guideline from a TXT file.
#'
#' The plain-text counterpart of [rt_reporting_pmc()]. Detects whether an article
#' states that it followed a reporting guideline and which one, using the same
#' precision-first rules.
#'
#' @param filename The name of the TXT file as a string.
#' @return A tibble with the filename, the PMID (if present in the file name),
#'   whether a reporting-guideline statement was found (`is_reporting_pred`), the
#'   guideline(s) named (`reporting_guideline`) and the matched statement
#'   (`reporting_text`).
#' @examples
#' \dontrun{
#' rt_reporting("article.txt")
#' }
#' @seealso [rt_reporting_pmc()] for the PMC XML detector.
#' @export
rt_reporting <- function(filename) {

  article <- basename(filename)
  pmid <- gsub("^.*PMID([0-9]+).*$", "\\1", filename)

  paper_text <- .read_txt(filename)
  found <- .detect_reporting(paper_text)

  tibble::as_tibble(list(
    article = article,
    pmid = pmid,
    is_reporting_pred = found$is_reporting_pred,
    reporting_guideline = found$reporting_guideline,
    reporting_text = found$reporting_text
  ))
}
