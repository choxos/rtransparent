test_that("get_ct_1 detects NCT numbers with registration context", {
  article_with_nct <- c(
    "The study was pre-registered: NCT12345678.",
    "Methods were approved by the IRB."
  )
  article_without_nct <- c(
    "Participants were randomized to two groups.",
    "The outcome was measured at 6 months."
  )

  idx_found <- get_ct_1(article_with_nct)
  expect_true(length(idx_found) > 0, info = "Should detect NCT number with registration context")

  idx_empty <- get_ct_1(article_without_nct)
  expect_equal(length(idx_empty), 0, info = "Should not flag text without NCT")
})


test_that("get_prospero_1 detects PROSPERO registrations", {
  article_with_prospero <- c(
    "This systematic review was registered in PROSPERO (CRD42020123456).",
    "We conducted a comprehensive literature search."
  )
  article_without_prospero <- c(
    "A systematic review was performed.",
    "We searched MEDLINE and Embase."
  )

  idx_found <- get_prospero_1(article_with_prospero)
  expect_true(length(idx_found) > 0, info = "Should detect PROSPERO registration")

  idx_empty <- get_prospero_1(article_without_prospero)
  expect_equal(length(idx_empty), 0, info = "Should not flag text without PROSPERO ID")
})


test_that("get_isrctn_1 detects ISRCTN registrations", {
  article_with_isrctn <- c(
    "The trial was registered at ISRCTN (ISRCTN12345678).",
    "Ethics approval was obtained from the IRB."
  )
  article_without_isrctn <- c(
    "The trial was conducted in London.",
    "All patients signed informed consent."
  )

  idx_found <- get_isrctn_1(article_with_isrctn)
  expect_true(length(idx_found) > 0, info = "Should detect ISRCTN number")

  idx_empty <- get_isrctn_1(article_without_isrctn)
  expect_equal(length(idx_empty), 0, info = "Should not flag text without ISRCTN")
})


test_that("get_anzctr_1 detects ANZCTR registrations", {
  article_with_anzctr <- c(
    "The study was registered with ANZCTR (ACTRN12614001234567).",
    "Written consent was obtained."
  )

  idx_found <- get_anzctr_1(article_with_anzctr)
  expect_true(length(idx_found) > 0, info = "Should detect ACTRN number")
})


test_that("get_drks_1 detects DRKS registrations", {
  article_with_drks <- c(
    "Trial registration: DRKS00012345.",
    "All procedures were approved by the ethics board."
  )

  idx_found <- get_drks_1(article_with_drks)
  expect_true(length(idx_found) > 0, info = "Should detect DRKS number")
})


test_that("get_irct_1 detects IRCT registrations", {
  article_with_irct <- c(
    "This trial was registered at IRCT (IRCT20120526009954N3).",
    "Participants provided written consent."
  )

  idx_found <- get_irct_1(article_with_irct)
  expect_true(length(idx_found) > 0, info = "Should detect IRCT number")
})


test_that("get_umin_1 detects UMIN registrations", {
  article_with_umin <- c(
    "The study was registered at UMIN (UMIN000012345).",
    "Ethical approval was obtained."
  )

  idx_found <- get_umin_1(article_with_umin)
  expect_true(length(idx_found) > 0, info = "Should detect UMIN number")
})


test_that("new registry helpers detect ChiCTR, INPLASY and OSF protocols", {
  expect_true(length(get_chictr_1(
    "This trial was registered at Chinese Clinical Trial Registry (ChiCTR2300070763)."
  )) > 0)
  expect_true(length(get_inplasy_1(
    "This systematic review was registered with INPLASY, registration number INPLASY202560049."
  )) > 0)
  expect_true(length(get_osf_protocol_1(
    "The protocol of this scoping review was registered on the Open Science Framework and is publicly available at https://osf.io/6h3vm."
  )) > 0)
})


test_that("validation registry helpers detect flexible CT, OSF and blinded PROSPERO text", {
  expect_true(length(get_ct_4(
    "The study is registered at clinicaltrials.gov (NCT03297034)."
  )) > 0)
  expect_true(length(get_ct_4(
    "Clinical trial registration www.clinicaltrials.gov identifier is NCT05856578."
  )) > 0)
  expect_true(length(get_ct_4(
    "It was registered at ClinicalTrial.gov with registration number NCT05856578."
  )) > 0)
  expect_true(length(get_osf_preregistered_1(
    "This work was pre-registered at: https://osf.io/gzh2j/."
  )) > 0)
  expect_true(length(get_osf_preregistered_1(
    "This study was pre-registered on the Open Science Framework (OSF)."
  )) > 0)
  expect_true(length(get_prospero_redacted_1(
    "The protocol for this review was registered with PROSPERO (CRD number redacted for anonymity)."
  )) > 0)
})


test_that("registration false-statement guard rejects IRB and not applicable text", {
  false_text <- c(
    "Clinical trial number Not applicable.",
    "Ethical clearance was granted by the Institutional Review Board (IRB Registration No. HA-01-R-104).",
    "As this was a narrative review, the protocol was not registered.",
    "The study was reviewed under RIO University of Southern Denmark registration.",
    "The research was registered in SisGen for genetic heritage access.",
    "The Institutional Ethics Committee registration number is ECR/1234/Inst."
  )
  expect_true(all(rtransparent:::.is_false_register_statement(false_text)))
  expect_false(rtransparent:::.is_false_register_statement(
    "The study was registered at clinicaltrials.gov (NCT03297034)."
  ))
})


test_that("registry helpers return integer(0) for empty/non-matching input", {
  empty <- character(0)
  non_matching <- c("This study examined lung cancer.", "Results were significant.")

  expect_equal(get_isrctn_1(empty), integer(0))
  expect_equal(get_anzctr_1(empty), integer(0))
  expect_equal(get_drks_1(empty), integer(0))
  expect_equal(get_irct_1(non_matching), integer(0))
  expect_equal(get_umin_1(non_matching), integer(0))
  expect_equal(get_chictr_1(non_matching), integer(0))
  expect_equal(get_inplasy_1(non_matching), integer(0))
  expect_equal(get_osf_protocol_1(non_matching), integer(0))
  expect_equal(get_osf_preregistered_1(non_matching), integer(0))
  expect_equal(get_prospero_redacted_1(non_matching), integer(0))
})

test_that(".which_ct_4 detects varied ClinicalTrials.gov NCT phrasings", {
  pos <- c(
    "The RCT is registered with ClinicalTrials.gov (NCT04347291).",
    "This trial was prospectively registered (NCT01234567).",
    "Trial registration number NCT09876543.",
    "The study was registered on ClinicalTrials.gov, NCT05555555."
  )
  for (s in pos) {
    expect_true(length(rtransparent:::.which_ct_4(s)) > 0,
                info = paste("should detect:", s))
  }
  # A trial cited by its id, without any registration of this study, is not a
  # registration of the present article.
  expect_equal(
    length(rtransparent:::.which_ct_4(
      "Efficacy was demonstrated in the LUMINOSITY trial (NCT05012345).")),
    0
  )
})
