test_that(".which_replication_replicat_1 detects replication of previous results", {
  article_positive <- c(
    "We replicated previously reported findings in a new cohort.",
    "The replication of earlier results confirmed the association."
  )
  article_negative <- c(
    "The study examined cardiovascular outcomes over 5 years.",
    "A total of 1200 patients were enrolled.",
    "All experimental data were derived from a minimum of three independent replicates and are reported as mean SD.",
    "The assay was performed in triplicate as previously described."
  )

  idx_pos <- rtransparent:::.which_replication_replicat_1(article_positive)
  expect_true(length(idx_pos) > 0, info = "Should detect 'replicated previous findings'")

  idx_neg <- rtransparent:::.which_replication_replicat_1(article_negative)
  expect_equal(length(idx_neg), 0, info = "Should not flag non-replication text")
})


test_that(".which_replication_confirm_1 detects 'confirmed findings from'", {
  article_positive <- c(
    "These results confirmed findings from our earlier study.",
    "The analysis validated results of previous reports."
  )
  article_negative <- c(
    "We performed logistic regression to assess risk factors.",
    "Blood samples were collected at baseline and follow-up.",
    "The findings were confirmed by RT-qPCR in the same samples.",
    "We validated the results of the assay by western blot."
  )

  idx_pos <- rtransparent:::.which_replication_confirm_1(article_positive)
  expect_true(length(idx_pos) > 0, info = "Should detect 'confirmed findings from'")

  idx_neg <- rtransparent:::.which_replication_confirm_1(article_negative)
  expect_equal(length(idx_neg), 0, info = "Should not flag analysis methods as replication")
})


test_that(".which_replication_independent_1 detects 'independently validated'", {
  article_positive <- c(
    "An independent replication study confirmed the association.",
    "The findings were independently validated in a separate dataset."
  )
  article_negative <- c(
    "Independent living was assessed using the ADL scale.",
    "The two groups were matched on age and sex."
  )

  idx_pos <- rtransparent:::.which_replication_independent_1(article_positive)
  expect_true(length(idx_pos) > 0, info = "Should detect 'independently validated'")

  idx_neg <- rtransparent:::.which_replication_independent_1(article_negative)
  expect_equal(length(idx_neg), 0, info = "Should not flag 'independent living' as replication")
})


test_that(".which_replication_validation_1 detects 'validation cohort'", {
  article_positive <- c(
    "Results were confirmed in a validation cohort of 500 patients.",
    "A replication dataset was used to verify the primary findings.",
    "The model underwent internal validation using bootstrap resampling.",
    "These results were validated in the validation cohort.",
    "ROC curve analysis was performed in both the training and independent validation cohorts."
  )
  article_negative <- c(
    "A cohort study was conducted from 2010 to 2020.",
    "The study population included adults aged 18-65."
  )

  idx_pos <- rtransparent:::.which_replication_validation_1(article_positive)
  expect_true(length(idx_pos) > 0, info = "Should detect 'validation cohort'")

  idx_neg <- rtransparent:::.which_replication_validation_1(article_negative)
  expect_equal(length(idx_neg), 0, info = "Should not flag plain cohort description as replication")
})


test_that(".negate_replication_1 correctly identifies negated replication claims", {
  negated_claims <- c(
    "The study failed to replicate the original findings.",
    "We were unable to replicate previously reported results.",
    "Our results did not replicate those from prior work.",
    "This retrospective study was single-centric and lacking external validation.",
    "Future research should validate the model in diverse populations.",
    "Only two biological replicates were available per group.",
    "The mechanism regulates viral replication in infected cells.",
    "The findings were confirmed by RT-qPCR in the same samples.",
    "The OpenBHB dataset includes only training and validation datasets.",
    "Author contributions: methodology, validation, formal analysis.",
    "Further validation across independent cohorts is required.",
    "External validation in independent cohorts will be necessary.",
    "External validation was not available in this study.",
    "The model lacks external validation.",
    "External validation remains necessary before deployment.",
    "The predictive model used five-fold cross-validation.",
    "Non-parametric confirmatory analysis used Mann-Whitney U tests.",
    "Field validation studies would further strengthen the model.",
    "The validation and sensitivity analysis supported the composite indicator.",
    "Prior validation studies have evaluated this questionnaire.",
    "The study aimed to reproduce the results obtained with oxaliplatin.",
    "Repeated measures were sampled repeatedly during follow-up.",
    "Newcastle disease virus replication was reduced by treatment.",
    "Future studies should replicate the intervention across different regions.",
    "Author contributions: conceptualization, methodology, validation, visualization.",
    "The proposed system was evaluated under randomized validation dataset subsets.",
    "Independent CLSI-guided validation studies remain limited.",
    "The first phase III clinical trial confirmed the efficacy of the regimen.",
    "Conclusions drawn would require external validation.",
    "The validation dataset is comprised of bacterial genomes.",
    "To evaluate the effects on GTPV replication, virus-containing samples were collected.",
    "Platform-independent entry criteria make values reproducible, traceable, and comparable."
  )
  valid_claims <- c(
    "We independently replicated the findings from the original study.",
    "The results were validated in an external cohort."
  )

  is_negated_pos <- rtransparent:::.negate_replication_1(negated_claims)
  expect_true(all(is_negated_pos), info = "All negated claims should be flagged")

  is_negated_neg <- rtransparent:::.negate_replication_1(valid_claims)
  expect_true(all(!is_negated_neg), info = "Valid replication claims should not be negated")
})


test_that("replication functions return integer(0) for empty input", {
  empty <- character(0)
  expect_equal(rtransparent:::.which_replication_replicat_1(empty), integer(0))
  expect_equal(rtransparent:::.which_replication_confirm_1(empty), integer(0))
  expect_equal(rtransparent:::.which_replication_independent_1(empty), integer(0))
  expect_equal(rtransparent:::.which_replication_reproduced_1(empty), integer(0))
  expect_equal(rtransparent:::.which_replication_validation_1(empty), integer(0))
})


test_that(".which_replication_validation_1 ignores internal train/validation splits", {
  internal <- c(
    "Patients were divided into a training cohort and a validation cohort.",
    "In the validation cohort, the model achieved an AUC of 0.83.",
    "The validation set comprised 30% of the sample."
  )
  external <- c(
    "The model was externally validated in an independent validation cohort.",
    "Findings were confirmed in an external validation cohort.",
    "We performed external validation in a separate population."
  )
  expect_equal(
    length(rtransparent:::.which_replication_validation_1(internal)), 0,
    info = "An internal training/validation split is model development, not replication"
  )
  expect_true(
    length(rtransparent:::.which_replication_validation_1(external)) > 0,
    info = "External or independent validation is a replication-like component"
  )
})
