# Native data and code sharing detection (GPL-3).
#
# Clean-room reimplementation of the open-data / open-code detection that the
# package previously delegated to oddpub (AGPL-3). The patterns are derived from
# public facts (the repositories' own accession-number schemes and names) and
# from curated benchmark availability statements, not from oddpub's keyword
# files. The benchmark in inst/benchmark is a reproducible regression benchmark
# for this native detector, not an untouched external validation set.
#
# `.detect_data_code()` takes a character vector of sentences (one statement per
# element) and returns a list with logical `is_open_data` / `is_open_code` and
# the matched `data_text` / `code_text`.


# Field-specific accession identifiers. These schemes are specific enough that a
# match is, on its own, strong evidence that data were deposited.
.dc_accession <- function() {
  paste(
    "\\bgse[0-9]{2,}\\b", "\\bgds[0-9]{2,}\\b", "\\bgsm[0-9]{3,}\\b", "\\bgpl[0-9]{3,}\\b",
    "\\bsr[rxpsz][0-9]{4,}\\b", "\\berp[0-9]{5,}\\b", "\\berr[0-9]{5,}\\b", "\\bdrr[0-9]{5,}\\b",
    "\\bprjna[0-9]{3,}\\b", "\\bprjeb[0-9]{3,}\\b", "\\bprjdb[0-9]{3,}\\b",
    "\\bsam[end][a-z]?[0-9]{4,}\\b",
    "\\bphs[0-9]{6}\\b",
    "\\bscv[0-9]{6,}\\b",
    "\\bega[a-z][0-9]{6,}\\b",
    "\\bgc[af]_[0-9]{9}\\.[0-9]+\\b",
    "\\bccdc\\s*(no\\.?|number|id|identifier)?\\s*[0-9]{4,}\\b",
    "\\be-[a-z]{4}-[0-9]+\\b",
    "\\bmtbls[0-9]+\\b", "\\bpxd[0-9]{4,}\\b", "\\bchembl[0-9]+\\b", "\\bipr[0-9]{6}\\b",
    "\\b[0-9][a-z0-9]{3}\\b\\s*(\\)|,|;|\\.|\\s)*(and|,)?\\s*(crystal|structure|pdb)",
    "\\b10\\.5061/dryad", "\\b10\\.5281/zenodo", "\\b10\\.6084/m9\\.figshare",
    "\\b10\\.7910/dvn", "\\b10\\.17632", "\\b10\\.6084", "\\b10\\.7937",
    sep = "|"
  )
}

# Generic GenBank-style sequence accessions are short enough to collide with
# SNP identifiers and instrument model numbers, so they require accession
# wording in `.detect_data_code()`.
.dc_sequence_accession <- function() {
  "\\b[a-z]{1,2}[0-9]{5,8}(\\.[0-9]+)?\\b"
}

# Repository URLs and DOIs that host shared research data (self-sufficient).
# Code-primary hosts (GitHub, GitLab, ...) are deliberately excluded here and
# placed in the repository-name list, so they only count as data when paired
# with a data noun and availability language.
.dc_data_repo_url <- function() {
  paste(
    "osf\\.io", "zenodo\\.org", "figshare\\.com", "datadryad", "dataverse",
      "ncbi\\.nlm\\.nih\\.gov/(geo|sra|genbank|bioproject|nuccore|clinvar)",
      "ebi\\.ac\\.uk", "ddbj", "rcsb\\.org", "/pdb", "proteomecentral", "ebi\\.ac\\.uk/pride",
      "ccdc\\.cam\\.ac\\.uk", "ega-archive\\.org", "flowrepository\\.org",
      "gbif\\.org", "neurovault\\.org", "ukdataservice\\.ac\\.uk", "qiita\\.ucsd\\.edu",
      "ngdc\\.cncb\\.ac\\.cn", "sciencedb\\.", "nda\\.nih\\.gov", "abcdstudy\\.org",
      "hdl\\.handle\\.net", "dx\\.doi\\.org/10\\.21227", "doi\\.org/10\\.12795",
      "doi\\.org/10\\.57760/sciencedb", "mostwiedzy\\.pl", "doi\\.org/10\\.34808",
      "10\\.5061/dryad", "10\\.5281/zenodo", "10\\.6084", "10\\.7910/dvn", "10\\.17632",
      "10\\.34808",
      sep = "|"
    )
}

