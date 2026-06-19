#' Identify whether a study claims novelty in TXT files.
#'
#' Takes a TXT file and returns data related to the presence of novelty claims,
#'     including whether a novelty claim exists. If a novelty claim exists, it
#'     extracts the relevant text. Novelty is defined as the study claiming to
#'     report something "for the first time."
#'
#' @param filename The name of the TXT file as a string.
#' @return A tibble of results. It returns the filename, PMID (if it was part
#'     of the file name), whether a novelty claim was found, the text
#'     identified, and whether each pattern-matching function identified
#'     relevant text or not.
#' @examples
#' \dontrun{
#' # Path to TXT file.
#' filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.txt"
#'
#' # Identify and extract novelty claims.
#' results_table <- rt_novelty(filepath)
#' }
#' @export
rt_novelty <- function(filename) {

  article <- basename(filename)
  pmid <- gsub("^.*PMID([0-9]+).*$", "\\1", filename)

  is_novelty_pred <- FALSE
  novelty_text <- ""

  index_any <- list(
    novelty_first_time_1 = NA,
    novelty_first_time_2 = NA,
    novelty_first_to_1 = NA,
    novelty_previously_1 = NA,
    novelty_novel_1 = NA,
    novelty_knowledge_1 = NA
  )

  paper_text <- readr::read_file(filename)

  # Relevance gate: a cheap superset of every cue the pattern functions below can
  # match. Precision is enforced by those functions and .negate_novelty_1, not
  # here, so this only needs to admit anything potentially relevant.
  rel_regex <- paste(
    "first", "novel", "innovativ", "unprecedent", "previously un",
    "not been", "to our knowledge", "to the best of",
    sep = "|"
  )
  is_relevant <- grepl(rel_regex, paper_text, ignore.case = TRUE)

  if (!is_relevant) {
    return(tibble::as_tibble(c(
      list(article = article, pmid = pmid,
           is_novelty_pred = is_novelty_pred,
           novelty_text = novelty_text),
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

  # Novelty claims frequently occur in abstracts, introductions and discussion,
  # but the external XML validation also found many explicit first-time claims
  # in results/conclusion paragraphs. Scan the full article and rely on the
  # specific phrase rules below for precision.
  article_scan <- splitted

  index_any$novelty_first_time_1 <- .which_novelty_first_time_1(article_scan)
  index_any$novelty_first_time_2 <- .which_novelty_first_time_2(article_scan)
  index_any$novelty_first_to_1   <- .which_novelty_first_to_1(article_scan)
  index_any$novelty_previously_1 <- .which_novelty_previously_1(article_scan)
  index_any$novelty_novel_1       <- .which_novelty_novel_1(article_scan)
  index_any$novelty_knowledge_1   <- .which_novelty_knowledge_1(article_scan)

  index <- unlist(index_any) %>% unique() %>% sort()

  # Drop cues attributed to a cited study or ordinal/temporal "first".
  if (!!length(index)) {
    is_negated <- .negate_novelty_1(article_scan[index])
    index <- index[!is_negated]
  }

  is_novelty_pred <- !!length(index)
  novelty_text <- article_scan[index] %>% paste(collapse = " ")

  index_any %<>% purrr::map(function(x) !!length(x))

  tibble::as_tibble(c(
    list(article = article, pmid = pmid,
         is_novelty_pred = is_novelty_pred,
         novelty_text = novelty_text),
    index_any
  ))
}


#' Identify "for the first time" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_first_time_1 <- function(article) {

  grep("\\bfor the first time\\b", article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "first time that" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_first_time_2 <- function(article) {

  grep("\\bfirst time (that|to|we|this)\\b", article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "first to show/report/demonstrate" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_first_to_1 <- function(article) {

  verbs <- paste0("(show|report|demonstrate|identify|describe|establish|characteri[sz]e|",
    "reveal|document|observe|detect|assess|evaluate|examine|investigate|analy[sz]e|",
    "elucidate|introduce|compare|address|understand|isolate|generate|provide|present|",
    "develop|propose|design|create|apply|combine|summari[sz]e|attenuate|construct|",
    "derive|formulate|achieve|obtain|map|quantify|uncover|link|relate|integrate|",
    "confirm|validate|corroborate|prove|find|discover|predict|model|estimate|",
    "measure|test|explore|define|classify|determine|record|implement|deploy)")
  # Research-output nouns for the "first <noun> ... <ing verb>" branch. These are
  # rarely used as ordinal enumerations ("the first study to show", not "the first
  # method involves"), so they stay narrow; "method/test/model/system" etc are
  # deliberately excluded here because "the first method involves ..." is an
  # enumeration, not a priority claim.
  nouns <- paste0("study|report|trial|analysis|investigation|paper|work|demonstration|",
    "case|description|survey|scoping review|systematic review|meta-analysis|cohort|series")
  # Broader research-object nouns for the "first <noun> to <verb>" branch, where
  # the trailing "to <verb>" already signals a priority claim.
  nouns_to <- paste0(nouns, "|attempt|technology|technique|approach|method|tool|system|",
    "device|platform|model|framework|sensor|assay|drug|agent|biomarker|program|intervention")
  ing <- paste0("(compar|evaluat|examin|investigat|analy[sz]|describ|report|demonstrat|",
    "assess|identif|address|understand|isolat|generat|provid|present|develop|propos|",
    "summari[sz]|attenuat|character|confirm|validat|corroborat|prov|find|discover|",
    "predict|model|estimat|measur|test|explor|defin|classif|determin|record|implement)")
  adverbials <- "(to date |to our knowledge |ever |so far |yet |in the literature )?"
  to_v <- paste0("to ([a-z]+ly )?", verbs)
  # Author voice claiming priority with an adverbial "first": "our study first
  # provided evidence". The subject is restricted to "our/this study" on purpose;
  # bare "we first <verb>" is overwhelmingly procedural ("we first examined ...,
  # then ...") rather than a priority claim, so it is excluded.
  self_first <- paste0("\\b(our (study|work|report|group|analysis|research|investigation)|",
    "this (study|work|report|investigation))\\b",
    ".{0,30}\\bfirst (", verbs, ")")
  pattern <- paste(
    # Article-anchored "first [adverb] [noun] to <verb>": "the/our/this first to
    # report", "the first ever study to characterize". Requiring an article before
    # a bare "first to" excludes procedural "performed first to confirm".
    paste0("\\b(the|a|an|our|this|its|their) first ", adverbials, "((", nouns_to,
           ") )?", adverbials, to_v),
    # Noun-anchored "first <research object> to <verb>" (article optional).
    paste0("\\bfirst (", nouns_to, ") ", adverbials, to_v),
    # "(the) first <research-output noun> ... <ing verb>".
    paste0("\\b(this is |our report is |our cohort is )?(the )?first (", nouns,
           ")( of its kind)?\\b.{0,90}\\b", ing),
    self_first,
    # Author voice "we provide/report the first evidence that ...": a priority
    # claim phrased around evidence. The self anchor is required because a bare
    # "the first evidence of ..." is usually historical or attributed to prior
    # work ("providing the first evidence in the 1990s ...").
    paste0("\\b(we|our (study|work|group|team)|this (study|work)|here,? we|",
      "the present study)\\b[a-z ,]{0,30}\\b(provide|provides|provided|present|presents|",
      "presented|report|reports|reported|offer|offers|offered|show|shows|showed|",
      "give|gives|gave|describe|describes|described)\\b (the |a )?first ",
      "(direct |experimental |systematic |empirical |genetic |molecular |strong |robust )?",
      "(evidence|proof) (that|of|for|to|in|linking|showing|demonstrating)\\b"),
    "\\b(present|presents|presented|report|reports|reported|describe|describes|described) (the |a )?first (reported |documented |known )?case\\b",
    "\\bfirst (reported |documented |known )?case (of|report)\\b",
    "\\bthis is the first report that (we know of|to our knowledge)\\b",
    "\\bour report first reported a case\\b",
    "\\bas the first study of its kind\\b",
    sep = "|"
  )

  grep(pattern, article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "previously unknown/unreported" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_previously_1 <- function(article) {

  prevun <- paste0("previously (unknown|unreported|uncharacterized|undescribed|",
    "unidentified|unrecognized|unappreciated|undocumented|unexplored|unexamined)")
  # The gap must belong to the present study, not a cited work or a background
  # fact. "X has not been studied" on its own is too often a tangential aside, so
  # require a first-person/this-study anchor or a discovery verb beside the cue.
  self <- paste0("\\b(we|our|us|this (study|work|report|analysis|paper|article)|",
    "here|the present (study|work|analysis|paper)|the current (study|work|analysis))\\b")
  dverb <- paste0("\\b(identif(y|ied|ies)|reveal(s|ed)?|discover(s|ed)?|uncover(s|ed)?|",
    "found|find|detect(s|ed)?|observ(e|ed|es)?|report(s|ed)?)\\b")
  grep(paste(
    paste0(self, ".{0,80}\\b", prevun, "\\b"),
    paste0(dverb, ".{0,40}\\b", prevun, "\\b"),
    paste0("\\b", prevun, ".{0,40}", dverb),
    "\\bnot been (reported|studied|examined|evaluated|assessed|investigated|described|characteri[sz]ed) (previously|before)\\b",
    sep = "|"
  ),
       article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "novel finding/approach" claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_novel_1 <- function(article) {

  # "novel"/"innovative"/"unprecedented" applied to a research object the authors
  # claim. Bare "new" is deliberately excluded; it is far too frequent in
  # non-priority contexts ("a new model", "new insights") to be a reliable cue.
  nv <- "(novel|innovative|unprecedented)"
  term <- paste0("(finding|observation|approach|method|methodology|technique|",
    "insight|evidence|aspect|role|mechanism|target|treatment|therapy|association|",
    "result|perspective|pathway|model|framework|tool|device|strategy|system|assay|",
    "algorithm|sequence|index|score|metric|procedure|biomarker|signature|classifier|",
    "agent|compound|inhibitor|variant|subtype|isolate|strain|concept|paradigm|",
    "hypothesis|data ?set|application|pipeline|platform|protocol|formulation|material)s?")
  self <- "\\b(this|the present|the current|our) (study|work|research|analysis|paper|report|investigation)\\b"
  # Author voice immediately followed by a development/presentation verb: the
  # authors' own claim, not an attribution to a cited study.
  author_verb <- paste0("\\b(we|here,? we|in (this|the present) (study|work|paper|analysis))\\b.{0,90}",
    "\\b(provide|present|propose|develop|design|construct|create|identif|report|describe|reveal|demonstrate|introduce|establish|discover|generate|offer)")
  # NB: a bare "this novel <term>" pattern was deliberately dropped; "this novel
  # approach/method/system" is too often a passing reference rather than a
  # priority claim. A self-anchored claim is still caught by the first pattern.
  pattern <- paste(
    paste0(self, ".{0,120}\\b", nv, " ", term, "\\b"),
    paste0(author_verb, "[a-z]*.{0,50}(a |an |the )?", nv, " ", term, "\\b"),
    paste0(author_verb, "[a-z]*.{0,40}(a |an |the )", nv, " [a-z]"),
    paste0("(a |an |the )", nv, " [a-z][a-z -]{2,40}(is|was|are|were|has been|have been) ",
      "(developed|presented|introduced|proposed|described|reported|identified|established|designed|created|constructed|generated|discovered|demonstrated|detected|found|isolated|characteri[sz]ed|observed)\\b"),
    sep = "|"
  )

  grep(pattern, article, ignore.case = TRUE, perl = TRUE)

}


#' Identify "to our knowledge" novelty claims
#'
#' @param article A character vector of paragraphs.
#' @return Integer index of matching elements.
#' @noRd
.which_novelty_knowledge_1 <- function(article) {

  # "to our knowledge" only counts when it introduces a first/gap claim, not a
  # bare hedge ("to our knowledge, the data are consistent with ...").
  know <- "\\bto (our|the best of our|the best of my) knowledge\\b"
  gap <- paste0("(\\bfirst\\b|",
    "\\b(largest|biggest|longest|greatest|most (comprehensive|detailed|extensive|complete|thorough)) ",
    "[a-z ]{0,25}(stud|cohort|sample|trial|analys|series|dataset|investigation|survey|report|comparison|meta-analysis|examination|evaluation)|",
    "\\bno (other |previous |prior |published |existing |such )?",
    "(stud|report|work|data|research|investigation|paper|trial|evidence|literature|one |article|effort|attempt)|",
    "\\bnot (yet )?been\\b|\\bnever been\\b|\\bhas not\\b|\\bhave not\\b|\\bhas yet to\\b|",
    "\\bfails? to (provide|address|account|capture|report|describe|examine|investigate|cover|offer|give|present)\\b|",
    "\\bremains? (un|to be|largely un)|\\bunknown\\b|\\bunreported\\b|\\bunexplored\\b|",
    "\\bunexamined\\b|\\buninvestigated\\b|\\black(s|ing)?\\b)")
  # The gap claim can follow "to our knowledge" or precede it ("no studies, to
  # our knowledge, have demonstrated ...").
  rev_gap <- paste0("(\\bno (\\w+ )?(studies|study|reports?|data|work|trials?|evidence|literature)\\b|",
    "\\bhas not\\b|\\bhave not\\b|\\bnot been \\w+|\\bnever been\\b)")
  grep(paste(
    paste0(know, ".{0,110}", gap),
    paste0(rev_gap, ".{0,55}", know),
    sep = "|"
  ), article, ignore.case = TRUE, perl = TRUE)

}


#' Suppress non-self or non-research uses of first/novel cues
#'
#' Removes paragraphs whose novelty cue is attributed to a cited study, or is an
#' ordinal/temporal "first" (first day, first-time transplant) rather than a
#' priority claim, or names an entity ("the novel coronavirus").
#'
#' @param article A character vector of paragraphs.
#' @return Logical vector, TRUE where the cue should be suppressed.
#' @noRd
.negate_novelty_1 <- function(article) {

  # NB: do not suppress the bare phrase "first time"; "for the first time we
  # reveal ..." is the canonical priority claim. Only its ordinal/attributed
  # uses are removed.
  pattern <- paste(
    # Firstness/novelty attributed to a cited study (an author + et al near the
    # cue). Author voice ("we ... for the first time") is never written this way.
    "\\b[A-Z][a-zA-Z'-]+ et al\\b.{0,65}(for the )?\\bfirst\\b",
    "\\b[A-Z][a-zA-Z'-]+ et al\\b.{0,65}\\b(novel|previously un)\\b",
    "\\b[A-Z][a-zA-Z'-]+ (and colleagues|and co-?workers)\\b.{0,65}\\b(first|novel)\\b",
    # The authors explicitly disclaim priority.
    "\\bnot the first\\b",
    # Historical "first" (a dated prior event), not the present study's priority.
    "\\bfor the first time in (1[0-9]|20)[0-9][0-9]\\b",
    "\\b(used|introduced|invented|described|reported|developed) (for the )?first time in (1[0-9]|20)[0-9][0-9]",
    paste0("\\bfirst (report|study|trial|case|description|demonstration|account|",
      "isolation|use|usage|application) of [A-Za-z0-9 ,'/()-]{2,60} in (1[5-9]|20)[0-9][0-9]\\b"),
    "\\bfirst to [a-z]+ .{0,70} in (1[5-9]|20)[0-9][0-9]\\b",
    # Disease epidemiology: the first reported case of a named disease in a place
    # or date, not a research priority claim.
    paste0("\\bfirst (known |confirmed |reported |documented )?cases? of ",
      "[A-Za-z0-9() /'-]{2,45} (was|were|has been|have been|is|are) ",
      "(confirmed|reported|recorded|detected|identified|diagnosed|documented|",
      "registered|notified|isolated|observed)\\b"),
    # Ordinal / temporal "first" (hyphenated adjective or an enumerated count),
    # not a priority claim. The bare phrase "first time" is deliberately excluded.
    "\\bfirst-time\\b",
    "\\bfirst time points?\\b",
    paste0("\\bfirst (day|days|week|weeks|month|months|year|years|trimester|hour|hours|",
      "stage|phase|wave|visit|line|step|passage|generation|episode|dose|cycle|",
      "quarter|round|edition|postoperative|post-operative|trimesters?|",
      "two|three|four|five|six|seven|eight|nine|ten|few|several|couple)\\b"),
    paste0("\\bfirst time [a-z]+ (transplant|surgery|underwent|received|presented|admi",
      "(tted|ssion)|diagnos(is|ed)|pregnancy|birth|dose|exposure|episode)\\b"),
    # A person's, patient's or specimen's first encounter/observation, not a
    # research priority claim.
    paste0("\\b(see|saw|seen|seeing|sees|admitted|diagnos(ed|ing)|visit(s|ed|ing)?|",
      "came|come|arriv(e|ed|es|ing)|experienc(e|ed|es|ing)|met|meets?|meeting|",
      "captur(e|ed|es|ing)|recruit(ed|ing)?|enroll(ed|ing)?) ",
      "(the |a |to |his |her |their |our )?[a-z' ]{0,25}for the first time\\b"),
    "\\bfor the first [0-9]",
    "\\bthe novel (coronavirus|severe acute|sars|influenza|virus\\b)",
    sep = "|"
  )

  grepl(pattern, article, perl = TRUE)

}
