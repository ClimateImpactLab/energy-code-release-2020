# Note - this code should be run from the risingverse (python 3)

rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(haven)
library(tidyr)
library(imputeTS)
cilpath.r:::cilpath()


setwd(paste0(REPO,"/energy-code-release-2020/"))

db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
source_python(paste0(projection.packages, "future_gdp_pop_data.py"))

# load population
pop = read_csv(paste0(output,'/projection_system_outputs/covariates/' ,
    'SSP3_IR_level_population.csv')) %>% mutate(iso = substr(region, 1, 3)) %>% 
    group_by(iso, year) %>%
    summarize(iso_pop = sum(pop))

# gdppc = read_csv(paste0(output,'/projection_system_outputs/covariates/' ,
#     'SSP3_IR_level_gdppc.csv'))
# gdppc = gdppc %>% mutate(lgdppc = log(gdppc))

# load country level income
cov_pixel_interaction= read_csv(paste0("/mnt/CIL_energy/code_release_data_pixel_interaction/", '/miscellaneous/covariates_FD_FGLS_719_Exclude_all-issues_break2_semi-parametric_TINV_clim.csv'))

country_inc = cov_pixel_interaction %>%
        dplyr::select(year, region, loggdppc) %>%
        mutate(iso = substr(region, 1, 3)) %>% 
        group_by(iso, year) %>%
        summarize(iso_lgdppc = mean(loggdppc))

# merge

year_list = seq(2010, 2100, 1)

merged = merge(pop, country_inc, by = c("iso","year")) %>%
    mutate(above_threshold = ifelse(iso_lgdppc > 9.087, 1, 0)) %>% 
    group_by(year) %>%
    summarize(total_pop = sum(iso_pop), 
        high_inc_pop = sum(iso_pop[above_threshold == 1])) %>%
    complete(year = 2010:2100)


merged$total_pop <- na.interpolation(ts(c(merged$total_pop)), option = "linear") 
merged$high_inc_pop <- na.interpolation(ts(c(merged$high_inc_pop)), option = "linear") 

merged = merged %>% mutate(pct = high_inc_pop / total_pop)


write_csv(merged, "/mnt/CIL_energy/code_release_data_pixel_interaction/referee_comments/pct_high_income_pop_upto_2100_linear_interpolation.csv")



