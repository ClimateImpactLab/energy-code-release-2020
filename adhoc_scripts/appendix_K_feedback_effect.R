# calculating feedback effect for appendix K

# get numbers used in the paper from NumberReferences.tex
# need to run in risingverse-py27


rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)
cilpath.r:::cilpath()


db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
				'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

pop = (read_csv(paste0('/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/covariates/', 
	'SSP3-high-IR_level-gdppc_pop-2099.csv')) %>%
	summarize(total_pop = sum(pop99)))$total_pop

# Global Other Fuels Impact (quantity) per capita at end-of-century (RCP8.5 no adaptation)
impactpc_other = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = "rcp85", 
                    ssp = "SSP3", 
                    price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                    unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "climate", # full, climate, values
                    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim", 
                    adapt_scen = "noadapt", 
                    clim_data = "GMFD", 
                    yearlist = 2099,  
                    spec = "OTHERIND_other_energy",
                    grouping_test = "semi-parametric")
print(impactpc_other$mean*pop)



# Global Electricity Impact (quantity) per capita at end-of-century (RCP8.5 full adaptation)
impactpc_elec = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = "rcp85", 
                    ssp = "SSP3", 
                    price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                    unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "climate", # full, climate, values
                    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim", 
                    adapt_scen = "fulladapt", 
                    clim_data = "GMFD", 
                    yearlist = 2099,  
                    spec = "OTHERIND_electricity",
                    grouping_test = "semi-parametric")
print(impactpc_elec$mean*pop)


# EF : emission factor
elec_EF_kg_per_kWh = 

emission_factor_other = 

