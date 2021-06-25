#' ---
#' Purpose:  ${1: Query data from Medain Run}
#' authors: ${2: Maya Norman and Tom Bearpark}
#' date:   ${3:`date +%Y-%m-%d`}
#' 
#' Functions: 
#'  load.median.check.params - Check data query parameters are valid (probably still a work in progress)
#'  load.median - load queried data frame
#'

# to dos:
# filter to region in load.median
# change global = NA to global = ""
# delete iam controls for values extraction from the system

library(testit)
library(data.table)
library(dplyr)
library(rlist)
library(readr)
library(haven)


#' Check data query parameters are valid (probably still a work in progress)
#' 
#' @param proj_mode type of projection (like delta method or point estimate)
#' @param uncertainty amount of uncertainty reflected in data
#' @param region region for which querying data
#' @param regions multiple regions for which querying data
#' @param rcp rcp scenario
#' @param iam iam scenario
#' @param price_scen dollarized damages price scenario
#' @param ssp ssp scenario
#' @param spec type of projection (ie fuel type or crop)
#' @param sector sector querying data for
#' @param sector dollar convert tells you whether to convert to 2019 dollars
#' @inheritParams
#' @export
#' 

load.median.check.params <- function(proj_mode = '', dollar_convert=NULL,
  uncertainty = NULL, region = NULL, regions = NULL, rcp = NULL, iam = NULL, ssp = 'SSP3', spec = NULL, 
  sector = 'energy', price_scen = NULL, geo_level, ...) {

  print(list(...))

  # both proj_mode are a part of the full uncertainty configs, thus the code and configs are set up such that
  testit::assert(!(proj_mode == '_dm' && uncertainty == 'full')) 
  
  if (uncertainty == 'values') {    
    # testit::assert(!is.null(region))
    testit::assert(is.null(rcp))
    testit::assert(is.null(iam))

  } else if (uncertainty == 'full') {
    testit::assert(!(is.null(region) && is.null(regions) && geo_level == "aggregated")) 
    # we either extract a certain set of regions, or extract all regions from levels file only
    # because there's a bug with extracted all regions from the aggregated files 
    # which james is fixing here https://github.com/jrising/prospectus-tools/issues/41
    # update: james has changed the code to ignore those regions
    # those are all small regions with no population data
    testit::assert(!is.null(ssp)) # due to memory constraints
    testit::assert(!is.null(rcp)) # rcp should only be null for values (possibly this might not hold when OTHERIND_total_energy gets integrated)

  } else if (uncertainty == 'climate') {

    testit::assert(proj_mode != '_dm')
    testit::assert(!is.null(rcp)) # rcp should only be null for values (possibly this might not hold when OTHERIND_total_energy gets integrated)

  }

  # only combine impacts for dollarized values
  if (is.null(price_scen) & sector == 'energy') {
    testit::assert(spec != "OTHERIND_total_energy")
  }

  # all output is ssp specific 
  testit::assert(!is.null(ssp))

}


#' Load median data frame
#' 
#' @param yearlist list of years wanted in queried data
#' @param uncertainty amount of uncertainty reflected in data
#' @param region region getting queried
#' @inheritParams
#' @return queried data
#' @export
#' 

get_regions_string = function(regions) {
    s = paste0("[", paste(regions, collapse=','), "]")
    return(s)
}

load.median <- function(yearlist = as.character(seq(1980,2100,1)), 
  dollar_convert = NULL, uncertainty = NULL, region = NULL, regions = NULL, proj_mode, regenerate = FALSE, ...) {

  kwargs = list(...)
  if (!is.null(regions)) {
    regions = get_regions_string(regions)
  }
  testit::assert(uncertainty != 'single')
  kwargs = rlist::list.append(kwargs, yearlist = yearlist, uncertainty = uncertainty, region = region, regions = regions, proj_mode=proj_mode)

  # convert the list to a string so that it can be passed to the shell script
  # browser()
  

  print('Checking the parametres make sense...')
  do.call(load.median.check.params, kwargs)

  print('Fetching paths...')
  paths = do.call(get.paths, kwargs)

  # If the file we want doesn't exit - produce it using quantiles.py on the relevant netcdf! 
  # note: please feel free to revise check.memory() function if it is currently too cautious


  if (file.exists(paths$file) && regenerate) {
    #Delete file if it exists
    file.remove(paths$file)
  }

  if (!file.exists(paths$file)) {
    print(paths$file)
    print('File does not already exist or we would like to regenerate, so we are extracting...')
    kwargs = rlist::list.append(kwargs, paths = paths)
    do.call(extract, kwargs)
  }  

  # Let's load the file!
  print(paste0("Loading file: ", paths$file))
  # browser()
  
  df <-readr::read_csv(paths$file) %>% dplyr::filter(year %in% yearlist)
  # browser()

  # browser()
  print('Adding data identifiers to data frame...')
  print(colnames(df))
  # browser()
  kwargs = rlist::list.append(kwargs, df = as.data.frame(df))
  df <- do.call(assign.names, kwargs)
  print('Data frame column names:')
  print(colnames(df))

  print('Changing projection mode column name to something that makes sense...')
  
  if (uncertainty != 'full') {
    df$proj_mode[df$proj_mode == ""] <- "point-estimate"
    df$proj_mode[df$proj_mode == "_dm"] <- 'variance'
  } else {
    df$proj_mode <- NULL
  }

  # if ('region' %in% colnames(df) & !is.null(region)) { 
  #   print('Filtering data frame to region queried...')
  #   df$region[is.na(df$region)] <- ""
  #   rgn = ifelse(region == "global", "", region)
  #   df = df %>% dplyr::filter(region == rgn)
  # }

  # if (!is.null(regions_list) & (! ("global" %in% regions_list)) { 
  #   print('Filtering data frame to regions queried...')
  #   df = df %>% dplyr::filter(region %in% regions_list)
  # }

  if (!is.null(dollar_convert)) { 
    # testit::assert(!is.null(price_scen))
    print(paste0('converting to 2019 USD'))
    df <- convert.to.2019(df=df, proj_mode = proj_mode)
  }
  print("done load_median")
  
  return(df)
}
