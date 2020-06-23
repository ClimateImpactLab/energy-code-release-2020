#' ---
#' Purpose:  ${1: Load single projection data}
#' authors: ${2: Maya Norman and Tom Bearpark}
#' date:   ${3:`date +%Y-%m-%d`}
#'

library(dplyr)
library(purrr)
library(testit)
library(glue)
library(data.table)
library(rlist)
library(readr)
library(DescTools)
library(stringr)
library(benchmarkme)
library(parallel)
library(sys)
squish_function <- stringr::str_squish


# Outputted by singles.py (this function needs to get updated its not going to work with the current setup)
load.single <- function(single_input = "/shares/gcp/social/parameters/energy/extraction/", 
  rcp = "rcp85", 
  ssp = "SSP3", 
  price = NULL,
  iam = NULL, 
  clim_model = "ccsm4",
  model = "TINV_clim_income_spline", 
  adapt = "fulladapt", 
  geo_level = "", 
  clim_data = "GMFD", 
  grouping_test = "semi-parametric",
  proj_mode = "",
  yearlist = as.character(seq(1980,2100,1)), 
  spec = "OTHERIND_electricity",
  date = "719", 
  file.function = paste.median.file, 
  ...) {

  kwargs = list(...)
  args <- as.list(environment())
  args.kwargs = append(kwargs,args)
  testit::assert(is.null(kwargs$median_input))

  if (adapt == "fulladapt") {
    adapt_tit = ""
  }
  else {
    adapt_tit = paste0("-",adapt)
  }

  if (!is.null(price)) {
    price = paste0("-",price)
    testit::assert(type %in% list("-aggregated","-levels"))
  } else {
    price = ''
  }

  code.paths = do.call(get.code.paths, all.params)

  filename = paste0("single", geo_level, "_energy_",rcp,"_",clim_model,"_",iam,"_",ssp,"_",spec,"_FD_FGLS")
  single_file = do.call(file.function, c(kwargs,args))
  file = paste0(single_input,"/",single_file,"/",filename)
  impact.file = paste0(file,adapt_tit,price,proj_mode,".csv")
  print(paste0("Loading file: ", impact.file))

  # This calls a bash script, if the file we need doesn't exist, we call the bash script, and then produces it 
  # Want to incorporate the same thing into the load.median
  if (!file.exists(impact.file) & grepl("median",single_file)) {
    
    parameters = paste(model, grouping_test, ssp, iam, clim_model, rcp, proj_mode, price, sep = " ")
    
    print('Parameters:')
    print(parameters)
    
    cmd = paste0("bash ",code.paths$shell_path,"extract_single_from_mulit-model.sh ", parameters)
    print('Command:')
    print(cmd)
    
    print('Exctracting...')
    system(cmd)
  }

  print(single_file)

  impacts <- readr::read_csv(impact.file) %>%
    dplyr::select(region,year,value) %>%
    dplyr::filter(year %in% yearlist)
    
  #only subtract off histclim for impacts and not no adapt
  if (!(proj_mode %in% list("_deltamethod","_dm")) & adapt_tit != "-noadapt") {
    histclim <- readr::read_csv(paste0(file,"-histclim",price,".csv")) %>%
      dplyr::select(region,year,value) %>%
      dplyr::filter(year %in% yearlist)
    
    impacts <- dplyr::left_join(impacts, histclim, by=c("year","region")) %>%
      dplyr::mutate(value = value.x - value.y) %>%
      dplyr::select(region, year, value)
    
    print("Subtracted off histclim!")
  }
  impacts = impacts %>% dplyr::rename(mean = value)
  impacts <- assign.names(df = impacts, adapt = adapt, rcp = rcp, iam = iam, price = price, product = spec)
  return(impacts)
}
