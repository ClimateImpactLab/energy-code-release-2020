# find out why florida (USA.10) 2020 is missing in impacts_pct_gdp file

library(tidyverse)
library(dplyr)
d = read_csv(
	paste0("/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/median_OTHERIND_electricity_TINV_clim_GMFD/",
	"SSP3-rcp85_USA_impactpc_median_fulluncertainty_high_fulladapt-aggregated.csv"))

florida = d %>% filter(substr(region,1,6) == "USA.10") 

d %>% filter(year == 2020)

f2020 = florida %>% filter(year == 2020)

f2021 = florida %>% filter(year == 2021)

print(f2020, n=100)

print(f2021, n=100)



library(glue)
library(R.cache)
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)

# cilpath.r:::cilpath()
db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/'

REPO <- "/home/liruixue/repos"

dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
    'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

df_dm = load.median(conda_env = "risingverse-py27",
                proj_mode = '_dm', # '' and _dm are the two options
                region = "USA.10", # needs to be specified for 
                # regions = "USA.10",
                regions_suffix = "florida",
                # rcp = "rcp85", 
                ssp = "SSP3", 
                price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
                unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                uncertainty = "values", # full, climate, values
                geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                # iam = "low", 
                model = "TINV_clim", 
                adapt_scen = "fulladapt", 
                clim_data = "GMFD", 
                yearlist = seq(2000, 2030),  
                spec = "OTHERIND_total_energy",
                dollar_convert = "yes",
                grouping_test = "semi-parametric",
                regenerate = FALSE)

df %>% filter(year == 2020) %>% select(gcm, iam, rcp, value)

df_dm %>% filter(year == 2020) %>% select(gcm, iam, rcp, value)







