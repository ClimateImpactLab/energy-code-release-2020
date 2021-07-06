# Compare our results to Li et al. 2019: who construct end-of-century
 # damage function for Shanghai impact region (with and without 
 # surrogate climate models) in terms of total electricity consumption 
 # as percent of current consumption.

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
# CHN.25
# CHN.25.262.1764 - Shanghai Proper 


# source of data: (electricity consumption of residential and productive use)
# /mnt/CIL_energy/China/china_energy_consumption_data
shanghai_2012_total = (18.738 + 78.625) * 100000000 * 0.0036


pop_shanghai = read_csv(paste0(output,'/projection_system_outputs/covariates/' ,
	'SSP3_IR_level_population.csv')) %>% dplyr::filter(substr(region,1,6) == "CHN.25") %>%
	filter(year == 2095) %>% 
        summarize(pop = sum(pop))
        # 2097 pop not available


impact_shanghai = load.median(conda_env = "risingverse-py27",
                proj_mode = '', # '' and _dm are the two options
                region = "CHN.25", # needs to be specified for 
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
                yearlist = as.character(seq(2080,2099,1)), ,  
                spec = "OTHERIND_electricity",
                grouping_test = "semi-parametric")  %>% 
	select(rcp,year,gcm,iam,value)  %>%
	mutate(value = value * pop_shanghai$pop / shanghai_2012_total * 100) # convert to percentage

impact_shanghai_nosurrogate = impact_shanghai %>% dplyr::filter(!grepl("surrogate",gcm))
write_csv(impact_shanghai, "/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/li_et_al_shanghai_comparison/shanghai_impact_2097_electricity.csv")

write_csv(impact_shanghai_nosurrogate, "/home/liruixue/repos/energy-code-release-2020/figures/referee_comments/li_et_al_shanghai_comparison/shanghai_impact_no_srg_2097_electricity.csv")

