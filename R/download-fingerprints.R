#' Download fingerprints from the Recog repo
#'
#' @md
#' @param download_path path to a directory where the most current Recog
#'        fingerprints will be downloaded to and compressed.
#' @note This uses `GITHUB_PAT` from the environment, if available
#' @export
download_fingerprints <- function(download_path) {

  download_path <- path.expand(download_path)
  stopifnot(dir.exists(download_path))

  pat <- Sys.getenv("GITHUB_PAT")
  if (pat == "") pat <- NULL

  httr::GET(
    url = "https://api.github.com/repos/rapid7/recog/contents/xml",
    httr::add_headers(
      `Accept`="application/vnd.github.v3+json"
    ),
    query = list(
      access_token = pat
    )
  ) -> res

  httr::content(res, as = "parsed") %>%
    map_chr("download_url") %>%
    walk(~{
      fil <- basename(.x)
      tmp <- readLines(base::url(.x))
      writeLines(tmp, gzfile(file.path(download_path, sprintf("%s.gz", fil))))
    })

}


