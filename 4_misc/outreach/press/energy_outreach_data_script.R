rm(list=ls())
library(glue)
library(parallel)
library(vroom)

cilpath.r:::cilpath()

source(glue("{REPO}/mortality/utils/wrap_mapply.R"))

source(glue("{REPO}/energy-code-release-2020/4_misc/",
    "outreach/press/energy_outreach_data.R"))



# ###########################################################
# ###########################################################
# # extract files - aggregated quantity - electricity all done
# # ***** done! 
# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_gj",
#   resolution=c("states","global","iso"), 
#   rcp=c("rcp45", "rcp85"),
#   stats="mean",
#   fuel = c("electricity","other_energy"),
#   export = TRUE,
#   regenerate = FALSE,
#   FUN=ProcessImpacts,
#   mc.cores=6,
#   mc.silent=FALSE
# )

# # extract files - aggregated dollar - done
# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_pct_gdp",
#   resolution=c("global", "iso"), 
#   rcp=c("rcp45"),
#   stats="mean",
#   fuel = c("total_energy"),
#   export = TRUE,
#   regenerate = FALSE,
#   FUN=ProcessImpacts,
#   mc.cores=2,
#   mc.silent=FALSE
# )



# # # extract files - levels quantity
# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_gj",
#   resolution=c("all_IRs"), 
#   rcp=c("rcp45", "rcp85"),
#   stats="mean",
#   fuel = c("electricity", "other_energy"),
#   export = TRUE,
#   regenerate = FALSE,
#   FUN=ProcessImpacts,
#   mc.cores=1,
#   mc.silent=FALSE
# )


# # # extract files - levels dollar

# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_pct_gdp",
#   resolution=c("all_IRs"), 
#   rcp=c("rcp45", "rcp85"),
#   stats="mean",
#   fuel = c("total_energy"),
#   export = TRUE,
#   regenerate = FALSE,
#   FUN=ProcessImpacts,
#   mc.cores=1,
#   mc.silent=FALSE
# )


# **** done! 
###########################################################
###########################################################


# # generate all aggregated file stats
# out = wrap_mapply(  
#   time_step=c("all", "averaged"),
#   impact_type=c("impacts_gj", "impacts_kwh"),
#   resolution=c("states","global","iso"), 
#   rcp=c("rcp45", "rcp85"),
#   stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
#   fuel = c("electricity", "other_energy"),
#   regenerate = FALSE,
#   export = TRUE,
#   FUN=ProcessImpacts,
#   mc.cores=6,
#   mc.silent=FALSE
# )


# # aggregated files impacts in pct gdp
# out = wrap_mapply(  
#   time_step=c("all", "averaged"),
#   impact_type="impacts_pct_gdp",
#   resolution=c("states","global","iso"), 
#   rcp=c("rcp45", "rcp85"),
#   stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
#   fuel = "total_energy",
#   regenerate = FALSE,
#   export = TRUE,
#   FUN=ProcessImpacts,
#   mc.cores=6,
#   mc.silent=FALSE
# )


# # IR level quantity 
# out = wrap_mapply(  
#   time_step=c("all", "averaged"),
#   impact_type=c("impacts_gj", "impacts_kwh"),
#   resolution=c("all_IRs"), 
#   rcp=c("rcp45", "rcp85"),
#   stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
#   fuel = c("electricity","other_energy"),
#   regenerate = FALSE,
#   export = TRUE,
#   FUN=ProcessImpacts,
#   mc.cores=4,
#   mc.silent=FALSE
# )


# # IR level impacts in pct gdp
# out = wrap_mapply(  
#   time_step=c("all", "averaged"),
#   impact_type="impacts_pct_gdp",
#   resolution=c("all_IRs"), 
#   rcp=c("rcp45","rcp85"),
#   stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
#   fuel = "total_energy",
#   regenerate = FALSE,
#   export = TRUE,
#   FUN=ProcessImpacts,
#   mc.cores=16,
#   mc.silent=FALSE
# )


# filter 500k cities from all IR level files

path = "/mnt/CIL_energy/impacts_outreach/"
setwd(path)
# all_IRs_files = Sys.glob("*all_IRs*.csv")
# regions_500k_cities = read_csv("~/repos/energy-code-release-2020/data/500k_cities.csv") %>%
#   select(Region_ID)
# regions_500k_cities = unlist(regions_500k_cities)

# filter_500k_cities <- function(path, regions_500k_cities) {
#   save_path = gsub("all_IRs", "500k_cities", path)
#   print(save_path)  

#   if (!file.exists(save_path)) {
#     print("generating")
#     dt = vroom(path)
#     dt = dt %>% filter(all_IRs %in% regions_500k_cities)
#     write_csv(dt, save_path)
#   }
# }

# # testing function
# # filter_500k_cities(all_IRs_files[1], regions_500k_cities)

# # run all files
# out = wrap_mapply(  
#   path = all_IRs_files,
#   regions_500k_cities = regions_500k_cities,
#   FUN=filter_500k_cities,
#   mc.cores=5,
#   mc.silent=FALSE
# )


# check values
dt = vroom("electricity_impacts_gj_geography_global_years_all_SSP3_low_rcp85_q95.csv")
dt = vroom("other_energy_impacts_gj_geography_global_years_all_SSP3_low_rcp85_mean.csv")

dt = vroom("total_energy_impacts_pct_gdp_geography_global_years_all_SSP3_low_rcp85_mean.csv")

dt = vroom("other_energy_impacts_kwh_geography_global_years_all_SSP3_low_rcp85_mean.csv")

dt = vroom("other_energy_impacts_gj_geography_global_years_averaged_SSP3_low_rcp85_mean.csv")

dt = vroom("other_energy_impacts_gj_geography_iso_years_all_SSP3_low_rcp85_mean.csv")
dt = vroom("other_energy_impacts_gj_geography_states_years_all_SSP3_low_rcp85_mean.csv")
dt = vroom("other_energy_impacts_gj_geography_states_years_all_SSP3_low_rcp85_q5.csv")


dt = vroom("other_energy_impacts_gj_geography_all_IRs_years_all_SSP3_low_rcp85_q5.csv")
