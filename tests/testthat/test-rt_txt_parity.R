# The TXT detectors (rt_coi/rt_fund/rt_register) delegate to the same cores as
# the PMC detectors. These exercise the public entry points end to end.

write_txt <- function(lines) {
  f <- tempfile(fileext = ".txt")
  writeLines(lines, f)
  f
}

test_that("rt_coi detects a competing-interests declaration", {
  f <- write_txt(c("Conflict of interest",
                   "The authors declare no competing interests."))
  on.exit(unlink(f), add = TRUE)
  expect_true(rt_coi(f)$is_coi_pred)
})

test_that("rt_coi returns FALSE with no COI statement", {
  f <- write_txt(c("Introduction", "We studied X and found Y."))
  on.exit(unlink(f), add = TRUE)
  expect_false(rt_coi(f)$is_coi_pred)
})

test_that("rt_fund detects a funding statement", {
  f <- write_txt(c("Acknowledgements",
                   paste("This work was supported by grant R01CA123456 from the",
                         "National Institutes of Health.")))
  on.exit(unlink(f), add = TRUE)
  expect_true(rt_fund(f)$is_funded_pred)
})

test_that("rt_fund returns FALSE for a no-funding declaration", {
  f <- write_txt(c("Funding",
                   paste("This research received no specific grant from any",
                         "funding agency.")))
  on.exit(unlink(f), add = TRUE)
  expect_false(rt_fund(f)$is_funded_pred)
})

test_that("rt_register detects a trial registration", {
  f <- write_txt(c("Methods",
                   paste("This randomized trial was registered at",
                         "ClinicalTrials.gov (NCT01234567)."),
                   "Patients were enrolled between 2019 and 2020."))
  on.exit(unlink(f), add = TRUE)
  out <- rt_register(f)
  expect_true(out$is_register_pred)
  expect_true(out$is_NCT)
})

test_that("rt_register returns FALSE with no registration", {
  f <- write_txt(c("Methods", "We recruited 100 patients and measured outcomes."))
  on.exit(unlink(f), add = TRUE)
  expect_false(rt_register(f)$is_register_pred)
})
