# The detectors use magrittr pipes with the `.` placeholder, which R CMD check
# otherwise flags as an undefined global variable. Declare it package-wide.
utils::globalVariables(".")


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
