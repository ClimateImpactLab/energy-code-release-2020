# Compare our results to Clarke et al et al. 2017
 # Appendix table J panel C


# risingverse
rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(haven)
library(tidyr)
cilpath.r:::cilpath()
library(readstata13)


setwd(paste0(REPO,"/energy-code-release-2020/"))

db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'


# Source a python code that lets us load SSP data directly from the SSPs
# Make sure you are in the risingverse conda environment for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
# source_python(paste0(projection.packages, "future_gdp_pop_data.py"))

setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

# get the end-of-century damage in total energy for SSP2, global, price014
impact = load.median(conda_env = "risingverse-py27",
                proj_mode = '', # '' and _dm are the two options
                region = "global", # needs to be specified for 
                rcp = NULL, 
                ssp = "SSP2", 
                price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
                unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                uncertainty = "values", # full, climate, values
                geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                iam = NULL, 
                model = "TINV_clim", 
                adapt_scen = "fulladapt", 
                clim_data = "GMFD", 
                yearlist = 2099,  
                spec = "OTHERIND_total_energy",
                grouping_test = "semi-parametric")  

# take the model we need
impact_global = impact %>% filter(gcm == "CESM1-BGC",rcp=="rcp85",iam=="high")


# get SSP2 global GDP data
gdp = read_csv(paste0('/mnt/CIL_energy/code_release_data_pixel_interaction/', 
    '/projection_system_outputs/covariates/SSP2-global-gdp-time_series.csv')) %>%
    filter(year == 2100)

result = impact_global$value / gdp$gdp * 100



