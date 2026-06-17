#' Identify whether a study includes a replication component in TXT files.
#'
#' Takes a TXT file and returns data related to the presence of a replication
#'     or validation component, including whether such a component exists.
#'     Replication is defined as the study independently confirming findings
#'     from a prior study in a new sample.
#'
#' @param filename The name of the TXT file as a string.
#' @return A tibble of results. It returns the filename, PMID (if it was part
#'     of the file name), whether a replication component was found, the text
#'     identified, and whether each pattern-matching function identified
#'     relevant text or not.
#' @examples
#' \dontrun{
#' # Path to TXT file.
#' filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.txt"
#'
#' # Identify and extract replication components.
#' results_table <- rt_replication(filepath)
#' }
#' @export
rt_replication <- function(filename) {

  article <- basename(filename)
  pmid <- gsub("^.*PMID([0-9]+).*$", "\\1", filename)

  is_replication_pred <- FALSE
  replication_text <- ""

  index_any <- list(
    replication_replicat_1    = NA,
    replication_confirm_1     = NA,
    replication_independent_1 = NA,
    replication_reproduced_1  = NA,
    replication_validation_1  = NA
  )

  paper_text <- readr::read_file(filename)

  # Quick relevance check
  rel_regex <- paste(
    "replicat",
    "independent(ly)? (confirm|validat|reproduc)",
    "external validation", "internal validation",
    "validation cohort", "validation sample", "validation dataset",
    "training cohort", "confirmatory cohort",
    "reproduced (the|our|their|these) (findings|results)",
    sep = "|"
  )
  is_relevant <- grepl(rel_regex, paper_text, ignore.case = TRUE)

  if (!is_relevant) {
    return(tibble::as_tibble(c(
      list(article = article, pmid = pmid,
           is_replication_pred = is_replication_pred,
           replication_text = replication_text),
      index_any
    )))
  }

  # Split into paragraphs
  broken_1 <- "([a-z]+)-\n+([a-z]+)"
  broken_2 <- "([a-z]+)(|,|;)\n+([a-z]+)"
  splitted <-
    paper_text %>%
    purrr::map(gsub, pattern = broken_1, replacement = "\\1\\2") %>%
    purrr::map(gsub, pattern = broken_2, replacement = "\\1\\3") %>%
    purrr::map(strsplit, "\n| \\*") %>%
    unlist() %>%
    utf8::utf8_encode()

  index_any$replication_replicat_1    <- .which_replication_replicat_1(splitted)
  index_any$replication_confirm_1     <- .which_replication_confirm_1(splitted)
  index_any$replication_independent_1 <- .which_replication_independent_1(splitted)
  index_any$replication_reproduced_1  <- .which_replication_reproduced_1(splitted)
  index_any$replication_validation_1  <- .which_replication_validation_1(splitted)

  index <- unlist(index_any) %>% unique() %>% sort()

  # Remove negations
  if (!!length(index)) {
    is_negated <- .negate_replication_1(splitted[index])
    index <- index[!is_negated]
  }

  is_replication_pred <- !!length(index)
  replication_text <- splitted[index] %>% paste(collapse = " ")

  index_any %<>% purrr::map(function(x) !!length(x))

  tibble::as_tibble(c(
    list(article = article, pmid = pmid,
         is_replication_pred = is_replication_pred,
         replication_text = replication_text),
    index_any
  ))
}


