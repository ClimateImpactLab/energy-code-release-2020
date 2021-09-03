# Prepare code release data, and save it on Dropbox...
# Note - all maps in the paper are for 2099, SSP3, rcp85, high, so these are hard coded 
# This code should be run from inside the risingverse-py27 conda environment 
# Extract not for integration, but integration scenario

rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)

REPO <- "/home/liruixue/repos"
db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
				'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

# Note on naming convention: 
# Time series naming convention:
# {model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scen}

# Map data naming convention:
# {model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scen}-{year}-map

###############################################
# Figure 3
######################done#########################

# 3A  
# Need GDP data, at IR level, damages in 2099, and values csvs for each featured IR
# GDP data: 

# Get impacts data
args = list(
      conda_env = "risingverse-py27",
      proj_mode = '', # '' and _dm are the two options
      region = NULL, # needs to be specified for 
      rcp = "rcp85", 
      ssp = "SSP3", 
      price_scen = "integration", # have this as NULL, "integration", "MERGEETL", ...
      unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
      uncertainty = "climate", # full, climate, values
      geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
      iam = "high", 
      model = "TINV_clim", 
      adapt_scen = "fulladapt", 
      clim_data = "GMFD", 
      dollar_convert = "yes",
      yearlist = 2099,  
      spec = "OTHERIND_total_energy",
      grouping_test = "semi-parametric",
      regenerate = TRUE)

impacts = do.call(load.median, args) %>%
	dplyr::select(region, mean, q5, q95) %>%
	rename(damage = mean)

write_csv(impacts, 
		paste0(output, '/projection_system_outputs/mapping_data/', 
			'main_model-total_energy-SSP3-rcp85-high-fulladapt-integration-2099-map.csv'))


#####################done######################
# Get values csvs for the kernel density plots

IR_list = c("USA.14.608", "SWE.15", "CHN.2.18.78", "CHN.6.46.280", "IND.21.317.1249", "BRA.25.5235.9888")
IR_list_names = c("Chicago", "Stockholm", "Beijing", "Guangzhou", "Mumbai", "Sao Paulo")

get.dfs <- function(env, IR, ssp, iam, rcp, price = NULL, unit, year, fuel) {
  
 
  geo_level = ifelse(IR == "global", "aggregated", "levels")
  price_scen = price

  if(is.null(price)){dollar_convert=NULL} else{dollar_convert = "yes"}

  mean_df <- load.median(
    conda_env = env,
    proj_mode = '', # '' and _dm are the two options
    region = IR, # needs to be specified for 
    rcp = NULL, 
    ssp = ssp, 
    price_scen = price, # have this as NULL, "integration", "MERGEETL", ...
    unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
    uncertainty = "values", # full, climate, values
    geo_level = geo_level, # aggregated (ir agglomerations) or 'levels' (single irs)
    iam = NULL, 
    model = "TINV_clim", 
    adapt_scen = "fulladapt", 
    clim_data = "GMFD", 
    yearlist = year,  
    spec = fuel,
    regenerate = TRUE,
    dollar_convert = dollar_convert, 
    grouping_test = "semi-parametric" ) %>%
    dplyr::filter(!! iam==`iam`, !! rcp==`rcp`) %>%
    dplyr::select(gcm, value, weight) %>%
    rename(mean=value)

  var_df <- load.median(
    conda_env = env,
    proj_mode = '_dm', # '' and _dm are the two options
    region = IR, # needs to be specified for 
    rcp = NULL, 
    ssp = ssp, 
    price_scen = price, # have this as NULL, "integration", "MERGEETL", ...
    unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
    uncertainty = "values", # full, climate, values
    geo_level = geo_level, # aggregated (ir agglomerations) or 'levels' (single irs)
    iam = NULL, 
    model = "TINV_clim", 
    adapt_scen = "fulladapt", 
    clim_data = "GMFD", 
    yearlist = year,  
    spec = fuel,
    regenerate = FALSE,
    dollar_convert = dollar_convert, 
    grouping_test = "semi-parametric")  %>%
    dplyr::filter(!! iam==`iam`, !!rcp==`rcp`) %>%
    dplyr::select(gcm, value, weight) %>%
    rename(variance=value) %>%
    mutate(sd=sqrt(variance))

  df_joined = left_join(mean_df, var_df) 

  if(rcp=="rcp85"){
    assert(dim(df_joined)==c(33, 5))
  }
  
  return(df_joined)
}


