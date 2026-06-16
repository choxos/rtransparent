.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion(pkgname)
  packageStartupMessage(sprintf(paste0(
    "rtransparent %s: identify indicators of transparency (conflicts of ",
    "interest, funding,\nprotocol registration, novelty, replication, and data ",
    "and code sharing) in\nbiomedical articles. GitHub: ",
    "https://github.com/choxos/rtransparent | vignette(\"rtransparent\")"),
    version
  ))
  invisible()
}
