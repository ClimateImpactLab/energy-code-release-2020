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




# rcp85
python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy.yml  --only-ssp=SSP3  --only-rcp=rcp85 --suffix=_damage-price014_median_fulladapt-levels_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels 
# rcp45
python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy.yml  --only-ssp=SSP3  --only-rcp=rcp45 --suffix=_damage-price014_median_fulladapt-levels_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels 

# _dm
# rcp85
python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy_dm.yml  --only-ssp=SSP3   --only-rcp=rcp85 --suffix=_damage-price014_median_fulladapt-levels_dm_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels
# rcp45
python -u quantiles.py /home/liruixue/repos/energy-code-release-2020/projection_inputs/configs/GMFD/TINV_clim/break2_Exclude/semi-parametric/Extraction_Configs/sacagawea/damage/price014/values_press/levels/median/energy-extract-damage-levels-price014-median_OTHERIND_total_energy_dm.yml  --only-ssp=SSP3   --only-rcp=rcp45 --suffix=_damage-price014_median_fulladapt-levels_dm_press FD_FGLS_inter_OTHERIND_electricity_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_electricity_TINV_clim-histclim-price014-levels FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-price014-levels -FD_FGLS_inter_OTHERIND_other_energy_TINV_clim-histclim-price014-levels


if (price %in% c("price014", "price0", "price03")) {

    mean = do.call(load.median, c(args, proj_mode = '')) %>%
		rename(mean=value) %>% 
		dplyr::select(rcp, year, region, gcm, iam, mean) %>% 
		mutate(mean = mean / 0.0036)

	if(include_variance == TRUE){	
		var = do.call(load.median, c(args, proj_mode = '_dm')) %>% 
			mutate(sd=sqrt(value))%>% 
			dplyr::select(rcp, year, region, gcm, iam, sd) %>% 
			mutate(sd = sd / 0.0036)
	}