get_IR_values_csv = function(IR) {
	df_joined <- get.dfs(env="risingverse-py27", IR=IR, 
					ssp="SSP3", price="integration", unit="damage", 
					year=2099, fuel="OTHERIND_total_energy", rcp="rcp85", iam="high") %>%
				dplyr::mutate(region = !!IR)
	return(df_joined)
}

df = lapply(IR_list, get_IR_values_csv) %>% 
	bind_rows() %>% as.data.frame()

write_csv(df, paste0(output, '/projection_system_outputs/IR_GCM_level_impacts/',
	'gcm_damages-main_model-total_energy-SSP3-rcp85-high-fulladapt-integration-2099-select_IRs.csv'))


######################done#########################
 # 2 Load the impacts data for figure 3 time series as percent GDP

args = list(
    conda_env = "risingverse-py27",
    # proj_mode = '', # '' and _dm are the two options
    region = "global", # needs to be specified for 
    # rcp = "rcp85", 
    ssp = "SSP3", 
    price_scen = "integration", # have this as NULL, "integration", "MERGEETL", ...
    unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
    uncertainty = "full", # full, climate, values
    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
    iam = "high", 
    model = "TINV_clim", 
    adapt_scen = "fulladapt", 
    clim_data = "GMFD", 
    yearlist = as.character(seq(2010,2100,1)),  
    spec = "OTHERIND_total_energy",
    dollar_convert = "yes",
    grouping_test = "semi-parametric")

get_df_ts_main_model_total_energy = function(rcp, args) {
	plot_df = do.call(load.median, c(args, rcp = rcp, proj_mode = '')) %>% 
	                        dplyr::select(year, mean, q5, q95, rcp) %>%
	                        mutate(rcp = !!rcp)
	write_csv(plot_df, 
		paste0(output, '/projection_system_outputs/time_series_data/', 
			'main_model-total_energy-SSP3-',rcp, '-high-fulladapt-integration.csv'))
}

rcps = c("rcp45", "rcp85")
lapply(rcps, get_df_ts_main_model_total_energy, args = args) 


# incadapt version for producing timeseries for referee comments
args = list(
    conda_env = "risingverse-py27",
    # proj_mode = '', # '' and _dm are the two options
    region = "global", # needs to be specified for 
    # rcp = "rcp85", 
    ssp = "SSP3", 
    price_scen = "integration", # have this as NULL, "integration", "MERGEETL", ...
    unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
    uncertainty = "full", # full, climate, values
    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
    iam = "high", 
    model = "TINV_clim", 
    adapt_scen = "incadapt", 
    clim_data = "GMFD", 
    yearlist = as.character(seq(2010,2100,1)),  
    spec = "OTHERIND_total_energy",
    dollar_convert = "yes",
    grouping_test = "semi-parametric")

get_df_ts_main_model_total_energy = function(rcp, args) {
  plot_df = do.call(load.median, c(args, rcp = rcp, proj_mode = '')) %>% 
                          dplyr::select(year, mean, q5, q95, rcp) %>%
                          mutate(rcp = !!rcp)
  write_csv(plot_df, 
    paste0(output, '/projection_system_outputs/time_series_data/', 
      'main_model-total_energy-SSP3-',rcp, '-high-incadapt-integration.csv'))
}

rcps = c("rcp85")
lapply(rcps, get_df_ts_main_model_total_energy, args = args) 




