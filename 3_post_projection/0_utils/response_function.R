############################################################################
# Energy specific codes to work with the yellow_purple_package.R functions
# Author: Maya Norman
# Last Modified: 11/15/19
#############################################################################

# currently only setup to run on TINV_clim... increase functionality for other models in the future!

library(DescTools)
library(stringr)
library(testit)
library(gdata)
library(readstata13)
library(dplyr)
library(glue)
library(stringr)
squish_function <- stringr::str_squish

# Part 1 -----------------------------------------------------------------------
# helper functions: get.config.name, get.income.cut, load.price, load.population
# execute small tasks for the functions in part 2, which return response functions
# either in kWh pc, $ 2005 USD pc or levels 
# get.config.name and get.income.cut could probably be replaced using functions 
# from ./load_projection ... so if you want to innovate i would look there first
# ------------------------------------------------------------------------------

#' Get name of config file
#' 
#' @param product type of fuel
#' @param model econometric model
#' @inheritParams
#' @return name of config file
#' @export
#' 

get.config.name <- function(product = 'electricity', model = 'TINV_clim', ...) {
  if(grepl("TINV_clim", model)) {
    return(paste0("energy-diagnostics-hddcddspline_OTHERIND_",product,".yml"))
  } else {
    stop(paste0("Cannot read in config file for this ",model))
  }
}

#' Retrive the gdp pc value which divides the two income groups
#' 
#' @param filepath path to config with income group (ie /path/to/config/filename.yml)
#' @param var a parameter name in the config who's assigned value you want to retrieve
#' @inheritParams
#' @return income group cut off
#' @export
#'

get.income.cut = function(filepath ='', var="loggdppc-delta", ...) {
  con = file(filepath, "r")
  line = squish_function(readLines(con))
  for (i in seq(line)){
    if (substr(line[i],1,DescTools::StrPos(line[i], ":", pos=1) - 1) == var) {
      value = substr(line[i],DescTools::StrPos(line[i], ":", pos=1) + 1, stringr::str_length(line[i]))
    }
  }
  close(con)
  #print(paste0("file: ",filepath, " inc cut: ", value))
  return(as.numeric(value))
}

#' Get the price of a fuel for a particular price scenario, in a particular impact region in a given year
#' 
#' @param product fuel type
#' @param price_scen price scenario for which you are querying a price for
#' @param price.data.dir path to where the price data is stored
#' @param region impact region you want a price for
#' @param year year you want a price for
#' @inheritParams 
#' @return price for a given product in a given impact region in a given year
#' @export
#'

load.price <- function(product = 'electricity', price_scen = 'price014', price.data.dir = '/shares/gcp/social/baselines/energy/', region = 'ARE.3', year = 2010, ...) {
  
  price.file.names = list.files(path = price.data.dir, recursive = FALSE)
  
  yr = year
  
  if (startsWith(price_scen, "price")) {
    gr = substr(price_scen,6, nchar(price_scen))
    price.file = price.file.names[startsWith(price.file.names, paste0('IEA_Price_FIN_Clean_gr',gr))]
    testit::assert(length(price.file) == 1)
  } else {
    price.file = price.file.names[startsWith(price.file.names, paste(price_scen))]
  }

  price.df <- readstata13::read.dta13(paste0(price.data.dir, price.file)) 
  price.df <- dplyr::filter(price.df, year == yr & country == substr(region,1,3))
  
  ##need to add safety here if peakprice isn't last
  var.index = names(price.df)[grep(product, names(price.df))][1]
  price = price.df[,var.index]

  if (grepl('peak',price_scen) & product == "electricity") {
    price = price.df[,names(price.df)[grep('peak', names(price.df))]]
  }

  return(price)

}

#' Get population data for a given impact region in a given year
#' 
#' @param covars covariates data frame with a variable named population_imputed (note the imputation method may not be exactly what James does)
#' @param impact region querying pop data for
#' @param year querying pop data
#' @inheritParams 
#' @return population data for a given impact region in a given year 
#' @export
#'

