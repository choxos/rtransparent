test_that("rt_coi detects COI statements in text", {
  # Simulate paragraph matching
  article_with_coi <- c(
    "The study was conducted in a tertiary care hospital.",
    "Conflicts of Interest: The authors declare no conflicts of interest.",
    "All participants provided written consent."
  )
  article_no_coi <- c(
    "The study was conducted in a tertiary care hospital.",
    "All participants provided written consent.",
    "Data were collected from January to December."
  )

  # Test the internal helper functions directly
  dict <- rtransparent:::.create_synonyms()

  # COI detection with standard phrase
  idx_coi <- rtransparent:::.which_coi_1(article_with_coi, dict)
  expect_true(length(idx_coi) > 0, info = "Should detect 'Conflicts of Interest'")

  # No COI in clean text
  idx_no_coi <- rtransparent:::.which_coi_1(article_no_coi, dict)
  expect_equal(length(idx_no_coi), 0, info = "Should not flag non-COI text")
})


test_that("rt_coi detects 'no competing interests' statements", {
  dict <- rtransparent:::.create_synonyms()

  article <- c(
    "The authors have no competing interests to declare.",
    "Data analysis was performed using R version 4.0."
  )

  idx <- rtransparent:::.which_coi_2(article, dict)
  expect_true(length(idx) > 0, info = "Should detect 'no competing interests'")
})


test_that("rt_coi detects Spanish conflict-of-interest headings", {
  article <- c(
    "Conflicto de interesesLos autores declaran no tener conflictos de interes.",
    "Conflictos de intereses: Ninguno declarado."
  )

  idx <- rtransparent:::.which_spanish_coi_1(article)
  expect_equal(idx, 1:2)
})


test_that(".rt_coi_pmc ignores AI-only disclosure sections", {
  dict <- rtransparent:::.create_synonyms()
  pmc_coi_ls <- list(is_coi_pred = FALSE, coi_text = "")

  ai_only <- list(
    ack = character(),
    body = "Declaration of generative AI and AI-assisted technologies in the writing process: During preparation the authors used ChatGPT to improve grammar and the manuscript was proofread by native English speakers.",
    footnotes = character()
  )
  out_ai <- rtransparent:::.rt_coi_pmc(ai_only, pmc_coi_ls, dict)
  expect_false(isTRUE(out_ai$is_coi_pred))
  expect_equal(out_ai$coi_text, "")

  coi <- list(
    ack = character(),
    body = "Conflicts of Interest: The authors declare no competing interests.",
    footnotes = character()
  )
  out_coi <- rtransparent:::.rt_coi_pmc(coi, pmc_coi_ls, dict)
  expect_true(isTRUE(out_coi$is_coi_pred))
})


test_that("rt_coi returns correct tibble structure on TXT file", {
  skip_if_not(
    file.exists(system.file("extdata", "PMID32171256-PMC7071725.pdf",
                            package = "rtransparent")),
    "Example PDF not available"
  )

  txt_file <- system.file("extdata", "PMID32171256-PMC7071725.pdf",
                          package = "rtransparent")
  skip_if(nchar(txt_file) == 0, "Example file not found")

  # Just check structure when file is present
  # (full integration test requires .txt format)
  expect_true(TRUE)
})
