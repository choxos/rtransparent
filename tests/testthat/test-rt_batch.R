test_that("rt_all_pmc_dir processes every XML in a directory", {
  src <- system.file("extdata", "PMID32171256-PMC7071725.xml",
                     package = "rtransparent")
  skip_if(!nzchar(src), "bundled XML not found")

  d <- tempfile("rtbatch_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  file.copy(src, file.path(d, c("a.xml", "b.xml")))

  res <- rt_all_pmc_dir(d, remove_ns = TRUE, progress = FALSE)

  expect_s3_class(res, "tbl_df")
  expect_equal(nrow(res), 2L)
  expect_true(all(res$is_success))
  expect_true(all(c("is_coi_pred", "is_fund_pred", "is_register_pred",
                    "is_novelty_pred", "is_replication_pred", "is_open_data",
                    "is_open_code", "is_ai_pred") %in% names(res)))
})


test_that("rt_all_pmc_dir accepts an explicit vector of paths", {
  src <- system.file("extdata", "PMID32171256-PMC7071725.xml",
                     package = "rtransparent")
  skip_if(!nzchar(src), "bundled XML not found")

  d <- tempfile("rtbatch_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  paths <- file.path(d, c("a.xml", "b.xml"))
  file.copy(src, paths)

  res <- rt_all_pmc_dir(paths, remove_ns = TRUE, progress = FALSE)
  expect_equal(nrow(res), 2L)
  expect_setequal(res$filename, paths)
})


test_that("rt_all_pmc_dir isolates per-file failures", {
  src <- system.file("extdata", "PMID32171256-PMC7071725.xml",
                     package = "rtransparent")
  skip_if(!nzchar(src), "bundled XML not found")

  d <- tempfile("rtbatch_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  good <- file.path(d, "good.xml")
  bad  <- file.path(d, "bad.xml")
  file.copy(src, good)
  writeLines("this is not xml <<<", bad)

  res <- rt_all_pmc_dir(c(good, bad), remove_ns = TRUE, progress = FALSE)

  expect_equal(nrow(res), 2L)
  expect_false(res$is_success[res$filename == bad])
  expect_true(res$is_success[res$filename == good])
})


test_that("rt_all_pmc_dir resumes from and appends to an existing output", {
  src <- system.file("extdata", "PMID32171256-PMC7071725.xml",
                     package = "rtransparent")
  skip_if(!nzchar(src), "bundled XML not found")

  d <- tempfile("rtbatch_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  file.copy(src, file.path(d, c("a.xml", "b.xml")))
  out <- tempfile(fileext = ".csv")
  on.exit(unlink(out), add = TRUE)

  r1 <- rt_all_pmc_dir(d, remove_ns = TRUE, output = out, progress = FALSE,
                       chunk_size = 1L)
  expect_equal(nrow(r1), 2L)
  expect_true(file.exists(out))

  # A new file appears; a re-run must skip the two done and process only the new
  # one, returning all three.
  file.copy(src, file.path(d, "c.xml"))
  r2 <- rt_all_pmc_dir(d, remove_ns = TRUE, output = out, progress = FALSE)
  expect_equal(nrow(r2), 3L)
  expect_setequal(basename(r2$filename), c("a.xml", "b.xml", "c.xml"))
})


test_that("rt_all_pmc_dir errors on an empty file set", {
  d <- tempfile("rtbatch_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  expect_error(rt_all_pmc_dir(d, progress = FALSE), "No files")
})


test_that("rt_all_pmc_dir runs in parallel via furrr", {
  skip_if_not_installed("furrr")
  skip_if_not_installed("future")
  src <- system.file("extdata", "PMID32171256-PMC7071725.xml",
                     package = "rtransparent")
  skip_if(!nzchar(src), "bundled XML not found")

  d <- tempfile("rtbatch_")
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  file.copy(src, file.path(d, c("a.xml", "b.xml")))

  res <- rt_all_pmc_dir(d, remove_ns = TRUE, parallel = TRUE, progress = FALSE)
  expect_equal(nrow(res), 2L)
  expect_true(all(res$is_success))
})
