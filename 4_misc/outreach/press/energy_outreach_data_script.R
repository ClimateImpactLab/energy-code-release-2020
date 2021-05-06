rm(list=ls())
library(glue)
library(parallel)
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
  mc.cores=6,
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
  mc.cores=6,
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
  mc.cores=4,
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
  mc.cores=16,
  mc.silent=FALSE
)


df = read.csv("/mnt/CIL_energy/impacts_outreach/total_energy_impacts_pct_gdp_geography_states_years_averaged_SSP3_low_rcp85_q95.csv")
