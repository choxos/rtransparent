#' Identify mentions of registration on ClinicalTrials.gov
#'
#' Extract the index of mentions such as: "The study is registered at
#'     www.clinicaltrials.gov (NCT01624883)."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_ct_1 <- function(article) {

  # Just using the NCT was too sensitive
  # e.g. picked up references to protocols, mentions of trials underway, etc.
  grep("\\b(|pre|pre-)regist.{0,20}NCT[0-9]{8}", article, perl = T)

}


#' Identify mentions of registration on ClinicalTrials.gov
#'
#' Extract the index of mentions such as: "The study (EudraCT 2011‐001925‐26;
#'     ClinicalTrial.gov NCT01489592) was approved by the Ethics Committee of
#'     Rennes University Hospital."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_ct_2 <- function(article) {

  grep("[Cc]linical[Tt]rial.* NCT[0-9]{8}", article, perl = T)

}


#' Identify flexible ClinicalTrials.gov registration statements.
#'
#' Extract the index of mentions such as "The study is registered at
#'     clinicaltrials.gov (NCT03297034)" and "Clinical trial registration
#'     clinicaltrials.gov identifier is NCT05856578."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_ct_4 <- function(article) {

  grep(
    paste(
      "\\b(the|this|our) (study|trial).{0,80}registered at clinicaltrials\\.?gov.{0,80}NCT[0-9]{8}",
      "\\b(the|this|our|it) (study|trial)? ?was registered at clinicaltrial(s)?\\.?\\s*gov.{0,100}(registration number )?NCT[0-9]{8}",
      "\\bclinical trial registration.{0,100}clinicaltrial(s)?\\.?\\s*gov.{0,80}NCT[0-9]{8}",
      "\\bclinicaltrial(s)?\\.?\\s*gov identifier is NCT[0-9]{8}",
      sep = "|"
    ),
    article,
    perl = TRUE,
    ignore.case = TRUE
  )

}


#' Identify mentions of registration on PROSPERO
#'
#' Extract the index of mentions such as: "We registered the protocol for this
#'     meta-analysis with the PROSPERO database (www.crd.york.ac.uk/prosper
#'     o)—registration no. CRD42014015595."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_prospero_1 <- function(article) {

  # Just using the NCT was too sensitive
  # e.g. picked up references to protocols, mentions of trials underway, etc.
  grep("PROSPERO.*[A-Z]{2}\\s*[0-9]{5,11}", article, perl = T)

}


#' Identify generic mentions of registration
#'
#' Extract the index of mentions such as: "This study was approved by the local
#'     Scientific and Ethics Committees of IRCCS \"Saverio de Bellis\",
#'     Castellana Grotte (Ba), Italy, and it was part of a registered research
#'     on https://www.clinicaltrials.gov, reg. number: NCT01244945."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registered_1 <- function(article) {

  synonyms <- .create_synonyms()
  words <- c("this", "research_lower_strict", "and", "registered_registration")
  # Too generic without research & registered, or if including registration

  this_research <-
    synonyms %>%
    magrittr::extract(words[c(1, 2)]) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = .max_words(" ", 5, space_first = F))

  this_research_registered <-
    synonyms %>%
    magrittr::extract(words[c(1, 2, 4)]) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = .max_words(" ", 5, space_first = F))

  and_registered <-
    synonyms %>%
    magrittr::extract(words[c(3:4)]) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = .max_words(" ", 5, space_first = F))

  research_and_registered <-
    synonyms %>%
    magrittr::extract(words[2]) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(and_registered, sep = synonyms$txt)

  this_research_and_registered <-
    this_research %>%
    paste(and_registered, sep = synonyms$txt)

  # c(this_research_registered, research_and_registered) %>%
  #   lapply(.encase) %>%
  #   .encase() %>%
  #   paste("([A-Z]{2}\\s*[0-9]{2}|[0-9]{5})", sep = synonyms$txt) %>%
  #   grep(article, perl = T)

  c(this_research_registered, this_research_and_registered) %>%
    lapply(.encase) %>%
    .encase() %>%
    paste("([A-Z]{2}\\s*[0-9]{2}|[0-9]{5})", sep = synonyms$txt) %>%
    grep(article, perl = T)

}


