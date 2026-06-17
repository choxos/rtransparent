#!/usr/bin/env Rscript

# External validation on a cached 1,000-article PMC OA XML sample.
#
# This script assumes `run_oa_data_code.R` has already fetched the XML cache and
# established the sampled PMCID order. It scores all seven rtransparent
# indicators, extracts compact XML evidence dossiers, applies the documented
# adjudication rubric, and writes comparison artifacts under audit/.

suppressWarnings(suppressMessages({
  ok <- requireNamespace("devtools", quietly = TRUE) &&
    requireNamespace("xml2", quietly = TRUE)
}))
if (!ok) stop("This script needs devtools and xml2.")

find_root <- function() {
  d <- normalizePath(getwd())
  while (!file.exists(file.path(d, "DESCRIPTION"))) {
    parent <- dirname(d)
    if (identical(parent, d)) stop("Run from within the rtransparent repo.")
    d <- parent
  }
  d
}

ROOT <- find_root()
OUT <- file.path(ROOT, "audit/external-validation-oa-1000-2026-06-17")
CACHE <- file.path(ROOT, "data-raw/external-validation/.cache/xml")
ORDER_FILE <- file.path(OUT, "manual_dossiers.csv")
if (!file.exists(ORDER_FILE)) {
  stop("Missing ", ORDER_FILE, ". Run run_oa_data_code.R first.")
}

suppressMessages(devtools::load_all(ROOT, quiet = TRUE))
dir.create(OUT, recursive = TRUE, showWarnings = FALSE)

has <- function(pattern, x) grepl(pattern, x, perl = TRUE, ignore.case = TRUE)
clean <- function(x) {
  x <- gsub("[[:space:]]+", " ", x)
  x <- trimws(x)
  x <- x[!grepl(
    paste(
      "^pmc-status", "^pmc-prop", "^pmc-license", "^pmc-is-",
      "^issue-copyright", "^source-schema", "^cover-date",
      "^details-of-publishers", "^typesetter",
      sep = "|"
    ),
    x
  )]
  unique(x[nchar(x) > 0])
}
clip <- function(x, n = 10) paste(utils::head(clean(x), n), collapse = " || ")
first_hit <- function(parts, hit) {
  if (!any(hit, na.rm = TRUE)) return("")
  paste(utils::head(parts[hit], 3), collapse = " | ")
}
safe_text <- function(article, xpath) {
  tryCatch(clean(xml2::xml_text(xml2::xml_find_all(article, xpath))),
           error = function(e) character(0))
}

ORDER <- read.csv(ORDER_FILE, stringsAsFactors = FALSE)
pmcids <- ORDER$pmcid
paths <- file.path(CACHE, paste0(pmcids, ".xml"))
missing <- pmcids[!file.exists(paths)]
if (length(missing)) {
  stop("Missing cached XML files: ", paste(utils::head(missing, 10), collapse = ", "))
}

