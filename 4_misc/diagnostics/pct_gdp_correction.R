# this script compares the gdp used in computing percent gdp for plotting 3A
# and saves an updated gdp file to be used in plotting

rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(haven)
library(tidyr)
library(glue)
library(imputeTS)
REPO = "/home/liruixue/repos"

setwd(paste0(REPO,"/energy-code-release-2020/"))

db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

DB = "/mnt/CIL_energy"
DB_data = paste0(DB, "/code_release_data_pixel_interaction")


# Source a python code that lets us load SSP data directly from the SSPs
# Make sure you are in the risingverse conda environment for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
source_python(paste0(projection.packages, "future_gdp_pop_data.py"))

###########################################
# load covariates from the projection that was actually run
covars_from_projection = read_csv(paste0(output, '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))

# extract 2099 IR level loggdppc, and compute gdppc
correct_gdp = covars_from_projection %>% select(c("year", "region", "loggdppc")) %>% filter(year == 2099) %>%
			mutate(gdppc = exp(loggdppc)) %>%
			select(region, gdppc)

# load the gdp data that's used in plotting 3A before
# it has columns: pop99, gdppc99, gdp99(which is pop*gdppc99) 

wrong_gdp = read_csv(
    paste0(DB_data, '/projection_system_outputs/covariates/', 
           'SSP3-high-IR_level-gdppc_pop-2099.csv'))  

# replace gdppc99 with the gdppc we just grabbed from projection
# and multiply with pop to compute gdp99 again 
correction = merge(wrong_gdp, correct_gdp, on = "region") %>%
		mutate(gdppc99 = gdppc) %>% 
		mutate(gdp99 = pop99 * gdppc99) %>%
		select(region, pop99, gdppc99, gdp99)

write_csv(correction,
    paste0(DB_data, '/projection_system_outputs/covariates/', 
           'SSP3-high-IR_level-gdppc_pop-2099_correction_iso-income.csv'))  


diag = correction %>% mutate(iso = substr(region, 1, 3)) %>% group_by(iso) %>% arrange(gdppc99) %>%
		select(gdppc99, iso) %>% unique()


write_csv(diag,
    paste0('/home/liruixue/diag_high.csv'))  

# length(unique(diag$iso))
# length(unique(diag$gdppc99))


# correction_old = read_csv(paste0(DB_data, '/projection_system_outputs/covariates_backup_gdp_correction/', 
#            'SSP3-high-IR_level-gdppc_pop-2099_correction_iso-income.csv'))  


# comparison = merge(correction, correction_old, by = c("region"))
# comparison = comparison %>% mutate(ratio = gdppc99.x / gdppc99.y) %>% summarise(mean(ratio), sd(ratio))

# extract 2099 IR level loggdppc, and compute gdppc
# write_csv(covars_from_projection %>% select(c("year", "region", "loggdppc")) %>% filter(year == 2099) %>%
# 			mutate(gdppc = exp(loggdppc)),
# 			paste0(DB_data, '/projection_system_outputs/covariates/', 
#            'temp.csv'))


# do the same for SSP3 low


###########################################
# load covariates from the projection that was actually run
covars_from_projection = read_csv(paste0(output, '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim_low.csv'))
# covars_from_projection = cov_electricity_single_low

# extract 2099 IR level loggdppc, and compute gdppc
correct_gdp = covars_from_projection %>% select(c("year", "region", "loggdppc")) %>%
			mutate(gdppc = exp(loggdppc)) %>%
			select(region, gdppc, year) %>% 
			rename(gdppc_new = gdppc)


wrong_gdp = read_csv(
    paste0(DB_data, '/projection_system_outputs/covariates/', 
           'SSP3-low-IR_level-gdppc-pop-gdp-all-years.csv'))  

# replace gdppc99 with the gdppc we just grabbed from projection
# and multiply with pop to compute gdp99 again 
correction = merge(wrong_gdp, correct_gdp, on = c("region", "year")) %>%
		select(year, region, pop, gdppc, gdppc_new) %>% 
		mutate(gdppc = gdppc_new) %>% 
		mutate(gdp = pop * gdppc) %>%
		select(year, region, pop, gdppc, gdp)


write_csv(correction,
    paste0(DB_data, '/projection_system_outputs/covariates/', 
           'SSP3-low-IR_level-gdppc-pop-gdp-all-years_iso-income.csv'))  


diag = correction %>% mutate(iso = substr(region, 1, 3)) %>% filter(year == 2099)%>%
		group_by(iso) %>% arrange(gdppc) %>%
		select(gdppc, iso) %>% unique()


write_csv(diag,
    paste0('/home/liruixue/diag_low.csv'))  

# length(unique(diag$iso))
# length(unique(diag$gdppc))


# correction_old = read_csv(paste0(DB_data, '/projection_system_outputs/covariates_backup_gdp_correction/', 
#            'SSP3-low-IR_level-gdppc-pop-gdp-all-years_iso-income.csv'))  


# comparison = merge(correction, correction_old, by = c("region"))
# comparison = comparison %>% mutate(ratio = gdppc99.x / gdppc99.y) %>% summarise(mean(ratio), sd(ratio))




#####################check ######################
# load covariates from the projection that was actually run
covars_from_projection = read_csv(paste0(output, '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))

# extract 2099 IR level loggdppc, and compute gdppc
gdp = covars_from_projection %>% select(c("year", "region", "loggdppc"))


covars_from_projection_old = read_csv(paste0(output, '/miscellaneous_backup_before_gdp_correction/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))

# extract 2099 IR level loggdppc, and compute gdppc
gdp = covars_from_projection %>% select(c("year", "region", "loggdppc"))








