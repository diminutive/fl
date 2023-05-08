

#' an experiment with raadtools sst
#'
#' date in put is processed by raad.times
#' @param date the dates you want
#'
#' @return files, data frame with columns date, datasource
#' @export
#' @importFrom stringr str_replace
#' @importFrom raadfiles oisst_daily_files
#' @importFrom raad.times raad_process_files
#' @examples
ghrsst_daily_sst_files <- function(date) {
  files <- raadfiles::ghrsst_daily_files()
  if (!missing(date)) {
    files <- raad.times::raad_process_files(date, files, "daily")
  }
  files$datasource <- sprintf("NETCDF:\"%s\":analysed_sst", files$fullname)
  ## this is yucky
  vrt <- vapour:::vapour_vrt(files$datasource[1], projection = "OGC:CRS84", nomd = TRUE)

  files$datasource <- stringr::str_replace(vrt, files$datasource[1L], files$datasource)
  files[c("date", "datasource", "fullname")]
}

