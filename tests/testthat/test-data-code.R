det <- function(x) rtransparent:::.detect_data_code(x)

test_that(".detect_data_code detects data sharing statements", {
  expect_true(det("All sequencing data have been deposited in GEO under accession GSE12345.")$is_open_data)
  expect_true(det("The data are available at the Open Science Framework https://osf.io/abc/.")$is_open_data)
  expect_true(det("Structural data were deposited in the Protein Data Bank (PDB) under accession 4XHR.")$is_open_data)
  expect_true(det("Data availability: the dataset is available in the Dryad Digital Repository.")$is_open_data)
  expect_true(det("CIF file for the Na12[Co5POM] is deposited with the Cambridge Crystallographic Data Centre (CCDC no. 1558372).")$is_open_data)
  expect_true(det("Raw sequencing data are available via the European Genome-phenome Archive under accession EGAS00001002213.")$is_open_data)
  expect_true(det("The new genotypes reported in this paper are available in GenBank under accession numbers KJ170100.1 to KJ170108.1.")$is_open_data)
  expect_true(det("All files are available from the Open Science Framework database.")$is_open_data)
  expect_true(det("Variants described in Supplemental Table 1 have been submitted to ClinVar as accession numbers SCV000245445-SCV000245563.")$is_open_data)
  expect_true(det("Data AvailabilitySequences have been uploaded to the Qiita servers (qiita.ucsd.edu) under study ID 10453.")$is_open_data)
  expect_true(det("Data AvailabilityAll relevant data are within the paper.")$is_open_data)
  expect_true(det("Data AvailabilityData has been included with the submission, as S1 Data.")$is_open_data)
  expect_true(det("Data availability statementThe original contributions presented in the study are included in the article/Supplementary Material.")$is_open_data)
  expect_true(det("Data availabilityThe data used to support the findings of this study are included within the article.")$is_open_data)
  expect_true(det("Data availabilityAll data supporting the results presented in the paper are included in the figures.")$is_open_data)
  expect_true(det("Data availabilityAll data are in the article.")$is_open_data)
  expect_true(det("DATA AVAILABILITYThe complete anonymized dataset supporting the findings of this study is included within the article itself.")$is_open_data)
  expect_true(det("Data availability statementAll data relevant to the study are included in the article or uploaded as supplementary information.")$is_open_data)
  expect_true(det("Availability of data and materialsAll data generated or analyzed during this study are included in this published article.")$is_open_data)
  expect_true(det("All data generated or analyzed during this research are fully included in the published article.")$is_open_data)
  expect_true(det("All data generated and analyzed during this study are included in this paper.")$is_open_data)
  expect_true(det("All data supporting this study are included in this manuscript and its supplementary materials.")$is_open_data)
  expect_true(det("All data supporting the findings of this study are available within the paper.")$is_open_data)
  expect_true(det("The raw data for confocal images are provided in the Supplementary Material.")$is_open_data)
  expect_true(det("All data needed to evaluate the conclusions in the paper are available in the GitHub repository.")$is_open_data)
  expect_true(det("Data generated and analyzed during this study is openly available in Bridge of Knowledge at https://mostwiedzy.pl/.")$is_open_data)
  expect_true(det("Data Availability StatementThe raw data that supports the findings of this study are available in the Supporting Information.")$is_open_data)
  expect_true(det("Data availabilityThis study utilized the OpenBHB dataset, which is publicly available at https://dx.doi.org/10.21227/7jsg-jx57.")$is_open_data)
  expect_true(det("The raw sequence data have been deposited in the Genome Sequence Archive in the National Genomics Data Center.")$is_open_data)
  expect_true(det("Data Availability StatementThe data used in this study have been submitted in Science Data Bank (SciDB).")$is_open_data)
  expect_true(det("Oligonucleotide sequences are provided in Supplementary Table S2.")$is_open_data)
  expect_true(det("Data AvailabilityEmpirical data were obtained from the website of the NIH Human Microbiome Project (http://www.hmpdacc.org/HMSMCP/).")$is_open_data)
})

