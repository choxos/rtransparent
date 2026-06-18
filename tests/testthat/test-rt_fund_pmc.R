# Regression tests for the exported rt_fund_pmc(): it must agree with the
# funding prediction produced by rt_all_pmc() and must never predict funding
# without supporting evidence (it previously returned TRUE with empty text).

test_that("a funding-group naming a funder counts even without a statement", {
  # PMC funding-group with a <funding-source> and award id but no narrative
  # <funding-statement>: the named funder is itself a funding disclosure.
  xml <- xml2::read_xml(paste0(
    "<article><front><article-meta><funding-group>",
    "<award-group><funding-source>Ministry of Science and Technology</funding-source>",
    "<award-id>107-2314-B-075-032</award-id></award-group>",
    "</funding-group></article-meta></front><body><p>Methods.</p></body></article>"
  ))
  res <- rtransparent:::.get_fund_pmc(xml, rtransparent:::.create_synonyms())
  expect_true(res$is_fund_pred)
  expect_true(grepl("Ministry of Science", res$fund_text))

  # A funding-group with no funder and no statement is not funding.
  xml0 <- xml2::read_xml(
    "<article><front><article-meta><funding-group/></article-meta></front><body><p>x</p></body></article>"
  )
  expect_false(rtransparent:::.get_fund_pmc(xml0, rtransparent:::.create_synonyms())$is_fund_pred)
})

test_that("rt_fund_pmc rejects no-funding articles and matches rt_all_pmc", {
  fx <- test_path("fixtures", "benchmark")
  skip_if(!dir.exists(fx), "no benchmark fixtures")

  for (id in c("PMC5998853", "PMC6247086")) {
    f <- file.path(fx, paste0(id, ".xml"))
    skip_if(!file.exists(f))
    r <- rtransparent::rt_fund_pmc(f, remove_ns = TRUE)
    expect_false(isTRUE(r$is_fund_pred[1]))
    expect_equal(nchar(r$fund_text[1]), 0)
  }

  f <- file.path(fx, "PMC5684277.xml")
  if (file.exists(f)) {
    r <- rtransparent::rt_fund_pmc(f, remove_ns = TRUE)
    expect_true(isTRUE(r$is_fund_pred[1]))
  }
})

test_that("rt_fund_pmc never predicts funding without evidence", {
  fx <- test_path("fixtures", "benchmark")
  skip_if(!dir.exists(fx), "no benchmark fixtures")

  for (f in list.files(fx, "\\.xml$", full.names = TRUE)) {
    r <- rtransparent::rt_fund_pmc(f, remove_ns = TRUE)
    if (isTRUE(r$is_fund_pred[1])) {
      evidence <- nchar(r$fund_text[1]) > 0 ||
        isTRUE(r$is_fund_pmc_group[1]) ||
        ("fund_pmc_anysource" %in% names(r) && nchar(r$fund_pmc_anysource[1]) > 0)
      expect_true(evidence, info = basename(f))
    }

    a <- rtransparent::rt_all_pmc(f, remove_ns = TRUE)
    if ("is_fund_pred" %in% names(a)) {
      expect_identical(isTRUE(r$is_fund_pred[1]), isTRUE(a$is_fund_pred[1]),
                       info = basename(f))
    }
  }
})

test_that("funding absence negation covers common PMC no-funding statements", {
  absent <- c(
    "Funding The authors have nothing to report.",
    "Funding information: This case report was not funded.",
    "Funding Not applicable.",
    "Funding Nil.",
    "Funding Nothing to declare.",
    "Funding",
    "FUNDING/SUPPORT",
    "Financial support None declared.",
    "This article was commissioned without any funding or sponsorship.",
    "Funding/support None.",
    "No financial support is available for the study.",
    "Funding There are no relevant sources of funding pertaining to this article.",
    "This conclusion was supported by previous studies and clinical guidelines.",
    "The decision was supported by contextual factors.",
    "Waiver of informed consent was granted by the review board.",
    "This association was supported by PSM analysis.",
    "There are no funders to report.",
    "The author(s) declared that no grants were involved in supporting this work.",
    "Author contributions: funding acquisition, writing and editing.",
    "This work has not been funded yet.",
    "This research received no specific grant from any funding agency in the public, commercial or not-for-profit sectors.",
    "Funding The authors declare that no funds, grants or other support were received during the preparation of this manuscript.",
    "No funds have been received for this study.",
    "The authors have not received any funding or benefits from industry to conduct this study.",
    "Funding The study was not supported by any funding.",
    "This work was not supported by any funding.",
    "The study was not supported by any grant."
  )

  expect_true(all(rtransparent:::negate_absence_1(absent)))
})

