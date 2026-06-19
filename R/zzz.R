# The detectors use magrittr pipes with the `.` placeholder, and rt_summary()
# refers to the lazily-loaded `rt_accuracy` dataset; R CMD check would otherwise
# flag both as undefined global variables. Declare them package-wide.
utils::globalVariables(c(".", "rt_accuracy"))


.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion(pkgname)
  packageStartupMessage(sprintf(paste0(
    "rtransparency %s: identify indicators of transparency (conflicts of ",
    "interest, funding,\nprotocol registration, novelty, replication, and data ",
    "and code sharing) in\nbiomedical articles. GitHub: ",
    "https://github.com/choxos/rtransparency | vignette(\"rtransparency\")"),
    version
  ))
  invisible()
}
