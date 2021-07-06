rm(list=ls())
library(glue)
library(parallel)
library(vroom)


# (1) 
# would be nice to have this ready to be run as much as possible. 
# Omitting the repo path problem, at least uncommenting stuff and have the script
# be such that if it is run correctly, it produces all what's needed an in the outreach data, without
# testing stuff around. 


# (2) 
# the global files look a little weird, not sure that was the case for mortality, but just wanted to flag. E.g. : 
# Global  year_2020 year_2021
#  0.022236756 0.022411465


# (3)
# I noticed a lot of empty rows in the country files. For example : 
# " unit_total_energy_impacts_pct_gdp_geography_country_level_years_all_rcp85_SSP3_quantiles_q5.csv"
# is this normal ?

REPO <- "/home/liruixue/repos"

source(glue("{REPO}/mortality/utils/wrap_mapply.R"))

source(glue("{REPO}/energy-code-release-2020/4_misc/",
    "outreach/press/energy_outreach_data.R"))


# # # testing function
# out = ProcessImpacts(
#   time_step="all",
#   impact_type="impacts_pct_gdp",
#   resolution="states", 
#   rcp="rcp85",
#   stats="q50",
#   fuel = "total_energy",
#   regenerate = FALSE,
#   export = FALSE)





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
##########################################################
##########################################################

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
  mc.cores=40,
  mc.silent=FALSE
)



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
#   mc.cores=60,
#   mc.silent=FALSE
# )


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
  mc.cores=40,
  mc.silent=FALSE
)


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
#   mc.cores=60,
#   mc.silent=FALSE
# )



# Here you're iterating over all IR files to pick cities and save aside for the 'city' style output right?
# Could wrap this in one single function, so that it looks as clean as the above ? Or other suggestion, keep only
# the last call (wrap_mapply) and the above moved to energy_outreach_data.R.  Since this is suppoed to be only a script (calling stuff). 

# filter 500k cities from all IR level files

path = "/mnt/CIL_energy/impacts_outreach/"
setwd(path)

all_IRs_files = list.files(path = path, 
  pattern = "geography_impact_regions",
  recursive = TRUE,
  include.dirs = TRUE)

cities_500k = read_csv("~/repos/energy-code-release-2020/data/500k_cities.csv") %>% 
  select(city, country, Region_ID)

cities_500k_regions = unlist(cities_500k$Region_ID)

filter_500k_cities <- function(path, overwrite, cities_500k_arg = cities_500k, cities_500k_regions_arg = cities_500k_regions) {
  save_path = gsub("impact_regions", "500kcities", path)
  print(save_path)  
  # browser()
  if ((!file.exists(save_path)) || overwrite ) {
    dir.create(dirname(save_path), recursive = TRUE, showWarnings = FALSE)
    print("generating")
    dt = vroom(path)
    dt = dt %>% filter(Region_ID %in% cities_500k_regions_arg) 
    dt=setkey(as.data.table(dt),Region_ID)
    cities_500k_lookup = setkey(as.data.table(cities_500k_arg), Region_ID)
    merged = merge(cities_500k_arg, dt)
    write_csv(dt, save_path)
    return(dt)
  }
  else return(glue("{save_path} exists"))
}

# testing function
# dt = filter_500k_cities(all_IRs_files[3], cities_500k, cities_500k_regions)

# run over all files
out = wrap_mapply(  
  path = all_IRs_files,
  overwrite = TRUE,
  FUN=filter_500k_cities,
  mc.cores=40,
  mc.silent=FALSE
)