load.population <- function(covars = NULL, region = 'ARE.3', year = 2010, ...) {
  covars = covars[(covars['region']==region) & (covars['year']== year),]
  pop = covars['population_imputed'][[1]] 
  testit::assert(length(pop) == 1)
  return(pop)
}

# Part 1.5 ----------------------------------------------------------------------------------------
# energy response curve function -- constructs energy response function

#' Get the energy response curve in kWh pc
#' list as the sector.response.function parameter if you want impacts per capita

get.curve.energy <- function(product = 'electricity', model = "TINV_clim", csvv.name.glue = NULL, cdd = NULL, hdd = NULL, loggdppc = NULL, TT = seq(-23, 45,.5), ...) {

  kwargs = list(...)

  testit::assert(all(grepl("TINV_clim", model)))

  #create above and below 20 indicator
  above20 <-ifelse(TT>=20, 1, 0)
  below20 <-ifelse(TT<20, 1, 0)

  #get info about income cutoff
  income.cut <- get.income.cut(paste0(config.path,get.config.name(product = product, model = model)))
  incgroup = ifelse(loggdppc > income.cut, 'incbin9', 'incbin1')
  loggdppc.shifted = loggdppc - income.cut

  csvv.name = glue::glue(csvv.name.glue)
  csvv = read.csvv(paste0(csvv.dir,csvv.name)) 
  
  beta1 <- get.gamma(csvv, prednames='tas', covarnames=incgroup) 
  beta2 <- get.gamma(csvv, prednames='tas2', covarnames=incgroup) 
  
  gamma1 <- get.gamma(csvv, prednames='tas-cdd-20', covarnames=paste0("climtas-cdd-20*",incgroup)) * cdd 
  gamma2 <- get.gamma(csvv, prednames='tas-cdd-20-poly-2', covarnames=paste0("climtas-cdd-20*",incgroup)) * cdd 
  
  lambda1 <- get.gamma(csvv, prednames='tas-hdd-20', covarnames=paste0("climtas-hdd-20*",incgroup)) * hdd 
  lambda2 <- get.gamma(csvv, prednames='tas-hdd-20-poly-2', covarnames=paste0("climtas-hdd-20*",incgroup)) * hdd 

  beta <- beta1 * (TT-20) + beta2 * (TT^2 - 400)
  gamma <- gamma1 * (TT - 20) * above20 + gamma2 * (TT^2 - 400) * above20
  lambda <- lambda1 * (20 - TT) * below20 + lambda2 * (400 - TT^2) * below20

  response <- beta + gamma + lambda

  if (model == "TINV_clim_ui") {
    eta1 <- get.gamma(csvv, prednames='tas', covarnames=paste0("loggdppc*",incgroup)) * loggdppc 
    eta2 <- get.gamma(csvv, prednames='tas2', covarnames=paste0("loggdppc*",incgroup)) * loggdppc 
    eta <- eta1 * (TT-20) + eta2 * (TT^2 - 400)
    response <- response + eta
  } else if (model == "TINV_clim") {
    eta1 <- get.gamma(csvv, prednames='tas', covarnames=paste0("loggdppc-shifted*",incgroup)) * loggdppc.shifted
    eta2 <- get.gamma(csvv, prednames='tas2', covarnames=paste0("loggdppc-shifted*",incgroup)) * loggdppc.shifted 
    eta <- eta1 * (TT-20) + eta2 * (TT^2 - 400)
    response <- response + eta
  }

  return(response)
}

# Part 2 ------------------------------------------------------------------------------------------
# worker functions: get.energy.response -- constructs the energy response data array to be returned to the yellow purple package 
# wrapper function: get.energy.sum.response -- calls ger.energy.response for both products and adds the response together (useful for damage output)
# both of these functions can be input as func in the yellow purple package
# -------------------------------------------------------------------------------------------------

