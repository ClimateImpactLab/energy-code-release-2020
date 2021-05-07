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
		"/sacagawea/damage/price014/values_press/levels/",
		"median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy", dm, ".yml  ",
		"--only-ssp=", ssp, "  --only-rcp=", rcp, "  --only-models=", gcm, 
		"  --only-iam=",iam, "  --do-gcmweights=no  ",
		"--suffix=_",iam, "_", gcm, "_damage-price014_median_fulladapt-levels", dm, "_press ",
		"FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels ",
		"-FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels ",
		"FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels ",
		"-FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels ")

	print(command)
	system(command)
}

out = wrap_mapply(  
  gcm = gcms$rcp45,
  rcp="rcp45",
  iam = c("high","low"),
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  FUN=extract_file,
  dm = "",
  mc.cores=34,
  mc.silent=FALSE
)

out = wrap_mapply(  
  gcm = gcms$rcp85,
  rcp="rcp85",
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  dm = "",
  iam = c("high","low"),
  FUN=extract_file,
  mc.cores=34,
  mc.silent=FALSE
)


out = wrap_mapply(  
  gcm = gcms$rcp45,
  rcp="rcp45",
  iam = c("high","low"),
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  FUN=extract_file,
  dm = "_dm",
  mc.cores=34,
  mc.silent=FALSE
)

out = wrap_mapply(  
  gcm = gcms$rcp85,
  rcp="rcp85",
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  dm = "_dm",
  iam = c("high","low"),
  FUN=extract_file,
  mc.cores=34,
  mc.silent=FALSE
)


out = wrap_mapply(  
  gcm = gcms$rcp45,
  rcp="rcp45",
  iam = c("high","low"),
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  FUN=extract_file,
  dm = "_dm",
  mc.cores=34,
  mc.silent=FALSE
)


out = wrap_mapply(  
  gcm = gcms$rcp85,
  rcp="rcp85",
  iam = c("high","low"),
  ssp = c("SSP1","SSP2","SSP3","SSP4","SSP5"),
  FUN=extract_file,
  dm = "_dm",
  mc.cores=34,
  mc.silent=FALSE
)


# extract_file(gcm = "surrogate_GFDL-CM3_89", ssp = "SSP3", rcp = "rcp45")



# ssp = "SSP3"
# rcp = "rcp45"
# gcm = "CanESM2"
# command = paste0("nohup python -u quantiles.py ",
# 	"/home/liruixue/repos/energy-code-release-2020",
# 	"/projection_inputs/configs/GMFD/TINV_clim/",
# 	"break2_Exclude/semi-parametric/Extraction_Configs",
# 	"/sacagawea/damage/price014/values_press/levels/",
# 	"median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy.yml  ",
# 	"--only-ssp=", ssp, "  --only-rcp=", rcp, "  --only-models=", gcm, 
# 	"  --do-gcmweights=no  ",
# 	"--suffix=_", gcm, "_damage-price014_median_fulladapt-levels_press ",
# 	"FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels ",
# 	"-FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels ",
# 	"FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels ",
# 	"-FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels ")



# python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy.yml  --only-ssp=SSP3  --only-rcp=rcp85 --only-models=CanESM2 --do-gcmweights=no --only-iam=high  --suffix=_CanESM2_damage-price014_median_fulladapt-levels_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels


# # bash script:
# for ssp in {1..5}
# do 
# 	# python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy.yml  --only-ssp=SSP3  --only-rcp=rcp85 --suffix=_damage-price014_median_fulladapt-levels_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels 
# 	python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy.yml  --only-ssp=SSP3  --only-rcp=rcp45 --suffix=_damage-price014_median_fulladapt-levels_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels 
# done 

# # run under risingverse-py27 environment, prospectus-tools/gcp/extract directory
# # # rcp85
# # python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy.yml  --only-ssp=SSP3  --only-rcp=rcp85 --suffix=_damage-price014_median_fulladapt-levels_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels 
# # # rcp45
# # python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy.yml  --only-ssp=SSP3  --only-rcp=rcp45 --suffix=_damage-price014_median_fulladapt-levels_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels 

# # # _dm
# # # rcp85
# # python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy_dm.yml  --only-ssp=SSP3   --only-rcp=rcp85 --suffix=_damage-price014_median_fulladapt-levels_dm_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels
# # # rcp45
# # # 
# python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy_dm.yml --only-ssp=SSP3   --only-rcp=rcp45 --suffix=_damage-price014_median_fulladapt-levels_dm_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels


# python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy_dm.yml  --only-ssp=SSP3  --only-rcp=rcp85  --only-models=CCSM4  --only-iam=high  --do-gcmweights=no  --suffix=_low_CanESM2_damage-price014_median_fulladapt-levels_dm_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels
