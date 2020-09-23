# energy numbers for IPCC AR6
# ISO level electricity and other energy impacts in 2099 for RCP85 SSP3 
# for all African countries in GJ. 
# Please include the average change for electricity and other energy 
# across all ISOs in Africa (should be straight out of James' aggregated files, 
# which aggregate into an "Africa" region - let me know if you have questions).
# ISO level total % of GDP impacts in 2099 for RCP85 SSP3, 
# summed across fuel types, for all African countries. 
# Please also include the Africa average from the aggregated files.
# Same as the above for labor -- both high risk and low risk minutes lost, 
# and the total measured in % of GDP.


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


dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
                    'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')


# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
setwd(REPO)

# Source codes that help us load projection system outputs
miceadds::source.all(paste0(projection.packages,"load_projection/"))

data = '/shares/gcp/social/parameters/energy_pixel_interaction/extraction/'

root =  paste0(REPO, "/energy-code-release-2020")
output = "/mnt/CIL_energy/code_release_data_pixel_interaction/projection_system_outputs/"

source("/home/liruixue/projection_repos/post-projection-tools/mapping/imgcat.R") #this redefines the way ggplot plots. 
source(paste0(root, "/3_post_projection/0_utils/time_series.R"))



# get african countries

hier = read_csv("/mnt/GCP_Reanalysis/cross_sector/hierarchy.csv", skip = 31)
african_regions = hier %>% filter(parent_key == "U002") %>% pull(region_key) # this gives us the big regions within africa

# get the african countries, which are one level below african regions
african_countries = hier %>% filter(parent_key %in% c(african_regions))# | region_key == "U002")
# hier %>% filter(region_key == "U002") --- this is the code for Africa in hierarchy.csv, but it's not in the aggregated files
african_country_codes = african_countries %>% pull(region_key)



# get IR level population and gdp, and sum them by ISO
african_IRs = hier %>% filter(parent_key %in% african_country_codes) %>%
   select(region_key, parent_key, name) %>% rename(region = region_key)

# this is the output from other part of the repo
gdp_pop = read_csv(paste0(output, '/covariates/', 
  'SSP3-high-IR_level-gdppc_pop-2099.csv'))
gdp_pop_iso = merge(gdp_pop, african_IRs, by = "region") %>% 
    group_by(parent_key) %>% 
    summarize(iso_gdp99 = sum(gdp99), iso_pop99 = sum(pop99)) %>%
    rename(region = parent_key)




# extract electricity impactpc
command = paste0("python -u /home/liruixue/repos/prospectus-tools/gcp/extract/quantiles.py ",
  "/home/liruixue/repos/energy-code-release-2020/projection_inputs/configs",
  "/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea",
  "/impactpc/climate/aggregated/median/",
  "energy-extract-impactpc-aggregated-median_OTHERIND_electricity.yml ",
  "--only-iam=high  --suffix=_impactpc_median_high_fulladapt-aggregated_ipcc ",
  "--only-ssp=SSP3  --only-rcp=rcp85 ",
  "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-aggregated ",
  "-FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-aggregated ")
system(command)

# extract other energy impactpc
command = paste0("python -u /home/liruixue/repos/prospectus-tools/gcp/extract/quantiles.py ",
  "/home/liruixue/repos/energy-code-release-2020/projection_inputs/configs",
  "/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea",
  "/impactpc/climate/aggregated/median/",
  "energy-extract-impactpc-aggregated-median_OTHERIND_other_energy.yml ",
  "--only-iam=high  --suffix=_impactpc_median_high_fulladapt-aggregated_ipcc ",
  "--only-ssp=SSP3  --only-rcp=rcp85 ",
  "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-aggregated ",
  "-FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-aggregated ")
system(command)


# read in output of the previous command
elec_impactpc = read_csv("/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/median_OTHERIND_electricity_TINV_clim_GMFD/SSP3-rcp85_impactpc_median_high_fulladapt-aggregated_ipcc.csv")
afr_elec_impactpc = elec_impactpc %>%
 filter(region %in% african_country_codes) %>%
 filter(year == 2099) %>%
 select(region, year, mean) %>%
 rename(impactpc_elec = mean)
# the african mean is a weighted mean of the country values (pop weights)
elec_afr_mean = merge(afr_elec_impactpc, gdp_pop_iso, by = "region") %>% 
  summarize(african_mean_impactpc_elec = weighted.mean(impactpc_elec, iso_pop99)) 


# read in output of the previous command
other_impactpc = read_csv("/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/median_OTHERIND_other_energy_TINV_clim_GMFD/SSP3-rcp85_impactpc_median_high_fulladapt-aggregated_ipcc.csv")
afr_other_impactpc = other_impactpc %>%
 filter(region %in% african_country_codes) %>%
 filter(year == 2099) %>%
 select(region, year, mean)%>%
 rename(impactpc_other = mean)

# the african mean is a weighted mean of the country values (pop weights)
other_afr_mean = merge(afr_other_impactpc, gdp_pop_iso, by = "region") %>%
 summarize(african_mean = weighted.mean(impactpc_other, iso_pop99)) 


# get values of the total damages

command = paste0("python -u /home/liruixue/repos/prospectus-tools/gcp/extract/quantiles.py ",
  "/home/liruixue/repos/energy-code-release-2020/projection_inputs/configs",
  "/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea",
  "/damage/price014/climate/aggregated/median/",
  "energy-extract-damage-aggregated-price014-median_OTHERIND_total_energy.yml ",
  "--only-iam=high  --suffix=_damage-price014_median_high_fulladapt-aggregated_ipcc ",
  "--only-ssp=SSP3  --only-rcp=rcp85 ",
  "FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-aggregated ",
  "-FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-aggregated ",
  "FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-aggregated ",
  "-FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-aggregated")
system(command)

# read in output of the previous command
damages = read_csv(paste0("/shares/gcp/social/parameters/energy_pixel_interaction/extraction",
  "/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD",
  "/total_energy/SSP3-rcp85_damage-price014_median_high_fulladapt-aggregated_ipcc.csv"))

afr_damages = damages %>% 
 filter(region %in% african_country_codes) %>%
 filter(year == 2099) %>%
 select(region, year, mean) %>%
 rename(dollar_damages = mean)

afr_pct_gdp = merge(afr_damages, gdp_pop_iso, by = "region") %>% 
        mutate(pct_gdp = dollar_damages / iso_gdp99)

pct_gdp_mean = afr_pct_gdp %>% summarize(african_mean_pct_gdp = weighted.mean(pct_gdp, iso_gdp99)) 




# output them into a file

output_file =  Reduce(function(x,y) merge(x = x, y = y, by = c("region","year")), 
       list(afr_pct_gdp, afr_other_impactpc, afr_elec_impactpc))
write_csv(output_file, paste0(output,"/ipcc_data/african_countries_impactpc_pctgdp.csv"))

print(elec_afr_mean)
print(other_afr_mean)
print(pct_gdp_mean)