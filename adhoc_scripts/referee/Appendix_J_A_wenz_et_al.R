# Compare our results to Wenz et al et al. 2017
 # Appendix table J panel A


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

# get current consumption from the same source as regression data
# for year 2012, electricity, EU countries
EU_countries = c("FRA","ITA","ESP","GBR","GRC","DEU")
EU_electricity = read.dta13(paste0(REPO, 
        "/energy-code-release-2020/data","/energy_consumption_all_years.dta"))%>% 
        select(country, year, product, load) %>%
        filter(year == 2012) %>%
        filter(country %in% EU_countries) %>%
        filter(product == "electricity")

# get SSP3 population data from the projection system, since 2099 is not readily available, we use 2095
EU_pop = read_csv(paste0(output,'/projection_system_outputs/covariates/' ,
        'SSP3_IR_level_population.csv')) %>%
        dplyr::mutate(country = substr(region, 1,3)) %>%
        dplyr::filter(country %in% EU_countries) %>%
        filter(year == 2095) %>%
        group_by(country) %>% 
        summarize(pop = sum(pop))

calculate_percentage <- function(country, pop_2095, electricity_current ){

        # extract raw impacts for each model, electricity, country level aggregated
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
                filter(gcm == "GFDL-ESM2M",rcp=="rcp85",iam=="high") %>% 
        	dplyr:: mutate(value = value * pop_2095 / electricity_current * 100) # convert to percentage

        return(impact)
}


EU_impacts = c() 

for (c in EU_countries) {
        EU_impacts = c(EU_impacts, (calculate_percentage(c,(EU_pop %>% filter(country == c))$pop,
        (EU_electricity %>% filter(country == c))$load))$value)
}

EU_countries
EU_impacts