#' Identify replication claims using "replicate" terms
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_replication_replicat_1 <- function(article) {

  # "replicat" root to cover replicate/replicated/replicating/replication
  # Require actual findings/results context. This avoids laboratory replicates
  # in paragraphs that also mention a previous method or publication.
  replication <- "\\breplicat(e|es|ed|ing|ion)\\b"
  prior <- "\\b(previous|prior|earlier|original|published|reported|known|established)\\b"
  finding <- "\\b(findings?|results?|observations?|associations?|effects?|stud(y|ies))\\b"
  pattern <- paste(
    paste0(replication, ".{0,80}", prior, ".{0,80}", finding),
    paste0(prior, ".{0,80}", finding, ".{0,80}", replication),
    paste0(finding, ".{0,50}", replication, "\\b.{0,40}\\b(in|by|using|with|across)\\b"),
    paste0("\\breplication\\b.{0,20}\\bof\\b.{0,50}", prior, ".{0,50}", finding),
    sep = "|"
  )

  grep(pattern, article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "confirm findings" replication claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_replication_confirm_1 <- function(article) {

  confirm_verbs <- "(confirm(s|ed|ing)?|corroborate(s|d|ing)?|validate(s|d|ing)?)"
  findings <- "(finding(s)?|result(s)?|observation(s)?|association(s)?|effect(s)?)"
  context  <- "(from|of|in|reported in|by)"
  prior <- "(previous|prior|earlier|independent|external|separate|another|published|reported)"

  pattern <- paste(
    paste0("\\b", confirm_verbs, "\\b.{0,60}\\b", findings,
           "\\b.{0,40}\\b", context, "\\b.{0,60}\\b", prior, "\\b"),
    paste0("\\b", findings, "\\b.{0,40}\\b", confirm_verbs,
           "\\b.{0,40}\\b(in|using|with)\\b.{0,40}\\b",
           "(independent|external|separate|validation)\\b"),
    sep = "|"
  )

  grep(pattern, article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "independently replicated/validated" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_replication_independent_1 <- function(article) {

  pattern <- paste0(
    "\\bindependent(ly)?\\b.{0,40}",
    "\\b(replicat|validat|reproduc|confirm)(e|es|ed|ing|ion)?\\b",
    "|",
    "\\b(independent|external)\\b.{0,10}\\b(replication|validation|reproduction|cohort|sample|dataset)\\b"
  )

  grep(pattern, article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "reproduced the/our findings" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_replication_reproduced_1 <- function(article) {

  pattern <- paste0(
    "\\breproduced? (the |our |their |these )?(findings|results|observations|associations)\\b",
    "|",
    "\\b(findings|results|observations)\\b.{0,40}\\breproduced?\\b"
  )

  grep(pattern, article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "validation cohort/sample" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_replication_validation_1 <- function(article) {

  pattern <- paste0(
    "\\b(validation|replication|confirmatory)\\b.{0,20}",
    "\\b(cohorts?|samples?|datasets?|sets?|populations?|studies|analyses|groups?|trials?)\\b",
    "|",
    "\\b(cohorts?|samples?|datasets?|sets?|populations?|studies|groups?|trials?)\\b.{0,20}",
    "\\b(validation|replication|confirmatory)\\b",
    "|",
    "\\b(internal|external) validation\\b",
    "|",
    "\\bvalidated in (the |an? )?(validation|independent) (cohorts?|samples?|datasets?|sets?|populations?)\\b",
    "|",
    "\\btraining cohort\\b.{0,120}\\bvalidation cohort\\b"
  )

  grep(pattern, article, ignore.case = TRUE, perl = TRUE)

}


#' Remove negated replication mentions
#'
#' Removes mentions such as "failed to replicate" or "could not replicate".
#'
#' @param article A character vector of matching paragraphs.
#' @return Logical vector; TRUE where the match is a negation (to be excluded).
#' @noRd
.negate_replication_1 <- function(article) {

  pattern <- paste(
    "not replicated",
    "independently replicated a minimum",
    "experiments? .{0,80}replicat",
    "replicated (a minimum|at least)",
    "mean values? of the replicates",
    "confirmatory analysis",
    "failed to replicate",
    "unable to replicate",
    "could not replicate",
    "fail(ed|s|ing) to replicate",
    "did not replicate",
    "future .{0,60}validat",
    "validation .{0,80}will be necessary",
    "validation .{0,80}(is|are|was|were)? ?required",
    "further validation .{0,80}(required|needed|necessary)",
    "needs? to be conducted .{0,80}validat",
    "needs? to be replicated",
    "lack(s|ed|ing)? .{0,40}validation",
    "lack(s|ed|ing)? external validation",
    "lacking external validation",
    "external validation was not available",
    "external validation .{0,80}(warranted|required|necessary|remains necessary)",
    "(would )?requires? external validation",
    "(would )?require external validation",
    "external validation .{0,80}(is )?required",
    "regression-derived formulas require external validation",
    "validation in the future",
    "should be (replicated|validated)",
    "future studies? should replicat",
    "should replicate (the|this|our) (intervention|study|findings|results)",
    "software validation",
    "workflow validation",
    "pipeline validation",
    "method validation",
    "validation of (the )?(software|workflow|pipeline|method)",
    "qrt-pcr validation",
    "mechanistic validation",
    "mass recovery and validation",
    "validation of gene expression",
    "validate(d)? the results of .{0,40}assay",
    "validate(d)? .{0,80}(rt-q?pcr|q?pcr|western blot|immunohistochem|immunofluorescence|flow cytometry|elisa|luciferase|staining|co-?immunoprecipitation|assay)",
    "(to further confirm|further confirmed|further validate|we confirmed|we validated|confirmed by|validated by).{0,120}(rt-q?pcr|q?pcr|western blot|immunohistochem|immunofluorescence|flow cytometry|elisa|luciferase|staining|co-?immunoprecipitation|assay|experiment)",
    "experimental validation",
    "field validation",
    "clinical validation dataset",
    "clsi-guided validation",
    "platform-independent .{0,80}(reproducible|entry criteria)",
    "reproducible, traceable, and comparable",
    "training and validation datasets?",
    "training and validation subsets?",
    "validation subsets?",
    "validation dataset subsets?",
    "validation dataset only includes",
    "ground-truth validation dataset",
    "validation datasets? .{0,60}(comprised|curated|constructed)",
    "validation dataset .{0,20}comprised",
    "validation set",
    "validation and sensitivity analysis",
    "cross-validation",
    "predictive model",
    "train-test design",
    "randomly split .{0,80}training .{0,40}validation",
    "methodology, validation",
    "formal analysis, validation",
    "validation, visualization",
    "author contributions?.{0,120}validation",
    "conceptualization.{0,160}validation",
    "methodology validation",
    "formal analysis validation",
    "validation data curation",
    "entering validation phases",
    "immunohistochemical validation",
    "validation of marker genes",
    "composite indicator construction",
    "indicator validation",
    "internal consistency of the composite indicator",
    "prior validation studies",
    "workflow evaluation and validation",
    "dataset used for validation",
    "dataset includes only training and validation",
    "to validate the workflow",
    "technical replicat",
    "biological replicat",
    "experimental replicat",
    "independent serum sample",
    "independent replicates",
    "replicates and are reported",
    "sampled repeatedly",
    "ratings replicated all findings",
    "aimed to reproduce the results obtained",
    "reproduce the results obtained with",
    "replication-dependent",
    "replicate wells?",
    "\\breplicates of\\b",
    "\\breplicates\\b.{0,20}(strain|sample|dataset)",
    "\\bdna replication\\b",
    "\\bviral replication\\b",
    "\\bvirus replication\\b",
    "\\bgtpv replication\\b",
    "viral transcript",
    "phase (i|ii|iii|iv|[0-9]+).{0,80}confirm(ed|s)? the efficacy",
    "\\bndv replication\\b",
    "\\bnewcastle disease virus replication\\b",
    "\\bmmupv[0-9]?\\b",
    "\\bown replication\\b",
    "\\bpromote(s|d)? its replication\\b",
    "\\bhost .{0,40}replication\\b",
    "\\bfadv-?[0-9]? replication\\b",
    "\\bhpv replication\\b",
    sep = "|"
  )

  grepl(pattern, article, ignore.case = TRUE, perl = TRUE)

}