# Repository / database names.
.dc_data_repo_name <- function(include_code_hosts = TRUE) {
  repos <- c(
    "open science framework", "\\bosf\\b", "zenodo", "figshare", "dryad", "dataverse",
    "mendeley data", "gene expression omnibus", "\\bgeo\\b", "sequence read archive",
    "\\bsra\\b", "european nucleotide archive", "\\bena\\b", "genbank", "\\bddbj\\b",
    "protein data ?bank", "\\bpdb\\b", "\\bwwpdb\\b", "\\bpride\\b", "proteomexchange",
    "arrayexpress", "metabolights", "bioproject", "biosample", "biostudies", "dbgap",
    "uniprot", "ensembl", "\\bembl\\b", "\\bneuromorpho\\b", "openneuro", "physionet",
    "cambridge crystallographic data cent(?:er|re)", "\\bccdc\\b",
    "european genome-phenome archive", "\\bega\\b", "uk data service",
    "flowrepository", "\\bgbif\\b", "neurovault", "clinvar", "\\bqiita\\b",
    "genome sequence archive", "\\bgsa\\b", "national genomics data center",
    "china national center for bioinformation", "science data bank", "\\bscidb\\b",
    "nimh data archive", "\\bnda\\b",
    "adolescent brain cognitive development", "\\babcd\\b", "mostwiedzy"
  )
  if (include_code_hosts) repos <- c(repos, "github", "gitlab", "bitbucket")
  paste(repos, collapse = "|")
}

.dc_deposit <- function() {
  "deposit(ed|ion|s)?|submitted|archived|uploaded|released|recorded|stored|made (publicly )?available"
}

.dc_avail <- function() {
  "available|accessible|can be (found|accessed|downloaded|obtained|retrieved)|provided|shared|hosted"
}

.dc_accession_word <- function() {
  "accession (number|code|id|no|nos|numbers)|under accession"
}

.dc_data_noun <- function() {
  paste(
    "\\bdata\\b", "\\bdata ?sets?\\b", "raw data", "sequence(s|ing|d)?", "structures?",
    "coordinates", "microarray", "\\bgenomes?\\b", "\\breads\\b", "spectra", "\\bimages?\\b",
    "\\bcif\\b", "crystallographic information files?",
    sep = "|"
  )
}

.dc_supplement <- function() {
  paste(
    "supplementary (data|datasets?)", "supporting data", "source data",
    "\\bs[0-9]+ (data|dataset)", "data (file )?s[0-9]+",
    sep = "|"
  )
}

# Data-availability-statement phrasing: signals that the sentence is about
# making the authors' own data available, not merely citing a database.
.dc_das <- function() {
  paste(
    "data availability",
    "availability of (supporting |the )?data",
    "data (and code |and materials? )?(availability|deposition)",
    "(availability|deposition) of (the )?data",
    "data ?sets?( supporting| underlying| generated| analy[sz]ed| used| that support| presented| reported)?.{0,45}(are|is|were|have been|can be|will be) ?.{0,15}(available|accessible|deposited|found)",
    "(raw |all |these |our |the )?data\\b.{0,30}(have been|are|is|were|was|will be|can be)\\b.{0,20}(deposit|available|accessible|archived|released|uploaded|submitted|shared|provided|access)",
    "data .{0,25}(support|underl|generated|presented|reported) .{0,30}(this (study|article|paper|work)|are|is|have been|available|deposited|uploaded)",
    "data .{0,20}(have been |were |are |is )?(uploaded|provided|included|deposited) (as|in|to) .{0,20}(supporting|supplement|repositor|figshare|dryad|github|zenodo|osf)",
    sep = "|"
  )
}

