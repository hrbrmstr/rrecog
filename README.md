
# rrecog

Pattern Recognition for Hosts, Services and Content

## Description

‘Rapid7’ developed a framework dubbed ‘Recog’
<https://github.com/rapid7/recog> to facilitate fingerprinting hosts,
services and content. The original program was written in ‘Ruby’. Tools
are provided to download and match fingerprints using R.

## What’s Inside The Tin

The following functions are implemented:

  - `download_fingerprints`: Download fingerprints from the Recog repo
  - `load_fingerprints`: Load a directory of fingerprints
  - `read_fingerprints_file`: Ingest Recog XML fingerprints from a file
    and precompile regular expressions
  - `recog_match`: Find fingerprint matches for a given source
  - `use_builtin_fingerprints`: Use built-in fingerprints

## Installation

``` r
devtools::install_github("hrbrmstr/rrecog")
```

## Usage

``` r
library(rrecog)

# current verison
packageVersion("rrecog")
```

    ## [1] '0.1.0'

### Use Real Data

``` r
library(httr)
library(tidyverse)
```

    ## ── Attaching packages ─────────────────────────────────────────────── tidyverse 1.2.1 ──

    ## ✔ ggplot2 3.0.0     ✔ purrr   0.2.5
    ## ✔ tibble  1.4.2     ✔ dplyr   0.7.6
    ## ✔ tidyr   0.8.0     ✔ stringr 1.3.0
    ## ✔ readr   1.1.1     ✔ forcats 0.3.0

    ## ── Conflicts ────────────────────────────────────────────────── tidyverse_conflicts() ──
    ## ✖ dplyr::filter() masks stats::filter()
    ## ✖ dplyr::lag()    masks stats::lag()

``` r
# using the internet as a data source is fraught with peril
safe_GET <- safely(httr::GET)

sprintf(
  fmt = "http://%s", 
  c(
    "r-project.org", "pypi.org", "www.mvnrepository.com", "spark.apache.org",
    "www.oracle.com", "www.microsoft.com", "www.apple.com", "feedly.com"
  )
) -> use_these

pb <- progress_estimated(length(use_these))
map(use_these, ~{
  pb$tick()$print()
  res <- safe_GET(.x, httr::timeout(2))
  if (is.null(res$result)) return(NULL)
  res$result$headers$server
}) %>% 
  compact() %>% 
  flatten_chr() -> server_headers

server_headers
```

    ## [1] "Apache/2.4.10 (Debian)" "nginx/1.13.9"           "nginx/1.10.1"           "Apache/2.4.18 (Ubuntu)"
    ## [5] "Oracle-HTTP-Server"     "Apache"                 "cloudflare"

``` r
recog_db <- use_builtin_fingerprints()
map_df(server_headers, ~recog_match(recog_db, .x, "http")) %>%
  glimpse() -> found
```

    ## Observations: 6
    ## Variables: 9
    ## $ service.vendor  <chr> "Apache", "nginx", "nginx", "Apache", "Apache", "Apache"
    ## $ service.product <chr> "HTTPD", "nginx", "nginx", "HTTPD", "HTTPD", "HTTPD"
    ## $ service.family  <chr> "Apache", "nginx", "nginx", "Apache", "Apache", "Apache"
    ## $ service.version <chr> "2.4.10", "1.13.9", "1.10.1", "2.4.18", NA, NA
    ## $ apache.info     <chr> "(Debian)", NA, NA, "(Ubuntu)", NA, NA
    ## $ preference      <dbl> 0.9, 0.9, 0.9, 0.9, 0.9, 0.9
    ## $ description     <chr> "Apache", "nginx with version info", "nginx with version info", "Apache", "Apache returning...
    ## $ pattern         <chr> "^Apache(?:-AdvancedExtranetServer)?(?:/([012][\\d.]*)\\s*(.*))?$", "^nginx/(\\S+)", "^ngin...
    ## $ orig            <chr> "Apache/2.4.10 (Debian)", "nginx/1.13.9", "nginx/1.10.1", "Apache/2.4.18 (Ubuntu)", "Apache...

``` r
select(found, orig, service.vendor, service.version, apache.info, description)
```

    ## # A tibble: 6 x 5
    ##   orig                   service.vendor service.version apache.info description                            
    ##   <chr>                  <chr>          <chr>           <chr>       <chr>                                  
    ## 1 Apache/2.4.10 (Debian) Apache         2.4.10          (Debian)    Apache                                 
    ## 2 nginx/1.13.9           nginx          1.13.9          <NA>        nginx with version info                
    ## 3 nginx/1.10.1           nginx          1.10.1          <NA>        nginx with version info                
    ## 4 Apache/2.4.18 (Ubuntu) Apache         2.4.18          (Ubuntu)    Apache                                 
    ## 5 Apache                 Apache         <NA>            <NA>        Apache returning no version information
    ## 6 Apache                 Apache         <NA>            <NA>        Apache
