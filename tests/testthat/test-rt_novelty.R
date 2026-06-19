test_that(".which_novelty_first_time_1 detects 'for the first time'", {
  article_positive <- c(
    "We demonstrate for the first time that this pathway is activated.",
    "Blood pressure was measured at baseline."
  )
  article_negative <- c(
    "The results were consistent with prior reports.",
    "No significant differences were observed."
  )

  idx_pos <- rtransparent:::.which_novelty_first_time_1(article_positive)
  expect_true(length(idx_pos) > 0, info = "Should detect 'for the first time'")

  idx_neg <- rtransparent:::.which_novelty_first_time_1(article_negative)
  expect_equal(length(idx_neg), 0, info = "Should not flag non-novelty text")
})


test_that(".which_novelty_first_to_1 detects 'first to show/demonstrate'", {
  article_positive <- c(
    "This study is the first to demonstrate a causal relationship.",
    "We are the first to report this association in humans.",
    "This study is the first to examine the perioperative inflammatory trajectory.",
    "This is the first study comparing three large language models in this setting.",
    "This is the first report that we know of to describe this presentation.",
    "As the first study of its kind, this work evaluates clinical implementation."
  )
  article_negative <- c(
    "Prior work has shown similar results.",
    "These findings extend previous observations."
  )

  idx_pos <- rtransparent:::.which_novelty_first_to_1(article_positive)
  expect_true(length(idx_pos) > 0, info = "Should detect 'first to demonstrate/report'")

  idx_neg <- rtransparent:::.which_novelty_first_to_1(article_negative)
  expect_equal(length(idx_neg), 0, info = "Should not flag non-novelty text")
})


test_that(".which_novelty_previously_1 detects 'previously unknown/unreported'", {
  article_positive <- c(
    "We identified a previously unknown mechanism of drug resistance.",
    "This previously unreported variant was found in 5% of patients.",
    "This association has not been reported previously."
  )
  article_negative <- c(
    "Previous studies have reported similar findings.",
    "Earlier work demonstrated the same effect."
  )

  idx_pos <- rtransparent:::.which_novelty_previously_1(article_positive)
  expect_true(length(idx_pos) > 0, info = "Should detect 'previously unknown/unreported'")

  idx_neg <- rtransparent:::.which_novelty_previously_1(article_negative)
  expect_equal(length(idx_neg), 0, info = "Should not flag 'previous studies' as novelty")
})


test_that(".which_novelty_novel_1 detects 'novel finding/approach'", {
  article_positive <- c(
    "This novel finding suggests a new therapeutic target.",
    "We present a novel approach to treating drug-resistant infections.",
    "In summary, this study provides novel evidence for the regulatory axis.",
    "Together, these findings reveal a novel posttranscriptional mechanism."
  )
  article_negative <- c(
    "The study included 500 participants.",
    "We used logistic regression for all analyses.",
    "Novel approaches include graph analysis combined with deep learning models.",
    "Novel targeted treatments are becoming increasingly expensive."
  )

  idx_pos <- rtransparent:::.which_novelty_novel_1(article_positive)
  expect_true(length(idx_pos) > 0, info = "Should detect 'novel finding/approach'")

  idx_neg <- rtransparent:::.which_novelty_novel_1(article_negative)
  expect_equal(length(idx_neg), 0, info = "Should not flag non-novelty text")
})


test_that(".which_novelty_knowledge_1 detects 'to our knowledge'", {
  article_positive <- c(
    "To our knowledge, this is the first study to examine this outcome.",
    "To the best of our knowledge, no prior work has addressed this question."
  )
  article_negative <- c(
    "Previous studies have reported similar findings.",
    "The results were replicated in an independent cohort."
  )

  idx_pos <- rtransparent:::.which_novelty_knowledge_1(article_positive)
  expect_true(length(idx_pos) > 0, info = "Should detect 'to our knowledge'")

  idx_neg <- rtransparent:::.which_novelty_knowledge_1(article_negative)
  expect_equal(length(idx_neg), 0, info = "Should not flag non-novelty text")
})


test_that(".rt_novelty_pmc quick filter admits specific novel claim terms", {
  article_ls <- list(
    abstract = list("In summary, this study provides novel evidence for the regulatory axis."),
    body_all = list("The remaining text describes ordinary methods.")
  )
  result <- rtransparent:::.rt_novelty_pmc(article_ls)
  expect_true(result$is_novelty_pred)
  expect_match(result$novelty_text, "novel evidence", ignore.case = TRUE)

  negative <- list(
    abstract = list("Novel approaches include graph analysis and machine learning models."),
    body_all = list("The study used logistic regression for all analyses.")
  )
  expect_false(rtransparent:::.rt_novelty_pmc(negative)$is_novelty_pred)
})


