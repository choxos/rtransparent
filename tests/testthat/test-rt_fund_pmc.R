# Regression tests for the exported rt_fund_pmc(): it must agree with the
# funding prediction produced by rt_all_pmc() and must never predict funding
# without supporting evidence (it previously returned TRUE with empty text).

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
