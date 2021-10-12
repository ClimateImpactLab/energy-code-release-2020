
rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(haven)
library(tidyr)
library(glue)
library(imputeTS)
cilpath.r:::cilpath()
REPO = "/home/liruixue/repos"

setwd(paste0(REPO,"/energy-code-release-2020/"))

db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'


# Source a python code that lets us load SSP data directly from the SSPs
# Make sure you are in the risingverse conda environment for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
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
cov_electricity_single= read_csv("/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/single-OTHERIND_electricity_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_GMFD/rcp85/CCSM4/low/SSP3/hddcddspline_OTHERIND_electricity-allcalcs-FD_FGLS_inter_OTHERIND_electricity_TINV_clim.csv",
  skip = 114)


   %>% 
	write_csv(paste0(output, '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))