#' Identify generic mentions of registration
#'
#' Extract the index of mentions such as: " EPGP is registered with
#'     clinicaltrials.gov (NCT00552045)."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registered_2 <- function(article) {

  synonyms <- .create_synonyms()

  c("(^|\\.\\s*)(Ethical|Approval|(|The )[A-Z][A-Z]+)",
    "(registered|registration)",
    "([Tt]rial|[Ss]tudy)"
  ) %>%
    paste(collapse = synonyms$txt) %>%
    paste("([A-Z]{2}\\s*[0-9]{2}|[0-9]{5})", sep = synonyms$txt) %>%
    grep(article, perl = T)

}


#' Identify generic mentions of registration
#'
#' Extract the index of mentions such as: "registered with Clinical Trials
#'     (ChiCTR-IOR-14005438)"
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registered_3 <- function(article) {

  synonyms <- .create_synonyms()

  c("([Tt]rial|[Pp]rotocol) (registered|registration) (with\\b|under\\b|on\\b|at\\b|as\\b)") %>%
    paste("([A-Z]{2}\\s*[0-9]{2}|[0-9]{5})", sep = synonyms$txt) %>%
    grep(article, perl = T)

}


#' Identify generic mentions of registration
#'
#' Extract the index of mentions such as: "This registered study on
#'     www.clinicaltrials.gov (NCT01375270) was approved by the Ethics
#'     Committee of the Capital Region of Denmark (H-3-2010-127), and all
#'     subjects provided informed written consent to participate."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registered_4 <- function(article) {

  synonyms <- .create_synonyms()
  words <- c("this", "registered", "research_lower_strict")
  # Too generic without research & registered, or if including registration

  synonyms$this <- append(synonyms$this, "\\b[Ww]e")

  synonyms %>%
    magrittr::extract(words) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = .max_words(" ", 5, space_first = F)) %>%
    paste("([A-Z]{2}\\s*[0-9]{2}|[0-9]{5})", sep = synonyms$txt) %>%
    grep(article, perl = T)

}


#' Identify generic mentions of registration
#'
#' Extract the index of mentions such as: "The Régression de l'Albuminurie dans
#'     la Néphropathie Drépanocytaire (RAND) study design was approved by the
#'     local ethics committee (Ref: DGRI CCTIRS MG/CP09.503, 9 July 2009) and
#'     registered at ClinicalTrials.gov (NCT01195818)."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registered_5 <- function(article) {

  synonyms <- .create_synonyms()
  words <- c("this", "research_strict", "and", "registered_registration")
  SOME <- "\\([a-zA-Z]+\\)"
  # Too generic without research & registered, or if including registration

  SOME_research <-
    synonyms %>%
    magrittr::extract(words[2]) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(SOME, .)

  the_SOME_research <-
    synonyms %>%
    magrittr::extract(words[1]) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(SOME_research, sep = synonyms$txt)

  the_SOME_research_registered <-
    synonyms %>%
    magrittr::extract(words[4]) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(the_SOME_research, ., sep = .max_words(" ", 5, space_first = F))

  and_registered <-
    synonyms %>%
    magrittr::extract(words[c(3:4)]) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = .max_words(" ", 5, space_first = F))

  the_SOME_research_and_registered <-
    the_SOME_research %>%
    paste(and_registered, sep = synonyms$txt)


  c(the_SOME_research_registered, the_SOME_research_and_registered) %>%
    lapply(.encase) %>%
    .encase() %>%
    paste("([A-Z]{2}\\s*[0-9]{2}|[0-9]{5})", sep = synonyms$txt) %>%
    grep(article, perl = T)

}


#' Identify mentions of lack of registration
#'
#' Extract the index of mentions such as: "This trial and its protocol were not
#'     registered on a publicly accessible registry."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_not_registered_1 <- function(article) {

  synonyms <- .create_synonyms()
  words <- c("this", "research_lower_strict")

  synonyms %>%
    magrittr::extract(words) %>%
    lapply(.bound, location = "both") %>%
    lapply(.encase) %>%
    paste(collapse = .max_words(" ", n_max = 4, space_first = F)) %>%
    paste(" not", " registered", sep = .max_words("", n_max = 6)) %>%
    grep(article, perl = T)
}


#' Identify generic mentions of registration
#'
#' Extract the index of mentions such as: "Trial registration number is
#'     TCTR20151021001."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registration_1 <- function(article) {

  synonyms <- .create_synonyms()
  words <- c("research_strict", "registration")  # Too generic without these

  research_registration <-
    synonyms %>%
    magrittr::extract(words) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = " ") %>%
    paste0("(:|-+)")

  c(research_registration, "([A-Z]{2}\\s*[0-9]{2}|[0-9]{5})") %>%
    paste(collapse = synonyms$txt) %>%
    grep(article, perl = T)

}


#' Identify generic mentions of registration
#'
#' Extract the index of mentions such as: "Trial registration number is
#'     TCTR20151021001."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registration_2 <- function(article) {

  synonyms <- .create_synonyms()
  words <- c("Research_strict", "registration")

  research_registration <-
    synonyms %>%
    magrittr::extract(words) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = " ")

  c(research_registration, "([A-Z]{2}\\s*[0-9]{2}|[0-9]{5})") %>%
    paste(collapse = synonyms$txt) %>%
    grep(article, perl = T)

}


#' Identify generic mentions of registration
#'
#' Extract the index of mentions such as: "Public clinical trial registration
#'     (www.clinicaltrials.gov) ID# NCT02720653"
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registration_3 <- function(article) {

  grep("(^|\\.).{0,35}\\b(|pre|pre-)registration.{0,35}NCT[0-9]{8}",
       article, perl = T)

}


#' Identify generic mentions of registration
#'
#' Extract the index of mentions such as: "The RAPiD trial's International
#'     Standard Randomised Controlled Trial Number (ISRCTN) registration is
#'     ISRCTN 49204710."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registration_4 <- function(article) {

  synonyms <- .create_synonyms()
  words <- c("This", "research_lower_strict", "registration")
  # Too generic without research & registered, or if including registration

  this_research <-
    synonyms %>%
    magrittr::extract(words[c(1, 2)]) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = .max_words(" ", 5, space_first = F))

  c(this_research) %>%
    lapply(.encase) %>%
    .encase() %>%
    paste("registration", "([A-Z]{2}\\s*[0-9]{2}|[0-9]{5})", sep = synonyms$txt) %>%
    grep(article, perl = T)

}


#' Identify mentions of registry
#'
#' Extract the index of mentions such as: "Here, we describe a collaboration
#'     between an international group of patient organisations advocating for
#'     patients with atypical haemolytic uraemic syndrome (aHUS), the aHUS
#'     Alliance, and an international aHUS patient registry (ClinicalTrials.gov
#'     NCT01522183)."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_registry_1 <- function(article) {

  synonyms <- .create_synonyms()
  words <- c("research_lower_strict", "registry")  # Too generic without these

  research_registry <-
    synonyms %>%
    magrittr::extract(words) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = synonyms$txt)

  a <-
    c(research_registry, "[\\s,;:]+([A-Z]{2,10}\\s*[0-9]{2}|[0-9]{5})") %>%
    paste(collapse = synonyms$txt) %>%
    grep(article, perl = T)

  if (!!length(a)) {

    is_false <- negate_registry_1(article[a])
    a <- a[!is_false]

  }

  return(a)

}




#' Identify registration titles - sensitive with negation
#'
#' Extract the index of mentions such as: "Study registration: ..."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_reg_title_1 <- function(article) {

  b <- integer()
  synonyms <- .create_synonyms()
  words <- c("registration_title")

  a <-
    synonyms %>%
    magrittr::extract(words) %>%
    lapply(.bound) %>%
    lapply(.title_strict) %>%
    lapply(.encase) %>%
    paste() %>%
    grep(article, perl = T)

  if (!!length(a)) {

    if (nchar(article[a + 1]) == 0) {
      b <- c(a, a + 2)
    } else {
      b <- c(a, a + 1)
    }

    is_true <- any(negate_reg_title_1(article[b]))
    if (is_true) return(b)

  }

  a <-
    synonyms %>%
    magrittr::extract(words) %>%
    lapply(.bound) %>%
    lapply(.title_strict, within_text = T) %>%
    lapply(.encase) %>%
    paste() %>%
    grep(article, perl = T)

  if (!!length(a)) {

    is_true <- negate_reg_title_1(article[a])
    a <- a[is_true]

  }

  return(a)
}


