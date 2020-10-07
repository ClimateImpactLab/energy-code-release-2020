# Compare our results to Hsiang et al et al. 2017
 # Appendix table J panel B


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
current_consumption = read.dta13(paste0(REPO, 
        "/energy-code-release-2020/data","/IEA_Merged_long_GMFD.dta"))


US_electricity = current_consumption %>% 
        select(country, year, product, load) %>%
        filter(year >= 2010) %>%
        filter(country == "USA" ) %>%
        filter(product == "electricity")

prices = read.dta13(paste0(db,"/IEA_Replication/Data/Projection/prices/2_final/",
        "IEA_Price_FIN_Clean_gr014_GLOBAL_COMPILE.dta"))


US_2012_price = prices %>% filter(country == "USA",year == 2012) 


# 2012 consumption not available(EU_electricity %>% filter(country == "FRA"))$load
impact = load.median(conda_env = "risingverse-py27",
                proj_mode = '', # '' and _dm are the two options
                region = "USA", # needs to be specified for 
                rcp = "rcp85", 
                ssp = "SSP3", 
                price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
                unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                uncertainty = "climate", # full, climate, values
                geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                iam = "high", 
                model = "TINV_clim", 
                adapt_scen = "fulladapt", 
                clim_data = "GMFD", 
                yearlist = 2099,  
                spec = "OTHERIND_electricity",
                grouping_test = "semi-parametric")  


result = impact$mean / (US_electricity$load*US_2012_price$electricitycompile_price) * 100
print(result)


