#' Ingest Recog XML fingerprints from a file and precompile regular expressions
#'
#' @md
#' @param path path to a Recog XML fingerprints file
#' @return a `recog_fingerprints` object which is a list containing `recog_fingerprint` elements
#' @export
#' @examples
#' read_fingerprints_file(
#'   system.file("fingerprints", "http_servers.xml.gz", package="rrecog")
#' )
read_fingerprints_file <- function(path) {

  path <- path.expand(path)

  root <- xml2::read_xml(path)

  protocol <- xml2::xml_attr(root, "protocol") %||% NA_character_
  matches <- xml2::xml_attr(root, "matches") %||% NA_character_
  database_type <- xml2::xml_attr(root, "database_type") %||% NA_character_
  preference_value <- as.numeric(xml2::xml_attr(root, "preference") %||% "0")
  if (is.na(preference_value)) preference_value <- 0

  xml2::xml_find_all(root, "fingerprint") %>%
    map(function(fingerprint) {

      pattern <- xml2::xml_attr(fingerprint, "pattern")

      regex_flags <- xml2::xml_attr(fingerprint, "flags")

      options <- ""
      if (!is.na(regex_flags)) {
        if (grepl("REG_DOT_NEWLINE", regex_flags)) paste0(c(options, "m"), collapse="")
        if (grepl("REG_ICASE", regex_flags)) paste0(c(options, "i"), collapse="")
      }

      compiled_pattern <- ore::ore(pattern, options)

      xml2::xml_find_first(fingerprint, "description") %>%
        xml2::xml_text() %>%
        strsplit("\n") %>%
        unlist() %>%
        trimws() %>%
        paste0(collapse="\n") %>%
        trimws() -> description

      xml2::xml_find_all(fingerprint, "param") %>%
        map(function(parameter) {
          position <- as.integer(xml2::xml_attr(parameter, "pos"))
          name <- xml2::xml_attr(parameter, "name")
          value <- if (position == 0) xml2::xml_attr(parameter, "value") else NULL
          list(position = position, name = name, value = value)
        }) -> params

      list(
        pattern = pattern,
        compiled_pattern = compiled_pattern,
        regex_flags = regex_flags,
        description = description,
        params = params
      ) -> out

      class(out) <- c("recog_fingerprint", "list")

      out

    }) -> fingerprint_list

  list(
    protocol = protocol,
    matches = matches,
    database_type = database_type,
    preference_value = preference_value,
    fingerpints = fingerprint_list
  ) -> out

  class(out) <- c("recog_fingerprints", "list")

  out

}

#' Print fingerprints
#' @rdname fingerprint_printers
#' @param x object
#' @param ... unused
#' @keywords internal
#' @export
print.recog_fingerprints <- function(x, ...) {
  cat(
    "<Recog fingerprints>\n",
    if (!is.na(x$protocol)) sprintf("      Protocol: %s", x$protocol) else "",
    if (!is.na(x$matches)) sprintf("\n       Matches: %s", x$matches) else "",
    if (!is.na(x$database_type)) sprintf("\n Database Type: %s", x$database_type) else "",
    "\n    Preference: ", x$preference,
    "\n# Fingerprints: ", length(x$fingerpints),
    sep=""
  )
}

#' Print a fingerprint
#' @rdname fingerprint_printers
#' @param x object
#' @param ... unused
#' @keywords internal
#' @export
print.recog_fingerprint <- function(x, ...) {
  cat(
    "<Recog fingerprint>\n",
    "     Pattern: ", x$pattern,
    "\n Regex flags: ", x$regex_flags,
    "\n Description: ", x$regex_flags,
    "\n    Extracts: ", paste0(sapply(x$params, "name"), collapse=", "),
    sep=""
  )
}