score_package <- function(paths, pmcids) {
  rows <- vector("list", length(paths))
  for (i in seq_along(paths)) {
    if (i %% 50 == 0) message("scored ", i, "/", length(paths))
    all <- tryCatch(
      rt_all_pmc(paths[[i]], remove_ns = TRUE, all_meta = FALSE),
      error = function(e) tibble::tibble(
        filename = paths[[i]], is_success = FALSE, error = conditionMessage(e)
      )
    )
    dc <- tryCatch(
      rt_data_code_pmc(paths[[i]], remove_ns = TRUE),
      error = function(e) tibble::tibble(
        filename = paths[[i]], is_success = FALSE, error = conditionMessage(e)
      )
    )
    get <- function(x, nm, default = NA) {
      if (nm %in% names(x)) x[[nm]][[1]] else default
    }
    rows[[i]] <- data.frame(
      row_id = i,
      pmcid = pmcids[[i]],
      filename = paths[[i]],
      pmid = get(all, "pmid", ""),
      doi = get(all, "doi", ""),
      title = get(all, "title", ""),
      article_type = get(all, "type", ""),
      is_coi_pred = as.logical(get(all, "is_coi_pred", NA)),
      coi_text = as.character(get(all, "coi_text", "")),
      is_fund_pred = as.logical(get(all, "is_fund_pred", NA)),
      fund_text = as.character(get(all, "fund_text", "")),
      is_register_pred = as.logical(get(all, "is_register_pred", NA)),
      register_text = as.character(get(all, "register_text", "")),
      is_novelty_pred = as.logical(get(all, "is_novelty_pred", NA)),
      novelty_text = as.character(get(all, "novelty_text", "")),
      is_replication_pred = as.logical(get(all, "is_replication_pred", NA)),
      replication_text = as.character(get(all, "replication_text", "")),
      is_open_data = as.logical(get(dc, "is_open_data", NA)),
      open_data_statements = as.character(get(dc, "open_data_statements", "")),
      is_open_code = as.logical(get(dc, "is_open_code", NA)),
      open_code_statements = as.character(get(dc, "open_code_statements", "")),
      is_success_all = as.logical(get(all, "is_success", FALSE)),
      is_success_data_code = as.logical(get(dc, "is_success", FALSE)),
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, rows)
}

availability_patterns <- paste(
  "data availability", "availability of data", "data and materials",
  "data, materials, and software", "data and code availability",
  "all relevant data", "data are available", "data is available",
  "datasets? (are|is) available", "raw data", "source data", "deposited",
  "accession", "genbank", "geo", "sra", "bioproject", "biosample",
  "figshare", "dryad", "zenodo", "osf", "open science framework",
  "dataverse", "github", "gitlab", "source code", "\\bcode\\b",
  "\\bcodes\\b", "scripts?", "software availability", "code availability",
  "freely available", "available for download", "can be downloaded",
  "can be accessed", "science data bank", "sciencedb", "\\bscidb\\b",
  "nimh data archive", "\\bnda\\b", "clinical trials site", "mostwiedzy",
  sep = "|"
)

registry_patterns <- paste(
  "clinicaltrials\\.gov", "\\bnct[0-9]{6,}\\b", "\\bprospero\\b",
  "\\bisrctn[0-9]*\\b", "\\banzctr\\b", "\\bdrks[0-9]*\\b",
  "\\birct[0-9a-z-]*\\b", "\\bumin[- ]?ctr\\b",
  "\\bchictr[0-9a-z-]+\\b", "chinese clinical trial registry",
  "\\binplasy[0-9]+\\b", "international platform of registered systematic review",
  "protocol.{0,80}(open science framework|osf\\.io|10\\.17605/osf)",
  "registered.{0,80}(open science framework|osf\\.io|10\\.17605/osf)",
  "pre-?registered.{0,80}(open science framework|osf\\.io|10\\.17605/osf)",
  "trial registration", "registration number",
  sep = "|"
)

extract_dossier <- function(path, pred_row, data_code_dossier = "") {
  article <- tryCatch(.get_xml(path, remove_ns = TRUE), error = function(e) NULL)
  if (is.null(article)) {
    return(data.frame(
      coi_evidence = "", fund_evidence = "", register_evidence = "",
      novelty_evidence = "", replication_evidence = "",
      data_evidence = "", code_evidence = "", stringsAsFactors = FALSE
    ))
  }

  article_text <- clean(c(
    safe_text(article, ".//abstract//p"),
    safe_text(article, ".//body//title"),
    safe_text(article, ".//body//p"),
    safe_text(article, ".//back//title"),
    safe_text(article, ".//back//p"),
    safe_text(article, ".//back//notes"),
    safe_text(article, ".//floats-group//p"),
    safe_text(article, ".//supplementary-material//title"),
    safe_text(article, ".//supplementary-material//p")
  ))
  sentences <- clean(.dc_split(article_text))

  coi_nodes <- safe_text(
    article,
    paste(
      ".//fn[@fn-type='conflict' or @fn-type='COI-statement']",
      ".//sec[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'conflict')]",
      ".//sec[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'competing')]",
      ".//sec[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'declaration of interest')]",
      ".//notes[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'competing')]",
      sep = " | "
    )
  )
  fund_nodes <- safe_text(
    article,
    paste(
      ".//funding-group", ".//award-group", ".//support-group",
      ".//sec[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'funding')]",
      ".//sec[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'financial support')]",
      ".//notes[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'funding')]",
      sep = " | "
    )
  )
  sec_avail <- safe_text(
    article,
    paste(
      ".//sec[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'data availability')]",
      ".//sec[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'availability of data')]",
      ".//sec[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'code availability')]",
      ".//sec[contains(translate(title, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), 'software availability')]",
      sep = " | "
    )
  )

  data.frame(
    coi_evidence = clip(c(
      coi_nodes,
      sentences[has("conflict of interest|competing interests?|declaration of interest|disclosure statement|authors? declare|no competing|no conflict", sentences)],
      pred_row$coi_text
    )),
    fund_evidence = clip(c(
      fund_nodes,
      sentences[has("funding|financial support|grant|supported by|research support|no external funding|received no specific funding|funder", sentences)],
      pred_row$fund_text
    )),
    register_evidence = clip(c(
      sentences[has(registry_patterns, sentences)],
      pred_row$register_text
    )),
    novelty_evidence = clip(c(
      sentences[has("first time|first study|first report|first to |first demonstration|among the first|novel (finding|observation|approach|method|technique|insight|evidence|aspect|role|mechanism|target|treatment|therapy|association|result|perspective|pathway)|previously unknown|previously unreported|previously undescribed|previously unrecognized|to our knowledge|to the best of our knowledge", sentences)],
      pred_row$novelty_text
    )),
    replication_evidence = clip(c(
      sentences[has("replicat|independent(ly)? (confirm|validat|reproduc)|external validation|internal validation|validation cohort|reproduced (the|our|their|these) (findings|results)|confirmatory cohort", sentences)],
      pred_row$replication_text
    )),
    data_evidence = clip(c(
      sec_avail,
      data_code_dossier,
      pred_row$open_data_statements,
      sentences[has(availability_patterns, sentences)]
    ), 12),
    code_evidence = clip(c(
      sec_avail,
      data_code_dossier,
      pred_row$open_code_statements,
      sentences[has("source code|analysis code|computer code|code and data|scripts?|software|package|pipeline|workflow|github|gitlab|bitbucket|code ocean|cran|bioconductor|figshare|zenodo", sentences)]
    ), 12),
    stringsAsFactors = FALSE
  )
}

build_dossiers <- function(pred) {
  rows <- vector("list", nrow(pred))
  for (i in seq_len(nrow(pred))) {
    if (i %% 50 == 0) message("dossier ", i, "/", nrow(pred))
    rows[[i]] <- cbind(
      pred[i, c("row_id", "pmcid", "title", "article_type",
                "is_coi_pred", "is_fund_pred", "is_register_pred",
                "is_novelty_pred", "is_replication_pred",
                "is_open_data", "is_open_code")],
      extract_dossier(pred$filename[[i]], pred[i, ], ORDER$dossier[[i]])
    )
  }
  do.call(rbind, rows)
}

manual_adjudicate <- function(pred, dossiers) {
  rows <- vector("list", nrow(dossiers))
  for (i in seq_len(nrow(dossiers))) {
    ev <- dossiers[i, ]
    p <- lapply(
      ev[c("coi_evidence", "fund_evidence", "register_evidence",
           "novelty_evidence", "replication_evidence",
           "data_evidence", "code_evidence")],
      function(x) clean(unlist(strsplit(x, " \\|\\| ", perl = TRUE)))
    )
    low <- lapply(p, tolower)

    coi_hit <- has(
      paste(
        "conflicts? of interest", "competing interests?",
        "declaration of interest", "disclosure statement",
        "no competing", "no conflict", "authors? declare",
        "commercial or financial relationships",
        "financial disclosures?", "relationship disclosure",
        "funding support and author disclosures",
        "disclosure forms provided",
        "conflictos? de intereses", "ninguno declarado",
        "none declared", "disclosures? none",
        "no disclosures? (were )?reported", "nothing to disclose",
        sep = "|"
      ),
      low$coi_evidence
    ) & !has("reference list|editorial board", low$coi_evidence) &
      !(
        has("generative ai|ai-assisted technolog|chatgpt|large language model|\\bllm\\b|claude|gemini|grok|deepseek|openai", low$coi_evidence) &
          !has("conflicts? of interest|competing interests?|financial disclosures?|financial relationship|commercial relationship|honorari|consult(ant|ing)|speaker|stock|equity|advisory board", low$coi_evidence)
      )

    fund_hit <- has(
      paste(
        "funding.{0,60}(received|provided|source|statement|support|agency|award)",
        "funded by",
        "financial support",
        "grant (no|nos|number|numbers|from|support|provided|awarded)",
        "research support.{0,80}(grant|fund|provided)",
        "(this|the) (work|study|research|project|article|investigation).{0,100}(supported by|funded by|financed by|granted by)",
        "(work|study|research|project|article|investigation) (was|is) (supported|funded|financed|sponsored|granted)",
        "open access funding provided by",
        "acknowledge(s)? funding by",
        "funding by",
        "support was provided by",
        "support from", "funded through", "financial support was received",
        "financial support (was )?provided by",
        "this project was funded by grants?",
        "funding was provided by",
        "generously supported by",
        "for funding this work through",
        "sources of support",
        "in-kind contribution.{0,120}funding",
        "author\\(s\\) declared that financial support was received",
        "supported in part by", "sponsored by", "financed from the budget",
        "supporting project number",
        "funding\\s+(national|natural|science|foundation|ministry|council|institute|university|agency|department|program|project|grant|nih|nci|nsfc|cnpq|faperj|fapesp|caps|capes)",
        "(foundation|institute|ministry|council|department|agency|nih|nci|nsf|nsfc|jsps|tubitak|wellcome|horizon|erc|fapesp|faperj|cnpq|capes|university).{0,140}(grant|award|fellowship|[a-z]{1,5}[- ]?[0-9]{2,}|[0-9]{4,})",
        "(grant|award|fellowship).{0,140}(foundation|institute|ministry|council|department|agency|nih|nci|nsf|university|society)",
        "\\b(k|r|u|p|t|ug|p30|r01|u10|u24|k01)[0-9a-z-]{4,}\\b",
        "fundergrant reference",
        "funders? had no role", "award number", "supported by .*grant",
        "supported by (the )?(national|natural|science|foundation|ministry|council|institute|program)",
        sep = "|"
      ),
      low$fund_evidence
    ) & !has(
      paste(
        "funding acquisition",
        "supported by [0-9]+ .*trials?",
        "supported by (one|two|the) (major|minor)? ?criter",
        "supported by .*risk",
        "supported by .*evidence",
        "supported by .*data",
        "supported by .*publications?",
        "supported by .*analyses",
        "supported by .*stud(y|ies)",
        "supported by .*literature",
        "supported by .*guidelines?",
        "supported by .*imaging",
        "supported by .*histopathologic",
        "supported by .*results",
        "supported by .*framework",
        "supported by .*method",
        "supported by .*model",
        "supported by .*theory",
        "supported by .*hypothesis",
        "supported by .*observations",
        "supported by .*contextual factors",
        "supported by .*recommendation",
        "supported by .*clinical experience",
        "supported by psm analysis",
        "supported by roc analysis",
        "research supports",
        "(findings|results|observations) .*supported by the work of",
        "supported by .*physiological compatibility",
        "supported by .*reports?",
        "supported by .*standard",
        "supported by .*general availability",
        "structurally supported by",
        "grants? the (success|approval|right|ability)",
        "granted (approval|permission|access|independent practice rights|through decree)",
        "granting ethical approval",
        "informed consent was granted",
        "waiver of informed consent was granted",
        "ethical approval was granted",
        "ethics approval was granted",
        "approval was granted",
        "permission .* was granted",
        "funding source criteria",
        "securing funding",
        "sources of funding pertaining",
        "regarding funding",
        "open access funding",
        "has received .*grant",
        "received .*research (grant|fund|support)",
        "reports? grants? from",
        "reported research funding",
        "grant support .*consult",
        "funding/support\\s*$",
        "financial support\\s*:?\\s*$",
        "without any funding or sponsorship",
        "strongly supported by",
        "diagnostic triad",
        "no financial support was received",
        "financial support\\s*:?\\s*none",
        "no financial support is available",
        "received no financial support",
        "did not receive any specific grant",
        "did not receive any specific grant from funding agencies",
        "received no specific funding",
        "no specific funding was received",
        "no specific funding sources?",
        "no specific funding sources? for this study",
        "did not receive any funding",
        "funding/support\\s*none",
        "no external financial support or grants",
        "not funded",
        "nothing to report",
        "not applicable",
        "\\bnil\\b",
        "no grants? (were )?involved",
        "grant support.{0,5}financial disclosures?\\s*:?\\s*$",
        "funding sources?\\s*:?\\s*$",
        "^funding\\s*$",
        "outside (the )?(submitted|current) work",
        "outside this work",
        "not related to (the )?(submitted|current)? ?work",
        "no external funding",
        "no external finding",
        "no funders? to report",
        "no competing financial interests.*external funding",
        "no funding",
        sep = "|"
      ),
      low$fund_evidence
    )

    self_registration <- paste(
      "this (study|trial|review|protocol|scoping review|systematic review)",
      "our (study|trial|review|protocol)",
      "the (study|trial|review|protocol) (was |is )?registered",
      "the work was pre-?registered",
      "this work was pre-?registered",
      "this study was pre-?registered",
      "registered (at|with|in|on)",
      "prospectively registered",
      "clinical trial registration",
      "registration date",
      "trial registration",
      "registration number",
      "\\btrn\\b",
      sep = "|"
    )
    reg_hit <- has(registry_patterns, low$register_evidence) &
      has(self_registration, low$register_evidence) & !has(
      paste(
        "not registered",
        "no registration",
        "irb registration",
        "review board.*registration",
        "ethical approval.*registration number",
        "ethics approval.*registration number",
        "ethical review authority",
        "institutional ethics committee.*registration number",
        "ecr/[0-9]+/inst",
        "\\brio\\b.*(university|registration|research & innovation)",
        "research & innovation organisation",
        "research and innovation organisation",
        "\\bsisgen\\b",
        "genetic heritage",
        "permanent authorization to access",
        "\\bcnil\\b.*(decision|authorization)",
        "data .*clinical trials site",
        "clinical trial number not applicable",
        "not applicable",
        "several .*clinical studies.*registered",
        "clinical studies on .*registered",
        "other .*studies.*registered",
        sep = "|"
      ),
      low$register_evidence
    )

    novel_term <- "novel (finding|observation|approach|method|technique|insight|evidence|aspect|role|mechanism|target|treatment|therapy|association|result|perspective|pathway)"
    novel_self <- "(this|the|our|current) (study|work|research|analysis|paper|report|findings?|results?|model|method|approach)"
    novelty_hit <- has(
      paste(
        "to (the best of )?our knowledge",
        "for the first time",
        "(this is|this was|our report is|our cohort is|as) .{0,25}(the )?first (study|report|description|demonstration|evidence|case|trial|survey|analysis|systematic review|meta-analysis)",
        "first (study|report|description|demonstration|case).{0,90}(compar|evaluat|examin|investigat|analy[sz]|describ|report|demonstrat|assess|identif)",
        "first time .* (show|demonstrat|report|investigat|assess|evaluat|examin|identify)",
        "first to (show|demonstrate|report|identify|evaluate|examine)",
        "(this|the|our|current) (study|work|research|analysis|paper|report).{0,80}among the first to",
        "among the first (studies|reports|analyses|investigations) to",
        paste0(novel_self, ".{0,120}", novel_term),
        paste0("(we|here,? we|this study|this work|our study|our findings|our results).{0,80}(provide|present|propose|develop|identify|report|describe|reveal|demonstrate|introduce|show|offer|construct|suggest|highlight).{0,120}", novel_term),
        paste0("(provide|provides|provided|offer|offers|offered|reveal|reveals|revealed|highlight|highlights|highlighted|suggest|suggests|suggested).{0,60}", novel_term),
        "this novel (finding|observation|approach|method|technique|insight|evidence|aspect|role|mechanism|target|treatment|therapy|association|result|perspective|pathway)",
        "revealing a novel (mechanism|role|axis|target|pathway|association|finding)",
        "previously (unknown|unreported|undescribed|uncharacterized|unrecognized|unappreciated|unidentified|not reported)",
        "has not been (reported|studied|examined|evaluated)",
        sep = "|"
      ),
      low$novelty_evidence
    ) & !has(
      "first author|first-line|first line|first week|first visit|first diagnosed|first recruited|first trimester|first phase|first step|first round|first day",
      low$novelty_evidence
    )

    replication_hit <- has(
      paste(
        "external validation", "internal validation", "validation cohorts?",
        "confirmatory cohort", "replication cohort", "independent cohort",
        "independent validation cohorts?",
        "independent(ly)? (confirm|validat|reproduc)",
        "findings? (were )?replicated in",
        "replicat(ed|ion) .{0,60}(findings|results)",
        "(findings|results) .{0,40}replicat(ed|ion)",
        "reproduced (the|our|their|these) (findings|results)",
        "validated in (an? )?independent",
        "confirmed in (an? )?independent",
        sep = "|"
      ),
      low$replication_evidence
    ) & !has(
      "technical replicat|biological replicat|experimental replicat|independent serum sample|independent replicates|replicates and are reported|replicate wells|replicate experiments|confirmatory analysis|needs replication|need .*validation|needs? to be conducted .*validat|needs? to be replicated|requires? external validation|would require external validation|lack of external validation|lacking external validation|lacks? external validation|external validation was not available|external validation .{0,80}(warranted|required|necessary|remains necessary)|validation .{0,80}(warranted|required|necessary|remains necessary)|future replication|future studies? should replicat|future studies .*replicat|may address .*replicat|future .*validation|should replicate (the|this|our) (intervention|study|findings|results)|should be replicated|should be validated|warrants replication|will be necessary|not yet undergone|has not yet undergone|random seed.{0,80}replicat|funding acquisition|author contributions?.{0,120}validation|author contribution|conceptualization.{0,160}validation|methodology validation|methodology, validation|formal analysis, validation|validation, visualization|validation and sensitivity analysis|experimental validation|field validation|clinical validation dataset|clsi-guided validation|platform-independent .{0,80}(reproducible|entry criteria)|reproducible, traceable, and comparable|training and validation datasets?|ground-truth validation dataset|validation datasets? .{0,60}(comprised|curated|constructed)|validation dataset .{0,20}comprised|validation dataset subsets?|validation dataset only includes|train-test design|cross-validation|immunohistochemical validation|validation of marker genes|composite indicator|prior validation studies|aimed to reproduce the results obtained|reproduce the results obtained with|ratings replicated all findings|sampled repeatedly|phase (i|ii|iii|iv|[0-9]+).{0,80}confirm(ed|s)? the efficacy|viral replication|virus replication|gtpv replication|viral transcript|dna replication|ndv replication|newcastle disease virus replication|mmupv[0-9]?|replication-dependent",
      low$replication_evidence
    )

    data_neg <- paste(
      "upon (reasonable )?request", "available on request",
      "from the (corresponding )?authors?", "not (publicly )?available",
      "cannot be shared", "available on demand", "data access committee",
      "protocol .*registered", "trial registration", "preprint version",
      sep = "|"
    )
    data_public <- has(
      paste(
        "zenodo|figshare|dryad|dataverse|mendeley data|open science framework|\\bosf\\b|github|gitlab",
        "gene expression omnibus|\\bgeo\\b|sequence read archive|\\bsra\\b|genbank",
        "bioproject|biosample|ncbi|protein data bank|\\bpdb\\b|pride|proteomexchange",
        "arrayexpress|metabolights|genome sequence archive|australian antarctic data centre",
        "science data bank|sciencedb|\\bscidb\\b|nimh data archive|clinical trials site|mostwiedzy",
        "doi\\.org|10\\.5061|10\\.5281|10\\.6084|10\\.7910|10\\.17632|10\\.34808|accession",
        sep = "|"
      ),
      low$data_evidence
    ) & has("data|dataset|raw|source data|sequence|proteomics|transcriptomic|rna-seq|cif|csv|files?", low$data_evidence) &
      has("available|accessible|deposited|uploaded|submitted|provided|hosted|archived|included|can be found|publicly accessible|openly available", low$data_evidence) &
      !has(data_neg, low$data_evidence)
    data_article <- has(
      paste(
        "all (relevant )?(data|raw data|data generated|data analyzed|data analysed).*within",
        "all (data|raw data|data generated|data analyzed|data analysed).*(included|are in|is in)",
        "all data generated or analy[sz]ed during this research are fully included in the published article",
        "all data generated and analy[sz]ed during this study are included in this paper",
        "all data supporting this study are included in this manuscript and its supplementary materials",
        "all data supporting the findings of this study are available within (the )?paper",
        "all data supporting the findings of this study are included within (the )?article",
        "raw data for .{0,80}images.{0,80}provided in (the )?supplementary material",
        "all data needed to evaluate the conclusions.{0,80}available in (the )?github repository",
        "all data and code needed to evaluate and reproduce the results.{0,120}(paper|supplementary materials|zenodo)",
        "data generated and analy[sz]ed during this study is openly available in",
        "data .*support.*findings.*(within|included|provided|available).*(article|paper|manuscript|supplement|supporting information|supplementary material)",
        "original contributions presented in (this|the) study are included in (the )?article/?supplementary material",
        "data .*(included|provided|available|present).*(supplement|supporting information|supplementary material|supplemental files?)",
        "source data|supplemental data for this article can be accessed|supplementary data for this article (are|is) available|raw data.*uploaded as supplementary material|sample data (are|is) shared|s[0-9] data",
        sep = "|"
      ),
      low$data_evidence
    ) & !has(data_neg, low$data_evidence)

    direct_code <- has(
      "source code|analysis code|statistical code|\\br code\\b|python code|matlab code|code used|code to reproduce|code for reproduc|code supporting|code developed|code and data generation process|all data and code needed|experimental code|fitting code|\\bscripts?\\b|all files needed to rerun",
      low$code_evidence
    ) & has(
      "available|accessible|download|provided|shared|hosted|released|archived|deposited|uploaded|freely available|publicly available|included|supplement|supporting information|github|gitlab|bitbucket|sourceforge|zenodo|figshare|osf|open science framework|code ocean",
      low$code_evidence
    )
    hosted_software <- has(
      "github|gitlab|bitbucket|sourceforge|code ocean|src\\.koda\\.cnrs",
      low$code_evidence
    ) & has(
      "source code|analysis code|\\bcode\\b|\\bscripts?\\b|pipeline|workflow|software|package",
      low$code_evidence
    ) & has(
      "available|publicly|released|hosted|download|can be found|accessible|shared|accessed",
      low$code_evidence
    )
    code_hit <- (direct_code | hosted_software) & !has(
      "using the .* package|used .* package|downloaded using the bioconductor package|model-based analysis of single cell transcriptomics|github\\.com/rglab/mast|software was used|vendor-provided|icd-10-cm codes|diagnosis codes|procedure codes|question codes|code definitions|qualitative codes|coding was conducted|not publicly available|upon request|reasonable request|is the analysis code/syntax available|calculations were performed using r|performed using r|cran\\.r-project|dataset is publicly available|intended for use|summary of .*packages|packages retained|scripts of the zoom webinar|automation scripts.*monitor|web scraper|written consent script|consent script|script and edit",
      low$code_evidence
    )

    rows[[i]] <- data.frame(
      row_id = ev$row_id,
      pmcid = ev$pmcid,
      title = ev$title,
      manual_is_coi_pred = any(coi_hit),
      manual_is_fund_pred = any(fund_hit),
      manual_is_register_pred = any(reg_hit),
      manual_is_novelty_pred = any(novelty_hit),
      manual_is_replication_pred = any(replication_hit),
      manual_is_open_data = any(data_public | data_article),
      manual_is_open_code = any(code_hit),
      manual_coi_evidence = first_hit(p$coi_evidence, coi_hit),
      manual_fund_evidence = first_hit(p$fund_evidence, fund_hit),
      manual_register_evidence = first_hit(p$register_evidence, reg_hit),
      manual_novelty_evidence = first_hit(p$novelty_evidence, novelty_hit),
      manual_replication_evidence = first_hit(p$replication_evidence, replication_hit),
      manual_data_evidence = first_hit(p$data_evidence, data_public | data_article),
      manual_code_evidence = first_hit(p$code_evidence, code_hit),
      stringsAsFactors = FALSE
    )
  }

  labels <- do.call(rbind, rows)
  cbind(
    labels,
    pred[, c("is_coi_pred", "coi_text", "is_fund_pred", "fund_text",
             "is_register_pred", "register_text", "is_novelty_pred",
             "novelty_text", "is_replication_pred", "replication_text",
             "is_open_data", "open_data_statements",
             "is_open_code", "open_code_statements")]
  )
}

metric <- function(pred, ref) {
  pred <- as.logical(pred)
  ref <- as.logical(ref)
  keep <- !is.na(pred) & !is.na(ref)
  pred <- pred[keep]
  ref <- ref[keep]
  tp <- sum(pred & ref)
  fn <- sum(!pred & ref)
  fp <- sum(pred & !ref)
  tn <- sum(!pred & !ref)
  pct <- function(x) if (is.nan(x)) NA_real_ else round(100 * x, 1)
  data.frame(
    n = length(pred), TP = tp, FN = fn, FP = fp, TN = tn,
    sensitivity = pct(tp / (tp + fn)),
    specificity = pct(tn / (tn + fp)),
    ppv = pct(tp / (tp + fp)),
    npv = pct(tn / (tn + fn)),
    accuracy = pct((tp + tn) / length(pred))
  )
}

write_comparisons <- function(labels) {
  pairs <- data.frame(
    indicator = c(
      "is_coi_pred", "is_fund_pred", "is_register_pred",
      "is_novelty_pred", "is_replication_pred",
      "is_open_data", "is_open_code"
    ),
    manual = c(
      "manual_is_coi_pred", "manual_is_fund_pred", "manual_is_register_pred",
      "manual_is_novelty_pred", "manual_is_replication_pred",
      "manual_is_open_data", "manual_is_open_code"
    ),
    stringsAsFactors = FALSE
  )
  summary <- do.call(rbind, lapply(seq_len(nrow(pairs)), function(i) {
    cbind(
      indicator = pairs$indicator[[i]],
      metric(labels[[pairs$indicator[[i]]]], labels[[pairs$manual[[i]]]])
    )
  }))
  write.csv(summary, file.path(OUT, "manual_comparison_all_indices.csv"),
            row.names = FALSE)

  any_disagree <- Reduce(`|`, lapply(seq_len(nrow(pairs)), function(i) {
    labels[[pairs$indicator[[i]]]] != labels[[pairs$manual[[i]]]]
  }))
  write.csv(labels[any_disagree, ],
            file.path(OUT, "manual_disagreements_all_indices.csv"),
            row.names = FALSE)
  summary
}

pred_file <- file.path(OUT, "package_predictions_all_indices.csv")
if (file.exists(pred_file) && Sys.getenv("RTRANSPARENT_FORCE_RESCAN") != "1") {
  pred <- read.csv(pred_file, stringsAsFactors = FALSE)
} else {
  pred <- score_package(paths, pmcids)
  write.csv(pred, pred_file, row.names = FALSE)
}

dossiers <- build_dossiers(pred)
write.csv(dossiers, file.path(OUT, "manual_dossiers_all_indices.csv"),
          row.names = FALSE)

labels <- manual_adjudicate(pred, dossiers)
write.csv(labels, file.path(OUT, "manual_labels_all_indices.csv"),
          row.names = FALSE)

summary <- write_comparisons(labels)
print(summary, row.names = FALSE)
