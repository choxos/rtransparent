# Expand the novelty/replication gold set to the full 2023 hand-labeled sample
# (370 articles), keeping the original 160 maintainer-adjudicated labels as
# authoritative for the overlap (they carry earlier novelty corrections).
label_dir <- Sys.getenv("RT_LABEL_DIR", "/tmp/labels2")
root <- "."
out  <- file.path(root, "data-raw/benchmark/labels_novelty_replication.csv")

files <- sort(Sys.glob(file.path(label_dir, "batch_*.csv")))
gold  <- do.call(rbind, lapply(files, function(f)
  read.csv(f, stringsAsFactors = FALSE, colClasses = "character")))
gold  <- gold[!duplicated(gold$pmcid), ]
tf <- function(v) { v <- toupper(v); ifelse(v == "T", TRUE, ifelse(v == "F", FALSE, NA)) }
new <- data.frame(pmcid = gold$pmcid,
                  is_novelty = tf(gold$nov), is_replication = tf(gold$rep),
                  stringsAsFactors = FALSE)

orig <- read.csv(out, stringsAsFactors = FALSE)
# authoritative overlap
m <- match(orig$pmcid, new$pmcid)
new$is_novelty[m[!is.na(m)]]     <- as.logical(orig$is_novelty[!is.na(m)])
new$is_replication[m[!is.na(m)]] <- as.logical(orig$is_replication[!is.na(m)])
# append originals not in the new set (if any)
extra <- orig[is.na(match(orig$pmcid, new$pmcid)), c("pmcid","is_novelty","is_replication")]
new <- rbind(new, extra)
new <- new[!is.na(new$is_novelty), ]
write.csv(new, out, row.names = FALSE)
message("wrote ", out, ": ", nrow(new), " articles, ",
        sum(new$is_novelty), " novelty pos, ", sum(new$is_replication), " replication pos")
