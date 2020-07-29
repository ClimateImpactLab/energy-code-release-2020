# Prepare code release data, and save it on Dropbox...
# Note - all maps in the paper are for 2099, SSP3, rcp85, high, so these are hard coded 
# This code should be run from inside the risingverse-py27 conda environment 

rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)


user= 'liruixue'

db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data/'
dir = paste0('/shares/gcp/social/parameters/energy/extraction/',
				'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

git = paste0("/home/", user,"/repos")

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(git,"/energy-code-release-2020/pixel_interaction/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0('/home/',user, '/repos/')

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))


# Note on naming convention: 
# Time series naming convention:
# {model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scen}

# Map data naming convention:
# {model}-{fuel}-{ssp}-{rcp}-{iam}-{adapt_scenario}-{price_scen}-{year}-map



###############################################
# Impacts maps for figure 2A
###############################################

get_main_model_impacts_maps = function(fuel, price_scen, unit, year, output){
	
	spec = paste0("OTHERIND_", fuel)
	df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = NULL, # needs to be specified for 
                    rcp = "rcp85", 
                    ssp = "SSP3", 
                    price_scen = price_scen, # have this as NULL, "price014", "MERGEETL", ...
                    unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "values", # full, climate, values
                    geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim", 
                    adapt_scen = "fulladapt", 
                    clim_data = "GMFD", 
                    yearlist = year,  
                    spec = spec,
                    grouping_test = "semi-parametric") %>%
		dplyr::select(region, year, mean) %>%
		dplyr::filter(year == !!year) 

	price_tag = ifelse(is.null(price_scen), "impact_pc", price)

	write_csv(df, 
		paste0(output, '/projection_system_outputs/mapping_data/', 
			'main_model-', fuel, '-SSP3-rcp85-high-fulladapt-',price_tag ,'-2099-map.csv'))
}

# fuels = c("electricity", "other_energy")
fuels = c("electricity")

df = lapply(fuels, get_main_model_impacts_maps, 
	price_scen = NULL, unit = "impactpc", year = 2099, output = output)


	



###############################################
# Get time series data for figure 2C
###############################################

fuels = c("electricity", "other_energy")
rcps = c("rcp85", "rcp45")
adapt = c("fulladapt", "noadapt")
options = expand.grid(fuels = fuels, rcps = rcps, adapt= adapt)

get_main_model_impacts_ts = function(fuel, rcp, adapt) {

	spec = paste0("OTHERIND_", fuel)
	scale = function(x) (x* 0.0036)
	names = c("mean", "q50", "q5", "q95", "q10", "q90", "q75","q25")

	df = load.median(  
					conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = rcp, 
                    ssp = "SSP3", 
                    price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                    unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "full", # full, climate, values
                    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim_income_spline", 
                    adapt_scen = adapt, 
                    clim_data = "GMFD", 
                    yearlist = as.character(seq(1980,2099,1)),  
                    spec = spec,
                    grouping_test = "semi-parametric")%>%
		dplyr::filter(year > 2009)  %>%
	    mutate_at(names, scale)
	
	write_csv(df, 
		paste0(output, '/projection_system_outputs/time_series_data/', 
			'main_model-', fuel, '-SSP3-',rcp, '-high-',adapt,'-impact_pc.csv'))
}

# Get the required dataframe - note this extracts for you if the csv doesn't exist
mcmapply(get_main_model_impacts_ts, 
  fuel= options$fuels, rcp= options$rcps, adapt=options$adapt)

