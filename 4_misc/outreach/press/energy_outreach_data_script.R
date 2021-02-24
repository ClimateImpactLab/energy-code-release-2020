rm(list=ls())
library(glue)
library(parallel)
cilpath.r:::cilpath()

source(glue("{REPO}/mortality/utils/wrap_mapply.R"))


# unit testing

args=list(
  years="all",
  impact_type="impacts_gj",
  resolution="all_IRs",
  rcp="rcp85",
  stats="mean",
  fuel = "electricity",
  export = TRUE
  )

source(glue("{REPO}/energy-code-release-2020/4_misc/",
    "outreach/press/energy_outreach_data.R"))

test=do.call(ProcessImpacts,args)
head(test)

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