#' Get energy response function and return in a data array
#' 
#' This function relies on the sector specific response function fxn to know/understand exactly what get.response is passing to it. Specifically, 
#' this function passes a csvv, a temperature vector (TT), and covariates (cov.list) to the sector specific response function. 
#' 
#' Using the covar.names and list.names paramters, the user can ensure the covariates data object contains the neccessary covariates. covar.names specifies
#' the desired covariates in the covars data object. If the user wishes for the covariate names passed to the sector specific fxn to be different from covar.names, the user can use list.names to specify 
#' different covariates names. 
#' 
#' @param region impact region id
#' @param year year to evaluate response at 
#' @param base_year covariate base year (ie year noadapt covariates should be from)
#' @param adapt adaptation scenario to evaluate response function under
#' @param csvv csvv object from read.csvv function   
#' @param covars covariates object from load.covariates object
#' @param covar.names list of covariates needed from covars object
#' @param list.names list of covariates called from sector.response.function (might be cool to implant this info in sector specific function so dont also need to include in parameters) 
#' @param units units of response curve. options include: 'impactpc', 'damagepc', 'damage'
#' @inheritParams
#' @return data array with response at each temperature, other dimensions are just for labeling (only one dimension)
#' @export

get.energy.response <- function(units = 'impactpc', adapt = 'full', csvv = '', covars = data.frame(), covar.names = list(), list.names = NULL, model = NULL, product = NULL, year = 2099, region = 'ARE.3', TT=seq(-23, 45,.5), base_year = 2010, ...) {

  testit::assert(base_year != year)
  years = c(base_year,year)

  if (!is.null(list.names)) {
    testit::assert(length(list.names) == length(covar.names))
  }
  
  print('Fetching covariates...')
  cov.list = get.covariates(covars = covars, region = region, years = years, covar.names = covar.names, list.names = list.names, ...)

  if (!is.null(list.names)) {
    covar.names = list.names
  }

  for (ii in seq(1, length(covar.names))) {
    if (length(cov.list[[covar.names[[ii]]]]) != length(years)) {
      print(region)
      stop("covariates are incorrect size (years dimension)")
    }
  }

  if (length(cov.list) != length(covar.names) + 1) {
    print(region)
    stop("covariates are incorrect size (covariates dimension)")
  }

  if (sum(sapply(c('no','full','income','clim'), grepl, adapt)) != 1) {
    print(adapt)
    stop("Please specify one and only one adaptation scenario")
  }

  testit::assert(cov.list$years[1] == base_year & cov.list$years[2] == year)

  # this whole situation could probably be greatly simplified sorry its a mess
  if (sapply(c('full'), grepl, adapt)) {
    inc.pos <- 2
    clim.pos <- 2
    year_dim = year
  } else if (sapply(c('income'), grepl, adapt)){
    inc.pos <- 2
    clim.pos <- 1
    year_dim = paste0(toString(year),'_IA')
  } else if (sapply(c('no'), grepl, adapt)) {
    inc.pos <- 1
    clim.pos <- 1
    year_dim = paste0(toString(base_year),'_NA')
  } else {
    stop("Adaptation type needs to be incorporated into the code.")
  }

  cdd <- cov.list$climtascdd20[clim.pos] 
  hdd <- cov.list$climtashdd20[clim.pos]
  loggdppc <- cov.list$loggdppc[inc.pos] 

  kwargs <- c(as.list(environment()), list(...))

  print('Fetching response function...')
  response.curve = do.call(get.curve.energy, kwargs)

  if (grepl('damage', units)) {
    print('Making damages out of impacts...')
    price = do.call(load.price, kwargs)
    response.curve = response.curve * price
  }
  
  if (!(grepl('pc', units))) {
    print('Making levels out of pc...')
    population = do.call(load.population, kwargs)
    response.curve = response.curve * population
  }
  
  print('Returning response curve array...')
  return(array(response.curve,dim=c(length(response.curve),1,1), dimnames=list(paste(TT), year_dim, region)))

}

get.energy.sum.response <- function(products = c('electricity', 'other_energy'), ...) {
  kwargs = list(...)
  response.arrays = mapply(FUN=get.energy.response, product=products, MoreArgs=kwargs, SIMPLIFY=FALSE)
  response = response.arrays$electricity + response.arrays$other_energy
  return(response)
}



