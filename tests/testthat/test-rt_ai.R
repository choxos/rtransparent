test_that(".detect_ai_disclosure detects positive and negative AI disclosures", {
  pos <- list(
    "Acknowledgments The authors used ChatGPT (OpenAI) to support the manuscript writing process.",
    "During the preparation of this manuscript, the authors used Microsoft Copilot to assist with language refinement and readability.",
    "The authors declare that no generative artificial intelligence or AI-assisted tools were used in the writing, editing or preparation of this manuscript.",
    "Generative AI and AI-assisted technologies were not used in the preparation of this work.",
    "Portions of this manuscript's text were refined for clarity using ChatGPT (GPT-5, OpenAI).",
    "We acknowledge the use of the Gemini large language model (LLM) to improve the readability of the manuscript.",
    "No AI tool was used to produce this article."
  )
  for (s in pos) {
    expect_true(rtransparent:::.detect_ai_disclosure(s)$is_ai_disclosed,
                info = paste("should detect:", s))
  }
})

test_that(".detect_ai_disclosure does not flag AI used as a research method", {
  neg <- list(
    "We used a large language model to classify the clinical notes into diagnostic categories.",
    "An artificial intelligence model achieved an AUC of 0.92 for tumor detection.",
    "AI, artificial intelligence; LLM, large language model; NLP, natural language processing.",
    "ChatGPT was evaluated as a tool for answering patient questions about diabetes.",
    "The authors thank the reviewers for their helpful comments."
  )
  for (s in neg) {
    expect_false(rtransparent:::.detect_ai_disclosure(s)$is_ai_disclosed,
                 info = paste("should NOT detect:", s))
  }
})

test_that("rt_ai_pmc applies the 2023 year gate", {
  xml <- system.file("extdata", "PMID32171256-PMC7071725.xml", package = "rtransparent")
  skip_if(xml == "")
  r <- rt_ai_pmc(xml, remove_ns = TRUE)
  expect_true(r$is_success)
  # The bundled example article predates 2023, so AI disclosure is not evaluated.
  expect_lt(r$year, 2023)
  expect_true(is.na(r$is_ai_pred))
})

test_that("rt_all_pmc includes the AI indicator", {
  xml <- system.file("extdata", "PMID32171256-PMC7071725.xml", package = "rtransparent")
  skip_if(xml == "")
  a <- rt_all_pmc(xml, remove_ns = TRUE)
  expect_true("is_ai_pred" %in% names(a))
  expect_true("year" %in% names(a))
})

test_that(".ai_declaration_section recognizes 'Statement on the use of AI' titles", {
  xml <- xml2::read_xml(paste0(
    "<article><body>",
    "<sec><title>Statement on the use of artificial intelligence</title>",
    "<p>The authors declare that no generative AI was used.</p></sec>",
    "</body></article>"))
  expect_gt(nchar(rtransparent:::.ai_declaration_section(xml)), 0)

  xml2 <- xml2::read_xml(
    "<article><body><sec><title>Statistical analysis</title><p>We used R.</p></sec></body></article>")
  expect_equal(nchar(rtransparent:::.ai_declaration_section(xml2)), 0)
})
