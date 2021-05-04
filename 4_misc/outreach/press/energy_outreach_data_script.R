rm(list=ls())
library(glue)
library(parallel)
cilpath.r:::cilpath()

source(glue("{REPO}/mortality/utils/wrap_mapply.R"))

source(glue("{REPO}/energy-code-release-2020/4_misc/",
    "outreach/press/energy_outreach_data.R"))



ProcessImpacts(time_step = "all", 
    impact_type="impacts_gj",
  resolution=c("all_IRs"), 
  rcp=c("rcp45"),
  stats="mean",
  fuel = c("electricity"),
  export = TRUE,
  regenerate = FALSE)




# # extract files - levels quantity
out = wrap_mapply(  
  time_step="all",
  impact_type="impacts_gj",
  resolution=c("all_IRs"), 
  rcp=c("rcp45", "rcp85"),
  stats="mean",
  fuel = c("electricity", "other_energy"),
  export = TRUE,
  regenerate = FALSE,
  FUN=ProcessImpacts,
  mc.cores=1,
  mc.silent=FALSE
)

###########################################################
###########################################################
# extract files - aggregated quantity - electricity all done
# ***** done! 
out = wrap_mapply(  
  time_step="all",
  impact_type="impacts_gj",
  resolution=c("states","global","iso"), 
  rcp=c("rcp45", "rcp85"),
  stats="mean",
  fuel = c("electricity","other_energy"),
  export = TRUE,
  regenerate = FALSE,
  FUN=ProcessImpacts,
  mc.cores=6,
  mc.silent=FALSE
)

# extract files - aggregated dollar - done
out = wrap_mapply(  
  time_step="all",
  impact_type="impacts_pct_gdp",
  resolution=c("global", "iso"), 
  rcp=c("rcp45"),
  stats="mean",
  fuel = c("total_energy"),
  export = TRUE,
  regenerate = TRUE,
  FUN=ProcessImpacts,
  mc.cores=2,
  mc.silent=FALSE
)

# **** done! 
###########################################################
###########################################################


# # extract files - levels quantity - other_energy 
# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_gj",
#   resolution=c("all_IRs"), 
#   rcp=c("rcp45"),
#   stats="mean",
#   fuel = c("electricity", "other_energy"),
#   export = TRUE,
#   regenerate = FALSE,
#   FUN=ProcessImpacts,
#   mc.cores=1,
#   mc.silent=FALSE
# )
# # only extracted until 1982
# df = read_csv("/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/median_OTHERIND_other_energy_TINV_clim_GMFD/SSP3-rcp85_impactpc_median_fulluncertainty_low_SSP3_rcp85_fulladapt.csv")

# # extract files - levels dollar - error 

# # [1] "Loading file: /shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/total_energy/SSP3-rcp85_damage-price014_median_fulluncertainty_low_SSP3_rcp85_fulladapt-levels.csv"
# # Error: Problem with `filter()` input `..1`.
# # ✖ 'match' requires vector arguments
# # ℹ Input `..1` is `year %in% yearlist`.

# df = read_csv("/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/total_energy/SSP3-rcp85_damage-price014_median_fulluncertainty_low_SSP3_rcp85_fulladapt-levels.csv")

# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_pct_gdp",
#   resolution=c("all_IRs"), 
#   rcp=c("rcp85"),
#   stats="mean",
#   fuel = c("total_energy"),
#   export = TRUE,
#   regenerate = FALSE,
#   FUN=ProcessImpacts,
#   mc.cores=1,
#   mc.silent=FALSE
# )



# # ***************extract files****************

# # extract files - levels quantity - electricity -  done
# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_gj",
#   resolution=c("all_IRs"), 
#   rcp=c("rcp45", "rcp85"),
#   stats="mean",
#   fuel = c("electricity"),
#   export = TRUE,
#   regenerate = FALSE,
#   FUN=ProcessImpacts,
#   mc.cores=1,
#   mc.silent=FALSE
# )


# # extract files - levels quantity - other_energy rcp45 -  done
# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_gj",
#   resolution=c("all_IRs"), 
#   rcp=c("rcp45"),
#   stats="mean",
#   fuel = c("other_energy"),
#   export = TRUE,
#   regenerate = FALSE,
#   FUN=ProcessImpacts,
#   mc.cores=1,
#   mc.silent=FALSE
# )


# # extract files - levels quantity - gdp rcp45 -  done
# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_pct_gdp",
#   resolution=c("all_IRs"), 
#   rcp=c("rcp45"),
#   stats="mean",
#   fuel = c("total_energy"),
#   export = TRUE,
#   regenerate = FALSE,
#   FUN=ProcessImpacts,
#   mc.cores=1,
#   mc.silent=FALSE
# )



# out = wrap_mapply(  
#   time_step="all",
#   impact_type="impacts_gj",
#   resolution=c("states","global","iso"), 
#   rcp=c("rcp45", "rcp85"),
#   stats="mean",
#   fuel = c("other_energy"),
#   export = TRUE,
#   regenerate = TRUE,
#   FUN=ProcessImpacts,
#   mc.cores=6,
#   mc.silent=FALSE
# )



df = read_csv("/shares/gcp/social/parameters/energy_pixel_interaction/extraction/multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/TINV_clim_GMFD/median_OTHERIND_electricity_TINV_clim_GMFD/SSP3-rcp45_impactpc_median_fulluncertainty_low_fulladapt.csv")




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
  mc.cores=32,
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
  regenerate = TRUE,
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=32,
  mc.silent=FALSE
)


# IR level electricity 
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type=c("impacts_gj", "impacts_kwh"),
  resolution=c("all_IRs"), 
  rcp=c("rcp45", "rcp85"),
  stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
  fuel = c("electricity"),
  regenerate = FALSE,
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=16,
  mc.silent=FALSE
)


# IR level other energy - rcp45
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type="impacts_gj",
  resolution=c("all_IRs"), 
  rcp=c("rcp45"),
  stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
  fuel = c("other_energy"),
  export = TRUE,
  regenerate = FALSE,
  FUN=ProcessImpacts,
  mc.cores=16,
  mc.silent=FALSE
)

# IR level impacts in pct gdp - rcp45
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type="impacts_pct_gdp",
  resolution=c("all_IRs"), 
  rcp=c("rcp45"),
  stats=c("mean", "q5", "q17", "q50", "q83", "q95"),
  fuel = "total_energy",
  regenerate = FALSE,
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=16,
  mc.silent=FALSE
)