#' Identify registration titles - specific with no negation
#'
#' Extract the index of mentions such as: "Trial registration: ..."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_reg_title_2 <- function(article) {

  b <- integer()
  synonyms <- .create_synonyms()

  reg_title_synonyms <- c(
    "R(?i)egistration info(|rmation)(?-i)",
    "R(?i)egistration detail(|s)(?-i)",
    "R(?i)egistration no(|s)(|\\.)(?-i)",
    "R(?i)egistration number(|s)(?-i)",
    "R(?i)egistration identifier(|s)(?-i)",
    "T(?i)rial(|s) identifier(|s)(?-i)",
    "C(?i)linical trial(|s) identifier(|s)(?-i)",
    "T(?i)rial(|s) registration(?-i)",
    "C(?i)linical trial(|s) registration(?-i)",
    "S(?i)tudy registration(?-i)"
  )

  a <-
    reg_title_synonyms %>%
    lapply(.bound) %>%
    lapply(.title_strict) %>%
    .encase %>%
    grep(article, perl = T)

  if (!!length(a)) {

    if (nchar(article[a + 1]) == 0) {
      b <- c(a, a + 2)
    } else {
      b <- c(a, a + 1)
    }

    is_true <- TRUE
    if (is_true) return(b)

  }

  a <-
    reg_title_synonyms %>%
    lapply(.bound) %>%
    lapply(.title_strict, within_text = T) %>%
    .encase %>%
    grep(article, perl = T)

  if (!!length(a)) {

    is_true <- TRUE
    a <- a[is_true]

  }

  return(a)
}


#' Identify registration titles - specific
#'
#' Extract the index of mentions such as: "Retrospective clinical trial
#'     registration:"
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_reg_title_3 <- function(article) {

  b <- integer()
  d <- integer()
  synonyms <- .create_synonyms()
  punct <-

    # Protocol only contributed to FPs due to protocol ethical approval
    registration_synonyms <- c(
      "Registration",
      "Clinical [Tt]rial",
      "Trial"
    )

  number_synonyms <- c(
    "registration",
    "number",
    "no(|s)(|\\.)",
    "number(|s)",
    "#",
    "ID(|s)",
    "identifier(|s)",
    "registration"
  )

  start <-  "^.{0,1}[A-Z](?i)\\w+"
  registration <- registration_synonyms %>% .bound %>% .encase
  number <- number_synonyms %>% .bound %>% .encase
  finish <- "(| \\w+)(\\.|:|-+)(?-i)"

  a <-
    paste(start, registration, number, finish, sep = "\\s*") %>%
    paste0("$") %>%
    grep(article, perl = T)

  if (!!length(a)) {

    for (i in seq_along(a)) {

      if (nchar(article[a[i] + 1]) == 0) {
        d <- c(a[i], a[i] + 2)
      } else {
        d <- c(a[i], a[i] + 1)
      }

      is_true <- any(negate_reg_title_1(article[d]))
      if (is_true) b <- c(b, d)
    }

    if (!!length(b)) return(unique(b))

  }

  a <-
    paste(start, registration, number, finish, sep = "\\s*") %>%
    grep(article, perl = T)

  if (!!length(a)) {

    is_true <- negate_reg_title_1(article[a])
    a <- a[is_true]

  }

  return(a)
}