# Data being reused (obtained from an external source), which is not sharing.
.dc_reuse <- function() {
  paste(
    "(obtained|downloaded|retrieved|acquired|extracted|collected|derived|accessed|sourced|gathered|taken|drawn|compiled|mined) .{0,20}from",
    "were (obtained|downloaded|retrieved|extracted|collected|acquired)",
    "publicly available .{0,30}(were|was) (downloaded|obtained|retrieved|used)",
    sep = "|"
  )
}

.dc_code_repo <- function() {
  paste(
    "github\\.com", "gitlab\\.com", "bitbucket\\.org", "sourceforge\\.net", "git\\.io",
    "code ?ocean", "zenodo", "\\bgithub\\b", "\\bgitlab\\b",
    sep = "|"
  )
}

.dc_code_registry <- function() {
  paste(
    "\\bcran\\b", "cran\\.r-project\\.org", "bioconductor",
    sep = "|"
  )
}

.dc_code_term <- function() {
  paste(
    "source code", "\\bcode\\b", "\\bscripts?\\b", "\\bsoftware\\b", "\\bpackage\\b",
    "implementation", "algorithm", "\\bcodebase\\b", "computer code", "\\bpipelines?\\b",
    "r[- ]?syntax", "matlab code", "python codes?",
    sep = "|"
  )
}

# Statements that should not count as open sharing (data only on request, or
# explicitly not available). Applied only to weak signals.
.dc_negation <- function() {
  paste(
    "(up)?on (reasonable )?request", "from the (corresponding )?authors?",
    "not (publicly )?available", "not be (made )?available", "not shown",
    "restricted access", "controlled access", "data are not", "cannot be shared",
    "available on demand",
    sep = "|"
  )
}


# Split text chunks (paragraphs) into sentences without breaking URLs, DOIs or
# accession identifiers: only split on sentence punctuation followed by space and
# a capital letter / digit / opening bracket, never on a period inside a token
# (e.g. "osf.io", "10.5281", "e.g.").
.dc_split <- function(x) {
  unlist(lapply(x, function(p) {
    p <- gsub("[[:space:]]+", " ", p)
    strsplit(p, "(?<=[.!?;:])\\s+(?=[A-Z0-9(])", perl = TRUE)[[1]]
  }), use.names = FALSE)
}


# Extract the text chunks (paragraphs, titles, notes, supplement captions) of a
# PMC article that are relevant to data and code sharing.
.dc_article_text <- function(article_xml) {
  xp <- paste(
    ".//body//p", ".//body//title", ".//back//p", ".//back//title",
    ".//back//notes", ".//floats-group//p", ".//supplementary-material//p",
    ".//supplementary-material//title", ".//abstract//p", ".//front//custom-meta",
    sep = " | "
  )
  nodes <- tryCatch(xml2::xml_find_all(article_xml, xp), error = function(e) NULL)
  if (is.null(nodes)) return(character(0))
  txt <- xml2::xml_text(nodes)
  txt[nchar(txt) > 0]
}


