
#' ---
#' Purpose:  ${1: Clean queried data}
#' authors: ${2: Maya Norman and Tom Bearpark}
#' date:   ${3:`date +%Y-%m-%d`}
#' 
#' Functions: 
#'  assign.names - based on data query and data frame add more identifying names to df
#'  convert.to.2019 - based on whether we want to 2005 or 2019 dollars, converts (both for means and variances)
#'

#' Based on data query and data frame add more identifying names to df
#' 	criteria for adding a column with information about data
#' 		* if argument type not already column in data frame 
#'		* if argument not null
#' 
#' @param df data frame adding columns to or converting dollars of 
#' @param adapt_scen adaptation scenario
#' @param rcp rcp scenario
#' @param iam iam scenario
#' @param ssp ssp scenario
#' @param price_scen dollarized damages price scenario
#' @param proj_mode type of projection (like delta method or point estimate)
#' @inheritParams
#' @return original data frame with some additional columns
#' @export
#' 

assign.names <- function(df = NULL, adapt_scen = 'fulladapt', 
  rcp = 'rcp85', ssp = 'SSP3', iam = NULL, price_scen = NULL, spec = NULL, proj_mode = '', ...) {

  args = as.list(environment())
  args$df = NULL

  for (arg in names(args)) {

    # only create new column if column variable does not already exist in the dataset
    # and if arg is not null
    
    if (!(arg %in% colnames(df)) & !is.null(arg)) {
      #creating list here but want to create a vector
      df[[arg]] <- args[[arg]]
    }
  }

  return(df)
}

convert.to.2019 <- function(df, proj_mode) {

  # Value taken from mortality paper conversion - converts from 2005 to 2019 dollars 
  conversion_value = 1.273526

  # If we have variance dataframe, need to convert by multiplying by the square 

  for(var in names(df)) {
      
    if(var %in% c("mean", "q50", "q5", "q95", "q17", "q83", "q10", "q90", "q75", "q25", "value")) {

      print(paste0('converting variable ', var, ' to billions of 2019 dollars'))

      if(proj_mode ==''){
        df[[var]]  = df[[var]] * conversion_value / 1000000000
      }
      if(proj_mode == '_dm') {
        df[[var]]  = df[[var]] * conversion_value^2 / 1000000000^2
      }
    }
  }

  return(df)
}