#' Identify registration titles - specific
#'
#' Extract the index of mentions such as: "Clinical trial registration detail:"
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_reg_title_4 <- function(article) {

  b <- integer()
  d <- integer()
  synonyms <- .create_synonyms()

  # Protocol only contributed to FPs due to protocol ethical approval
  registration_synonyms <- c(
    "R(?i)egistration",
    "C(?i)linical [Tt]rial",
    "T(?i)rial"
  )

  number_synonyms <- c(
    "registration",
    "number",
    "no(|s)(|\\.)",
    "number(|s)",
    "#",
    "ID(|s)",
    "identifier(|s)",
    "registration"
  )

  start <-  "^.{0,1}"
  registration <- registration_synonyms %>% .bound %>% .encase
  number <- number_synonyms %>% .bound %>% .encase
  finish <- "(| \\w+)(\\.|:|-+)(?-i)"

  a <-
    paste(start, registration, number, finish, sep = "\\s*") %>%
    paste0("$") %>%
    grep(article, perl = T)

  if (!!length(a)) {

    for (i in seq_along(a)) {

      if (nchar(article[a[i] + 1]) == 0) {
        d <- c(a[i], a[i] + 2)
      } else {
        d <- c(a[i], a[i] + 1)
      }

      is_true <- any(negate_reg_title_1(article[d]))
      if (is_true) b <- c(b, d)
    }

    if (!!length(b)) return(unique(b))

  }

  a <-
    paste(start, registration, number, finish, sep = "\\s*") %>%
    grep(article, perl = T)

  if (!!length(a)) {

    is_true <- negate_reg_title_1(article[a])
    a <- a[is_true]

  }

  return(a)
}


#' Identify mentions of protocol
#'
#' Extract the index of mentions such as: "The complete study protocol has been
#'     published previously (Supplement 1)"
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_protocol_1 <- function(article) {

  synonyms <- .create_synonyms()
  words <- c("study_protocol", "published", "previously")

  synonyms %>%
    magrittr::extract(words) %>%
    lapply(.bound) %>%
    lapply(.encase) %>%
    paste(collapse = synonyms$txt) %>%
    grep(article, perl = T)

}


#' Identify mentions of protocol
#'
#' Extract the index of mentions such as: "Alliance for Clinical Trials in
#'     Oncology (formerly Cancer and Leukemia Group B) Protocol #369901"
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_protocol_2 <- function(article) {

  grep("[Pp]rotocol .{0,5}(|[A-Z]+)[0-9]{5}", article, perl = T)

}


#' Identify mentions of funding followed by NCT
#'
#' Extract the index of mentions such as: "Funded by: the National Heart, Lung,
#'     and Blood Institute, the National Institute of Diabetes and Digestive and
#'     Kidney Disease, and others; SPECS ClinicalTrials.gov number, NCT00443599;
#'     Nutrition and Obesity Center at Harvard; NIH 5P30DK040561-17"
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_funded_ct_1 <- function(article) {

  synonyms <- .create_synonyms()

  # Anything more general contributed more false than true matches
  funded_by_SOME_ct_NCT <- paste0(
    "[Ff]unded by",
    synonyms$txt,
    "[A-Z]{2,7}.{0,20}[Cc]linical[Tt]rial.{0,20}NCT[0-9]{8}"
  )

  grep(funded_by_SOME_ct_NCT, article, perl = T)

}


#' Negate unwanted mentions of registry
#'
#' Negate mentions of registry such as: "Ethics approval and consent to
#'     participate This study was approved by the Institutional Review Board of
#'     Chang Gung Memorial Hospital under registry number 201601023B0."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
negate_registry_1 <- function(article) {

  synonyms <- .create_synonyms()

  research <- synonyms$research %>% .bound %>% .encase
  registry <- synonyms$registry %>% .bound %>% .encase
  code <- "[\\s,;:]+([A-Z]{2,10}\\s*[0-9]{2}|[0-9]{5})"

  paste(research, "approv", registry, code, sep = synonyms$txt) %>%
    grepl(article, perl = T)

}


#' Negate unwanted mentions of title
#'
#' Negate title mentions that refer to unwanted text.
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
negate_reg_title_1 <- function(article) {

  grepl("[A-Z]{2}\\s*[0-9]{2}|[0-9]{5}", article, perl = T)

}


