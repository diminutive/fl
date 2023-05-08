
<!-- README.md is generated from README.Rmd. Please edit that file -->

# fl

<!-- badges: start -->
<!-- badges: end -->

The goal of fl is to …

## Installation

You can install the development version of fl like so:

``` r
# FILL THIS IN! HOW CAN PEOPLE INSTALL YOUR DEV PACKAGE?
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(fl)
files <- oisst_daily_sst_files(seq(as.Date("1992-03-21"), by = "1 month", length.out = 12L * 580))


## we can get a mean
ext <- c(120, 250, -70, -30)
dm <- c(60, 30)
#mn <- vapour::gdal_raster_data(files$datasource, target_dim = dm, target_ext = ext)
## or vectorize over sources
#bands <- lapply(files$datasource, vapour::gdal_raster_data, target_dim = dm, target_ext = ext)

library(furrr)
options(parallelly.fork.enable = TRUE, future.rng.onMisuse = "ignore")
plan(multicore)
func <- function(.x) vapour::gdal_raster_dsn(.x, target_dim = dm, target_ext = ext, resample = "average")[[1]]

## or write to file
system.time({
flist <- future_map_chr(files$datasource, func) 
})
plan(sequential)
```
