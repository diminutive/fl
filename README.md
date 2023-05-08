
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

The idea is that we obtain data sources for gdal that don’t require any
logic in R functions.

In this case, the OISST files are augmented as VRT. We need

- declare the driver and the subdataset (we get NETCDF:<filename>:sst in
  this case)
- fill in the missing crs metadata (we need a full VRT expansion)

In GDAL 3.7.0 we don’t need vrt expansion, we would use

    vrt://NETCDF:<filename>:sst?a_srs=OGC:CRS83

but for now, need some tricks here to keep the VRT generation fast (by
templating) and small-ish (by removing metadata).

Then we have data source strings ready for the warper! Here we get a
source for every month, and write to a GeoTIFF for each, using average
resampling (the data are aggregated to 2.5 cells from 0.25). We can
cross the dateline or the prime meridian, it doens’t matter because the
warper sorts that out.

``` r
library(fl)
#> global option 'raadfiles.data.roots' set:
#> '/rdsi/PRIVATE/raad/data               
#>  /rdsi/PRIVATE/raad/data_local         
#>  /rdsi/PRIVATE/raad/data_staging       
#>  /rdsi/PRIVATE/raad/data_deprecated    
#>  /rdsi/PUBLIC/raad/data                '
#> Uploading raad file cache as at 2023-05-08 20:28:59 (1211638 files listed)
files <- oisst_daily_sst_files(seq(as.Date("1992-03-21"), by = "1 month", length.out = 12L * 580))
#> Warning in raad_dedupe(findex, qdate, removeDupes = TRUE): duplicated dates
#> will be dropped
#> Warning in raad_match_files(date, fdate[findex], findex, daytest =
#> switch(timeres, : 1 input dates have no corresponding data file within 1.500000
#> days of available files
#files <- oisst_daily_sst_files()


## we can get a mean
ext <- c(-60, 50, -70, -30)
dm <- c(60, 30)
#mn <- vapour::gdal_raster_data(files$datasource, target_dim = dm, target_ext = ext)
## or vectorize over sources
#bands <- lapply(files$datasource, vapour::gdal_raster_data, target_dim = dm, target_ext = ext)

library(furrr)
#> Loading required package: future
options(parallelly.fork.enable = TRUE, future.rng.onMisuse = "ignore")
plan(multicore)
func <- function(.x) vapour::gdal_raster_dsn(.x, target_dim = dm, target_ext = ext, resample = "average")[[1]]

## or write to file
system.time({
flist <- future_map_chr(files$datasource, func) 
})
#>    user  system elapsed 
#>  26.054   7.395   4.499
plan(sequential)

str(basename(flist))
#>  chr [1:374] "file9649a5dd944ab.tif" "file9649a5d499332.tif" ...
# chr [1:374] "file90aa0142157a4.tif" "file90aa0453395b2.tif" "file90aa04bd28a87.tif" "file90aa05fb4b65d.tif" ...
```

On 32 cores that takes 27 seconds, 374 input files.

For the entire series, 15216 files it takes 162 seconds.

Just to see what we get.

``` r
library(terra)
#> terra 1.7.23
r <- rast(flist[seq(1, length(flist), length.out = 374)])
mn <- mean(r)
plot(mn - rast(sample(flist, 1)))
```

<img src="man/figures/README-terra-1.png" width="100%" />

The data natively are in 0,360 - we can target any grid we want from
this improved source collection.

How long does it take to process to southern hemisphere 10000m.

``` r
library(fl)
files <- oisst_daily_sst_files(seq(as.Date("1992-03-21"), by = "1 month", length.out = 12L * 580))
#> Warning in raad_dedupe(findex, qdate, removeDupes = TRUE): duplicated dates
#> will be dropped
#> Warning in raad_match_files(date, fdate[findex], findex, daytest =
#> switch(timeres, : 1 input dates have no corresponding data file within 1.500000
#> days of available files
#files <- oisst_daily_sst_files()


## we can get a mean
ext <- c(-1, 1, -1, 1) * 6378137 * pi/1.2
res <- rep(25000, 2L)
#mn <- vapour::gdal_raster_data(files$datasource, target_dim = dm, target_ext = ext)
## or vectorize over sources
#bands <- lapply(files$datasource, vapour::gdal_raster_data, target_dim = dm, target_ext = ext)


library(furrr)
options(parallelly.fork.enable = TRUE, future.rng.onMisuse = "ignore")
plan(multicore)
options(warn = 1)
func <- function(.x) vapour::gdal_raster_dsn(.x, target_res = res, target_ext = ext, target_crs = "EPSG:3031", resample = "average")[[1]]

## or write to file
system.time({
flist <- future_map_chr(files$datasource, func) 
})

#>     user   system  elapsed 
#> 1280.388   25.012   44.706
plan(sequential)

str(basename(flist))
#>  chr [1:374] "file9663f688f1a6e.tif" "file9663f88e4fd7.tif" ...
# chr [1:374] "file90aa0142157a4.tif" "file90aa0453395b2.tif" "file90aa04bd28a87.tif" "file90aa05fb4b65d.tif" ...

terra::rast(flist[1])
#> class       : SpatRaster 
#> dimensions  : 1336, 1336, 1  (nrow, ncol, nlyr)
#> resolution  : 25000, 25000  (x, y)
#> extent      : -16697924, 16702076, -16702076, 16697924  (xmin, xmax, ymin, ymax)
#> coord. ref. : WGS 84 / Antarctic Polar Stereographic (EPSG:3031) 
#> source      : file9663f688f1a6e.tif 
#> name        : file9663f688f1a6e
terra::plot(terra::rast(flist[1]))
```

<img src="man/figures/README-laea-1.png" width="100%" />
