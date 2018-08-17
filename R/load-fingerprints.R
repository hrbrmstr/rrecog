#' Load a directory of fingerprints
#'
#' @md
#' @param fingerprints_directory a directory where Recogs XML fingerprints are stored
#' @return a `list` of `recog_fingerprints`
#' @note You **cannot** serialize the resultant object as it uses the `ore`
#'       regex library and those compiled patterns are not serializable.
#' @export
#' @examples
#' load_fingerprints(
#'   system.file("fingerprints", package="rrecog")
#' )
load_fingerprints <- function(fingerprints_directory) {

  fingerprints_directory <- path.expand(fingerprints_directory)
  stopifnot(dir.exists(fingerprints_directory))

  list.files(fingerprints_directory, "xml$|xml\\.gz$", full.names = TRUE) %>%
    map(read_fingerprints_file)

}

#' Use built-in fingerprints
#'
#' Use a snapshot of the Recog repository was taken on 2018-08-17. There may be
#' newer fingerprints or updates to existing ones in the repository. Use
#' [download_fingerprints()] to download, compress and store new fingerprints
#' from the Recog repository.
#'
#' @md
#' @note this is simply `load_fingerprints(system.file("fingerprints", package="rrecog"))`
#' @note You **cannot** serialize the resultant object as it uses the `ore`
#'       regex library and those compiled patterns are not serializable.
#' @export
#' @examples
#' use_builtin_fingerprints()
use_builtin_fingerprints <- function() {

  load_fingerprints(
    system.file("fingerprints", package="rrecog")
  )

}
