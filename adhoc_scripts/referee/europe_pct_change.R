# Compare our results to Li et al. 2019: who construct end-of-century
 # damage function for Shanghai impact region (with and without 
 # surrogate climate models) in terms of total electricity consumption 
 # as percent of current consumption.

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

EU_electricity = current_consumption %>% 
        select(country, year, product, load) %>%
        filter(year >= 2010) %>%
        filter(country %in% c("FRA","ITA","ESP","GBR","GRC","DEU")) %>%
        filter(product == "electricity")



# 2012 consumption not available
calculate_percentage <- function(country = "FRA", country_2012_total = NULL){

        browser()
        country_2012_total = EU_electricity %>% filter(country == country) 
        country_2012_total = country_2012_total$load
        pop = read_csv(paste0(output,'/projection_system_outputs/covariates/' ,
        	'SSP3_IR_level_population.csv')) %>%
                dplyr::mutate(country = substr(region, 1,3)) %>%
                dplyr::filter(country = country) %>%
        	filter(year == 2095) %>% 
                summarize()

        impact = load.median(conda_env = "risingverse-py27",
                        proj_mode = '', # '' and _dm are the two options
                        region = country, # needs to be specified for 
                        rcp = NULL, 
                        ssp = "SSP3", 
                        price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                        unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                        uncertainty = "values", # full, climate, values
                        geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                        iam = NULL, 
                        model = "TINV_clim", 
                        adapt_scen = "fulladapt", 
                        clim_data = "GMFD", 
                        yearlist = 2099,  
                        spec = "OTHERIND_electricity",
                        grouping_test = "semi-parametric")  %>% 
        	select(rcp,year,gcm,iam,value)  %>%
                filter(gcm == "GFDL-ESM2M") %>% 
        	mutate(value = value *  / country_2012_total * 100) # convert to percentage

        return(0)
}

calculate_percentage




