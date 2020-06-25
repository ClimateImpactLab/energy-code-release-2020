# Prepare code release covariates data
# Note - all maps in the paper are for 2099, ssp3, rcp85, high, so these are hard coded 
# Note - this code should be run from the risingverse (python 3)

# This code moves some of our projection results from our usual location on sac 
# and Dropbox to the code release data storage 


rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(ncdf4)
library(tidyr)

user= 'tbearpark'

output = '/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/code_release_data/'
dir = paste0('/shares/gcp/social/parameters/energy/extraction/',
				'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')
db = '/mnt/norgay_synology_drive/GCP_Reanalysis/ENERGY/'
git = paste0("/home/", user,"/repos")

# Make sure you are in the risingverse for this... 
projection.packages <- paste0(git,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd('/home/tbearpark/repos/')

# Source a python code that lets us load SSP data directly from the SSPs
source_python(paste0(projection.packages, "future_gdp_pop_data.py"))



###########################################
# 1 Data for plotting city response functions for figure 2A

# Min and max temperature for each city - this is just for plotting aesthetics 
min_max_temp = read_csv(paste0(db, 
	'IEA_Replication/Data/Miscellaneous/Cities_12_MinMax.csv'), skip = 4) %>%
		dplyr::filter(city %in% c("Guangzhou", "Stockholm")) %>%
	write_csv(paste0(output, '/miscellaneous/stockholm_guangzhou_2015_min_max.csv'))

city_list = read_csv(paste0(db, 
	'IEA_Replication/Data/Miscellaneous/City_List.csv')) %>%
		dplyr::filter(city %in% c("Guangzhou", "Stockholm")) %>%
		dplyr::rename(region = hierid) %>%
		write_csv(paste0(output, '/miscellaneous/stockholm_guangzhou_region_names_key.csv'))

# Covariates are from a single run allcalcs file
covariates = read_csv(paste0(db,
	'IEA_Replication/Data/Projection/covariates/', 
	'FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_income_spline.csv'))%>%
		dplyr::filter(year %in% c(2015, 2099))%>%
		dplyr::right_join(city_list, by = "region") %>%
		write_csv(paste0(output, '/miscellaneous/stockholm_guangzhou_covariates_2015_2099.csv'))


###########################################

# 2 Data for figure 2B bar chart
# Just need population for each impact region (since we have KWh/capita info from the projection)

pop = get_pop() 
pop_df = pop %>% 
	dplyr::filter(ssp == "SSP3") %>%
	dplyr::select(region, pop, year) 

write_csv(pop_df, paste0(output,'/projection_system_outputs/covariates/' ,
	'SSP3_IR_level_population.csv'))


# Get population and gdp values: 
inf = paste0("/mnt/norgay_synology_drive", 
	"/Global ACP/MORTALITY/Replication_2018/3_Output/7_valuation/1_values/adjustments/vsl_adjustments.dta")
con_df = read_dta(inf) 
conversion_value = con_df$inf_adj[1]

###########################################
# 3 Data for figure 3A map

gdppc = get_gdppc_all_regions('high', 'SSP3') %>%
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

write_csv(covs, paste0(output, '/projection_system_outputs/covariates/', 
	'SSP3-high-IR_level-gdppc_pop-2099.csv.csv'))


###########################################
# 4 Figure 3B Time series data 
gdppc = get_gdppc_all_regions('high', 'SSP3')

gdp = convert_global_gdp(gdppc) 
gdp$year = seq(2010,2100,1) 

gdp = gdp %>% as.data.frame() %>% 
	mutate(gdp = gdp * conversion_value)

write_csv(gdp, paste0(output, 
	'/projection_system_outputs/covariates/SSP3-global-gdp-time_series.csv'))


############################################################
# 5 Get data needed for income decile plot 

gdppc = get_gdppc_all_regions('high', 'SSP3') %>%
	mutate(gdppc = gdppc * conversion_value) 

df = gdppc %>% 
	dplyr::filter(year == 2012)

# Get 2012 population projections
pop12 = pop %>% 
	dplyr::filter(ssp == "SSP3") %>%
	dplyr::filter(year == 2010) %>% 
	dplyr::select(region, pop)

df = left_join(df, pop12, by = "region") %>% 
	dplyr::select(region, year, gdppc, pop)

write_csv(df, paste0(output, '/projection_system_outputs/covariates/',
	'SSP3-high-IR_level-gdppc-pop-2012.csv'))