test_that("open-access publishing funding is not a research-funding acknowledgment", {
  # "Open access funding ..." pays the article-processing charge; the noun
  # phrase is stripped so its "funding ... by <consortium>" wording stops
  # registering as a funding acknowledgment.
  oa <- c(
    "Open Access funding enabled and organized by Projekt DEAL.",
    "Open Access funding enabled and organized by CAUL and its Member Institutions.",
    "Open access funding provided by IReL."
  )
  stripped <- rtransparent:::obliterate_misleading_fund_1(oa)
  expect_length(rtransparent:::get_fund_acknow_new(stripped), 0)
  expect_length(rtransparent:::get_fund_acknow(stripped), 0)

  # A genuine grant stated alongside the open-access line is still detected.
  mixed <- rtransparent:::obliterate_misleading_fund_1(
    "Open Access funding enabled and organized by Projekt DEAL. This work was funded by the NIH under grant R01CA000000."
  )
  expect_gt(length(rtransparent:::get_fund_acknow_new(mixed)), 0)
})

test_that("an AOSSM conflict-of-interest disclosure is not read as funding", {
  # Sports-medicine journals introduce author industry ties with this fixed
  # preamble; "received research support from <company>" is a COI, not funding.
  coi <- paste(
    "One or more of the authors has declared the following potential conflict",
    "of interest or source of funding: J.L.C. has received research support from",
    "Vericel and Ossur and is a consultant for Arthrex."
  )
  stripped <- rtransparent:::obliterate_conflict_3(coi)
  expect_false(grepl("research support", stripped, ignore.case = TRUE))
  expect_length(rtransparent:::get_fund_acknow(stripped), 0)
  expect_length(rtransparent:::get_fund_acknow_new(stripped), 0)

  # a genuine funding sentence (no disclosure preamble) is left untouched
  real <- "This study received funding from the National Institutes of Health (R01CA000000)."
  expect_identical(rtransparent:::obliterate_conflict_3(real), real)
})

test_that("get_common_6 detects explicit validation funding phrases", {
  article <- c(
    "This project was funded by Grants NA22OAR4590515 and NA22OAR4590512 by NOAA.",
    "Funding was provided by the Scientific Research Projects Fund of Erciyes University.",
    "Financial support was provided by Professor Shumin Liu.",
    "This study was generously supported by Jingding Medical Tech.",
    "We thank the Deanship of Scientific Research for funding this work through research groups program under Grant No. RGP2/123/45.",
    "M.C.P was supported by the Fonds de recherche du Quebec en Sante award.",
    "This conclusion was supported by PSM analysis.",
    "Research supports hope's benefits."
  )

  idx <- rtransparent:::get_common_6(article)
  expect_equal(idx, 1:6)
})

test_that("positive funding clauses override local no-industry clauses", {
  mixed <- paste(
    "Funding: The development of PACK was funded by the University of Cape Town Lung Institute.",
    "The KTU receives no funding from the pharmaceutical industry.",
    "Funding for the work was provided by PEPFAR via TB/HIV Care, grant no. NU2GGH001933-01."
  )

  expect_true(rtransparent:::has_positive_fund_text(mixed))
  expect_true(rtransparent:::negate_absence_1(mixed))

  pure_absence <- "Funding: The authors received no specific funding for manuscript."
  expect_false(rtransparent:::has_positive_fund_text(pure_absence))
  expect_true(rtransparent:::can_scan_after_negated_fund_tag(pure_absence))

  no_grant <- paste(
    "Funding This research did not receive any specific grant from funding agencies",
    "in the public, commercial, or not-for-profit sectors."
  )
  expect_false(rtransparent:::has_positive_fund_text(no_grant))
})
