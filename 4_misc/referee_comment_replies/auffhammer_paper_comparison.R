# Auffhammer paper comparison
# Task: compare our results to Auffhammer et al. 2017: 
# percent increase in US electricity consumption due to climate change at 2090 
# (relative to 2012 or 2010). average across non-surrogate climate models.

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
source_python(paste0(projection.packages, "future_gdp_pop_data.py"))

setwd(paste0(REPO))

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))


df = load.median(conda_env = "risingverse-py27",
                proj_mode = '', # '' and _dm are the two options
                region = "USA", # needs to be specified for 
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
                yearlist = 2090,  
                spec = "OTHERIND_electricity",
                grouping_test = "semi-parametric") 

df_pc = df %>% dplyr::filter(!grepl("surrogate",gcm)) %>% select(rcp,year,gcm,iam,value)

pop_usa = read_csv(paste0(output,'/projection_system_outputs/covariates/' ,
	'SSP3_IR_level_population.csv')) %>% dplyr::filter(grepl("USA",region)) %>%
	filter(year == 2090) %>% summarize(country_pop = sum(pop))


df_usa = df_pc %>% mutate(value = value * pop_usa$country_pop) %>%
    group_by(rcp,iam) %>% 
    summarize(mean = mean(value))

df_historical = read.dta13(paste0(REPO, "/energy-code-release-2020",
	"/data/IEA_Merged_long_GMFD.dta"))

df_2010 = df_historical %>% select(year, country, product, pop, load_pc) %>%
	filter(country == "USA", year == 2010) %>%
	mutate(load = pop * load_pc) %>% filter(product == "electricity")

df_result = df_usa %>% mutate(pct = mean / df_2010$load * 100 )

