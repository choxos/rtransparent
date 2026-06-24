#' rtransparency: Identify indicators of transparency in the biomedical literature
#'
#' Detects and extracts ten indicators of transparency (conflicts of interest,
#' funding, protocol registration, novelty, replication, data sharing, code
#' sharing, disclosure of generative-AI use, open-access licensing, and
#' reporting-guideline use) from PubMed Central XML or plain-text articles. For
#' each indicator it returns a prediction and the statement or value that
#' triggered it. This package builds on the original \pkg{rtransparent} tool of
#' Serghiou et al. (2021).
#'
#' @importFrom magrittr %>%
#' @importFrom magrittr %<>%
#' @importFrom rlang .data
#' @importFrom utils tail
"_PACKAGE"
