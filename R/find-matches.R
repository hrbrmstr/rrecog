#' Find fingerprint matches for a given source
#'
#' @md
#' @param recog_db a structure created with [load_fingerprints()] or
#'        [use_builtin_fingerprints()]
#' @param source the 1-element character vector to compare against
#' @param protocol,matches regexs to limit what you're comparing against. These
#'        are boolean **OR'd** together
#' @export
#' @examples
#' recog_db <- use_builtin_fingerprints()
#' recog_match(recog_db, "VShell_Special_Edition_2_5_0_204 VShell", "ssh")
recog_match <- function(recog_db, source, protocols = ".*", matches = NULL) {

  if (
    identical(
      attr(recog_db[[1]]$fingerpints[[1]]$compiled_pattern, ".compiled"),
      new("externalptr")
    )) {
    stop(
      "The external pointers for the compiled patterns are not valid. ",
      "Please re-load the data you are supplying to the `recog_db` parameter."
    )
  }

  protocol_matchers <- if (is.null(protocols)) {
    numeric()
  } else {
    which(grepl(protocols, map_chr(recog_db, "protocol")))
  }

  matches_matchers <- if (is.null(matches)) {
    numeric()
  } else {
    which(grepl(matches, map_chr(recog_db, "matches")))
  }

  matchers <- unique(c(protocol_matchers, matches_matchers))

  if (length(matchers) == 0) return(list())

  lapply(recog_db[matchers], function(.x) {

    preference <- .x$preference

    lapply(.x$fingerpints, function(.x) {

      res <- ore::ore_search(.x$compiled_pattern, source, simplify=TRUE)

      if (!is.null(res)) {

        grps <- as.vector(ore::groups(res))

        lapply(.x$params, function(.x) {
          value <- if (.x$position == 0) .x$value else grps[.x$position]
          as.list(set_names(value, .x$name))
        }) %>% unlist(recursive = FALSE) -> mat_out

        mat_out$preference <- preference
        mat_out$description <- .x$description
        mat_out$pattern <- .x$pattern
        mat_out$orig <- source

        mat_out

      }
    }) %>%
      discard(is.null) %>%
      discard(~length(.x) == 0)

  }) %>%
    discard(is.null) %>%
    discard(~length(.x) == 0) %>%
    unlist(recursive = FALSE) %>%
    bind_rows() -> out

  class(out) <- c("tbl_df", "tbl", "data.frame")

  out

}