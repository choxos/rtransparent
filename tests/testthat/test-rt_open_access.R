test_that(".classify_license maps URLs and prose to canonical identifiers", {
  cl <- rtransparency:::.classify_license
  expect_equal(cl("http://creativecommons.org/licenses/by/4.0/"), "CC-BY-4.0")
  expect_equal(cl("https://creativecommons.org/licenses/by-nc-nd/4.0/"), "CC-BY-NC-ND-4.0")
  expect_equal(cl("Creative Commons Attribution-NonCommercial 4.0 License"), "CC-BY-NC-4.0")
  expect_equal(cl("https://creativecommons.org/publicdomain/zero/1.0/"), "CC0-1.0")
  # A CC-BY article that also carries a CC0 data-waiver boilerplate stays CC-BY.
  expect_equal(
    cl(c("creativecommons.org/licenses/by/4.0/",
         "The Creative Commons public domain dedication waiver",
         "creativecommons.org/publicdomain/zero/1.0/ applies to the data")),
    "CC-BY-4.0"
  )
  # Retained copyright is not an open license.
  expect_equal(cl("(c) 2020 The Authors. All rights reserved."), "")
  expect_equal(cl(character(0)), "")
})

test_that("rt_oa_pmc reads the license from the example PMC XML", {
  xml <- system.file("extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency")
  skip_if(xml == "")
  r <- rt_oa_pmc(xml, remove_ns = TRUE)
  expect_true(r$is_success)
  expect_true(r$is_open_access)
  expect_equal(r$oa_license, "CC-BY-4.0")
})

test_that("rt_oa detects an open-access license in plain text", {
  f <- tempfile(fileext = ".txt")
  on.exit(unlink(f), add = TRUE)
  writeLines(paste("This is an open access article distributed under the terms of the",
                   "Creative Commons Attribution 4.0 International License",
                   "(http://creativecommons.org/licenses/by/4.0/)."), f)
  r <- rt_oa(f)
  expect_true(r$is_open_access)
  expect_equal(r$oa_license, "CC-BY-4.0")

  g <- tempfile(fileext = ".txt")
  on.exit(unlink(g), add = TRUE)
  writeLines("All rights reserved. Reproduction requires permission from the publisher.", g)
  expect_false(rt_oa(g)$is_open_access)
})

test_that("rt_all_pmc includes the open-access columns and matches rt_oa_pmc", {
  xml <- system.file("extdata", "PMID32171256-PMC7071725.xml", package = "rtransparency")
  skip_if(xml == "")
  a <- rt_all_pmc(xml, remove_ns = TRUE)
  expect_true(all(c("is_open_access", "oa_license", "oa_text") %in% names(a)))
  expect_true(a$is_open_access)
  # Parity: the combined output equals the standalone detector.
  o <- rt_oa_pmc(xml, remove_ns = TRUE)
  expect_equal(a$is_open_access, o$is_open_access)
  expect_equal(a$oa_license, o$oa_license)
})

test_that("rt_oa does not count data/supplement availability or open-access funding", {
  mk <- function(s) { f <- tempfile(fileext = ".txt"); writeLines(s, f); on.exit(unlink(f)); rt_oa(f) }
  # "freely available" refers to data/code, not the article license.
  expect_false(mk(paste("Data and code are freely available at https://github.com/x/y.",
                        "The article is copyright the publisher."))$is_open_access)
  # Open-access *funding* (APC / Projekt DEAL) is not an article license.
  expect_false(mk("Open Access funding was enabled by Projekt DEAL. All rights reserved.")$is_open_access)
  expect_false(mk("The article processing charge was waived. (c) 2024, all rights reserved.")$is_open_access)
})

test_that(".classify_license handles SA, ND and missing-version URLs", {
  cl <- rtransparency:::.classify_license
  expect_equal(cl("https://creativecommons.org/licenses/by-nc-sa/4.0/"), "CC-BY-NC-SA-4.0")
  expect_equal(cl("https://creativecommons.org/licenses/by-sa/3.0/"), "CC-BY-SA-3.0")
  expect_equal(cl("https://creativecommons.org/licenses/by/"), "CC-BY")          # no version
  expect_equal(cl("https://creativecommons.org/licenses/by-nd/4.0/"), "CC-BY-ND-4.0")
})

test_that("rt_oa_pmc returns is_success = FALSE on a malformed file", {
  f <- tempfile(fileext = ".xml"); writeLines("<not-xml", f); on.exit(unlink(f))
  r <- rt_oa_pmc(f, remove_ns = TRUE)
  expect_false(r$is_success)
})
