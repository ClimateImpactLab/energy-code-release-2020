

# Rae liruixue@uchicago.edu
# 10 jul 2020
# to extract time series data for all climate models as percentage gdp
# similar to figure 3B


rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)

user= 'liruixue'

db = '/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/'
output = '/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/code_release_data/'
dir = paste0('/shares/gcp/social/parameters/energy/extraction/',
                    'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

git = paste0("/home/", user,"/repos")

# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(git,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(paste0('/home/',user, '/repos/'))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

# get damages 
df_dmg = load.median(conda_env = "risingverse-py27",
               proj_mode = '', # '' and _dm are the two options
               region = "global", # needs to be specified for 
               # rcp = "rcp45", 
               ssp = "SSP3", 
               price_scen = "price014", # have this as NULL, "price014", "MERGEETL", ...
               unit =  "damage", # 'damagepc' ($ pc) 'impactpc' (kwh pc) 'damage' ($ pc)
               uncertainty = "values", # full, climate, values
               geo_level = "aggregated", # aggregated (ir agglomerations) or 'levels' (single irs)
               # iam = "high", 
               model = "TINV_clim_income_spline", 
               adapt_scen = "fulladapt", 
               clim_data = "GMFD", 
               yearlist = as.character(seq(2010,2099,1)),  
               spec = "OTHERIND_total_energy",
               dollar_convert = "yes",
               grouping_test = "semi-parametric") %>%
	dplyr::select(year, rcp, iam, gcm, value) %>%
	dplyr::filter(iam == "high")


write_csv(df_dmg, 
	paste0(output, '/projection_system_outputs/21jul2020_pre_data/', 
		'main_model-', "OTHERIND_total_energy", '-SSP3-high-fulladapt-',"price014" ,'-2010_2099-damages-timeseries.csv'))

# get GDP
df_gdp = read_csv(paste0(output, '/projection_system_outputs/covariates/', 
                      "/SSP3-global-gdp-time_series.csv"))

# convert damage to percent GDP
df_pct = df_dmg %>% 
     dplyr::left_join(df_gdp, by = "year")%>% 
     dplyr::mutate(value = value * 1000000000) %>% #convert from billions of dollars 
     dplyr::mutate(percent_gdp = (value/gdp)*100) %>%
     dplyr::select(year, gcm, rcp, value, percent_gdp) %>%
     dplyr::rename(damage = value)


write_csv(df_pct, 
     paste0(output, '/projection_system_outputs/21jul2020_pre_data/', 
          'main_model-', "OTHERIND_total_energy", '-SSP3-high-fulladapt-',"price014" ,'-2010_2099-pct-gdp-timeseries.csv'))




	