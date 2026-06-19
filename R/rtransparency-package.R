#' rtransparency: Identify indicators of transparency in the biomedical literature
#'
#' Detects and extracts eight indicators of transparency (conflicts of interest,
#' funding, protocol registration, novelty, replication, data sharing, code
#' sharing, and disclosure of generative-AI use) from PubMed Central XML or
#' plain-text articles. For each indicator it returns a boolean prediction and
#' the statement that triggered it. This package builds on the original
#' \pkg{rtransparent} tool of Serghiou et al. (2021).
#'
#' @importFrom magrittr %>%
#' @importFrom magrittr %<>%
#' @importFrom rlang .data
#' @importFrom utils tail
"_PACKAGE"