#' Remove mentions of previously reported registered studies
#'
#' Removes mentions such as: "An active o <- servational cohort study was
#'     conducted as previously reported (ClinicalTrials.gov identifier
#'     NCT01280162) [16]."
#'
#' @param article A List with paragraphs of interest.
#' @return The list of paragraphs without mentions of financial COIs.
#' @noRd
obliterate_refs_1 <- function(article) {

  # Good for finding, but not for substituting b/c it's a lookahead
  # words <- c(
  #   # positive lookahead makes these phrases interchangeable
  #   "(?=[a-zA-Z0-9\\s,()-]*(financial|support))",
  #   "(?=[a-zA-Z0-9\\s,()-]*(conflict|competing))"
  # )

  # reported_synonyms <- c(
  #   "reported",
  #   "published"
  # )
  #
  # cohort_synonyms <- c(
  #   "cohort study",
  #   "retrospective\\b",
  #   "propsecitve study",
  #   "nested",
  #   "case( |\\s*-\\s*)control"
  # )
  #
  # gsub("(reported|published).{0,20}([Cc]linical[Tt]rial|NCT", "", article, perl = T)

  gsub("NCT[0-9]{8}.{3}[0-9]+", "", article, perl = T)

  # TODO: This to be inserted only for get_ct_2!

}


#' Remove references
#'
#' Removes mentions such as: "An active o <- servational cohort study was
#'     conducted as previously reported (ClinicalTrials.gov identifier
#'     NCT01280162) [16]."
#'
#' @param article A List with paragraphs of interest.
#' @return The list of paragraphs without mentions of financial COIs.
#' @noRd
obliterate_references_1 <- function(article) {

  # If within References or under references and starts with 1. or contains et al. then remove.

  ref_from <- .where_refs_txt(article)

  if (!!length(ref_from)) {

    ref_to <- length(article)

    article[ref_from] <- ""
    article[ref_from:ref_to] <-
      gsub("^([0-9]{1,3}\\.\\s|.*et al\\.).*$", "",
      article[ref_from:ref_to], perl = T)

  }
  return(article)
}


#' Remove semicolons when within parentheses
#'
#' Removes mentions such as: "guidelines for diagnostic studies (trial
#'     registered at www.clinicaltrial.gov; NCT01697930)."
#'
#' @param article A List with paragraphs of interest.
#' @return The list of paragraphs without mentions of financial COIs.
#' @noRd
obliterate_semicolon_1 <- function(article) {

  gsub("(\\(.*); (.*\\))", "\\1 - \\2", article)

}


#' Remove commas
#'
#' Removes commas to simplify regular expressions.
#'
#' @param article A List with paragraphs of interest.
#' @return The list of paragraphs without mentions of financial COIs.
#' @noRd
obliterate_comma_1 <- function(article) {

  gsub(", ", " ", article)

}


#' Remove apostrophe
#'
#' Removes commas to make ease creation of regular expressions. After
#'     implmenting this function, "ball's" should become balls and l'Alba
#'     should become lAlba and balls' into balls.
#'
#' @param article A List with paragraphs of interest.
#' @return The list of paragraphs without mentions of financial COIs.
#' @noRd
obliterate_apostrophe_1 <- function(article) {

  txt_1 <- "([a-zA-Z])'([a-zA-Z])"
  txt_2 <- "[a-z]+s'"

  article %>%
    purrr::map(gsub, pattern = txt_1, replacement = "\\1\\2") %>%
    purrr::map(gsub, pattern = txt_2, replacement = "s")

}


#' Remove hash
#'
#' Removes hashes to make ease creation of regular expressions.
#'
#' @param article A List with paragraphs of interest.
#' @return The list of paragraphs without mentions of financial COIs.
#' @noRd
obliterate_hash_1 <- function(article) {

  gsub("#", "", article)

}


#' Find the Methods section
#'
#' Find the index of the start of the Methods section.
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest

#' @noRd
find_methods <- function(article) {

  method_index <- integer()

  synonyms <- .create_synonyms()
  words <- c("Methods", "Abstract", "Results", "Conclusion")

  method_index <-
    synonyms %>%
    magrittr::extract(words[1]) %>%
    lapply(.title_strict) %>%
    lapply(stringr::str_sub, end = -2) %>%  # remove the $
    # lapply(paste, "($|\\s+[A-Z]") %>%  # TODO: if too sensitive, uncomment
    lapply(.encase) %>%
    paste() %>%
    grep(article, perl = T)

  if (!!length(method_index)) {

    method_index <- method_index[length(method_index)]
    return(method_index)

    # TODO: if too sensitive, uncomment
    # is_abstract <-
    #   synonyms %>%
    #   magrittr::extract(words[2:4]) %>%
    #   grepl(article[(method_index - 3):(method_index + 3)]) %>%
    #   any()
    #
    # if (!is_abstract) {
    #
    #   return(method_index)
    #
    # }
  }

  method_index <-
    synonyms %>%
    magrittr::extract(words[1]) %>%
    lapply(.title_strict, within_text = T) %>%
    lapply(paste, "[A-Z]", sep = "\\s*") %>%
    lapply(.encase) %>%
    paste() %>%
    grep(article, perl = T)

  if (!!length(method_index)) {

    method_index <- method_index[length(method_index)]

  }

  return(method_index)

}