test_that("novelty functions return integer(0) for empty input", {
  empty <- character(0)
  expect_equal(rtransparent:::.which_novelty_first_time_1(empty), integer(0))
  expect_equal(rtransparent:::.which_novelty_first_time_2(empty), integer(0))
  expect_equal(rtransparent:::.which_novelty_first_to_1(empty), integer(0))
  expect_equal(rtransparent:::.which_novelty_previously_1(empty), integer(0))
  expect_equal(rtransparent:::.which_novelty_novel_1(empty), integer(0))
  expect_equal(rtransparent:::.which_novelty_knowledge_1(empty), integer(0))
})


test_that(".which_novelty_first_to_1 allows an adverbial before 'to <verb>'", {
  pos <- c(
    "The present study is the first to date to report the predictive accuracy of imaging.",
    "This is the first ever study to characterize the mechanism."
  )
  neg <- c(
    "We used a standard cohort design.",
    "The first patient was enrolled in 2019."
  )
  expect_true(length(rtransparent:::.which_novelty_first_to_1(pos)) >= 2)
  expect_equal(length(rtransparent:::.which_novelty_first_to_1(neg)), 0)
})


test_that("novelty recall covers 'novel'/'innovative', passive and adverbial-first claims", {
  pos <- c(
    "A novel silicon-based microevaporator is developed in this work.",
    "Here we propose an innovative framework for risk assessment.",
    "In this study we present a novel diagnostic assay for the pathogen."
  )
  expect_true(length(rtransparent:::.which_novelty_novel_1(pos)) >= 2)

  # Bare "new" is deliberately not a novelty cue (too frequent in non-priority
  # contexts) and must not trigger on its own.
  expect_equal(length(rtransparent:::.which_novelty_novel_1(
    "We used a new device and new reagents for the assay.")), 0)

  first <- c(
    "Our study first provided evidence that this pathway drives tumorigenesis.",
    "This is the first study to attenuate a virulent strain via serial passage.",
    "We present the first reported case of this presentation."
  )
  expect_true(length(rtransparent:::.which_novelty_first_to_1(first)) >= 2)
})


test_that(".which_novelty_first_to_1 covers 'first to <verb>' for many verbs and nouns", {
  pos <- c(
    "This study is the first to confirm the effectiveness of the biomarker.",
    "We are the first to validate this model in an external cohort.",
    "These are the first technology to simultaneously achieve both goals.",
    "Ours is the first study to find a link between diversity and well-being.",
    "The present study is the first to directly compare the two devices."
  )
  expect_equal(length(rtransparent:::.which_novelty_first_to_1(pos)), 5)

  # Procedural / enumerated "first to" is not a priority claim.
  neg <- c(
    "Examination is performed first to confirm instability, then imaging follows.",
    "There are two stages: first to identify patients and then to treat them.",
    "The first method involves recording chronopotentiometry curves."
  )
  expect_equal(length(rtransparent:::.which_novelty_first_to_1(neg)), 0)
})


test_that(".which_novelty_previously_1 requires a study anchor, not a background gap", {
  pos <- c(
    "We identified a previously unknown mechanism of resistance.",
    "This previously unreported variant was found in 5% of patients.",
    "This association has not been reported previously."
  )
  expect_true(length(rtransparent:::.which_novelty_previously_1(pos)) >= 3)

  neg <- c(
    "Its role in liver metastasis has not been studied.",
    "The effect of the drug on these cells has not been evaluated."
  )
  expect_equal(length(rtransparent:::.which_novelty_previously_1(neg)), 0)
})


test_that("public rt_novelty_pmc and rt_replication_pmc do not duplicate columns", {
  f <- system.file("extdata", "PMID32171256-PMC7071725.xml",
                   package = "rtransparent")
  skip_if(f == "")
  nov <- rt_novelty_pmc(f, remove_ns = TRUE)
  rep <- rt_replication_pmc(f, remove_ns = TRUE)
  expect_false(anyDuplicated(names(nov)) > 0)
  expect_false(anyDuplicated(names(rep)) > 0)
  expect_true(all(c("is_novelty_pred", "novelty_text") %in% names(nov)))
  expect_true(all(c("is_replication_pred", "replication_text") %in% names(rep)))
})


test_that(".negate_novelty_1 suppresses attributed and ordinal 'first' but keeps 'for the first time, we'", {
  drop <- c(
    "Jaramillo et al demonstrated for the first time the suitability of the oxide.",
    "The patient underwent first-time heart transplantation.",
    "Symptoms decreased during the first day postoperatively.",
    "MARS was used for the first time in 1993."
  )
  expect_true(all(rtransparent:::.negate_novelty_1(drop)))

  keep <- c(
    "For the first time, we reveal a striking relationship.",
    "Here, for the first time, we directly relate these pathways."
  )
  expect_false(any(rtransparent:::.negate_novelty_1(keep)))
})


test_that("novelty 'to our knowledge' requires a first/gap claim", {
  expect_length(rtransparent:::.which_novelty_knowledge_1(
    "To our knowledge, the assay is a standard laboratory procedure."), 0)
  expect_true(length(rtransparent:::.which_novelty_knowledge_1(
    "To our knowledge, no previous study has examined this association.")) > 0)
})
