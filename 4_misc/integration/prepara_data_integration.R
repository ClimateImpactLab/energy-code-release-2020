# Prepare code release data, and save it on Dropbox / Synology...
# Note - you need to be in the `risingverse-py27` conda environment to run this code for the first time (ie to extract impacts using quantiles.py)

rm(list = ls())
library(readr)
library(dplyr)
library(reticulate)
library(parallel)
library(miceadds)
library(haven)
library(tidyr)
cilpath.r:::cilpath()


db = '/mnt/CIL_energy/'
output = '/mnt/CIL_energy/code_release_data_pixel_interaction/'

data_dir = paste0(db,'/code_release_data_pixel_interaction/')

output = paste0(db, 
	'/code_release_data_pixel_interaction/projection_system_outputs/damage_function_estimation')
dir = paste0('/shares/gcp/social/parameters/energy_pixel_interaction/extraction/',
				'multi-models/rationalized_code/break2_Exclude_all-issues_semi-parametric/')

# Source codes that help us load projection system outputs
# Make sure you are in the risingverse-py27 for this... 
projection.packages <- paste0(REPO,
	"/energy-code-release-2020/2_projection/0_packages_programs_inputs/extract_projection_outputs/")
miceadds::source.all(paste0(projection.packages,"load_projection/"))

source(glue("{REPO}/mortality/utils/wrap_mapply.R"))

projection_path = "/shares/gcp/outputs/energy_pixel_interaction/impacts-blueghost/median_OTHERIND_electricity_TINV_clim_GMFD/median/"

gcms = list()

gcms$"rcp45" = c(list.dirs(path = paste0(projection_path, "rcp45/"), 
  full.names = FALSE,
  recursive = FALSE))

gcms$"rcp85" = c(list.dirs(path = paste0(projection_path, "rcp85/"), 
  full.names = FALSE,
  recursive = FALSE))


setwd("~/repos/prospectus-tools/gcp/extract")

extract_file <- function(gcm, ssp, rcp, dm, iam) {
	# browser()

	command = paste0("nohup python -u quantiles.py ",
		"/home/liruixue/repos/energy-code-release-2020",
		"/projection_inputs/configs/GMFD/TINV_clim/",
		"break2_Exclude/semi-parametric/Extraction_Configs",
		"/sacagawea/damage/integration/values_integration/levels/",
		"median/energy-extract-damage-levels-integration-median_OTHERIND_total_energy", dm, ".yml  ",
		"--only-ssp=", ssp, "  --only-rcp=", rcp, "  --only-models=", gcm, 
		"  --only-iam=",iam, "  --do-gcmweights=no  ",
		"--suffix=_",iam, "_", gcm, "_damage-integration_median_fulladapt-levels", dm, "_integration ",
		"FD_FGLS_inter_OTHERIND_electricity_TINV_clim-integration-levels ",
		"-FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-integration-levels ",
		"FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-integration-levels ",
		"-FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-integration-levels ")

	print(command)
	system(command)
}

# both rcps, median
out = wrap_mapply(  
  gcm = gcms$rcp45,
  rcp="rcp45",
  iam = c("high","low"),
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  FUN=extract_file,
  dm = "",
  mc.cores=10,
  mc.silent=FALSE
)

out = wrap_mapply(  
  gcm = gcms$rcp85,
  rcp="rcp85",
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  dm = "",
  iam = c("high","low"),
  FUN=extract_file,
  mc.cores=10,
  mc.silent=FALSE
)

# both rcps, delta methods
out = wrap_mapply(  
  gcm = gcms$rcp45,
  rcp="rcp45",
  iam = c("high","low"),
  dm = "_dm",
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  FUN=extract_file,
  mc.cores=2,
  mc.silent=FALSE
)

out = wrap_mapply(  
  gcm = gcms$rcp85,
  rcp="rcp85",
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  dm = "_dm",
  iam = c("high","low"),
  FUN=extract_file,
  mc.cores=2,
  mc.silent=FALSE
)