#' Identify mentions of registration on ISRCTN
#'
#' Extract the index of mentions such as: "The study was registered at ISRCTN
#'     (ISRCTN12345678)."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_isrctn_1 <- function(article) {

  grep("\\bISRCTN[0-9]{8}\\b", article, perl = TRUE)

}


#' Identify mentions of registration on ANZCTR
#'
#' Extract the index of mentions such as: "The study was registered with ANZCTR
#'     (ACTRN12614001234567)."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_anzctr_1 <- function(article) {

  grep("\\bACTRN[0-9]{14}\\b", article, perl = TRUE)

}


#' Identify mentions of registration on DRKS
#'
#' Extract the index of mentions such as: "Registered at DRKS (DRKS00012345)."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_drks_1 <- function(article) {

  grep("\\bDRKS[0-9]{8}\\b", article, perl = TRUE)

}


#' Identify mentions of registration on IRCT (Iranian Registry of Clinical Trials)
#'
#' Extract the index of mentions such as: "Registered at IRCT (IRCT20120526009954N3)."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_irct_1 <- function(article) {

  # IRCT IDs follow the format IRCT + digits + uppercase letter + digits
  # e.g. IRCT20120526009954N3, IRCT138707012049N3
  grep("\\bIRCT[0-9]{5,}[A-Z][0-9]+\\b", article, perl = TRUE)

}


#' Identify mentions of registration on UMIN (Japan Primary Registries Network)
#'
#' Extract the index of mentions such as: "Registered at UMIN (UMIN000012345)."
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_umin_1 <- function(article) {

  grep("\\bUMIN[0-9]{9}\\b", article, perl = TRUE)

}


#' Identify mentions of registration on ChiCTR
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_chictr_1 <- function(article) {

  grep("\\bChiCTR[-A-Z]*[0-9]{5,}\\b|Chinese Clinical Trial Registry",
       article, perl = TRUE, ignore.case = TRUE)

}


#' Identify mentions of registered systematic-review protocols on INPLASY
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_inplasy_1 <- function(article) {

  grep("\\bINPLASY[0-9]{5,}\\b|International Platform of Registered Systematic Review",
       article, perl = TRUE, ignore.case = TRUE)

}


#' Identify registered protocols hosted on OSF
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_osf_protocol_1 <- function(article) {

  grep("protocol.{0,80}(registered|registration).{0,80}(Open Science Framework|OSF|osf\\.io|10\\.17605/OSF)",
       article, perl = TRUE, ignore.case = TRUE)

}


#' Identify preregistered studies hosted on OSF.
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_osf_preregistered_1 <- function(article) {

  grep(
    "\\b(this|the|our) (study|work|trial|review|protocol).{0,80}pre-?registered.{0,100}(Open Science Framework|OSF|osf\\.io|10\\.17605/OSF)",
    article,
    perl = TRUE,
    ignore.case = TRUE
  )

}


#' Identify blinded PROSPERO registration statements.
#'
#' @param article A string or a list of strings.
#' @return Index of element with phrase of interest
#' @noRd
get_prospero_redacted_1 <- function(article) {

  grep(
    "\\bprotocol for (this|the) review.{0,100}registered with PROSPERO.{0,100}CRD number redacted",
    article,
    perl = TRUE,
    ignore.case = TRUE
  )

}


#' Exclude registration-like statements that are not study registration.
#'
#' @param article A string or a list of strings.
#' @return Logical vector; TRUE where the candidate should be excluded.
#' @noRd
.is_false_register_statement <- function(article) {

  pattern <- paste(
    "not registered",
    "protocol was not registered",
    "clinical trial number\\s*(not applicable|n/?a)",
    "\\bnot applicable\\b",
    "irb registration no",
    "institutional review board.{0,80}registration no",
    "review board.{0,80}registration no",
    "ethical approval.{0,80}registration number",
    "ethics approval.{0,80}registration number",
    "ethical review authority",
    "institutional ethics committee.{0,80}registration number",
    "ecr/[0-9]+/inst",
    "\\brio\\b.{0,80}(university|registration|research & innovation)",
    "research & innovation organisation",
    "research and innovation organisation",
    "\\bsisgen\\b",
    "genetic heritage",
    "permanent authorization to access",
    "\\bcnil\\b.{0,80}(decision|authorization)",
    "registration id:\\s*mr-",
    "medical research registration and filing information system",
    "protocol described by",
    "according to the protocol described by",
    sep = "|"
  )

  grepl(pattern, article, perl = TRUE, ignore.case = TRUE)

}


#' Identify and extract Registration statements in TXT files.
#'
#' Takes a TXT file and returns data related to the presence of a Registration
#'     statement, including whether a Registration statement exists. If a
#'     Registration statement exists, it extracts it.
#'
#' @param filename The name of the TXT file as a string.
#' @return A dataframe of results. It returns the PMID (if this was part of the
#'     filename and preceded by PMID), whether a registration statement was
#'     found, the identified statement, whether the text was deemed relevant
#'     (e.g. contained the word registration), whether a Methods section was
#'     identified, whether an NCT number was identified, whether a registration
#'     was explicitly identified (defunct) and whether each labeling function
#'     identified a relevant text or not. The labeling functions are returned to
#'     add flexibility in how this package is used; for example, future
#'     definitions of Registration may differ from the one we used.
#' @examples
#' \dontrun{
#' # Path to PMC XML.
#' filepath <- "../inst/extdata/00003-PMID26637448-PMC4737611.txt"
#'
#' # Identify and extract meta-data and indicators of transparency.
#' results_table <- rt_register(filepath)
#' }
#' @export
rt_register <- function(filename) {

  article <- basename(filename) %>% stringr::word(sep = "\\.")
  pmid <- gsub("^.*PMID([0-9]+).*$", "\\1", filename)

  dict <- .create_synonyms()

  # Fix common PDF-to-text artifacts (hyphenation and mid-word/number line
  # breaks), then split into paragraphs.
  broken_1 <- "([a-z]+)-\n+([a-z]+)"
  broken_2 <- "([a-z]+)(|,|;)\n+([a-z]+)"
  broken_3 <- "([0-9]+)-\n+([0-9]+)"
  paragraphs <-
    readr::read_file(filename) %>%
    purrr::map(gsub, pattern = broken_1, replacement = "\\1\\2") %>%
    purrr::map(gsub, pattern = broken_2, replacement = "\\1\\3") %>%
    purrr::map(gsub, pattern = broken_3, replacement = "\\1\\2") %>%
    purrr::map(strsplit, "\n| \\*") %>%
    unlist() %>%
    utf8::utf8_encode()
  paragraphs <- paragraphs[nzchar(trimws(paragraphs))]

  # A TXT file carries no XML structure. Route all text through the Methods slot
  # so the shared core's is_method gate passes, and disable the XML-structural
  # route. Detection then runs through the same helpers as rt_register_pmc().
  # Without an article-type tag we cannot exclude reviews, so every TXT article
  # is treated as research (is_research = TRUE).
  article_ls <- list(ack = character(0), methods = paragraphs,
                     abstract = character(0), footnotes = character(0))
  pmc_reg_ls <- list(is_research = TRUE, is_review = FALSE,
                     is_register_pred = FALSE, register_text = "",
                     type = "", is_reg_pmc_title = FALSE)

  res <- .rt_register_pmc(article_ls, pmc_reg_ls, dict)

  tibble::tibble(
    article,
    pmid,
    is_register_pred = res$is_register_pred,
    register_text = res$register_text,
    is_relevant = res$is_relevant_reg,
    is_method = res$is_method,
    is_NCT = res$is_NCT,
    is_explicit = res$is_explicit_reg
  )
}
