# Prepare code release covariates data
# Note - this code should be run from the risingverse (python 3)

# This code moves some of our projection results from our usual location on our servers 
# and Dropbox/Synology to the code release data storage 
# TO-DO: tidy up "/Users/ruixueli/Downloads/energy_data_release/OUTPUT/projection_system_outputs/single_projection/"


rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(haven)
library(tidyr)
library(imputeTS)
library(logr)
LOG <- Sys.getenv(c("LOG"))
log_open(file.path(LOG, "2_projection/3_extract_projection_outputs/0_save_covariate_data.log"), logdir = FALSE)

# Sys.setenv(LANG = "en")

REPO <- Sys.getenv(c("REPO"))
DATA <- Sys.getenv(c("DATA"))
OUTPUT <- Sys.getenv(c("OUTPUT"))
# REPO <- "/home/liruixue/repos"
setwd(paste0(REPO,"/energy-code-release-2020/"))


# Source a python code that lets us load SSP data directly from the SSPs
# Make sure you are in the risingverse conda environment for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
use_condaenv("impact-env", required = TRUE)
reticulate::source_python(paste0(projection.packages, "future_gdp_pop_data.py"))
###########################################
# 1 Data for plotting city response functions for figure 2A

# Min and max temperature for each city - this is just for plotting aesthetics 
min_max_temp = read_csv(paste0(DATA, 
	'/miscellaneous/Cities_12_MinMax.csv'), skip = 4) %>%
		dplyr::filter(city %in% c("Guangzhou", "Stockholm")) %>%
	write_csv(paste0(DATA, '/miscellaneous/stockholm_guangzhou_2015_min_max.csv'))

city_list = read_csv(paste0(DATA, 
	'/miscellaneous/City_List.csv')) %>%
		dplyr::filter(city %in% c("Guangzhou", "Stockholm")) %>%
		dplyr::rename(region = hierid) %>%
		write_csv(paste0(DATA, '/miscellaneous/stockholm_guangzhou_region_names_key.csv'))

# TO-DO: make sure that the singles are generated into the corresponding directories
# Covariates are from a single run allcalcs file
cov_electricity_single= read_csv(paste0(OUTPUT,
	"/projection_system_outputs/single_projection/",
	"/single-OTHERIND_electricity_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_GMFD/",
	"/rcp85/CCSM4/high/SSP3/hddcddspline_OTHERIND_electricity-allcalcs-FD_FGLS_inter_OTHERIND_electricity_TINV_clim.csv"),
  skip = 114) %>% 
	write_csv(paste0(DATA, '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))

# TO-DO: repeated variable names gets named random stuff
covariates = cov_electricity_single %>%
		dplyr::rename(year = "year...2") %>%
		dplyr::select(year, region, "climtas-cdd-20", "climtas-hdd-20", loggdppc) %>%
		dplyr::filter(year %in% c(2015, 2099))%>%
		dplyr::right_join(city_list, by = "region") %>%
		write_csv(paste0(DATA, '/miscellaneous/stockholm_guangzhou_covariates_2015_2099.csv'))


###########################################

# 2 Data for figure 2B bar chart
# Just need population for each impact region (since we have KWh/capita info from the projection)
# this has to be run where "../server.yml" exists

pop = get_pop() 
pop_df = pop %>% 
	dplyr::filter(ssp == "SSP3") %>%
	dplyr::select(region, pop, year) 

write_csv(pop_df, paste0(OUTPUT,'/projection_system_outputs/covariates/' ,
	'SSP3_IR_level_population.csv'))

# Get population and gdp values: 
inf = paste0(DATA, 
	"/miscellaneous/vsl_adjustments.dta")
con_df = read_dta(inf) 
conversion_value = con_df$inf_adj[1]

###########################################
# 3 Data for figure 3A map

gdppc = get_gdppc_all_regions('high', 'SSP3')

gdppc = gdppc %>%
	mutate(gdppc = gdppc * conversion_value)


# Population values are every 5 years. We use flat interpolation (a step function)
# in between. So the 2099 population is assigned to the value we have in 2095. 

pop99 = pop %>% 
	dplyr::filter(ssp == "SSP3") %>%
	dplyr::filter(year == 2095) %>% 
	dplyr::select(region, pop) %>%
	rename(pop99 = pop)

gdppc99 = gdppc %>% 
	dplyr::filter(year == 2099) %>%
	rename(gdppc99 = gdppc)

covs = left_join(pop99, gdppc99, by = "region") %>%
	dplyr::select(region, pop99, gdppc99) %>%
	mutate(gdp99 = gdppc99 *pop99)

write_csv(covs, paste0(OUTPUT, '/projection_system_outputs/covariates/', 
	'SSP3-high-IR_level-gdppc_pop-2099.csv'))


###########################################
# 4 Figure 3B Time series data 
gdppc = get_gdppc_all_regions('high', 'SSP3')

gdp = convert_global_gdp(gdppc,'SSP3') 
gdp$year = seq(2010,2100,1) 

gdp = gdp %>% as.data.frame() %>% 
	mutate(gdp = gdp * conversion_value)

write_csv(gdp, paste0(OUTPUT, 
	'/projection_system_outputs/covariates/SSP3-global-gdp-time_series.csv'))

gdppc = get_gdppc_all_regions('low', 'SSP3')

gdp = convert_global_gdp(gdppc,'SSP3') 
gdp$year = seq(2010,2100,1) 

gdp = gdp %>% as.data.frame() %>% 
	mutate(gdp = gdp * conversion_value)

write_csv(gdp, paste0(OUTPUT, 
	'/projection_system_outputs/covariates/SSP3-low-global-gdp-time_series.csv'))



# also get SSP2 gdp time series for referee comments
gdppc = get_gdppc_all_regions('high', 'SSP2')

gdp = convert_global_gdp(gdppc,'SSP2') 
gdp$year = seq(2010,2100,1) 

gdp = gdp %>% as.data.frame() %>% 
    mutate(gdp = gdp * conversion_value)

write_csv(gdp, paste0(OUTPUT, 
    '/projection_system_outputs/covariates/SSP2-global-gdp-time_series.csv'))


############################################################
# 5 Get data needed for income decile plot 

gdppc = get_gdppc_all_regions('high', 'SSP3') %>%
	mutate(gdppc = gdppc * conversion_value) 

df = gdppc %>% 
	dplyr::filter(year == 2012)

all_year_IR_comb = expand.grid(region = unique(pop$region), year = seq(2010, 2100))

pop_allyears = left_join(all_year_IR_comb, pop, )
# Get 2012 population projections
pop12 = pop %>% 
	dplyr::filter(ssp == "SSP3") %>%
	dplyr::filter(year == 2010) %>% 
	dplyr::select(region, pop)

df = left_join(df, pop12, by = "region") %>% 
	dplyr::select(region, year, gdppc, pop)

write_csv(df, paste0(OUTPUT, '/projection_system_outputs/covariates/',
	'SSP3-high-IR_level-gdppc-pop-2012.csv'))


