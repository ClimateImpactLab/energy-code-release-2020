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
ProcessImpacts(
  time_step="averaged",
  impact_type="impacts_gj",
  resolution="iso", 
  rcp="rcp85",
  stats="mean",
  fuel = "electricity",
  regenerate = FALSE,
  export = TRUE)

# generate all aggregated file stats
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type=c("impacts_gj", "impacts_kwh"),
  resolution=c("states","global","iso"), 
  rcp=c("rcp45", "rcp85"),
  stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
  fuel = c("electricity", "other_energy"),
  regenerate = FALSE,
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=30,
  mc.silent=FALSE
)


# aggregated files impacts in pct gdp
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type="impacts_pct_gdp",
  resolution=c("states","global","iso"), 
  rcp=c("rcp45", "rcp85"),
  stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
  fuel = "total_energy",
  regenerate = FALSE,
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=30,
  mc.silent=FALSE
)


# IR level quantity 
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type=c("impacts_gj", "impacts_kwh"),
  resolution=c("all_IRs"), 
  rcp=c("rcp45", "rcp85"),
  stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
  fuel = c("electricity","other_energy"),
  regenerate = FALSE,
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=30,
  mc.silent=FALSE
)


# IR level impacts in pct gdp
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type="impacts_pct_gdp",
  resolution=c("all_IRs"), 
  rcp=c("rcp45","rcp85"),
  stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
  fuel = "total_energy",
  regenerate = FALSE,
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=24,
  mc.silent=FALSE
)


# filter 500k cities from all IR level files

path = "/mnt/CIL_energy/impacts_outreach/"
setwd(path)

all_IRs_files = Sys.glob("*all_IRs*.csv")

cities_500k = read_csv("~/repos/energy-code-release-2020/data/500k_cities.csv")	%>% 
	select(city, country, Region_ID)

cities_500k_regions = unlist(cities_500k$Region_ID)



filter_500k_cities <- function(path, cities_500k, cities_500k_regions) {
  save_path = gsub("all_IRs", "500k_cities", path)
  print(save_path)  

  if (!file.exists(save_path)) {
    print("generating")
    dt = vroom(path)
    dt = dt %>% filter(all_IRs %in% cities_500k_regions) %>%
    	rename(Region_ID = all_IRs)
    dt=setkey(as.data.table(dt),Region_ID)
    cities_500k_lookup = setkey(as.data.table(cities_500k), Region_ID)
    merged = merge(cities_500k, dt)
    write_csv(dt, save_path)
  }
}

# testing function
# filter_500k_cities(all_IRs_files[1], cities_500k, cities_500k_regions)

# # run all files
out = wrap_mapply(  
  path = all_IRs_files,
  regions_500k_cities = regions_500k_cities,
  FUN=filter_500k_cities,
  mc.cores=5,
  mc.silent=FALSE
)