test_that(".detect_data_code detects code sharing statements", {
  expect_true(det("All source code is available at https://github.com/user/repo.")$is_open_code)
  expect_true(det("Our analysis scripts can be downloaded from https://gitlab.com/x/y.")$is_open_code)
  expect_true(det("All data and R-syntax used in the article are available at the Open Science Framework.")$is_open_code)
  expect_true(det("Our codes and data are publicly available at https://github.com/user/repo.")$is_open_code)
  expect_true(det("The CPI-EM algorithm is available at https://github.com/user/cpi-em.")$is_open_code)
  expect_true(det("All files needed to rerun the analysis are available on GitHub via https://github.com/user/project.")$is_open_code)
  expect_true(det("R scripts to calculate lambda and statistical power have been provided for convenience.")$is_open_code)
  expect_true(det("In-house Matlab scripts have been made available for free online via figshare.")$is_open_code)
  expect_true(det("CONAN and its documentation are freely available for download on GitHub.")$is_open_code)
  expect_true(det("The tools are available on the South Green platform https://github.com/SouthGreenPlatform.")$is_open_code)
  expect_true(det("Data AvailabilityAll model data files are available from the Github database (https://github.com/user/model).")$is_open_code)
  expect_true(det("FACETS (https://github.com/user/FACETS) can be easily used to map addresses.")$is_open_code)
  expect_true(det("Previously published spike sorting methods are now available in a software program, SpikeSorter.")$is_open_code)
  expect_true(det("The number of substitutions was calculated using a Python script (Supplemental Script).")$is_open_code)
})

test_that(".detect_data_code separates data from code on a code repository", {
  r <- det("The source code is available on GitHub at https://github.com/x/y.")
  expect_true(r$is_open_code)
  expect_false(r$is_open_data)
})

test_that(".detect_data_code rejects reuse, non-availability and unrelated text", {
  expect_false(det("The microarray data were downloaded from GEO (GSE999).")$is_open_data)
  expect_false(det("We used public data from GenBank accession KJ170100.1.")$is_open_data)
  expect_false(det("The code of Labclock Web can be downloaded from its public repository: https://github.com/txipi/Labclock-Web.")$is_open_data)
  expect_false(det("Data are available from the corresponding author upon reasonable request.")$is_open_data)
  expect_false(det("Data AvailabilityEthical restrictions preclude public repositories; de-identified data will be made available upon request.")$is_open_data)
  expect_false(det("This study examined lung cancer outcomes in 200 patients.")$is_open_data)
  expect_false(det("Supplementary information:Supplementary data are available at Bioinformatics online.")$is_open_data)
  expect_false(det("Supplementary Data are available at NAR Online.")$is_open_data)
  expect_false(det("The values of the interaction energy calculated for the whole data set are given in Supplementary Table S1.")$is_open_data)
  expect_false(det("The protocol of this scoping review was registered on the Open Science Framework and is publicly available at https://osf.io/6h3vm.")$is_open_data)
  expect_false(det("Code availabilityThe code supporting the findings of this study is publicly available at Zenodo (10.5281/zenodo.19080430) and mirrored on GitHub.")$is_open_data)
  expect_false(det("These can be exported by creating a Data Table and saving it as .csv.")$is_open_data)
  expect_false(det("Data <- read.csv(\"C:/Users/user/data.csv\").")$is_open_data)
})

test_that(".detect_data_code rejects code-use and generic reporting text", {
  expect_false(det("Read counts were imported into the R/Bioconductor package EdgeR for normalization.")$is_open_code)
  expect_false(det("Files were converted with Picard tools, http://broadinstitute.github.io/picard/.")$is_open_code)
  expect_false(det("The isolates available had identical MIRU-VNTR profiles with MtbC15-9 code 10287.")$is_open_code)
  expect_false(det("Only few works make their source code available.")$is_open_code)
  expect_false(det("State how analytic or statistical source code used to generate estimates can be accessed.")$is_open_code)
  expect_false(det("The PELE server provides ready-made scripts that can be accessed at https://pele.bsc.es/.")$is_open_code)
  expect_false(det("The source code is not publicly available at https://github.com/user/private.")$is_open_code)
  expect_false(det("ICD-10-CM codes used for these conditions are provided in Table S1.")$is_open_code)
  expect_false(det("Is the analysis code/syntax available?")$is_open_code)
  expect_false(det("Cell-cell communication analysis was performed using the CellChat package (v2.1.2, https://github.com/sqjin/CellChat).")$is_open_code)
  expect_false(det("TCGA data were downloaded using the Bioconductor package TCGAbiolinks.")$is_open_code)
  expect_false(det("Differential expression was performed using Model-based Analysis of Single-cell Transcriptomics (MAST; https://github.com/RGLab/MAST).")$is_open_code)
})

test_that(".detect_data_code returns the matched statement text", {
  r <- det("All raw data have been deposited in the Sequence Read Archive (SRA) under accession PRJNA414414.")
  expect_true(r$is_open_data)
  expect_true(grepl("PRJNA414414", r$data_text))
})

test_that("generic publisher supplement boilerplate is not open data on its own", {
  # This line appears in every article of some journals and is not a
  # data-availability statement.
  r <- det("The online version contains supplementary material available at 10.1007/s00431-026-07109-9.")
  expect_false(r$is_open_data)
  # A genuine availability statement is still detected.
  r2 <- det("Data availability: all sequencing data have been deposited in GEO under accession GSE123456.")
  expect_true(r2$is_open_data)
})

