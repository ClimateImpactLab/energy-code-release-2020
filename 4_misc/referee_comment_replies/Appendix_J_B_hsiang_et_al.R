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
US_energy = current_consumption %>% 
        select(country, year, product, load, load_pc) %>%
        filter(year == 2012) %>%
        filter(country == "USA" ) 


# get prices under price014 scenario
prices = read.dta13(paste0(db,"/IEA_Replication/Data/Projection/prices/2_final/",
        "IEA_Price_FIN_Clean_gr014_GLOBAL_COMPILE.dta"))


# get US 2012 price
US_2012_price = prices %>% filter(country == "USA",year == 2012) 
US_2090_price = prices %>% filter(country == "USA",year == 2090) 

# multiply price with quantity
US_exp = merge(US_energy, US_2012_price, by = c("year")) %>%
                mutate(electricity_exp = load * electricitycompile_price,
                        other_exp = load * other_energycompile_price)
# 
US_energy_expenditure_2012 = (US_exp %>% filter(product == "electricity"))$electricity_exp + 
                        (US_exp %>% filter(product == "other_energy"))$other_exp

load_projection_data <- function(unit, spec) {
        result = load.median(conda_env = "risingverse-py27",
                proj_mode = '', # '' and _dm are the two options
                region = "USA", # needs to be specified for 
                rcp = "rcp85", 
                ssp = "SSP3", 
                price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
                unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                uncertainty = "climate", # full, climate, values
                geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                iam = "high", 
                model = "TINV_clim", 
                adapt_scen = "fulladapt", 
                clim_data = "GMFD", 
                yearlist = 2090,  
                spec = spec,
                grouping_test = "semi-parametric")  
}

# 2012 consumption not available(EU_electricity %>% filter(country == "FRA"))$load
impact_energy = load_projection_data("damage", "OTHERIND_total_energy")
result_energy = impact_energy$mean / US_energy_expenditure_2012 * 100
print(result_energy)


# electricity

US_electricity_expenditure_2012 = (US_exp %>% filter(product == "electricity"))$electricity_exp 
# 2012 consumption not available(EU_electricity %>% filter(country == "FRA"))$load
impact_electricity = load_projection_data("damage", "OTHERIND_electricity")
result_electricity = impact_electricity$mean / US_electricity_expenditure_2012 * 100
print(result_electricity)



# other_energy
US_other_energy_expenditure_2012 = (US_exp %>% filter(product == "other_energy"))$other_exp
# 2012 consumption not available(EU_electricity %>% filter(country == "FRA"))$load
impact_other_energy = load_projection_data("damage", "OTHERIND_other_energy")
result_other_energy = impact_other_energy$mean / US_other_energy_expenditure_2012 * 100
print(result_other_energy)





# per capita

load_projection_data_pc <- function(unit, spec) {
        result = load.median(conda_env = "risingverse-py27",
                proj_mode = '', # '' and _dm are the two options
                region = "USA", # needs to be specified for 
                rcp = "rcp85", 
                ssp = "SSP3", 
                price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                unit =  unit, # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                uncertainty = "climate", # full, climate, values
                geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                iam = "high", 
                model = "TINV_clim", 
                adapt_scen = "fulladapt", 
                clim_data = "GMFD", 
                yearlist = 2090,  
                spec = spec,
                grouping_test = "semi-parametric")  
}

# impactpc_energy = load_projection_data_pc("impactpc", "OTHERIND_total_energy")
impactpc_electricity = load_projection_data_pc("impactpc", "OTHERIND_electricity")$mean
impactpc_other_energy = load_projection_data_pc("impactpc", "OTHERIND_other_energy")$mean



