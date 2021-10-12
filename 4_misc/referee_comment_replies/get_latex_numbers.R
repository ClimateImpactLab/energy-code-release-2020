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

# Global Other Fuels Impact (quantity) per capita at end-of-century (RCP8.5 no adaptation)
df = load.median(conda_env = "risingverse-py27",
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
print(df$mean)



# Global Electricity Impact (quantity) per capita at end-of-century (RCP8.5 full adaptation)
df = load.median(conda_env = "risingverse-py27",
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
print(df$mean)




# Global Electricity Impact (quantity) per capita at end-of-century (RCP4.5 full adaptation)
df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = "rcp45", 
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
print(df$mean)

# Global pop average electricity consumption at 2012 (or 2010 if that's easier)
# didn't change


# Global Other Fuels Impact (quantity) per capita at end-of-century (RCP8.5 no adaptation)
df = load.median(conda_env = "risingverse-py27",
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
                    spec = "OTHERIND_other_energy",
                    grouping_test = "semi-parametric")
print(df$mean)



# Global Other Fuels Impact (quantity) per capita at end-of-century (RCP4.5 no adaptation)
df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = "rcp45", 
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
                    spec = "OTHERIND_other_energy",
                    grouping_test = "semi-parametric")
print(df$mean)






# Global Other Fuels Impact (quantity) per capita at end-of-century (RCP8.5 full adaptation)
df = load.median(conda_env = "risingverse-py27",
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
                    spec = "OTHERIND_other_energy",
                    grouping_test = "semi-parametric")
print(df$mean)


# Global Other Fuels Impact (quantity) per capita at end-of-century (RCP4.5 full adaptation)
df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = "rcp45", 
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
                    spec = "OTHERIND_other_energy",
                    grouping_test = "semi-parametric")
print(df$mean)


# Global pop average other fuels consumption at 2012 (or 2010 if that's easier)
# didn't change


gdp_SSP3 = read_csv(paste0(output, 
     '/projection_system_outputs/covariates/SSP3-global-gdp-time_series.csv'))


# End-of-century damages under RCP 8.5, price014
df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
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
                    dollar_convert = "yes",
                    yearlist = 2099,  
                    spec = "OTHERIND_total_energy",
                    grouping_test = "semi-parametric")
print(df$mean/0.0036)

# Global total damages at 2100 as percent of global GDP (RCP 8.5, 1.4% price growth). 

print(df$mean/0.0036/((gdp_SSP3 %>% filter(year == 2099))$gdp / 1000000000))



# End-of-century damages under RCP 4.5, price014
df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = "rcp45", 
                    ssp = "SSP3", 
                    price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
                    unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "climate", # full, climate, values
                    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim", 
                    adapt_scen = "fulladapt", 
                    clim_data = "GMFD", 
                    dollar_convert="yes",
                    yearlist = 2099,  
                    spec = "OTHERIND_total_energy",
                    grouping_test = "semi-parametric")
print(df$mean/0.0036)
print(df$mean/0.0036/((gdp_SSP3 %>% filter(year == 2099))$gdp/1000000000))





# Global Electricity Impact (quantity) per capita at end-of-century (RCP8.5 full adaptation tech trends)
df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = "rcp85", 
                    ssp = "SSP3", 
                    price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                    unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "climate", # full, climate, values
                    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim_lininter", 
                    adapt_scen = "fulladapt", 
                    clim_data = "GMFD", 
                    yearlist = 2099,  
                    spec = "OTHERIND_electricity",
                    grouping_test = "semi-parametric")
print(df$mean)




# Global Other Fuels Impact (quantity) per capita at end-of-century (RCP8.5 full adaptation tech trends)
df = load.median(conda_env = "risingverse-py27",
                    proj_mode = '', # '' and _dm are the two options
                    region = "global", # needs to be specified for 
                    rcp = "rcp85", 
                    ssp = "SSP3", 
                    price_scen = NULL, # have this as NULL, "price014", "MERGEETL", ...
                    unit =  "impactpc", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
                    uncertainty = "climate", # full, climate, values
                    geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
                    iam = "high", 
                    model = "TINV_clim_lininter", 
                    adapt_scen = "fulladapt", 
                    clim_data = "GMFD", 
                    yearlist = 2099,  
                    spec = "OTHERIND_other_energy",
                    grouping_test = "semi-parametric")
print(df$mean)



