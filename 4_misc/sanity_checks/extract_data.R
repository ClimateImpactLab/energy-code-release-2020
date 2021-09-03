# extract data for 
# map 2099 damages as percent gdp (SSP2/3/4 x RCP4.5/8.5 x IAM high/low)
# map the 2099 damages as percent gdp separately for electricity and other fuels. (SSP2/3/4 x RCP4.5/8.5 x IAM high/low)
# pick a couple of IRs (2 from among the kernel density IRs that are in different countries would be fine) and plot their electricity/other fuels prices over time, under the tool price scenario and the 1.4% scenario. actually this doesn’t even need to be in a graph. it can just be in a spreadsheet.

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
for (ssp in c("SSP2", "SSP3", "SSP4")) {
	for (fuel in c("electricity", "other_energy", "total_energy")) {
		for (iam in c("low", "high")) {
			for (rcp in c("rcp85","rcp45")) {


			# Get impacts data
			args = list(
			      conda_env = "risingverse-py27",
			      proj_mode = '', # '' and _dm are the two options
			      region = NULL, # needs to be specified for 
			      rcp = rcp, 
			      ssp = ssp, 
			      price_scen = "integration", # have this as NULL, "integration", "MERGEETL", ...
			      unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
			      uncertainty = "climate", # full, climate, values
			      geo_level = "levels", # aggregated (ir agglomerations) or 'levels' (single irs)
			      iam = iam, 
			      model = "TINV_clim", 
			      adapt_scen = "fulladapt", 
			      clim_data = "GMFD", 
			      dollar_convert = "yes",
			      yearlist = 2099,  
			      spec = glue("OTHERIND_{fuel}"),
			      grouping_test = "semi-parametric",
			      regenerate = FALSE)

			impacts = do.call(load.median, args) %>%
				dplyr::select(region, mean, q5, q95) %>%
				rename(damage = mean)

			write_csv(impacts, 
					paste0(output, '/projection_system_outputs/mapping_data/', 
						glue('main_model-{fuel}-{ssp}-{rcp}-{iam}-fulladapt-integration-2099-map.csv')))


			}
		}
	}
}