test_that("data included within the article/manuscript is detected", {
  expect_true(det(
    "Availability of data and materials: All data supporting the findings are within the manuscript."
  )$is_open_data)
  expect_true(det(
    "The dataset supporting the conclusions of this article is included within the article."
  )$is_open_data)
  expect_true(det(
    "The data analyzed during the current study are included in this published article."
  )$is_open_data)
  expect_true(det(
    "All data supporting the findings in this study are included in the manuscript and its additional files."
  )$is_open_data)
  # A bare mention of data in a results sentence is not an availability statement.
  expect_false(det("The clinical data of the patients are summarized in Table 1.")$is_open_data)
  # The Frontiers default statement is detected with or without a supplement
  # clause; both forms mean the data are in the article.
  expect_true(det(
    "The original contributions presented in the study are included in the article/Supplementary Material, further inquiries can be directed to the corresponding author."
  )$is_open_data)
  expect_true(det(
    "The original contributions presented in the study are included in the article, further inquiries can be directed to the corresponding author."
  )$is_open_data)
})

test_that("analysis code shared in supplementary files is detected", {
  expect_true(det("The complete Matlab code can be found in the Supplementary Methods.")$is_open_code)
  expect_true(det("R code and a guide to data and scripts is contained in Additional file 7.")$is_open_code)
  expect_true(det("Our methods were easy to implement in R, and the code is presented in Supplementary Table 1.")$is_open_code)
  expect_true(det("The track membrane MATLAB script is provided as Source code 1.")$is_open_code)
  expect_true(det("Availability of source code: project home page https://github.com/user/tool.")$is_open_code)
  # Non-analysis "codes" in a supplement are not code sharing.
  expect_false(det("The qualitative codes are presented in Supplementary Table 2.")$is_open_code)
  expect_false(det("The diagnosis codes are provided in the supplementary appendix.")$is_open_code)
})

test_that("a repository deposit with a glued reference number is detected", {
  # PMC text extraction can attach a superscript reference number to the
  # repository name ("Mendeley Data20"); the data deposit must still be found.
  expect_true(det("The database was stored on Mendeley Data20.")$is_open_data)
  expect_true(det("The dataset was deposited in Dryad15.")$is_open_data)
  # The unrelated word "database" alone is not a data noun (avoids reuse FPs).
  expect_false(det("We queried the UK Biobank database for eligible records.")$is_open_data)
})

test_that("repository code is detected even when data is offered on request", {
  # A single availability sentence can host code on a public repository and, in
  # the same breath, offer the data only on request. The data-delivery wording
  # ("upon request", "from the authors") must not veto the code, which is openly
  # hosted on the repository.
  expect_true(det(
    "The full pipeline is available on GitHub (https://github.com/lab/tool), and sample data are available through Dataverse or upon request through a data sharing agreement."
  )$is_open_code)
  expect_true(det(
    "Analysis scripts are available on GitHub (https://github.com/x/y); the raw data are available from the corresponding author on reasonable request."
  )$is_open_code)
  # Code itself offered only on request, with no public repository, is still
  # not open code.
  expect_false(det("The source code is available from the authors upon request.")$is_open_code)
  # Genuine non-availability still vetoes repository-hosted code.
  expect_false(det("The source code is not publicly available at https://github.com/user/private.")$is_open_code)
})

test_that("a named data repository with an accession identifier is detected", {
  # The structured genome-data-paper form names the repository and an accession
  # without a separate availability verb.
  expect_true(det("European Nucleotide Archive accession number PRJEB51269 for this genome assembly.")$is_open_data)
  expect_true(det("Sequencing reads, Gene Expression Omnibus accession number GSE123456.")$is_open_data)
  # Reuse of an existing accession is still not data sharing.
  expect_false(det("Data were obtained from the European Nucleotide Archive under accession number PRJEB99999.")$is_open_data)
  expect_false(det("This pathway was studied previously using GEO GSE99999.")$is_open_data)
})

test_that("a sequencing-consortium author list is not code sharing", {
  # Genome-data-paper boilerplate names a consortium ("DNA Pipelines collective")
  # with a Zenodo author list; the word "pipelines" must not flag it as code.
  expect_false(det(
    "Members of the Wellcome Sanger Institute DNA Pipelines collective are listed here: https://doi.org/10.5281/zenodo.4790455."
  )$is_open_code)
})

test_that("code shared on the Open Science Framework is detected", {
  expect_true(det(
    "All components for reproducible analysis (data and code) are accessible via the Open Science Framework (https://osf.io/2cuf7/)."
  )$is_open_code)
  expect_true(det("The analysis code is available on OSF (https://osf.io/abc12/).")$is_open_code)
  # Data on OSF without any code mention is not code sharing.
  expect_false(det("The data are available on OSF (https://osf.io/xyz/).")$is_open_code)
})
