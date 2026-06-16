det <- function(x) rtransparent:::.detect_data_code(x)

test_that(".detect_data_code detects data sharing statements", {
  expect_true(det("All sequencing data have been deposited in GEO under accession GSE12345.")$is_open_data)
  expect_true(det("The data are available at the Open Science Framework https://osf.io/abc/.")$is_open_data)
  expect_true(det("Structural data were deposited in the Protein Data Bank (PDB) under accession 4XHR.")$is_open_data)
  expect_true(det("Data availability: the dataset is available in the Dryad Digital Repository.")$is_open_data)
})

test_that(".detect_data_code detects code sharing statements", {
  expect_true(det("All source code is available at https://github.com/user/repo.")$is_open_code)
  expect_true(det("Our analysis scripts can be downloaded from https://gitlab.com/x/y.")$is_open_code)
})

test_that(".detect_data_code separates data from code on a code repository", {
  r <- det("The source code is available on GitHub at https://github.com/x/y.")
  expect_true(r$is_open_code)
  expect_false(r$is_open_data)
})

test_that(".detect_data_code rejects reuse, non-availability and unrelated text", {
  expect_false(det("The microarray data were downloaded from GEO (GSE999).")$is_open_data)
  expect_false(det("Data are available from the corresponding author upon reasonable request.")$is_open_data)
  expect_false(det("This study examined lung cancer outcomes in 200 patients.")$is_open_data)
})

test_that(".detect_data_code returns the matched statement text", {
  r <- det("All raw data have been deposited in the Sequence Read Archive (SRA) under accession PRJNA414414.")
  expect_true(r$is_open_data)
  expect_true(grepl("PRJNA414414", r$data_text))
})
