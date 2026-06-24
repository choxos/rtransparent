.run_rt_reporting <- function(text, pmid = "12345678") {
  f <- tempfile(pattern = paste0("PMID", pmid, "-"), fileext = ".txt")
  writeLines(text, f)
  on.exit(unlink(f), add = TRUE)
  rt_reporting(f)
}

test_that("rt_reporting detects named reporting guidelines and which one", {
  cases <- list(
    PRISMA  = "We conducted this systematic review in accordance with the PRISMA 2020 guidelines.",
    CONSORT = "The trial was reported following the CONSORT statement and its flow diagram.",
    STROBE  = "This observational study was reported according to the STROBE checklist.",
    ARRIVE  = "Animal experiments are reported in line with the ARRIVE guidelines.",
    TRIPOD  = "The model was reported using the TRIPOD statement."
  )
  for (nm in names(cases)) {
    r <- .run_rt_reporting(cases[[nm]])
    expect_true(r$is_reporting_pred, info = nm)
    expect_true(grepl(nm, r$reporting_guideline), info = nm)
  }
})

test_that("rt_reporting does not fire on the ordinary-word senses of overloaded acronyms", {
  neg <- c(
    "Patients received the standard of care and we record their outcomes.",
    "In the spirit of collaboration, the authors agree on the analysis plan.",
    "We reviewed each medical record for the primary outcome.",
    "We enrolled 200 patients and measured blood pressure over 12 weeks."
  )
  for (s in neg) expect_false(.run_rt_reporting(s)$is_reporting_pred, info = s)
})

test_that("rt_reporting accepts overloaded acronyms next to a guideline noun", {
  expect_true(.run_rt_reporting(
    "The protocol was prepared following the SPIRIT 2013 statement.")$is_reporting_pred)
  expect_true(.run_rt_reporting(
    "Qualitative findings were reported using the SRQR and COREQ checklists.")$is_reporting_pred)
})

test_that("rt_reporting detects a spelled-out guideline name", {
  r <- .run_rt_reporting(paste("This systematic review was conducted following the",
                               "Preferred Reporting Items for Systematic Reviews and Meta-Analyses."))
  expect_true(r$is_reporting_pred)
  expect_true(grepl("PRISMA", r$reporting_guideline))
})

test_that("rt_reporting ignores animal-welfare and clinical guidelines", {
  neg <- c(
    "Animals were handled according to the Guide for the Care and Use of Laboratory Animals.",
    "Treatment followed the ESC clinical practice guidelines for heart failure.",
    "Variants were classified per the ACMG guidelines."
  )
  for (s in neg) expect_false(.run_rt_reporting(s)$is_reporting_pred, info = s)
})

test_that("rt_reporting returns the documented schema and PMID", {
  r <- .run_rt_reporting("Reported per the PRISMA guideline.", pmid = "99887766")
  expect_identical(names(r),
                   c("article", "pmid", "is_reporting_pred", "reporting_guideline", "reporting_text"))
  expect_equal(r$pmid, "99887766")
})

test_that("rt_reporting does not fire on guideline discourse, background, or extraction", {
  neg <- c(
    "The PRISMA statement is a widely used guideline for reporting systematic reviews.",
    "We extracted whether included trials adhered to the CONSORT statement.",
    "Background: CONSORT reporting guidelines improve clinical trial transparency.",
    "Reporting quality of the included studies was assessed using the STROBE checklist.",
    "Adherence to CONSORT among the reviewed trials was low."
  )
  for (s in neg) expect_false(.run_rt_reporting(s)$is_reporting_pred, info = s)
})

test_that("rt_reporting_pmc and rt_all_pmc expose and agree on the reporting columns", {
  xml <- system.file("extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency")
  skip_if(xml == "")
  rp <- rt_reporting_pmc(xml, remove_ns = TRUE)
  expect_true(rp$is_success)
  expect_true(all(c("is_reporting_pred", "reporting_guideline") %in% names(rp)))

  a <- rt_all_pmc(xml, remove_ns = TRUE)
  expect_true(all(c("is_reporting_pred", "reporting_guideline") %in% names(a)))
  # Parity: combined output equals the standalone detector.
  expect_equal(a$is_reporting_pred, rp$is_reporting_pred)
  expect_equal(a$reporting_guideline, rp$reporting_guideline)
})

test_that("rt_reporting_pmc returns is_success = FALSE on a malformed file", {
  f <- tempfile(fileext = ".xml"); writeLines("<broken", f); on.exit(unlink(f))
  expect_false(rt_reporting_pmc(f, remove_ns = TRUE)$is_success)
})
