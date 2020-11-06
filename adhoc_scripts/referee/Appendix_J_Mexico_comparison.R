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


miceadds::source.all(paste0(projection.packages,"load_projection/"))

# source of historical energy consumption: same as our regression data
current_consumption = read.dta13(paste0(REPO, 
        "/energy-code-release-2020/data","/energy_consumption_all_years.dta"))

# take 2012 values and sum electricity and other energy
MEX_energy = current_consumption %>% 
        select(country, year, product, load) %>%
        filter(year == 2010) %>%
        filter(country == "MEX" )  %>%
        filter(product == "electricity")

MEX_pop = read_csv(paste0(output,'/projection_system_outputs/covariates/' ,
        'SSP3_IR_level_population.csv')) %>%
        dplyr::mutate(country = substr(region, 1,3)) %>%
        dplyr::filter(country == "MEX") %>%
        filter(year == 2095) %>%
        summarize(pop = sum(pop))



# 2012 consumption not available(EU_electricity %>% filter(country == "FRA"))$load
impact = load.median(conda_env = "risingverse-py27",
                proj_mode = '', # '' and _dm are the two options
                region = "MEX", # needs to be specified for 
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


result = impact$mean * MEX_pop$pop / MEX_energy$load * 100
print(result)


