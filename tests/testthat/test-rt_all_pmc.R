test_that("rt_all_pmc returns all eight indicators", {
  xml <- system.file("extdata", "PMID32171256-PMC7071725.xml",
                     package = "rtransparent")
  skip_if(xml == "")

  res <- rtransparent::rt_all_pmc(xml, remove_ns = TRUE)

  indicator_cols <- c(
    "is_coi_pred", "is_fund_pred", "is_register_pred", "is_novelty_pred",
    "is_replication_pred", "is_open_data", "is_open_code", "is_ai_pred"
  )
  expect_true(all(indicator_cols %in% names(res)))
  # Statement-text columns for data/code come along too.
  expect_true(all(c("open_data_statements", "open_code_statements") %in%
                    names(res)))
  expect_true(isTRUE(res$is_success))
})

test_that("rt_all_pmc data/code agree with rt_data_code_pmc", {
  xml <- system.file("extdata", "PMID32171256-PMC7071725.xml",
                     package = "rtransparent")
  skip_if(xml == "")

  all_res <- rtransparent::rt_all_pmc(xml, remove_ns = TRUE)
  dc_res  <- rtransparent::rt_data_code_pmc(xml, remove_ns = TRUE)

  expect_identical(all_res$is_open_data, dc_res$is_open_data)
  expect_identical(all_res$is_open_code, dc_res$is_open_code)
  expect_identical(all_res$open_data_statements, dc_res$open_data_statements)
  expect_identical(all_res$open_code_statements, dc_res$open_code_statements)
})
