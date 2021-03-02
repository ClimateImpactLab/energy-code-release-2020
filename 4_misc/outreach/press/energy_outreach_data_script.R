rm(list=ls())
library(glue)
library(parallel)
cilpath.r:::cilpath()

source(glue("{REPO}/mortality/utils/wrap_mapply.R"))

source(glue("{REPO}/energy-code-release-2020/4_misc/",
    "outreach/press/energy_outreach_data.R"))


# extract files
out = wrap_mapply(  
  time_step="all",
  impact_type="impacts_gj",
  resolution=c("all_IRs", "iso","states","global"), 
  rcp=c("rcp45", "rcp85"),
  stats="mean",
  fuel = c("electricity", "other_energy"),
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=16,
  mc.silent=FALSE
)


out = wrap_mapply(  
  time_step="all",
  impact_type="impacts_pct_gdp",
  resolution=c("all_IRs", "iso","states","global"), 
  rcp=c("rcp45", "rcp85"),
  stats="mean",
  fuel = c("electricity", "other_energy"),
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=16,
  mc.silent=FALSE
)


# extract files
out = wrap_mapply(  
  time_step="all",
  impact_type="impacts_gj",
  resolution=c("states", "iso", "global", "all_IRs"), 
  rcp=c("rcp45", "rcp85"),
  stats="mean",
  fuel = c("electricity", "other_energy"),
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=8,
  mc.silent=FALSE
)


# impacts in quantity
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type=c("impacts_gj", "impacts_kwh"),
  resolution="states", 
  rcp=c("rcp45", "rcp85"),
  stats=c("mean","q50"),
  fuel = "electricity",
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=8,
  mc.silent=FALSE
)


# impacts in pct gdp
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type="impacts_pct_gdp",
  resolution="states", 
  rcp=c("rcp45", "rcp85"),
  stats=c("mean","q50"),
  fuel = "total_energy",
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=1,
  mc.silent=FALSE
)

# impacts in pct gdp
out = wrap_mapply(  
  time_step=c("all", "averaged"),
  impact_type="impacts_pct_gdp",
  resolution="states", 
  rcp=c("rcp45", "rcp85"),
  stats=c("mean","q50"),
  fuel = "total_energy",
  export = TRUE,
  FUN=ProcessImpacts,
  mc.cores=1,
  mc.silent=FALSE
)

