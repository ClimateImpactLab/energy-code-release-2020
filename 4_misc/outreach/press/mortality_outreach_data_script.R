rm(list=ls())
library(glue)
library(parallel)
cilpath.r:::cilpath()

source(glue("{REPO}/mortality/2_projection/",
    "y_diagnostics/comms/impacts_outreach/mortality_outreach_data.R"))
source(glue("{REPO}/mortality/utils/wrap_mapply.R"))


# Death rates

# ISO-level

out = wrap_mapply(
    unit=c("mortality_risk","change_in_deathrate"),
    rcp=c("rcp45","rcp85"),
    years=c("all", "averaged"),
    qtile=c("mean","q5","q17","q83","q95","q50"),
    mc.cores=32,
    mc.silent=FALSE,
    export=TRUE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        geography="ISO_code",
        ssp="SSP3"))

# Impact Regions.

out = wrap_mapply(
    unit=c("mortality_risk","change_in_deathrate"),
    rcp=c("rcp45","rcp85"),
    years=c("all"),
    qtile=c("mean"),
    mc.cores=32,
    mc.silent=FALSE,
    export=TRUE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        geography="Region_ID",
        ssp="SSP3"))

# States.

out = wrap_mapply(
    unit=c("mortality_risk","change_in_deathrate"),
    rcp=c("rcp45","rcp85"),
    years=c("all", "averaged"),
    qtile=c("mean","q5","q17","q83","q95","q50"),
    mc.cores=32,
    mc.silent=FALSE,
    export=TRUE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        geography="state_abbrev",
        ssp="SSP3"))

# Global.

out = wrap_mapply(
    unit=c("mortality_risk","change_in_deathrate"),
    rcp=c("rcp45","rcp85"),
    years=c("all", "averaged"),
    qtile=c("mean","q5","q17","q83","q95","q50"),
    mc.cores=32,
    mc.silent=FALSE,
    export=TRUE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        geography="Global",
        ssp="SSP3"))

# Damages, covariates, income, and population.

# Global, ISO-level, IR-level for all years

# Damages, adaptation costs in millions 2019$
out = wrap_mapply(
    geography=c("Global", "ISO_code", "Region_ID"),
    unit=c("adaptation_cost", "damages"),
    rcp=c("rcp45","rcp85"),
    years=c("all"),
    qtile=c("mean"),
    mc.cores=10,
    mc.silent=FALSE,
    export=TRUE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        ssp="SSP3"))

# Income, population
out = wrap_mapply(
    geography=c("Global", "ISO_code", "Region_ID"),
    unit=c("income_per_capita", "population_projections"),
    years=c("all"),
    mc.cores=10,
    export=TRUE,
    mc.silent=FALSE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        ssp="SSP3"))

out = wrap_mapply(
    geography=c("ISO_code", "Region_ID"),
    unit=c("long_run_av_temp_C"),
    rcp=c("rcp45","rcp85"),
    years=c("all"),
    mc.cores=10,
    export=TRUE,
    mc.silent=FALSE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        ssp="SSP3"))

# Global, ISO-level, IR-level, State level averaged years.

# Damages, percent of GDP 
out = wrap_mapply(
    geography=c("Global", "state_abbrev"),
    unit=c("damages_percent_GDP"),
    rcp=c("rcp45","rcp85"),
    years=c("averaged"),
    qtile=c("mean","q05","q17","q50","q83","q95"),
    mc.cores=10,
    mc.silent=FALSE,
    export=TRUE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        ssp="SSP3"))

# Damages, percent GDP (fewer quantiles)
out = wrap_mapply(
    geography=c("Region_ID", "ISO_code"),
    unit=c("damages_percent_GDP"),
    rcp=c("rcp45","rcp85"),
    years=c("averaged"),
    qtile=c("mean","q50"),
    mc.cores=10,
    mc.silent=FALSE,
    export=TRUE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        ssp="SSP3"))


out = wrap_mapply(
    geography=c("ISO_code"),
    unit=c("damages_percent_GDP"),
    rcp=c("rcp45","rcp85"),
    years=c("averaged"),
    qtile=c("mean","q05","q17","q50","q83","q95"),
    mc.cores=10,
    mc.silent=FALSE,
    export=TRUE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        ssp="SSP3"))

# Income / pop
out = wrap_mapply(
    geography=c("ISO_code"),
    unit=c("income_per_capita", "population_projections"),
    years=c("averaged"),
    mc.cores=10,
    export=TRUE,
    mc.silent=FALSE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        ssp="SSP3"))

out = wrap_mapply(
    geography=c("ISO_code", "Global", "US_states"),
    unit=c("adaptation_cost"),
    rcp=c("rcp45","rcp85"),
    years=c("averaged"),
    qtile=c("mean","q05","q17","q50","q83","q95"),
    mc.cores=10,
    mc.silent=FALSE,
    export=TRUE,
    FUN=ProcessImpacts,
    MoreArgs=list(
        ssp="SSP3"))

# unit testing
# undebug(ProcessImpacts)
# undebug(get_mortality_impacts)
# undebug(ConstructDF)

# args=list(unit="mortality_risk",
#   rcp="rcp85",
#   years="averaged",
#   qtile="mean",
#   geography="state_abbrev",
#   ssp="SSP3")


# test=do.call(ProcessImpacts,args)