# Detect data and code sharing in a vector of text chunks (sentences or
# paragraphs); paragraphs are split into sentences internally.
.detect_data_code <- function(sentences) {

  out <- list(is_open_data = FALSE, is_open_code = FALSE,
              data_text = "", code_text = "")

  if (!length(sentences)) return(out)
  sentences <- .dc_split(sentences)
  s <- tolower(sentences)
  keep <- !is.na(s) & nchar(s) > 0
  s <- s[keep]
  sentences <- sentences[keep]
  if (!length(s)) return(out)

  has <- function(p, x) grepl(p, x, perl = TRUE, ignore.case = TRUE)

  accession   <- .dc_accession()
  seq_accession <- .dc_sequence_accession()
  repo_url    <- .dc_data_repo_url()
  repo_name   <- .dc_data_repo_name()
  data_repo_name <- .dc_data_repo_name(include_code_hosts = FALSE)
  deposit     <- .dc_deposit()
  avail       <- .dc_avail()
  acc_word    <- .dc_accession_word()
  data_noun   <- .dc_data_noun()
  supplement  <- .dc_supplement()
  negation    <- .dc_negation()
  code_repo   <- .dc_code_repo()
  code_registry <- .dc_code_registry()
  code_term   <- .dc_code_term()

  # --- data ---
  das <- .dc_das()
  reuse <- .dc_reuse()
  has_deposit <- has(deposit, s)

  # An accession or repository URL only counts when it appears in a sharing
  # context (deposit / availability / data-availability statement), not as a
  # bare citation of a reused reference sequence or tool in the methods.
  ctx <- has(deposit, s) | has(avail, s) | has(das, s)
  concrete_data <-
    (has(accession, s) & ctx) |
    (has(seq_accession, s) & has(acc_word, s) & ctx) |
    (has(repo_url, s) & (ctx | has(data_noun, s)))

  # Data shared as supplementary material (data-specific, not generic
  # "supplementary material/information" boilerplate).
  supp_data <- paste(
    "(supplementary|supporting|additional) (data|datasets?|data ?sets?|data files?) ?(file )?s?[0-9]",
    "(data|datasets?|data ?sets?|raw data) .{0,18}(provided |included |deposited |available |found )?(in|as|within) .{0,18}(supplementary (table|file|data|dataset|material)|supporting (information|data)|additional files?)",
    "source data (file|are|is|\\d)",
    sep = "|"
  )

  # Data provided as files in a recognized data format.
  file_data <- paste0(
    "(data|datasets?|raw data|spreadsheets?|matri(x|ces)|table)\\b.{0,30}",
    "(\\.(csv|xlsx?|txt|tsv|fasta|cif|sav|zip|dta|rdata|mat|json|nii)\\b",
    "|as (a |an )?(comma[- ]separated|csv|excel|xls|tab[- ]delimited|fasta|text) (file|spreadsheet|table|format))"
  )

  public_source_data <- "data availability.{0,180}(human microbiome project|hmpdacc\\.org|hmpdacc)"
  in_article_data <- paste(
    "data availability.{0,80}all relevant data (are|is) within the paper",
    "all relevant data (are|is) within the paper",
    "data availability.{0,120}data (has|have) been included with (the )?submission",
    "data (has|have) been included with (the )?submission",
    "data availability.{0,180}original contributions presented in (this|the) study are included in (the )?article/?supplementary material",
    "original contributions presented in (this|the) study are included in (the )?article/?supplementary material",
    "data availability.{0,160}data used to support the findings.{0,60}included within (the )?article",
    "data used to support the findings.{0,80}included within (the )?article",
    "data availability.{0,180}all data that supports? the findings.{0,80}(published article|supporting information|supplementary material)",
    "all data that supports? the findings.{0,80}(published article|supporting information|supplementary material)",
    "data availability.{0,180}all data supporting the results.{0,80}(included|available).{0,40}(figures|article|supplementary material)",
    "all data supporting the results.{0,80}(included|available).{0,40}(figures|article|supplementary material)",
    "data availability.{0,120}all data (are|is) in the article",
    "all data (are|is) in the article",
    "complete anonymi[sz]ed dataset supporting the findings.{0,80}included within (the )?article",
    "data relevant to the study.{0,100}(included|uploaded).{0,80}(article|supplementary information)",
    "all data generated or analy[sz]ed during this study are included in this published article",
    "all data generated or analy[sz]ed during this research are fully included in the published article",
    "all data generated and analy[sz]ed during this study are included in this paper",
    "all data generated or analy[sz]ed during this study are included in this article",
    "all data supporting this study are included in this manuscript and its supplementary materials",
    "all data supporting the findings of this study are available within (the )?paper",
    "all data supporting the findings of this study are included within (the )?article",
    "raw data for .{0,80}images.{0,80}provided in (the )?supplementary material",
    "all data needed to evaluate the conclusions.{0,80}available in (the )?github repository",
    "all data and code needed to evaluate and reproduce the results.{0,120}(paper|supplementary materials|zenodo)",
    "data generated and analy[sz]ed during this study is openly available in",
    "data supporting this article.{0,80}included as part of the extended supplementary information",
    "data that supports? the findings.{0,80}available in the (supporting information|supplementary material)",
    "raw data that supports? the findings.{0,80}available in the supporting information",
    "authors confirm that the data supporting the findings.{0,120}included within",
    "datasets? presented in (this|the) study can be found in online repositories",
    "all relevant data and details of resources can be found within the article and (its )?supplementary information",
    public_source_data,
    sep = "|"
  )

  # Some data-availability statements refer generically to "files" in a known
  # data repository, especially OSF. Keep this path away from code-primary hosts.
  repository_files <- paste(
    "\\b(all|raw|source|supporting|supplementary|additional)? ?files?\\b",
    "\\bcif files?\\b",
    sep = "|"
  )

  supplementary_table_data <- paste0(
    "(strains?|oligonucleotide sequences).{0,80}",
    "(summari[sz]ed|provided|listed|shown).{0,40}",
    "(supplementary|supplemental) table"
  )
  journal_supplement_boilerplate <- paste(
    "supplementary (information:)?supplementary data are available at (bioinformatics|nar) online",
    "supplementary data are available at (bioinformatics|nar) online",
    # Generic publisher boilerplate present in every article of a journal,
    # not a data-availability statement (for example the Springer line
    # "The online version contains supplementary material available at <doi>").
    "online version.{0,40}contains supplementary materials? available at",
    sep = "|"
  )
  calculated_table_summary <- paste(
    "values? of .{0,80}(calculated|interaction energy).{0,80}",
    "(data set|dataset).{0,80}(supplementary|supplemental) table",
    sep = ""
  )
  code_or_ui_table <- paste(
    "read\\.csv\\(",
    "exported by creating a data table",
    "creating a data table and saving it as \\.csv",
    sep = "|"
  )
  protocol_or_code_only <- paste(
    "protocol .{0,80}(registered|available|publicly available).{0,80}(open science framework|osf\\.io)",
    "further details are available via the study repository",
    "script can be found at .{0,80}(open science framework|osf\\.io)",
    "scripts? .{0,80}generate .{0,30}simulated datasets?.{0,80}github",
    "scripts? for .{0,80}(decrypting|reformatting|analy[sz]ing).{0,40}data records",
    "shared genes between",
    "(source )?code supporting the findings.{0,100}(zenodo|github|10\\.5281)",
    "code availability.{0,120}(source code|code supporting|github|zenodo)",
    sep = "|"
  )

  # Deposit of this study's data in a named repository, a data-availability
  # statement tied to a repository / accession, data in the supplement, or data
  # provided as files in a data format.
  supp_ctx <- has("supplement|supporting information|additional files?", s)
  soft_data <-
    (has_deposit & has(repo_name, s) & has(data_noun, s)) |
    (has(das, s) & (has(repo_url, s) | has(repo_name, s) |
      has(accession, s) | (has(seq_accession, s) & has(acc_word, s)) | supp_ctx)) |
    has(supp_data, s) |
    has(file_data, s) |
    has(in_article_data, s) |
    has(supplementary_table_data, s) |
    (has(repository_files, s) & has(avail, s) & has(data_repo_name, s))

  # Veto sentences that reuse external data without depositing anything, and
  # statements of non-availability.
  public_source_hit <- has(public_source_data, s)
  data_boilerplate <- has(journal_supplement_boilerplate, s) |
    has(calculated_table_summary, s) |
    has(code_or_ui_table, s) |
    has(protocol_or_code_only, s)
  veto <- (has(reuse, s) & !has_deposit & !public_source_hit) |
    has(negation, s) | data_boilerplate

  data_hit <- (concrete_data | soft_data) & !veto

  if (any(data_hit)) {
    out$is_open_data <- TRUE
    out$data_text <- paste(sentences[data_hit], collapse = " | ")
  }

  # --- code ---
  code_avail <- paste(
    "available", "accessible", "can be (accessed|downloaded|obtained|retrieved)",
    "provided", "shared", "hosted", "released", "archived",
    "freely available", "can be installed", "installed from",
    "obtained from", "downloaded from", "supplied through", "made available",
    sep = "|"
  )
  registry_avail <- paste(
    "available", "accessible", "can be (downloaded|obtained|retrieved)",
    "open[- ]source", "freely available", "can be installed", "installed from",
    "obtained from", "downloaded from",
    sep = "|"
  )
  weak_code_term <- paste(
    "source code", "analysis code", "computer code", "r[- ]?syntax",
    "matlab code", "matlab scripts?", "python codes?", "codes? and data",
    "code and data", "analysis scripts?", "statistical scripts?",
    "r (code )?scripts?",
    "\\bscripts?\\b.{0,50}(reproduc|rerun|analysis|calculat|provided for convenience|included in the accompanied program)",
    "files needed to (rerun|reproduce) (the )?analysis",
    "data availability.{0,80}(model data files|all files).{0,80}github",
    "[a-z][a-z0-9_-]+ and its documentation are freely available for download on github",
    "facets \\(https://github\\.com/[^)]+\\).{0,80}can be .*used",
    "software program, spik(esorter|sorter)",
    "(python )?scripts? \\(supplemental script\\)",
    "tools? (are |is )?available .{0,80}github",
    "\\bcodes?\\b.{0,40}(generated|analy[sz]ed|available|provided|shared|hosted|released|archived)",
    sep = "|"
  )
  explicit_code_term <- paste(
    "facets \\(https://github\\.com/[^)]+\\).{0,80}can be .*used",
    "(python )?scripts? \\(supplemental script\\)",
    sep = "|"
  )
  generic_code_discussion <- paste(
    "few works.{0,70}(source code|codebase)",
    "requirement to disclose",
    "state how.{0,80}(computer|source|statistical|analytic).*code.{0,50}can be accessed",
    "how (computer|source|statistical|analytic).*code can be accessed",
    "will also create",
    sep = "|"
  )
  code_use_only <- paste(
    "server provides ready-made scripts",
    "created by .{0,40}, see \\[",
    "software applications are available for sorting spikes",
    "using open[- ]source .{0,30}code",
    "broadinstitute\\.github\\.io/picard",
    "cellchat package",
    "r-script downloaded from",
    "open source llamaindex",
    "icd-10-cm codes",
    "(diagnosis|procedure|question) codes",
    "code definitions",
    "qualitative codes",
    "analysis code/syntax available\\?",
    "coding was conducted",
    "open[- ]source nature means the code",
    "open.{0,3}source nature means the code",
    "code is concise, readable and available for inspection",
    "downloaded using the bioconductor package",
    "used .{0,80}bioconductor package",
    "model-based analysis of single cell transcriptomics",
    "github\\.com/rglab/mast",
    "\\bcomparem\\b",
    "\\bpocp-nf\\b",
    "\\bjcvi software\\b",
    sep = "|"
  )

  strong_code <- has(code_repo, s) & has(code_term, s)
  registry_code <- has(code_registry, s) & has(code_term, s) &
    has(registry_avail, s)
  weak_code <- has(weak_code_term, s) & has(code_avail, s)
  explicit_code <- has(explicit_code_term, s)
  code_hit <- (strong_code | registry_code | weak_code | explicit_code) &
    !has(negation, s) & !has(generic_code_discussion, s) &
    !has(code_use_only, s)

  if (any(code_hit)) {
    out$is_open_code <- TRUE
    out$code_text <- paste(sentences[code_hit], collapse = " | ")
  }

  out
}
